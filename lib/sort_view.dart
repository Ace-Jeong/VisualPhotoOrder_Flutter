import 'dart:io';

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:split_view/split_view.dart';

import 'MenuEntry.dart';
import 'Model/ItemSingleton.dart';
import 'left_view.dart';
import 'right_view.dart';

class SortView extends StatefulWidget {
  static const routeName = '/sort_view';
  const SortView({Key? key}) : super(key: key);

  @override
  SortViewState createState() => SortViewState();
}

class SortViewState extends State<SortView> {
  ShortcutRegistryEntry? _shortcutsEntry;
  String selectedImg = "";
  double weight = 0.8;
  bool onCloseDialog = false;

  @override
  void initState() {
    super.initState();
    DesktopWindow.setWindowSize(const Size(900, 600));

    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      if (onCloseDialog) return false;

      onCloseDialog = true;
      return await checkWhenClose();
    });
  }

  Future<bool> checkWhenClose() async {
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: const Text('프로그램을 종료하시겠습니까?\n저장되지 않은 사항은 사라집니다.'),
              actions: [
                ElevatedButton(
                    onPressed: () async {
                      await ItemSingleton().saveAll(context);
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

  SplitView buildMainContainer(BuildContext context) {
    return SplitView(
      viewMode: SplitViewMode.Horizontal,
      indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal),
      activeIndicator: const SplitIndicator(
        viewMode: SplitViewMode.Horizontal,
        isActive: true,
      ),
      controller: SplitViewController(
          weights: [null, weight],
          limits: [null, WeightLimit(min: 0.6, max: 0.9)]),
      onWeightChanged: (w) {
        double? wei = List.of(w)[1];
        if (wei != null) {
          weight = wei;
        } else {
          weight = 0.8;
        }
      },
      children: [
        const Center(child: LeftView()),
        RightView(selectedImg: selectedImg),
      ],
    );
  }

  ContextMenuOverlay buildMenuBar(BuildContext context) {
    return ContextMenuOverlay(
        buttonStyle: const ContextMenuButtonStyle(
          fgColor: Colors.red,
          hoverBgColor: Colors.red,
        ),
        child: Scaffold(
            backgroundColor: Colors.grey,
            body: Platform.isMacOS
                ? buildMacMenuBar(context)
                : buildNonMacMenuBar(context)));
  }

  // For MacOS MenuBar
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
                    exit(0);
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

  // For Non-MacOS platform menubar
  Column buildNonMacMenuBar(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: MenuBar(
                children: MenuEntry.build(_getMenus()),
              ),
            ),
          ],
        ),
        Expanded(child: buildMainContainer(context))
      ],
    );
  }

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
                exit(0);
              }
            },
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
          ),
        ],
      ),
    ];

    _shortcutsEntry?.dispose();
    _shortcutsEntry =
        ShortcutRegistry.of(context).addAll(MenuEntry.shortcuts(result));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return buildMenuBar(context);
  }
}
