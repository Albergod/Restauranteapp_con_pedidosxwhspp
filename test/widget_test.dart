import 'package:flutter_test/flutter_test.dart';
import 'package:restaurante_app/main.dart';

void main() {
  testWidgets('App should render HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const RestauranteApp());

    expect(find.text('Pedidos del Restaurante'), findsOneWidget);
  });
}
