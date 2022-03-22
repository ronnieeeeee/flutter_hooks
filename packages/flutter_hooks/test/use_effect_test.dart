import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  final effect = MockEffect();
  //unrelatedとは無関係なという意味である
  // HookBuilderの中で呼ぶことで順序の検証に使う
  final unrelated = MockWidgetBuild();
  List<Object>? parameters;

  Widget builder() {
    return HookBuilder(builder: (context) {
      useEffect(effect, parameters);
      unrelated();
      return Container();
    });
  }

  // 事後処理
  // 事前処理はsetUP
  tearDown(() {
    parameters = null;
    reset(unrelated);
    reset(effect);
  });

// このテストはなんだ？慣例か？
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useEffect(() {
          return null;
        }, []);
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
        ' │ useEffect\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useEffect calls callback on every build', (tester) async {
    // これらのMockのclassにはcall()が定義されているので
    // 変数に代入した後でeffect()でcall()を呼ぶことができる
    final effect = MockEffect();
    // 同じ階層にmock.dartというテスト用に作られたファイルがあり便利そうである
    //　Hooksのライフサイクルをmockで再現できるらしい
    // hook_widget_test.dartを参照しよう
    final dispose = MockDispose();

    when(effect()).thenReturn(dispose);

    Widget builder() {
      return HookBuilder(builder: (context) {
        useEffect(effect);
        unrelated();
        return Container();
      });
    }

    await tester.pumpWidget(builder());

    //hooksは呼び出しの順序が大事なので
    //mockitoの順序を検証するメソッドがよく呼ばれている

    // 複数モックの呼び出し順序の検証
    verifyInOrder([
      // 上のHookBuilderの呼び出し順の確認である when(effect()).thenReturn(dispose);の直後である
      effect(),
      unrelated(),
    ]);

    //失敗例が書かれているのでわかりやすい
    //https://www.gwtcenter.com/mockito-manual#:~:text=verifyZeroInteractions(mockTwo%2C%20mockThree)%3B-,8.%20%E5%86%97%E9%95%B7%E3%81%AA%E5%91%BC%E3%81%B3%E5%87%BA%E3%81%97%E3%82%92%E8%A6%8B%E3%81%A4%E3%81%91%E3%82%8B,-//%E3%83%A2%E3%83%83%E3%82%AF%E3%82%92%E4%BD%BF%E3%81%86

    verifyNoMoreInteractions(dispose);
    verifyNoMoreInteractions(effect);

    await tester.pumpWidget(builder());

    verifyInOrder([
      // TODO
      // hooksの仕様かな？推測だがbuilderを呼ぶことは2度目である
      // 何かしらキャッシュしたhooksがdisposeされ
      // builderの中の処理通りeffectが行われunrelatedが行われた。
      dispose(),
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(dispose);
    verifyNoMoreInteractions(effect);
  });

  testWidgets(
      'useEffect with parameters calls callback when changing from null to something',
      (tester) async {
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    // useEffectの第二引数であるparameters
    // このparameterは実際の開発ではよくcontroller.isXXXnなどが入ることご多い
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    //上のテストではdisposeが初めに走ったはずだが
    // useEffectの第二引数にparametersをセットすると
    // disposeが走らなくなった。
    // この差異に注目するべきであろう
    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);
  });

  testWidgets('useEffect adding parameters call callback', (tester) async {
    //このテストはparametersをセットし
    //parametersを追加し検証する
    //hooksがdisposeされることはなかった

    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['foo', 42];
    await tester.pumpWidget(builder());

    verifyInOrder([
      //　useEffectの第二引数であるparameterが変更されたのでeffectが走った
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);
  });

  testWidgets('useEffect removing parameters call callback', (tester) async {
    //上のテストではparametersの追加をしたが今回は要素を削除してみる
    //結果は上と同じ。parametersの要素数が変更されていることは共通しているからか？

    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = [];
    await tester.pumpWidget(builder());

    verifyInOrder([
      //　useEffectの第二引数であるparameterが変更されたのでeffectが走った
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);
  });
  testWidgets('useEffect changing parameters call callback', (tester) async {
// paramerterの値が変わった。ここのparameterは実際の開発ではよくcontroller.isXXXnなどが入ることご多い

// このテストで明らかになったことは要素数ではなく、要素の内容が変更されればdisposeは起こることはない
// つまりlistの状態に変更が起きればdisposeは起こることはない

    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['bar'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      //　useEffectの第二引数であるparameterが変更されたのでeffectが走った

      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);
  });
  testWidgets(
      'useEffect with same parameters but different arrays don t call callback',
      (tester) async {
// 同じ要素を再度代入し内容は同じlistを作り、それはトリガーに成り得るのか？のテストだが
// 結果は何も起きない。

    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(effect);
  });
  testWidgets(
      'useEffect with same array but different parameters don t call callback',
      (tester) async {
    // 同じ配列で異なるパラメータを持つuseEffectはコールバックを呼び出さない
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

// 上のテスト'useEffect adding parameters call callback'と同じような状況だが一つ違うのは
// 配列内の要素が再生成されているかどうか
// 上の例では
// parameters = ['foo'];
// parameters = ['foo', 42];
// 'foo'は同じだが参照を使いまわしているわけではない
// しかし今回の例は
// parameters = ['foo'];
// parameters!.add('bar');
// => ['foo','bar'];
// 配列の内容は同じだがfooの参照を使いまわしている
//
// 下記の配列は別物である
// parameters = ['foo'];
// parameters = ['foo', 42]; // effect!
//
// parameters = ['foo'];
// parameters!.add(42); // Don't exec effect.
//

    parameters!.add('bar');
    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(effect);
  });

  testWidgets('useEffect disposer called whenever callback called',
      (tester) async {
    final effect = MockEffect();
    List<Object>? parameters;

    Widget builder() {
      return HookBuilder(builder: (context) {
        useEffect(effect, parameters);
        return Container();
      });
    }

    parameters = ['foo'];
    final disposerA = MockDispose();
    when(effect()).thenReturn(disposerA);

    await tester.pumpWidget(builder());

    // effectが一度走る、build()されたので当然である
    verify(effect()).called(1);
    // それからeffectが呼ばれることはない
    verifyNoMoreInteractions(effect);
    // disposerAは呼ばれることはなかった
    verifyZeroInteractions(disposerA);

    await tester.pumpWidget(builder());

    //もう一度buildしてもparameterに変化はないので
    //何も起こらないのは当然である
    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerA);

    //parameterに変更があった
    parameters = ['bar'];
    final disposerB = MockDispose();
    when(effect()).thenReturn(disposerB);

    await tester.pumpWidget(builder());

    verifyInOrder([
      // parameterの変更に伴いeffectが走る
      effect(),
      // そしてcleanupであるdisposerAが走る
      disposerA(),
    ]);
    // それ以降はdisposerAとeffectが呼ばれることはない
    verifyNoMoreInteractions(disposerA);
    verifyNoMoreInteractions(effect);
    // disposerBはまだ呼ばれてはいない、当然である
    verifyZeroInteractions(disposerB);

    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(disposerA);
    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerB);

    // HookWidgetがdisposeされContainerWidgetが生成された
    await tester.pumpWidget(Container());

    // 当然disposeされたのでdisposerBが一度走る
    verify(disposerB()).called(1);
    verifyNoMoreInteractions(disposerB);
    verifyNoMoreInteractions(disposerA);
    verifyNoMoreInteractions(effect);
  });
}

class MockEffect extends Mock {
  VoidCallback? call();
}

class MockWidgetBuild extends Mock {
  // callはdartの言語仕様の一つらしい
  // https://qiita.com/lacolaco/items/acdb066a116353d02ae4
  void call();
}
