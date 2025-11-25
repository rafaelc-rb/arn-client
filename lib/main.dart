import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/webview_screen.dart';
import 'viewmodel/webview_viewmodel.dart';

/// URL de redirecionamento
const String kRedirectUrl =
    'https://aranetgo.sgplocal.com.br/accounts/central/login';

void main() {
  // Injeção de dependência simples para o ViewModel
  runApp(MainApp(viewModel: WebViewViewModel(kRedirectUrl)));
}

/// Widget principal do app
class MainApp extends StatelessWidget {
  final WebViewViewModel viewModel;
  const MainApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: WebViewScreen(viewModel: viewModel),
    );
  }
}
