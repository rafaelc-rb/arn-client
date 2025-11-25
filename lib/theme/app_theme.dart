import 'package:flutter/material.dart';

/// Cores do tema baseadas na logo
class AppColors {
  // Cores primárias da logo
  static const Color primaryRed = Color(0xFFE31C24);
  static const Color primaryRedDark = Color(0xFF981A1C);

  // Cor de fundo da tela de carregamento
  static const Color loadingBackground = Color(0xFFF1F1F1);
}

/// Configuração do tema do aplicativo
class AppTheme {
  /// Tema claro do aplicativo
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryRed,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        primary: AppColors.primaryRed,
      ),
    );
  }

  /// Tema escuro do aplicativo (opcional, para uso futuro)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryRed,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        primary: AppColors.primaryRed,
        brightness: Brightness.dark,
      ),
    );
  }
}
