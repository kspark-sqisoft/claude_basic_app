import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'router.dart';
import 'theme.dart';

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Todo',
      themeMode: ThemeMode.system,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // 시스템 모드 변경에 즉시 반응하도록 builder 안에서 brightness를 읽는다.
        final brightness = MediaQuery.platformBrightnessOf(context);
        return FTheme(
          data: appFTheme(brightness),
          child: FToaster(child: FTooltipGroup(child: child!)),
        );
      },
    );
  }
}
