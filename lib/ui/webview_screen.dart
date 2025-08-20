import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../viewmodel/webview_viewmodel.dart';

/// Tela que exibe o WebView com a URL fornecida pelo ViewModel.
class WebViewScreen extends StatefulWidget {
  final WebViewViewModel viewModel;
  const WebViewScreen({super.key, required this.viewModel});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Opcional: mostrar progresso de carregamento
          },
          onPageStarted: (String url) {
            // Opcional: mostrar loading
          },
          onPageFinished: (String url) {
            // Opcional: esconder loading
          },
          onWebResourceError: (WebResourceError error) {
            // Tratar erros de carregamento
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.viewModel.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
