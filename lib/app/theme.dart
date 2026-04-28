import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

// 시스템 brightness에 따라 forui zinc 팔레트의 desktop 변형을 반환한다.
FThemeData appFTheme(Brightness brightness) =>
    brightness == Brightness.dark
        ? FThemes.zinc.dark.desktop
        : FThemes.zinc.light.desktop;
