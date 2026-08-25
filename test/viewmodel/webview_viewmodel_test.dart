import 'package:aranet_go/viewmodel/webview_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _url = 'https://aranetgo.sgplocal.com.br/accounts/central/login';

WebResourceError _errorOf({
  WebResourceErrorType? errorType,
  String description = 'generic error',
  bool? isForMainFrame = true,
}) {
  return WebResourceError(
    errorCode: -1,
    description: description,
    errorType: errorType,
    isForMainFrame: isForMainFrame,
  );
}

/// Cria um ViewModel cujos retries automáticos disparam sem espera real,
/// permitindo testar o backoff de forma determinística e rápida.
WebViewViewModel _viewModel({
  int maxRetries = 3,
  List<Duration>? requestedDelays,
}) {
  return WebViewViewModel(
    _url,
    maxRetries: maxRetries,
    retryDelayBuilder: (retryCount) {
      final delay = Duration(seconds: 2 + retryCount * 2);
      requestedDelays?.add(delay);
      return delay;
    },
    scheduler: (duration) async {},
  );
}

/// Aguarda o encadeamento assíncrono fire-and-forget do retry automático
/// (agendamento -> scheduler fake -> reload) terminar de rodar.
Future<void> _flushAutoRetry() => Future<void>.delayed(Duration.zero);

void main() {
  group('WebViewViewModel', () {
    test('estado inicial é loading, com progresso zerado e sem erro', () {
      final viewModel = _viewModel();
      expect(viewModel.url, _url);
      expect(viewModel.status, WebViewPageStatus.loading);
      expect(viewModel.progress, 0);
      expect(viewModel.error, isNull);
      expect(viewModel.retryCount, 0);
    });

    test('onProgressChanged apenas atualiza o progresso', () {
      final viewModel = _viewModel();
      viewModel.onProgressChanged(42);
      expect(viewModel.progress, 42);
      expect(viewModel.status, WebViewPageStatus.loading);
    });

    test('onPageFinished marca como loaded e zera retries e erro', () {
      final viewModel = _viewModel();
      viewModel.onWebResourceError(_errorOf());
      expect(viewModel.status, WebViewPageStatus.error);

      viewModel.onPageFinished(_url);

      expect(viewModel.status, WebViewPageStatus.loaded);
      expect(viewModel.progress, 100);
      expect(viewModel.error, isNull);
      expect(viewModel.retryCount, 0);
    });

    test('onPageStarted volta para loading e limpa o erro anterior', () {
      final viewModel = _viewModel();
      viewModel.onWebResourceError(_errorOf());

      viewModel.onPageStarted(_url);

      expect(viewModel.status, WebViewPageStatus.loading);
      expect(viewModel.progress, 0);
      expect(viewModel.error, isNull);
    });

    test(
      'erro de um recurso secundário (não é a navegação principal) é ignorado',
      () {
        final viewModel = _viewModel();
        viewModel.onWebResourceError(_errorOf(isForMainFrame: false));

        expect(viewModel.status, WebViewPageStatus.loading);
        expect(viewModel.error, isNull);
      },
    );

    test(
      'erro não retryável entra em estado de erro sem agendar retry automático',
      () async {
        final reloads = <void>[];
        final viewModel = _viewModel()
          ..attachReloader(() async {
            reloads.add(null);
          });

        viewModel.onWebResourceError(
          _errorOf(errorType: WebResourceErrorType.authentication),
        );
        await _flushAutoRetry();

        expect(viewModel.status, WebViewPageStatus.error);
        expect(reloads, isEmpty);
      },
    );

    test(
      'erro retryável agenda um retry automático que recarrega a página',
      () async {
        var reloadCount = 0;
        final delays = <Duration>[];
        final viewModel = _viewModel(requestedDelays: delays)
          ..attachReloader(() async {
            reloadCount++;
          });

        viewModel.onWebResourceError(
          _errorOf(errorType: WebResourceErrorType.hostLookup),
        );
        await _flushAutoRetry();

        expect(reloadCount, 1);
        expect(viewModel.retryCount, 1);
        expect(viewModel.status, WebViewPageStatus.loading);
        expect(delays, [const Duration(seconds: 2)]);
      },
    );

    test('retries automáticos param ao atingir o limite configurado', () async {
      var reloadCount = 0;
      final viewModel = _viewModel(maxRetries: 2);
      viewModel.attachReloader(() async {
        reloadCount++;
        // Cada reload volta a falhar, simulando uma queda de conexão persistente.
        viewModel.onWebResourceError(
          _errorOf(errorType: WebResourceErrorType.timeout),
        );
      });

      viewModel.onWebResourceError(
        _errorOf(errorType: WebResourceErrorType.timeout),
      );
      // Uma iteração por retry esperado, mais uma extra para garantir que
      // nenhum retry a mais seja disparado.
      for (var i = 0; i < 4; i++) {
        await _flushAutoRetry();
      }

      expect(reloadCount, 2);
      expect(viewModel.retryCount, 2);
      expect(viewModel.retriesExhausted, isTrue);
      expect(viewModel.status, WebViewPageStatus.error);
    });

    test(
      'retryNow zera o contador, limpa o erro e recarrega imediatamente',
      () async {
        var reloadCount = 0;
        final viewModel = _viewModel(maxRetries: 1)
          ..attachReloader(() async {
            reloadCount++;
          });

        viewModel.onWebResourceError(
          _errorOf(errorType: WebResourceErrorType.timeout),
        );
        await _flushAutoRetry();
        expect(viewModel.retriesExhausted, isTrue);

        viewModel.retryNow();

        expect(viewModel.retryCount, 0);
        expect(viewModel.error, isNull);
        expect(viewModel.status, WebViewPageStatus.loading);
        expect(reloadCount, 2); // 1 retry automático + 1 manual
      },
    );

    group('errorMessage', () {
      test('é vazio quando não há erro', () {
        expect(_viewModel().errorMessage, isEmpty);
      });

      test('descreve timeout', () {
        final viewModel = _viewModel()
          ..onWebResourceError(
            _errorOf(errorType: WebResourceErrorType.timeout),
          );
        expect(viewModel.errorMessage, contains('expirou'));
      });

      test('descreve falha de resolução de host', () {
        final viewModel = _viewModel()
          ..onWebResourceError(
            _errorOf(errorType: WebResourceErrorType.hostLookup),
          );
        expect(viewModel.errorMessage, contains('encontrar o servidor'));
      });

      test('usa mensagem genérica para os demais erros', () {
        final viewModel = _viewModel()
          ..onWebResourceError(
            _errorOf(errorType: WebResourceErrorType.unknown),
          );
        expect(viewModel.errorMessage, contains('Não foi possível carregar'));
      });
    });
  });
}
