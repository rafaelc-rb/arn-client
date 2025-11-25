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
  bool _isLoading = true;
  int _loadingProgress = 0;
  WebResourceError? _error;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _error = null;
              _loadingProgress = 0;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _loadingProgress = 100;
              _error = null;
              _retryCount = 0; // Reset retry count on success
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            debugPrint('Error code: ${error.errorCode}');
            debugPrint('Error type: ${error.errorType}');
            debugPrint('Failed URL: ${error.url}');

            setState(() {
              _error = error;
              _isLoading = false;
            });

            // Retry automático para erros de conexão
            if (_shouldRetry(error) && _retryCount < _maxRetries) {
              _retryWithDelay();
            }
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('HTTP error: ${error.response?.statusCode}');
          },
        ),
      )
      ..loadRequest(
        Uri.parse(widget.viewModel.url),
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      );
  }

  bool _shouldRetry(WebResourceError error) {
    // Retry para erros de timeout e conexão
    final errorDesc = error.description.toLowerCase();
    return error.errorType == WebResourceErrorType.hostLookup ||
        error.errorType == WebResourceErrorType.timeout ||
        errorDesc.contains('timeout') ||
        errorDesc.contains('connection') ||
        errorDesc.contains('network') ||
        errorDesc.contains('failed to connect') ||
        errorDesc.contains('unable to resolve') ||
        errorDesc.contains('err_connection') ||
        errorDesc.contains('err_network');
  }

  void _retryWithDelay() {
    // Aumenta o delay progressivamente
    final delay = Duration(seconds: 2 + (_retryCount * 2));
    Future.delayed(delay, () {
      if (mounted && _retryCount < _maxRetries) {
        setState(() {
          _retryCount++;
          _error = null;
          _isLoading = true;
        });
        // Tenta recarregar a URL original em vez de reload
        _controller.loadRequest(
          Uri.parse(widget.viewModel.url),
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        );
      }
    });
  }

  void _manualRetry() {
    setState(() {
      _retryCount = 0;
      _error = null;
      _isLoading = true;
    });
    // Recarrega a URL original com headers
    _controller.loadRequest(
      Uri.parse(widget.viewModel.url),
      headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: Stack(
          children: [
            // WebView
            WebViewWidget(controller: _controller),

            // Indicador de progresso
            if (_isLoading && _error == null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),

            // Tela de erro
            if (_error != null && !_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 24),
                        Text(
                          'Erro de Conexão',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getErrorMessage(_error!),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        if (_retryCount >= _maxRetries) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tentativas automáticas esgotadas',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _manualRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(WebResourceError error) {
    if (error.description.toLowerCase().contains('timeout')) {
      return 'A conexão com o servidor expirou. Verifique sua conexão com a internet e tente novamente.';
    } else if (error.errorType == WebResourceErrorType.hostLookup) {
      return 'Não foi possível encontrar o servidor. Verifique sua conexão com a internet.';
    } else {
      return 'Não foi possível carregar a página. Verifique sua conexão com a internet.';
    }
  }
}
