import 'dart:async'; // 비동기 작업을 위한 라이브러리
import 'dart:io'; // 파일 작업을 위한 라이브러리

import 'package:flutter/material.dart'; // Flutter의 기본 위젯 라이브러리
import 'package:desktop_drop/desktop_drop.dart'; // 드롭 기능을 위한 라이브러리
import 'package:context_menus/context_menus.dart'; // 컨텍스트 메뉴를 위한 라이브러리
import 'package:flutter/rendering.dart'; // 렌더링 관련 라이브러리
import 'package:flutter/services.dart'; // 시스템 서비스 관련 라이브러리

import 'Model/ItemClass.dart'; // ItemClass 모델
import 'Model/ItemSingleton.dart'; // ItemSingleton 모델
import 'sort_view.dart'; // sort_view 파일

class LeftView extends StatefulWidget {
  const LeftView({Key? key}) : super(key: key);

  @override
  LeftViewState createState() => LeftViewState(); // 상태를 생성
}

class LeftViewState extends State<LeftView> {
  ItemSingleton singleton = ItemSingleton(); // 싱글톤 인스턴스 생성
  Set<int> select = {}; // 선택된 항목을 저장할 Set
  Timer? _timer; // 타이머를 위한 변수
  ScrollController sc = ScrollController(); // 스크롤 컨트롤러

  @override
  void initState() {
    super.initState();

    // 초기화 작업을 지연 실행하여 수행
    Future.delayed(Duration.zero, () {
      // 전달된 인자 가져오기
      final args = (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{}) as Map;
      setState(() {
        // 인자로 전달된 이미지 목록
        List<ItemClass> its = args['path_list'] as List<ItemClass>;
        if (its.isEmpty) {
          _showEmptyFolderDialog(); // 이미지가 없으면 다이얼로그 표시
        } else {
          singleton.list.addAll(its); // 이미지가 있으면 리스트에 추가
        }
      });
    });
  }

  void _showEmptyFolderDialog() {
    // 폴더가 비어 있을 때 다이얼로그 표시
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
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
          ],
        );
      },
    );
  }

  void reorderOneItem(int oldIdx, int newIdx) {
    // 항목을 하나만 재정렬하는 함수
    if (oldIdx < newIdx) {
      newIdx -= 1; // 새로운 인덱스를 조정
    }

    setState(() {
      // 항목을 제거한 후 새로운 위치에 삽입
      final item = singleton.list.removeAt(oldIdx);
      singleton.list.insert(newIdx, item);
    });
  }

  void reorderMultiItems(int oldIdx, int newIdx) {
    // 다중 항목을 재정렬하는 함수
    List<int> tmp = select.toList(); // 선택된 항목을 리스트로 변환
    tmp.sort(); // 인덱스를 정렬

    if (!select.contains(oldIdx) || tmp.length <= 1) {
      // 선택된 항목이 없거나 하나만 선택된 경우
      reorderOneItem(oldIdx, newIdx); // 하나만 재정렬
    } else {
      // 다중 항목을 재정렬
      List<ItemClass> arr = [];
      int idx = 0;
      for (var i in singleton.list) {
        if (!select.contains(idx)) {
          arr.add(i); // 선택되지 않은 항목 추가
        }
        idx++;
      }

      List<ItemClass> it = [];
      for (var i in tmp) {
        it.add(singleton.list[i]); // 선택된 항목 추가
      }

      if (newIdx >= singleton.list.length) {
        arr.addAll(it); // 끝에 추가
      } else {
        final to = singleton.list[newIdx]; // 새로운 위치의 항목
        if (arr.contains(to)) {
          int toMoveIndex = arr.indexOf(to);
          arr.insertAll(toMoveIndex, it); // 선택된 항목 삽입
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

      singleton.list.clear(); // 리스트 초기화
      singleton.list.addAll(arr); // 새로운 리스트 설정
    }

    select.clear(); // 선택된 항목 초기화
  }

  void stopTimer() {
    // 타이머 중지 함수
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void scrollUp() {
    // 위로 스크롤하는 함수
    _timer ??= Timer.periodic(const Duration(milliseconds: 10), (t) {
      if (sc.offset - 1 >= sc.position.minScrollExtent) {
        sc.jumpTo(sc.offset - 5); // 스크롤을 위로 이동
      }
    });
  }

  void scrollDown() {
    // 아래로 스크롤하는 함수
    _timer ??= Timer.periodic(const Duration(milliseconds: 10), (t) {
      if (sc.offset + 1 <= sc.position.maxScrollExtent) {
        sc.jumpTo(sc.offset + 5); // 스크롤을 아래로 이동
      }
    });
  }

  ReorderableListView makeContainer(BuildContext context) {
    // ReorderableListView를 생성하는 함수
    SortViewState? parent = context.findAncestorStateOfType<SortViewState>(); // 부모 상태 찾기

    return ReorderableListView.builder(
      scrollController: sc, // 스크롤 컨트롤러 설정
      buildDefaultDragHandles: false, // 기본 드래그 핸들 비활성화
      itemBuilder: (context, index) {
        return ReorderableDragStartListener(
          key: Key("$index"), // 항목 키 설정
          index: index,
          child: ContextMenuRegion(
            contextMenu: GenericContextMenu(
              buttonConfigs: [
                ContextMenuButtonConfig(
                  "Delete",
                  onPressed: () {
                    setState(() {
                      singleton.list.removeAt(index); // 항목 삭제
                      select.clear(); // 선택 초기화
                    });
                  },
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                if (HardwareKeyboard.instance
                    .isPhysicalKeyPressed(PhysicalKeyboardKey.controlLeft)) {
                  // Ctrl 키가 눌린 상태에서 클릭한 경우
                  setState(() {
                    select.contains(index)
                        ? select.remove(index)
                        : select.add(index);
                  });
                } else {
                  // 단일 클릭한 경우
                  setState(() {
                    select.clear();
                    select.add(index);
                  });

                  parent!.setState(() {
                    parent.selectedImg = singleton.list[index].imagePath; // 부모 상태 업데이트
                  });
                }
              },
              child: DropTarget(
                onDragDone: (details) {
                  stopTimer(); // 타이머 중지

                  List<ItemClass> arr = [];
                  for (var file in details.files) {
                    if (FileSystemEntity.typeSync(file.path) == FileSystemEntityType.directory) {
                      // 드래그된 파일이 디렉토리인 경우
                      Directory dir = Directory(file.path);
                      var files = dir.listSync().whereType<File>(); // 디렉토리 내 파일 목록
                      if (files.isEmpty) {
                        _showEmptyFolderDialog(); // 폴더가 비어 있으면 다이얼로그 표시
                      } else {
                        for (var f in files) {
                          arr.add(ItemClass(f.path)); // 파일 추가
                        }
                      }
                    } else {
                      // 드래그된 파일이 단일 파일인 경우
                      ItemClass it = ItemClass(file.path);
                      if (!singleton.list.contains(it)) {
                        arr.add(it); // 파일 추가
                      }
                    }
                  }

                  if (arr.isEmpty) {
                    _showEmptyFolderDialog(); // 추가할 파일이 없으면 다이얼로그 표시
                  } else {
                    RenderBox rb = singleton.list[index].globalKey.currentContext!.findRenderObject() as RenderBox;
                    double half = rb.size.height / 2;
                    int insertIdx = (details.localPosition.dy < half) ? index : index + 1;

                    setState(() {
                      singleton.list.insertAll(insertIdx, arr); // 항목 삽입
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
                      scrollUp(); // 위로 스크롤
                    } else if (dp > scDown) {
                      scrollDown(); // 아래로 스크롤
                    } else {
                      stopTimer(); // 타이머 중지
                    }
                  }
                },
                onDragEntered: (details) {
                  // 드래그가 항목 위로 들어왔을 때 호출되는 콜백
                },
                onDragExited: (details) {
                  stopTimer(); // 드래그가 항목 위에서 나갔을 때 타이머 중지
                },
                child: DragTarget(
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      alignment: Alignment.center, // 컨테이너의 정렬 설정
                      color: select.contains(index)
                          ? Colors.blue
                          : Colors.white, // 선택된 항목은 파란색으로 표시
                      padding: const EdgeInsets.all(3), // 컨테이너의 패딩 설정
                      child: Image.file(
                          key: singleton.list[index].globalKey,
                          File(singleton.list[index].imagePath)), // 이미지 파일 표시
                    );
                  },
                  onWillAcceptWithDetails: (details) {
                    return true; // 드래그된 항목을 수락할지 여부 반환
                  },
                  onAcceptWithDetails: (details) {
                    stopTimer(); // 타이머 중지
                    RenderBox rb = singleton.list[index].globalKey.currentContext!.findRenderObject() as RenderBox;
                    double half = rb.size.height / 2;
                    double point = rb.globalToLocal(details.offset).dy + 75;

                    int fromIdx = singleton.list.indexOf(ItemClass(details.data as String));
                    int toIdx = (point < half) ? index : index + 1;

                    reorderOneItem(fromIdx, toIdx); // 항목 재정렬
                  },
                  onMove: (details) {
                    Size? contextSize = context.size;
                    if (contextSize != null) {
                      double scUp = contextSize.height * (1 / 4); // 스크롤 업 영역
                      double scDown = contextSize.height * (3 / 4); // 스크롤 다운 영역

                      double dp = details.offset.dy + 75;
                      if (dp < scUp) {
                        scrollUp(); // 위로 스크롤
                      } else if (dp > scDown) {
                        scrollDown(); // 아래로 스크롤
                      } else {
                        stopTimer(); // 타이머 중지
                      }
                    }
                  },
                  onLeave: (data) {
                    stopTimer(); // 드래그가 항목을 떠날 때 타이머 중지
                  },
                ),
              ),
            ),
          ),
        );
      },
      itemCount: singleton.list.length, // 리스트 항목 수
      onReorder: (int oldIdx, int newIdx) {
        reorderMultiItems(oldIdx, newIdx); // 다중 항목 재정렬
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return makeContainer(context); // ReorderableListView 반환
  }
}
