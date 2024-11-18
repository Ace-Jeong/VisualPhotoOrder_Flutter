import 'package:flutter/material.dart';

class MenuEntry {
  //1. 생성자
  //MenuEntry:클래스의 생성자는 라벨(label), 단축키(shortcut), 눌림 시 콜백(onPressed), 및 하위 메뉴 항목(menuChildren)을 초기화한다.
  //assert를 사용하여 menuChildren이 제공된 경우 onPressed가 null이어야 한다는 조건을 검증한다. 이는 하위 메뉴가 있는 경우 onPressed가 무시된다는 의미다.
  const MenuEntry(
      {required this.label, this.shortcut, this.onPressed, this.menuChildren})
      : assert(menuChildren == null || onPressed == null,
            'onPressed is ignored if menuChildren are provided');
  //2. 필드
  //label: 메뉴 항목의 라벨입니다.
  //shortcut: 메뉴 항목의 단축키로 사용될 수 있는 MenuSerializableShortcut 객체다.
  //onPressed: 메뉴 항목이 눌렸을 때 호출될 콜백 함수다.
  //menuChildren: 하위 메뉴 항목의 리스트다.
  final String label;

  final MenuSerializableShortcut? shortcut;
  final VoidCallback? onPressed;
  final List<MenuEntry>? menuChildren;

  static List<Widget> build(List<MenuEntry> selections) {
    /*3. 정적 메서드: build
      build 메서드는 MenuEntry 객체 리스트를 받아 위젯 리스트로 변환한다.
      내부적으로 buildSelection이라는 함수를 정의하여, 각 MenuEntry 객체를 SubmenuButton 또는 MenuItemButton 위젯으로 변환한다.
      하위 메뉴 항목이 있으면 SubmenuButton을 생성하고, 그렇지 않으면 MenuItemButton을 생성한다.
    */
    Widget buildSelection(MenuEntry selection) {
      /*
      4. 정적 메서드: shortcuts
      shortcuts 메서드는 MenuEntry 객체 리스트를 받아 단축키와 인텐트(Intent)를 매핑한 맵을 반환한다.
      하위 메뉴 항목이 있으면 재귀적으로 해당 항목의 단축키 맵을 추가하고, 그렇지 않은 경우 단축키와 콜백을 매핑한다.
      */
      if (selection.menuChildren != null) {
        return SubmenuButton(
          menuChildren: MenuEntry.build(selection.menuChildren!),
          child: Text(selection.label),
        );
      }
      return MenuItemButton(
        shortcut: selection.shortcut,
        onPressed: selection.onPressed,
        child: Text(selection.label),
      );
    }

    return selections.map<Widget>(buildSelection).toList();
  }

  static Map<MenuSerializableShortcut, Intent> shortcuts(
      List<MenuEntry> selections) {
    final Map<MenuSerializableShortcut, Intent> result =
        <MenuSerializableShortcut, Intent>{};
    for (final MenuEntry selection in selections) {
      if (selection.menuChildren != null) {
        result.addAll(MenuEntry.shortcuts(selection.menuChildren!));
      } else {
        if (selection.shortcut != null && selection.onPressed != null) {
          result[selection.shortcut!] =
              VoidCallbackIntent(selection.onPressed!);
        }
      }
    }
    return result;
  }
}

/*
★요약
MenuEntry 클래스는 메뉴 항목을 정의하고 빌드하는 데 사용된다.
build 메서드는 MenuEntry 객체 리스트를 위젯 리스트로 변환한다.
shortcuts 메서드는 단축키와 인텐트를 매핑하여 반환합니다.
하위 메뉴가 있는 경우 재귀적으로 처리하여 모든 메뉴 항목을 다룬다
 */