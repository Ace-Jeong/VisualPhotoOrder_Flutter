import 'dart:io'; // 파일 입출력 관련 라이브러리
import 'dart:typed_data'; // 바이너리 데이터를 위한 라이브러리
import 'package:flutter/material.dart'; // Flutter의 Material 디자인 라이브러리
import 'package:flutter/services.dart'; // 시스템 서비스 관련 라이브러리
import 'package:flutter/widgets.dart'; // Flutter의 기본 위젯 라이브러리
import 'package:split_view/split_view.dart'; // 스플릿 뷰를 제공하는 라이브러리
import 'package:path_provider/path_provider.dart'; // 파일 경로 제공 라이브러리
import 'package:image/image.dart' as img; // 이미지 관련 라이브러리
import 'Model/ItemSingleton.dart'; // 싱글톤 패턴을 구현한 모델 클래스
import 'package:flutter/rendering.dart'; // 렌더링 관련 라이브러리
import 'dart:ui' as ui; // Flutter의 UI 라이브러리
import 'dart:math'; // 수학 관련 함수 제공 라이브러리

// RightView 클래스 정의: StatefulWidget을 상속받아 상태를 가질 수 있는 위젯을 정의
class RightView extends StatefulWidget {
  const RightView({Key? key, required this.selectedImg})
      : super(key: key); // 생성자 정의, selectedImg 파라미터 필수
  final String selectedImg; // 이미지 파일 경로

  @override
  RightViewState createState() => RightViewState(); // 상태를 생성하여 반환
}

// RightViewState 클래스 정의: 상태를 관리
class RightViewState extends State<RightView> {
  double weight = 0.2; // 스플릿 뷰의 가중치 설정
  final TextEditingController placeController =
      TextEditingController(); // 장소 입력을 위한 컨트롤러
  final TextEditingController contentController =
      TextEditingController(); // 내용 입력을 위한 컨트롤러
  DateTime selectedDate = DateTime.now(); // 현재 날짜를 저장
  Offset position = Offset(0, 0); // 테이블의 초기 위치
  final double magnetThreshold = 3.0; // 자석 기능이 발동하는 거리
  final double distanceThreshold = 2.24; // 최소 이동 거리

  Offset initialPosition = Offset(0, 0); // 초기 위치를 저장할 변수 추가
  GlobalKey imageKey = GlobalKey(); // 이미지 RenderRepaintBoundary를 찾기 위한 키
  GlobalKey boundaryKey = GlobalKey(); // 테이블 RenderRepaintBoundary를 찾기 위한 키

  bool showTable = false; // 테이블 표시 여부를 결정하는 변수
  int tableWidth = 300; // 테이블의 초기 너비 값

  @override
  Widget build(BuildContext context) {
    // SplitView 위젯을 반환: 수직 모드로 설정
    return SplitView(
      viewMode: SplitViewMode.Vertical, // 스플릿 뷰를 수직 모드로 설정
      indicator:
          const SplitIndicator(viewMode: SplitViewMode.Vertical), // 수직 모드 인디케이터
      activeIndicator: const SplitIndicator(
        viewMode: SplitViewMode.Vertical,
        isActive: true,
      ),
      controller: SplitViewController(
          weights: [null, weight], // 스플릿 뷰의 가중치 설정
          limits: [null, WeightLimit(min: 0.2, max: 3)]), // 가중치 제한
      onWeightChanged: (w) {
        double? wei = List.of(w)[1]; // 가중치 값을 가져옴
        if (wei != null) {
          setState(() {
            weight = wei; // 가중치 값 설정
          });
        } else {
          setState(() {
            weight = 0.2; // 기본 가중치 값 설정
          });
        }
      },
      children: [
        Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showTable = !showTable; // 버튼 클릭 시 테이블 표시 상태 토글
                    });
                  },
                  child: Text("test1"), // 버튼 텍스트
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveImageWithTable(); // 버튼 클릭 시 이미지와 테이블 저장
                  },
                  child: Text("test2"), // 버튼 텍스트
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    alignment: Alignment.topLeft, // 상단 왼쪽 정렬
                    child: widget.selectedImg.isEmpty
                        ? null
                        : Image.file(
                            key: imageKey,
                            File(widget.selectedImg)), // 이미지 파일 표시
                  ),
                  if (showTable)
                    _draggableShell(context), // showTable이 true일 때만 테이블 표시
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: const Color.fromARGB(255, 130, 228, 228), // 배경색 설정
                child: Column(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text("파일명",
                          style: TextStyle(fontSize: 18)), // 파일명 입력 텍스트
                    ),
                    Expanded(
                      flex: 7,
                      child: Container(
                          width: 200,
                          height: 50,
                          child: TextField(
                            maxLines: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9_]')) // 필터링 설정
                            ],
                            decoration: const InputDecoration(
                              hintText: "파일명 입력",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final single = ItemSingleton(); // 싱글톤 인스턴스 가져오기
                              single.saveName = value; // 저장 이름 설정
                            },
                          )),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Container(
                width: 200,
                height: 100,
                color: Colors.white, // 배경색 설정
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20), // 패딩 설정
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green, // 버튼 텍스트 색상
                            side: const BorderSide(
                                color: Colors.green), // 버튼 테두리 색상
                            textStyle: const TextStyle(fontSize: 20), // 텍스트 스타일
                            padding: const EdgeInsets.all(3), // 내부 패딩
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3), // 둥근 모서리
                            ),
                            minimumSize: const Size.fromHeight(50), // 최소 높이
                          ),
                          onPressed: () {
                            ItemSingleton().saveAll(context); // 저장 후 폴더 열기
                          },
                          child: const Text("저장 후 폴더 열기"), // 버튼 텍스트
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  // 드래그 가능한 쉘 위젯을 빌드
  Widget _draggableShell(BuildContext context) {
    // 화면의 너비와 높이를 가져옴
    double imageWidth = MediaQuery.of(context).size.width;
    double imageHeight = MediaQuery.of(context).size.height;

    // 이미지 렌더 박스에서 시작 위치 찾기
    if (imageKey.currentContext == null) {
      // 이미지가 아직 렌더링되지 않았을 경우 빈 컨테이너 반환
      return Container(
        width: double.infinity,
        color: Colors.black,
      );
    }

    // 이미지의 렌더 박스를 가져옴
    final RenderBox renderBox =
        imageKey.currentContext!.findRenderObject() as RenderBox;
    // 이미지의 위치를 전역 좌표로 변환
    final imagePosition = renderBox.localToGlobal(Offset.zero);

    // 드래그 가능한 위젯을 위치시킴
    return Positioned(
      top: position.dy, // 드래그 가능한 위젯의 초기 y 위치
      left: position.dx, // 드래그 가능한 위젯의 초기 x 위치
      child: GestureDetector(
        // 드래그 시작 시 호출
        onPanStart: (details) {
          initialPosition = position; // 자석 기능 시작 시 초기 위치 저장
        },
        // 드래그 중일 때 호출
        onPanUpdate: (details) {
          setState(() {
            // 드래그된 만큼 위치를 업데이트
            position += details.delta;

            // 자석 기능 적용 시작
            double distance = (position - initialPosition).distance;
            if (distance > distanceThreshold) {
              // 자석 기능 비활성화
              initialPosition = position;
            } else {
              // 자석 기능 활성화
              if (position.dx < magnetThreshold) {
                position = Offset(0, position.dy); // 왼쪽 경계에 붙임
              } else if (position.dx > imageWidth - 600 - magnetThreshold) {
                position = Offset(imageWidth - 600, position.dy); // 오른쪽 경계에 붙임
              }
              if (position.dy < magnetThreshold) {
                position = Offset(position.dx, 0); // 상단 경계에 붙임
              } else if (position.dy > imageHeight - 150 - magnetThreshold) {
                position = Offset(position.dx, imageHeight - 150); // 하단 경계에 붙임
              }
            }
            // 자석 기능 적용 끝

            // 이동 범위를 실제 이미지 크기로 한정 시작
            if (position.dx < 0) {
              position = Offset(0, position.dy); // 왼쪽 경계를 넘지 않도록
            } else if (position.dx > imageWidth - 600) {
              position =
                  Offset(imageWidth - 600, position.dy); // 오른쪽 경계를 넘지 않도록
            }
            if (position.dy < 0) {
              position = Offset(position.dx, 0); // 상단 경계를 넘지 않도록
            } else if (position.dy > imageHeight - 150) {
              position =
                  Offset(position.dx, imageHeight - 150); // 하단 경계를 넘지 않도록
            }
            // 이동 범위를 실제 이미지 크기로 한정 끝
          });
        },
        // 드래그 가능한 위젯을 빌드
        child: RepaintBoundary(
          key: boundaryKey, // 키 추가
          child: _buildShell(), // 드래그 가능한 컨테이너 생성
        ),
      ),
    );
  }

  // 드래그 가능한 컨테이너를 빌드하는 메서드
  Widget _buildShell() {
    return Container(
      // 컨테이너의 최대 너비를 설정
      constraints: BoxConstraints(
        maxWidth: double.infinity,
      ),
      // 컨테이너의 외관을 설정 (테두리, 배경색, 모서리 둥글게)
      decoration: BoxDecoration(
        color: Colors.white, // 완전히 불투명한 흰색 배경
        border: Border.all(
            color: const Color.fromARGB(255, 255, 255, 255)), // 흰색 테두리
        borderRadius: BorderRadius.circular(5), // 모서리를 둥글게 설정
      ),
      child: ClipRRect(
        // 컨테이너의 모서리를 둥글게 자름
        borderRadius: BorderRadius.circular(5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                // 컨테이너의 최소 및 최대 너비를 설정
                constraints: BoxConstraints(
                  minWidth: tableWidth.toDouble(),
                  maxWidth: tableWidth.toDouble(),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Table(
                          // 테이블의 테두리 설정
                          border: TableBorder(
                            top: BorderSide(color: Colors.black, width: 3),
                            bottom: BorderSide(color: Colors.black, width: 3),
                            left: BorderSide(color: Colors.black, width: 3),
                            right: BorderSide(color: Colors.black, width: 3),
                            horizontalInside: BorderSide(color: Colors.black),
                            verticalInside: BorderSide(color: Colors.black),
                          ),
                          // 테이블의 열 너비 설정
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(4),
                          },
                          children: [
                            TableRow(
                              children: [
                                TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: Center(
                                    child: Text('날  짜',
                                        textAlign: TextAlign.center),
                                  ),
                                ),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // 날짜 선택기 표시
                                      DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2101),
                                      );
                                      if (picked != null &&
                                          picked != selectedDate) {
                                        setState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                    child: Text(
                                      "${selectedDate.toLocal()}".split(' ')[0],
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: Center(
                                    child: Text('장  소',
                                        textAlign: TextAlign.center),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: TextField(
                                    controller: placeController,
                                    maxLines: null,
                                    textAlign: TextAlign.left,
                                    decoration: const InputDecoration(
                                      hintText: '장소 입력',
                                      border: InputBorder.none,
                                    ),
                                    style: TextStyle(fontSize: 14, height: 1.5),
                                    onChanged: (value) {
                                      TextPainter textPainter = TextPainter(
                                        text: TextSpan(
                                          text: value,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        maxLines: 1,
                                        textDirection: TextDirection.ltr,
                                      );
                                      textPainter.layout(
                                          minWidth: 0,
                                          maxWidth: double.infinity);
                                      int textSize =
                                          textPainter.size.width.toInt();

                                      setState(() {
                                        if (textSize > 500) {
                                          tableWidth = 500;
                                          placeController.value =
                                              TextEditingValue(
                                            text: value,
                                            selection: TextSelection.collapsed(
                                                offset: placeController
                                                    .selection.baseOffset),
                                          );
                                        } else if (textSize > 400) {
                                          tableWidth = textSize;
                                        } else {
                                          tableWidth = 400;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: Center(
                                    child: Text('내  용',
                                        textAlign: TextAlign.center),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth),
                                    child: TextField(
                                      controller: contentController,
                                      maxLines: null,
                                      textAlign: TextAlign.left,
                                      decoration: const InputDecoration(
                                        hintText: '내용 입력',
                                        border: InputBorder.none,
                                      ),
                                      style:
                                          TextStyle(fontSize: 14, height: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 이미지와 테이블을 저장하는 비동기 메서드
  Future<void> _saveImageWithTable() async {
    try {
      // 이미지 파일 불러오기
      final image =
          img.decodeImage(await File(widget.selectedImg).readAsBytes());
      if (image != null) {
        // RenderRepaintBoundary를 통해 테이블 이미지를 생성
        final RenderRepaintBoundary boundary = boundaryKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;
        final ui.Image tableImage =
            await boundary.toImage(pixelRatio: 5.0); // 해상도를 높임
        final ByteData? byteData =
            await tableImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null)
          throw Exception('Failed to convert table image to byte data');

        final Uint8List tablePngBytes = byteData.buffer.asUint8List();
        final img.Image? tableImg = img.decodeImage(tablePngBytes);
        if (tableImg == null) throw Exception('Failed to decode table image');

        // 테이블 이미지를 크기 조정
        final img.Image resizedTableImg = img.copyResize(tableImg, width: 400);

        // 테이블 위치 계산
        final RenderBox renderBox =
            imageKey.currentContext!.findRenderObject() as RenderBox;
        final double scale = renderBox.size.width / image.width;
        final int tableX = (position.dx / scale).round();
        final int tableY = (position.dy / scale).round();

        // 원본 이미지와 테이블 이미지를 합침
        final combinedImage = img.Image(image.width, image.height);
        img.copyInto(combinedImage, image, dstX: 0, dstY: 0);
        img.copyInto(combinedImage, resizedTableImg,
            dstX: tableX, dstY: tableY);

        // "Photo save" 폴더를 생성하고 파일을 저장할 경로를 설정
        final imageFile = File(widget.selectedImg);
        final photoSaveDir = Directory('${imageFile.parent.path}/Photo save');
        if (!photoSaveDir.existsSync()) {
          photoSaveDir.createSync();
        }
        final path = '${photoSaveDir.path}/${imageFile.uri.pathSegments.last}';
        await File(path)
            .writeAsBytes(img.encodePng(combinedImage)); // PNG 형식으로 저장

        // 저장 성공 메시지를 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지와 표가 저장되었습니다: $path')),
          );
        }
      }
    } catch (e) {
      // 오류 발생 시 사용자에게 오류 메시지를 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}
