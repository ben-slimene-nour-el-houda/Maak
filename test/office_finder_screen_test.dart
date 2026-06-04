import 'package:admin_process/screens/office_finder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Navigate draws a polyline route on the map', (tester) async {
    tester.view.physicalSize = const Size(2000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: OfficeFinderScreen(),
      ),
    );

    expect(find.byKey(const Key('office_route_polyline')), findsNothing);

    final buttonFinder = find.byKey(const Key('navigate_button_1'));
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('office_route_polyline')), findsOneWidget);
  });
}
