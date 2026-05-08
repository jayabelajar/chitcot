import 'package:bluemesh_chat/app/app_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App renders onboarding or home title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BlueMeshRootApp()));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    final hasOnboarding = find.text('BlueMesh').evaluate().isNotEmpty;
    final hasHome = find.text('Chat').evaluate().isNotEmpty && find.text('Peers').evaluate().isNotEmpty;
    expect(hasOnboarding || hasHome, isTrue);
  });
}
