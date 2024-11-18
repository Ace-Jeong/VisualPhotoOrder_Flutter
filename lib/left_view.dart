import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'Model/ItemClass.dart';
import 'Model/ItemSingleton.dart';
import 'sort_view.dart';

class LeftView extends StatefulWidget {
  const LeftView({Key? key}) : super(key: key);

  @override
  LeftViewState createState() => LeftViewState();
}

class LeftViewState extends State<LeftView> {
  ItemSingleton singleton = ItemSingleton();
  Set<int> select = {};
  Timer? _timer;
  ScrollController sc = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      final args = (ModalRoute.of(context)?.settings.arguments ??
          <String, dynamic>{}) as Map;
      setState(() {
        List<ItemClass> its = args['path_list'] as List<ItemClass>;
        if (its.isEmpty) {
          _showEmptyFolderDialog();
        } else {
          singleton.list.addAll(its);
        }
      });
    });
  }

  void _showEmptyFolderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("폴더 상태"),
          content: Text("폴더에 이미지가 없습니다!"),
          actions: [
            TextButton(
              child: Text("확인"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void reorderOneItem(int oldIdx, int newIdx) {
    if (oldIdx < newIdx) {
      newIdx -= 1;
    }

    setState(() {
      final item = singleton.list.removeAt(oldIdx);
      singleton.list.insert(newIdx, item);
    });
  }

  void reorderMultiItems(int oldIdx, int newIdx) {
    List<int> tmp = select.toList();
    tmp.sort();

    if (!select.contains(oldIdx) || tmp.length <= 1) {
      reorderOneItem(oldIdx, newIdx);
    } else {
      List<ItemClass> arr = [];
      int idx = 0;
      for (var i in singleton.list) {
        if (!select.contains(idx)) {
          arr.add(i);
        }
        idx++;
      }

      List<ItemClass> it = [];
      for (var i in tmp) {
        it.add(singleton.list[i]);
      }

      if (newIdx >= singleton.list.length) {
        arr.addAll(it);
      } else {
        final to = singleton.list[newIdx];
        if (arr.contains(to)) {
          int toMoveIndex = arr.indexOf(to);
          arr.insertAll(toMoveIndex, it);
        } else {
          while (true) {
            newIdx--;
            newIdx = (newIdx < 0) ? 0 : newIdx;

            final to = singleton.list[newIdx];
            if (newIdx == 0 || arr.contains(to)) {
              int toMoveIndex = arr.indexOf(to);
              arr.insertAll(toMoveIndex + 1, it);
              break;
            }
          }
        }
      }

      singleton.list.clear();
      singleton.list.addAll(arr);
    }

    select.clear();
  }

  void stopTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void scrollUp() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 10), (t) {
      if (sc.offset - 1 >= sc.position.minScrollExtent)
        sc.jumpTo(sc.offset - 5);
    });
  }

  void scrollDown() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 10), (t) {
      if (sc.offset + 1 <= sc.position.maxScrollExtent)
        sc.jumpTo(sc.offset + 5);
    });
  }

  ReorderableListView makeContainer(BuildContext context) {
    SortViewState? parent = context.findAncestorStateOfType<SortViewState>();

    return ReorderableListView.builder(
      scrollController: sc,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        return ReorderableDragStartListener(
          key: Key("$index"),
          index: index,
          child: ContextMenuRegion(
            contextMenu: GenericContextMenu(
              buttonConfigs: [
                ContextMenuButtonConfig(
                  "Delete",
                  onPressed: () {
                    setState(() {
                      singleton.list.removeAt(index);
                      select.clear();
                    });
                  },
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                if (HardwareKeyboard.instance
                    .isPhysicalKeyPressed(PhysicalKeyboardKey.controlLeft)) {
                  setState(() {
                    select.contains(index)
                        ? select.remove(index)
                        : select.add(index);
                  });
                } else {
                  setState(() {
                    select.clear();
                    select.add(index);
                  });

                  parent!.setState(() {
                    parent.selectedImg = singleton.list[index].imagePath;
                  });
                }
              },
              child: DropTarget(
                onDragDone: (details) {
                  stopTimer();

                  List<ItemClass> arr = [];
                  for (var file in details.files) {
                    if (FileSystemEntity.typeSync(file.path) ==
                        FileSystemEntityType.directory) {
                      Directory dir = Directory(file.path);
                      var files = dir.listSync().whereType<File>();
                      if (files.isEmpty) {
                        _showEmptyFolderDialog();
                      } else {
                        for (var f in files) {
                          arr.add(ItemClass(f.path));
                        }
                      }
                    } else {
                      ItemClass it = ItemClass(file.path);
                      if (!singleton.list.contains(it)) {
                        arr.add(it);
                      }
                    }
                  }

                  if (arr.isEmpty) {
                    _showEmptyFolderDialog();
                  } else {
                    RenderBox rb = singleton
                        .list[index].globalKey.currentContext!
                        .findRenderObject() as RenderBox;
                    double half = rb.size.height / 2;
                    int insertIdx =
                        (details.localPosition.dy < half) ? index : index + 1;

                    setState(() {
                      singleton.list.insertAll(insertIdx, arr);
                    });
                  }
                },
                onDragUpdated: (details) {
                  Size? contextSize = context.size;
                  if (contextSize != null) {
                    double scUp = contextSize.height * (1 / 4);
                    double scDown = contextSize.height * (3 / 4);

                    double dp = details.globalPosition.dy;
                    if (dp < scUp) {
                      scrollUp();
                    } else if (dp > scDown) {
                      scrollDown();
                    } else {
                      stopTimer();
                    }
                  }
                },
                onDragEntered: (details) {},
                onDragExited: (details) {
                  stopTimer();
                },
                child: DragTarget(
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      alignment: Alignment.center,
                      color: select.contains(index)
                          ? Colors.blue
                          : Colors.white, // 색상 변경
                      padding: const EdgeInsets.all(3),
                      child: Image.file(
                          key: singleton.list[index].globalKey,
                          File(singleton.list[index].imagePath)),
                    );
                  },
                  onWillAcceptWithDetails: (details) {
                    return true;
                  },
                  onAcceptWithDetails: (details) {
                    stopTimer();
                    RenderBox rb = singleton
                        .list[index].globalKey.currentContext!
                        .findRenderObject() as RenderBox;
                    double half = rb.size.height / 2;
                    double point = rb.globalToLocal(details.offset).dy + 75;

                    int fromIdx = singleton.list
                        .indexOf(ItemClass(details.data as String));
                    int toIdx = (point < half) ? index : index + 1;

                    reorderOneItem(fromIdx, toIdx);
                  },
                  onMove: (details) {
                    Size? contextSize = context.size;
                    if (contextSize != null) {
                      double scUp = contextSize.height * (1 / 4);
                      double scDown = contextSize.height * (3 / 4);

                      double dp = details.offset.dy + 75;
                      if (dp < scUp) {
                        scrollUp();
                      } else if (dp > scDown) {
                        scrollDown();
                      } else {
                        stopTimer();
                      }
                    }
                  },
                  onLeave: (data) {
                    stopTimer();
                  },
                ),
              ),
            ),
          ),
        );
      },
      itemCount: singleton.list.length,
      onReorder: (int oldIdx, int newIdx) {
        reorderMultiItems(oldIdx, newIdx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return makeContainer(context);
  }
}
