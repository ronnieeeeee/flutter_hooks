import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_hooks/flutter_hooks_287.dart';
import 'package:flutter_hooks/src/sandbox.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mock.dart';

void main() {
  testWidgets('useListenableCallback', (tester) async {
    // await tester.pumpWidget(
    //     MaterialApp(home: Builder(builder: (context) => Example())));
    late TextEditingController listenable;
    Future<void> pump() {
      return tester.pumpWidget(HookBuilder(builder: (context) {
        listenable = useTextEditingController();
        // final textIsNotEmpty =
        //     useListenableMap(listenable, () => listenable.text.isNotEmpty); //2
        final textIsNotEmpty =
            useMemoized2(listenable, () => listenable.text.isNotEmpty);
        return Container();
      }));
    }

    await pump();

    final element = tester.element(find.byType(HookBuilder));
    expect(element.dirty, false);
    listenable.value = TextEditingValue(text: "hello");
    expect(element.dirty, true);
    await tester.pump();
    expect(element.dirty, false);
  });
}
