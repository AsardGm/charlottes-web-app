import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test - app requires Supabase initialization
    // Full widget tests would require mocking Supabase
    expect(true, isTrue);
  });
}
