import 'package:flutter/material.dart';
import 'flutter_hooks.dart';
import 'src/sandbox.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Example(),
    );
  }
}

var i = 0;
class Example extends HookWidget {
  const Example({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    i = i + 1;
    final TextEditingController listenable = useTextEditingController();
    final bool textIsNotEmpty =
        useListenableMap(listenable, () => listenable.text.isNotEmpty);
    print('${listenable.text}, $textIsNotEmpty, ${textIsNotEmpty.hashCode}');
    return Scaffold(
        body: Column(
      children: [
        TextField(
          controller: listenable,
        ),
        ElevatedButton(
            onPressed: textIsNotEmpty ? () => print("Pressed!") : null,
            child: Text("Button")),
      ],
    ));
  }
}

U useListenableMap<T extends Listenable, U>(
    T listenable, U Function() callback) {
  // callbackをメモ化
  final f = useCallback(callback, []);
  // return用にsetStateを使用している
  // メモ化したcallbackを実行した結果はstateに入り返される
  final _state = useState(f());

  useEffect(() {
    // useEffectがしていることは
    // とてもシンプルでこれだけ
    // メモ化されたcallbackを_state.valueに入れてキャッシュし
    // listenerをセットしdispose時にアンセットする
    // 依存配列に変更を検知し値を変えるタイミングをコントロールする
    void _listener() {
      _state.value = f();
    }

    listenable.addListener(_listener);
    return () => listenable.removeListener(_listener);
  }, [listenable]);

  return _state.value;
}


bool useIsNotEmptyTextField(TextEditingController textEditingController) {
  final hasNotEmpty = useState(textEditingController.text.isNotEmpty);
  useEffect(() {
    void l() {
      hasNotEmpty.value = textEditingController.text.isNotEmpty;
    }

    textEditingController.addListener(l);
    return () => textEditingController.removeListener(l);
  }, [textEditingController]);

  return hasNotEmpty.value;
}
