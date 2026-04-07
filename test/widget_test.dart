import 'package:flutter_test/flutter_test.dart';

import 'package:sgu_ukm/app.dart';

void main() {
  testWidgets('shows SGU login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SguUkmApp());

    expect(find.text('Swiss German University'), findsOneWidget);
    expect(find.text('Club Management App'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
