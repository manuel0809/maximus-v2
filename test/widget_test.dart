import 'package:flutter_test/flutter_test.dart';
import 'package:maximus_v2/main.dart';
import 'package:sizer/sizer.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // We ignore the actual initialization errors in the test since we are just checking if it can be pumped.
    // SplashScreen tries to connect to Supabase which will fail.
    
    await tester.pumpWidget(const MyApp());
    
    // We expect to find the Sizer widget at least.
    expect(find.byType(Sizer), findsOneWidget);
  });
}
