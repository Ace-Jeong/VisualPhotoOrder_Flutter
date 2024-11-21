import 'package:flutter/material.dart'; // Flutter의 기본 UI 라이브러리

// MenuEntry 클래스 정의
class MenuEntry {
  // 1. 생성자
  // MenuEntry: 클래스의 생성자는 라벨(label), 단축키(shortcut), 눌림 시 콜백(onPressed), 및 하위 메뉴 항목(menuChildren)을 초기화
  // assert를 사용하여 menuChildren이 제공된 경우 onPressed가 null이어야 한다는 조건을 검증
  // 이는 하위 메뉴가 있는 경우 onPressed가 무시된다는 의미
  const MenuEntry({
    required this.label, 
    this.shortcut, 
    this.onPressed, 
    this.menuChildren
  }) : assert(menuChildren == null || onPressed == null,
            'onPressed is ignored if menuChildren are provided');

  // 2. 필드
  // label: 메뉴 항목의 라벨
  // shortcut: 메뉴 항목의 단축키로 사용될 수 있는 MenuSerializableShortcut 객체
  // onPressed: 메뉴 항목이 눌렸을 때 호출될 콜백 함수
  // menuChildren: 하위 메뉴 항목의 리스트
  final String label;
  final MenuSerializableShortcut? shortcut;
  final VoidCallback? onPressed;
  final List<MenuEntry>? menuChildren;

  // 3. 정적 메서드: build
  // build 메서드는 MenuEntry 객체 리스트를 받아 위젯 리스트로 변환
  static List<Widget> build(List<MenuEntry> selections) {
    // 내부적으로 buildSelection이라는 함수를 정의하여, 각 MenuEntry 객체를 SubmenuButton 또는 MenuItemButton 위젯으로 변환
    // 하위 메뉴 항목이 있으면 SubmenuButton을 생성하고, 그렇지 않으면 MenuItemButton을 생성
    Widget buildSelection(MenuEntry selection) {
      if (selection.menuChildren != null) {
        return SubmenuButton(
          menuChildren: MenuEntry.build(selection.menuChildren!), // 하위 메뉴 빌드
          child: Text(selection.label), // 라벨 설정
        );
      }
      return MenuItemButton(
        shortcut: selection.shortcut, // 단축키 설정
        onPressed: selection.onPressed, // 콜백 설정
        child: Text(selection.label), // 라벨 설정
      );
    }

    // selections 리스트를 순회하여 위젯 리스트로 변환하여 반환
    return selections.map<Widget>(buildSelection).toList();
  }

  // 4. 정적 메서드: shortcuts
  // shortcuts 메서드는 MenuEntry 객체 리스트를 받아 단축키와 인텐트(Intent)를 매핑한 맵을 반환
  static Map<MenuSerializableShortcut, Intent> shortcuts(
      List<MenuEntry> selections) {
    final Map<MenuSerializableShortcut, Intent> result =
        <MenuSerializableShortcut, Intent>{};
    
    // 하위 메뉴 항목이 있으면 재귀적으로 해당 항목의 단축키 맵을 추가
    // 그렇지 않은 경우 단축키와 콜백을 매핑
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
MenuEntry 클래스는 메뉴 항목을 정의하고 빌드하는 데 사용
- build 메서드는 MenuEntry 객체 리스트를 위젯 리스트로 변환
- shortcuts 메서드는 단축키와 인텐트를 매핑하여 반환
- 하위 메뉴가 있는 경우 재귀적으로 처리하여 모든 메뉴 항목을 다룸
 */
