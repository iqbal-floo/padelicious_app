import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padelicious/widgets/padel_header.dart';

void main() {
  Future<void> pumpPushed(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const Scaffold(body: PadelHeader(title: 'Second', subtitle: 'page')),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
  }

  testWidgets('the back button has a 48px tap target and a real icon', (tester) async {
    await pumpPushed(tester);

    final size = tester.getSize(find.byType(BackCircleButton));
    expect(size, const Size(48, 48));
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('←'), findsNothing);
    expect(tester.getSemantics(find.byType(BackCircleButton)).label, contains('Back'));
  });

  testWidgets('a tap near the edge of the target still goes back', (tester) async {
    await pumpPushed(tester);

    // 2px inside the corner of the 48px box: outside the 40px circle,
    // where the old 36px button would have missed.
    final topLeft = tester.getTopLeft(find.byType(BackCircleButton));
    await tester.tapAt(topLeft + const Offset(6, 24));
    await tester.pumpAndSettle();

    expect(find.text('Second'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('the icon sits in the exact centre of the circle', (tester) async {
    await pumpPushed(tester);

    final button = tester.getCenter(find.byType(BackCircleButton));
    final icon = tester.getCenter(find.byIcon(Icons.arrow_back_rounded));
    expect(icon, button);
  });

  testWidgets('back on a root route does nothing instead of a black screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PadelHeader(title: 'Root'))));
    await tester.tap(find.byType(BackCircleButton));
    await tester.pumpAndSettle();
    expect(find.text('Root'), findsOneWidget);
  });
}
