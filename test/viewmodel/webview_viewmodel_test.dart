import 'package:flutter_test/flutter_test.dart';
import 'package:aranet_go/viewmodel/webview_viewmodel.dart';

void main() {
  group('WebViewViewModel', () {
    test('deve armazenar a URL corretamente', () {
      const url = 'https://aranetgo.sgplocal.com.br/accounts/central/login';
      final viewModel = WebViewViewModel(url);
      expect(viewModel.url, url);
    });
  });
}
