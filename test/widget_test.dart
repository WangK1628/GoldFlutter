import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gold_monitor/ui/screens/shell_screen.dart';

void main() {
  testWidgets('app smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GoldMonitorApp()));
    await tester.pump();
    expect(find.text('Gold Monitor'), findsOneWidget);
  });
}
