import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:idena_p2p/app.dart';
import 'package:idena_p2p/providers/account_provider.dart';
import 'package:idena_p2p/providers/auth_provider.dart';

void main() {
  testWidgets('App starts with home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AccountProvider()),
        ],
        child: const IdenaApp(),
      ),
    );

    // Allow async initialization to complete
    await tester.pumpAndSettle();

    // Verify that we start with the home screen
    expect(find.text('Idena Wallet'), findsOneWidget);
  });
}
