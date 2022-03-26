import 'package:flutter/material.dart';

import 'framework.dart';

T useMemoized2<T>(
  TextEditingController listenable,
  T Function() valueBuilder,
    [
  List<Object?>? keys,
]) {
  return use(
    _Memoized2Hook(
      listenable,
      valueBuilder
    ),
  );
}

class _Memoized2Hook<T> extends Hook<T> {
  const _Memoized2Hook(
    this.listenable,
    this.valueBuilder, [
        List<Object?>? keys,
      ]) : super(keys: keys);

  final TextEditingController listenable;
  final T Function() valueBuilder;

  @override
  _Memoized2HookState<T> createState() => _Memoized2HookState<T>();
}

class _Memoized2HookState<T>
    extends HookState<T, _Memoized2Hook<T>> {
  T? state = null;
  void Function()? disposer;

  @override
  void initHook() {
    super.initHook();
    hook.listenable.addListener(_listener);
  }

  @override
  void didUpdateHook(_Memoized2Hook<T> oldHook) {
    super.didUpdateHook(oldHook);

    // 第二引数がセットされていない場合
    //
    if (hook.keys == null) {
      // セットされたdisposertを呼びだし
      disposer?.call();
      // effectをまたdisposerにセットする
      // scheduleEffect();
      hook.listenable.removeListener(_listener);
    }
    // 逆に第二引数がセットされている場合は
    // parent widgetがrebuildしてもeffectを実行しない
  }
  @override
  T build(BuildContext context) {
    return state ?? hook.valueBuilder();
  }

  void _listener() {
    state = hook.valueBuilder();
    setState(() {});
  }

  @override
  void dispose() {
    print('dispose');
    hook.listenable.removeListener(_listener);
  }
    // void dispose() => disposer?.call();

// effectをdisposerにセットする
//   void scheduleEffect() {
//     disposer = hook.listenable.removeListener(() { })
//   }

    @override
    String get debugLabel => 'useMemoized2<$T>';
  // }
}
//
// U useListenableCallback<T extends Listenable, U>(
//     T listenable, U Function() callback,
//     [List<Object?>? keys]) {
//   return use(_ListenableCallbackHook(listenable, callback, keys)).value;
// }
//
// class _ListenableCallbackHook<T extends Listenable, U>
//     extends Hook<ValueNotifier<U>> {
//   const _ListenableCallbackHook(this.listenable, this.callback,
//       [List<Object?>? keys])
//       : super(keys: keys);
//   final T listenable;
//   final U Function() callback;
//
//   @override
//   _ListenableCallbackHookState<T, U> createState() =>
//       _ListenableCallbackHookState();
// }
//
// class _ListenableCallbackHookState<T extends Listenable, U>
//     extends HookState<ValueNotifier<U>, _ListenableCallbackHook<T, U>> {
//   late U value = hook.callback();
//   late final _state = ValueNotifier<U>(hook.callback())..addListener(_listener);
//
//   @override
//   void initHook() {
//     super.initHook();
//     print('initHook');
//   }
//
//   @override
//   void didUpdateHook(_ListenableCallbackHook<T, U> oldHook) {
//     super.didUpdateHook(oldHook);
//     print('didUpdateHook');
//     //ValueChangeHookState
//     if (hook.callback() != oldHook.callback()) {
//       print('hook.callback() != oldHook.callback()');
//       value = hook.callback();
//       setState(() {});
//     }
//     // if (hook.listenable != oldHook.listenable) {
//     //   oldHook.listenable.removeListener(_listener);
//     //   hook.listenable.addListener(_listener);
//     // }
//   }
//
//   // @override
//   // U build(BuildContext context) {
//   //   print('build');
//   //   return value;
//   // }
//   @override
//   ValueNotifier<U> build(BuildContext context) {
//     print('build');
//     return _state;
//   }
//   // @override
//   // void build(BuildContext context) {}
//
//   void _listener() {
//     _state.value = hook.callback();
//     value = hook.callback();
//   }
//
//   @override
//   void dispose() {
//     hook.listenable.removeListener(_listener);
//   }
//
//   @override
//   String get debugLabel => 'useListenableCallback';
//
//   @override
//   bool get debugSkipValue => true;
// }
