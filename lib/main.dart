import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';
import 'ui/webview_screen.dart';
import 'viewmodel/webview_viewmodel.dart';

/// URL de redirecionamento
const String kRedirectUrl =
    'https://aranetgo.sgplocal.com.br/accounts/central/login';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Declara explicitamente o layout ponta a ponta: a partir do Android 15
  // (API 35+) isso já é o padrão do sistema, mas fixar aqui deixa a
  // intenção clara e garante o mesmo comportamento em versões anteriores do
  // Android (o conteúdo continua protegido pelos SafeArea da tela).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: WebViewScreen(viewModel: viewModel),
    );
  }
}
