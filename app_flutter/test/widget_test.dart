import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GestionCanchasApp(),
    );

    expect(find.text('Gestión de Clientes'), findsOneWidget);
  });
}