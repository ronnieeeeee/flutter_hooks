import 'package:flutter/material.dart';
import 'flutter_hooks.dart';

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

class Example extends HookWidget {
  const Example({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = useTextEditingController();
    final textIsNotEmpty = useIsNotEmptyTextField(ctrl); //2
    return Scaffold(
        body: Column(
      children: [
        TextField(
          controller: ctrl,
        ),
        ElevatedButton(
            onPressed: textIsNotEmpty ? () => print("Pressed!") : null,
            child: Text("Button")),
      ],
    ));
  }
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
