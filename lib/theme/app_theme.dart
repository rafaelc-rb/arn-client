import 'package:flutter/material.dart';

/// Cores da marca, usadas para semear os esquemas de cores claro e escuro.
abstract final class AppColors {
  static const Color primaryRed = Color(0xFFE31C24);
  static const Color primaryRedDark = Color(0xFF981A1C);

  /// Cor de fundo da tela enquanto a página carrega.
  static const Color loadingBackground = Color(0xFFF1F1F1);
}

/// Configuração do tema do aplicativo.
abstract final class AppTheme {
  static ThemeData get lightTheme => _themeFor(Brightness.light);

  static ThemeData get darkTheme => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryRed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? AppColors.loadingBackground
          : colorScheme.surface,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
