import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        // AlwaysStoppedAnimation 常に特定の値で停止するアニメーション
        useListenable(const AlwaysStoppedAnimation(42));
        return const SizedBox();
      }),
    );

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useListenable: AlwaysStoppedAnimation<int>#00000(▶ 42; paused)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useListenable', (tester) async {
    var listenable = ValueNotifier(0);

    Future<void> pump() {
      return tester.pumpWidget(HookBuilder(
        builder: (context) {
          useListenable(listenable);
          return Container();
        },
      ));
    }

    await pump();

    final element = tester.firstElement(find.byType(HookBuilder));

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    // rebuildを要請するdirtyフラグはfalse
    expect(element.dirty, false);
    // ValueNotifierのvalueが変更す
    listenable.value++;
    //ValueNotifierのvalueの状態が変更すると
    //elementのdirtyがtrueになる
    expect(element.dirty, true);
    await tester.pump();
    // pumpによってbuildをすればもちろん元に戻る
    expect(element.dirty, false);

    //現在の状態をpreviousListenableとしてfinalで定義
    final previousListenable = listenable;
    // 新たなlistenableをassign
    listenable = ValueNotifier(0);

    await pump();

    // おそらくだがhooksのテスト
    // 新たなlistenableが作られたので前回のhooksはcurrentHooksではなくなりアクティブではなくなったことをテストしている？
    // ignore: invalid_use_of_protected_member
    expect(previousListenable.hasListeners, false);
    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(element.dirty, false);

    // SizedBoxのみpumpWidgetすることでhookBuilderがdisposeされた？
    await tester.pumpWidget(const SizedBox());

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, false);

    listenable.dispose();
    previousListenable.dispose();
  });

  testWidgets('useListenable should handle null', (tester) async {
    ValueNotifier<int>? listenable;

    Future<void> pump() {
      return tester.pumpWidget(HookBuilder(
        builder: (context) {
          useListenable(listenable);
          return Container();
        },
      ));
    }

    await pump();

    final element = tester.firstElement(find.byType(HookBuilder));
    expect(element.dirty, false);

    final notifier = ValueNotifier(0);
    listenable = notifier;
    await pump();

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);

    listenable = null;
    await pump();

    // 参照渡しをしているのでhooksで管理しようと参照元にnullを入れれば使えなくなるということだろうか？
    // ignore: invalid_use_of_protected_member
    expect(notifier.hasListeners, false);

    await tester.pumpWidget(const SizedBox());

    notifier.dispose();
  });
}
