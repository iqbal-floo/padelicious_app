import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padelicious/widgets/roster_grid.dart';

RosterPerson person(int i, {String status = 'confirmed', List<String> tags = const []}) => RosterPerson(
      id: 'p$i',
      name: 'Player $i',
      initials: 'P${i % 10}',
      colorIndex: i % 8,
      username: 'player$i',
      status: status,
      tags: tags,
    );

Widget host(Widget child, {double width = 400}) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );

void main() {
  testWidgets('the avatar stack never overflows its space and counts the rest', (tester) async {
    final people = [for (var i = 0; i < 20; i++) person(i)];

    // 120px fits 5 avatars (28 + 4×22); with 20 people one slot goes to "+N".
    await tester.pumpWidget(host(AvatarStack(people: people, max: 6), width: 120));

    expect(tester.takeException(), isNull);
    expect(find.text('+16'), findsOneWidget);
    expect(tester.getSize(find.byType(AvatarStack)).width, lessThanOrEqualTo(120));

    // Plenty of room: capped by max.
    await tester.pumpWidget(host(AvatarStack(people: people, max: 6)));
    expect(find.text('+14'), findsOneWidget);

    // Fewer people than fit: no "+N".
    await tester.pumpWidget(host(AvatarStack(people: people.take(3).toList())));
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('tiles show the host star, waitlist and request captions, and no-show', (tester) async {
    await tester.pumpWidget(host(SingleChildScrollView(
      child: RosterGrid(people: [
        person(1, tags: const ['host']),
        person(2, status: 'waitlisted'),
        person(3, status: 'requested'),
        person(4, tags: const ['no_show']),
      ]),
    )));

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('Waitlist'), findsOneWidget);
    expect(find.text('Request'), findsOneWidget);
    expect(find.text('No-show'), findsOneWidget);
    expect(find.text('@player1'), findsOneWidget);
    expect(person(4, tags: const ['no_show']).canPlay, isFalse);
    expect(person(2, status: 'waitlisted').canPlay, isFalse);
    expect(person(1).canPlay, isTrue);
  });

  testWidgets('the add tile is shown first and tiles report taps', (tester) async {
    RosterPerson? tapped;
    var added = false;

    await tester.pumpWidget(host(SingleChildScrollView(
      child: RosterGrid(
        people: [person(7)],
        onTap: (p) => tapped = p,
        onAdd: () => added = true,
      ),
    )));

    await tester.tap(find.text('Add'));
    await tester.tap(find.text('Player 7'));
    expect(added, isTrue);
    expect(tapped?.id, 'p7');
  });
}
