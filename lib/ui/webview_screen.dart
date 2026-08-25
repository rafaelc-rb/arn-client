import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../viewmodel/webview_viewmodel.dart';
import 'widgets/webview_error_view.dart';
import 'widgets/webview_loading_bar.dart';

/// Tela que exibe o WebView com a URL fornecida pelo [WebViewViewModel].
///
/// Esta View é intencionalmente "burra": repassa os eventos de navegação
/// para o ViewModel e renderiza o estado que ele expõe, sem lógica de
/// negócio própria (padrão MVVM).
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.viewModel});

  final WebViewViewModel viewModel;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  WebViewViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
    _viewModel.attachReloader(() => _controller.reload());
  }

  WebViewController _buildController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: _viewModel.onProgressChanged,
          onPageStarted: _viewModel.onPageStarted,
          onPageFinished: _viewModel.onPageFinished,
          onWebResourceError: _viewModel.onWebResourceError,
        ),
      )
      ..loadRequest(Uri.parse(_viewModel.url));
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (mounted) {
      // Sem histórico dentro do WebView: deixa o sistema tratar o "voltar"
      // normalmente (ex.: fechar o app).
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              final vm = _viewModel;
              return Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (vm.status == WebViewPageStatus.loading)
                    WebViewLoadingBar(progress: vm.progress),
                  if (vm.status == WebViewPageStatus.error)
                    WebViewErrorView(
                      message: vm.errorMessage,
                      retriesExhausted: vm.retriesExhausted,
                      onRetry: vm.retryNow,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
