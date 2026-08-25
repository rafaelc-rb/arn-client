import 'package:flutter/material.dart';

/// Barra de progresso exibida no topo da tela enquanto a página carrega.
class WebViewLoadingBar extends StatelessWidget {
  const WebViewLoadingBar({super.key, required this.progress});

  /// Progresso de carregamento, de 0 a 100.
  final int progress;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: LinearProgressIndicator(value: progress / 100),
    );
  }
}
