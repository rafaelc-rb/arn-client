import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Estados possíveis da página exibida no WebView.
enum WebViewPageStatus {
  /// A página (ou um retry automático) está em andamento.
  loading,

  /// A página foi carregada com sucesso.
  loaded,

  /// A navegação principal falhou.
  error,
}

/// ViewModel responsável pelo estado da tela e pelas regras de negócio do
/// WebView (progresso de carregamento, retry automático com backoff e
/// mensagens de erro amigáveis).
///
/// A View apenas repassa os eventos do [WebViewController] para este
/// ViewModel e renderiza o estado exposto por ele — toda a lógica fica aqui,
/// isolada e testável sem precisar de um WebView real (padrão MVVM).
class WebViewViewModel extends ChangeNotifier {
  WebViewViewModel(
    this.url, {
    int maxRetries = 3,
    Duration Function(int retryCount)? retryDelayBuilder,
    Future<void> Function(Duration duration)? scheduler,
  }) : _maxRetries = maxRetries,
       _retryDelayBuilder = retryDelayBuilder ?? _defaultRetryDelay,
       _scheduler = scheduler ?? Future.delayed;

  /// URL inicial a ser exibida no WebView.
  final String url;

  final int _maxRetries;
  final Duration Function(int retryCount) _retryDelayBuilder;
  final Future<void> Function(Duration duration) _scheduler;

  /// Recarrega a página atual. Deve ser conectado pela View logo após criar
  /// o [WebViewController] (ver [attachReloader]).
  Future<void> Function()? _reload;

  WebViewPageStatus _status = WebViewPageStatus.loading;
  int _progress = 0;
  WebResourceError? _error;
  int _retryCount = 0;
  bool _retryInFlight = false;

  WebViewPageStatus get status => _status;

  /// Progresso de carregamento da página, de 0 a 100.
  int get progress => _progress;

  /// Último erro de navegação da página principal, ou `null`.
  WebResourceError? get error => _error;

  /// Quantidade de tentativas automáticas de retry já realizadas.
  int get retryCount => _retryCount;

  /// `true` quando o limite de tentativas automáticas foi atingido.
  bool get retriesExhausted => _retryCount >= _maxRetries;

  static Duration _defaultRetryDelay(int retryCount) =>
      Duration(seconds: 2 + retryCount * 2);

  /// Conecta a função de recarregamento da página. Chamado uma única vez
  /// pela View, imediatamente após criar o [WebViewController].
  void attachReloader(Future<void> Function() reload) {
    _reload = reload;
  }

  void onPageStarted(String url) {
    _status = WebViewPageStatus.loading;
    _error = null;
    _progress = 0;
    notifyListeners();
  }

  void onProgressChanged(int progress) {
    _progress = progress;
    notifyListeners();
  }

  void onPageFinished(String url) {
    // Quando a navegação principal falha (ex.: sem internet), o próprio
    // WebView costuma navegar internamente para sua página nativa de erro
    // (a interstitial "Webpage not available") e dispara onPageFinished
    // para ela. Isso não é um carregamento bem-sucedido — se já estamos em
    // estado de erro, só uma nova tentativa (onPageStarted) deve tirar a
    // tela desse estado, senão a tela de erro própria do app seria
    // encoberta pela página de erro nativa do WebView.
    if (_status == WebViewPageStatus.error) return;

    _status = WebViewPageStatus.loaded;
    _progress = 100;
    _error = null;
    _retryCount = 0;
    notifyListeners();
  }

  /// Trata uma falha de carregamento reportada pelo WebView.
  ///
  /// O WebView reporta erros de *qualquer* recurso da página (imagens,
  /// scripts, chamadas de API), não só da navegação principal. Só a falha da
  /// navegação principal deve derrubar a tela para o estado de erro —
  /// ignorar isso faria a tela de erro aparecer, por exemplo, por causa de um
  /// script de analytics que falhou ao carregar.
  void onWebResourceError(WebResourceError error) {
    if (error.isForMainFrame == false) return;

    _error = error;
    _status = WebViewPageStatus.error;
    notifyListeners();

    if (_isRetryable(error) && !retriesExhausted) {
      _scheduleAutoRetry();
    }
  }

  /// Reinicia o contador de tentativas e recarrega a página. Usado pelo
  /// botão "Tentar novamente" exibido na tela de erro.
  void retryNow() {
    _retryCount = 0;
    _reloadFromError();
  }

  Future<void> _scheduleAutoRetry() async {
    if (_retryInFlight) return;
    _retryInFlight = true;
    final delay = _retryDelayBuilder(_retryCount);
    await _scheduler(delay);
    _retryInFlight = false;

    // O usuário já pode ter corrigido a conexão e disparado um retry manual,
    // ou a página pode ter carregado sozinha nesse meio-tempo.
    if (_status != WebViewPageStatus.error) return;

    _retryCount++;
    _reloadFromError();
  }

  void _reloadFromError() {
    _status = WebViewPageStatus.loading;
    _error = null;
    _progress = 0;
    notifyListeners();
    unawaited(_reload?.call());
  }

  bool _isRetryable(WebResourceError error) {
    const retryableKeywords = [
      'timeout',
      'connection',
      'network',
      'failed to connect',
      'unable to resolve',
      'err_connection',
      'err_network',
    ];
    final description = error.description.toLowerCase();
    return error.errorType == WebResourceErrorType.hostLookup ||
        error.errorType == WebResourceErrorType.timeout ||
        retryableKeywords.any(description.contains);
  }

  /// Mensagem amigável para o erro atual, pronta para exibição na UI.
  String get errorMessage {
    final currentError = _error;
    if (currentError == null) return '';

    if (currentError.description.toLowerCase().contains('timeout') ||
        currentError.errorType == WebResourceErrorType.timeout) {
      return 'A conexão com o servidor expirou. Verifique sua conexão com '
          'a internet e tente novamente.';
    }
    if (currentError.errorType == WebResourceErrorType.hostLookup) {
      return 'Não foi possível encontrar o servidor. Verifique sua conexão '
          'com a internet.';
    }
    return 'Não foi possível carregar a página. Verifique sua conexão com '
        'a internet.';
  }
}
