import 'dart:io'; // 파일 입출력을 위한 라이브러리

import 'package:desktop_window/desktop_window.dart'; // 데스크탑 창 크기 설정을 위한 라이브러리
import 'package:flutter/material.dart'; // Flutter의 기본 UI 라이브러리
import 'package:context_menus/context_menus.dart'; // 컨텍스트 메뉴를 위한 라이브러리
import 'package:flutter/services.dart'; // 시스템 서비스 관련 라이브러리
import 'package:flutter/widgets.dart'; // Flutter 기본 위젯 라이브러리
import 'package:flutter_window_close/flutter_window_close.dart'; // 창 닫힘 이벤트를 처리하기 위한 라이브러리
import 'package:split_view/split_view.dart'; // SplitView 위젯을 사용하기 위한 라이브러리

import 'MenuEntry.dart'; // MenuEntry 클래스
import 'Model/ItemSingleton.dart'; // ItemSingleton 클래스
import 'left_view.dart'; // LeftView 위젯
import 'right_view.dart'; // RightView 위젯

class SortView extends StatefulWidget {
  static const routeName = '/sort_view'; // 경로 이름 정의
  const SortView({Key? key}) : super(key: key);

  @override
  SortViewState createState() => SortViewState(); // 상태 생성
}

class SortViewState extends State<SortView> {
  ShortcutRegistryEntry? _shortcutsEntry; // 단축키 레지스트리 엔트리
  String selectedImg = ""; // 선택된 이미지 경로
  double weight = 0.8; // SplitView의 가중치
  bool onCloseDialog = false; // 창 닫힘 다이얼로그 상태

  @override
  void initState() {
    super.initState();
    DesktopWindow.setWindowSize(const Size(900, 600)); // 초기 창 크기 설정

    // 창 닫힘 이벤트 핸들러 설정
    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      if (onCloseDialog) return false;

      onCloseDialog = true;
      return await checkWhenClose();
    });
  }

  // 창 닫힘 확인 다이얼로그
  Future<bool> checkWhenClose() async {
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: const Text('프로그램을 종료하시겠습니까?\n저장되지 않은 사항은 사라집니다.'),
              actions: [
                ElevatedButton(
                    onPressed: () async {
                      await ItemSingleton().saveAll(context); // 저장
                      if (context.mounted) {
                        onCloseDialog = false; // 상태 초기화
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: const Text('저장')),
                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('저장 안함')),
                ElevatedButton(
                    onPressed: () {
                      onCloseDialog = false;
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('취소')),
              ]);
        });
  }

  // SplitView 빌드
  SplitView buildMainContainer(BuildContext context) {
    return SplitView(
      viewMode: SplitViewMode.Horizontal, // 수평 모드로 설정
      indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal), // 인디케이터 설정
      activeIndicator: const SplitIndicator(
        viewMode: SplitViewMode.Horizontal,
        isActive: true,
      ),
      controller: SplitViewController(
          weights: [null, weight], // 가중치 설정
          limits: [null, WeightLimit(min: 0.6, max: 0.9)]), // 가중치 제한
      onWeightChanged: (w) {
        double? wei = List.of(w)[1];
        if (wei != null) {
          weight = wei; // 가중치 업데이트
        } else {
          weight = 0.8; // 기본 가중치 설정
        }
      },
      children: [
        const Center(child: LeftView()), // 왼쪽 뷰
        RightView(selectedImg: selectedImg), // 오른쪽 뷰
      ],
    );
  }

  // 메뉴바 빌드
  ContextMenuOverlay buildMenuBar(BuildContext context) {
    return ContextMenuOverlay(
        buttonStyle: const ContextMenuButtonStyle(
          fgColor: Colors.red,
          hoverBgColor: Colors.red,
        ),
        child: Scaffold(
            backgroundColor: Colors.grey,
            body: Platform.isMacOS // 플랫폼에 따라 메뉴바 빌드
                ? buildMacMenuBar(context)
                : buildNonMacMenuBar(context)));
  }

  // MacOS용 메뉴바 빌드
  PlatformMenuBar buildMacMenuBar(BuildContext context) {
    return PlatformMenuBar(menus: <PlatformMenuItem>[
      PlatformMenu(
        label: 'Visual Photo Order',
        menus: <PlatformMenuItem>[
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: 'About',
                onSelected: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Visual Photo Order',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
              PlatformMenuItem(
                label: 'Quit',
                onSelected: () async {
                  bool isClose = await checkWhenClose();
                  if (isClose) {
                    exit(0); // 애플리케이션 종료
                  }
                },
                shortcut:
                    const SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
              ),
            ],
          ),

          // if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit))
          // const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
        ],
      ),
    ], child: buildMainContainer(context));
  }

  // Non-MacOS용 메뉴바 빌드
  Column buildNonMacMenuBar(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: MenuBar(
                children: MenuEntry.build(_getMenus()), // 메뉴 항목 빌드
              ),
            ),
          ],
        ),
        Expanded(child: buildMainContainer(context))
      ],
    );
  }

  // 메뉴 항목 생성
  List<MenuEntry> _getMenus() {
    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: 'File',
        menuChildren: <MenuEntry>[
          MenuEntry(
            label: 'About',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Visual Photo Order',
                applicationVersion: '1.0.0',
              );
            },
          ),
          MenuEntry(
            label: 'Quit',
            onPressed: () async {
              bool isClose = await checkWhenClose();
              if (isClose) {
                exit(0); // 애플리케이션 종료
              }
            },
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
          ),
        ],
      ),
    ];

    // 단축키 등록
    _shortcutsEntry?.dispose();
    _shortcutsEntry =
        ShortcutRegistry.of(context).addAll(MenuEntry.shortcuts(result));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return buildMenuBar(context); // 메뉴바 빌드
  }
}
