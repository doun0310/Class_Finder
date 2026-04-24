import 'package:class_finder/main.dart';
import 'package:class_finder/services/app_state.dart';
import 'package:class_finder/services/auth_repository.dart';
import 'package:class_finder/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthService(LocalAuthRepository()),
          ),
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const ClassFinderApp(),
      ),
    );

    expect(find.text('ClassFinder'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();
  });
}
