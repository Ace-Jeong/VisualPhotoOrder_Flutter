import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:split_view/split_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'Model/ItemSingleton.dart';
import 'package:flutter/rendering.dart'; // RenderRepaintBoundary 클래스를 사용하기 위한 import
import 'dart:ui' as ui; // ImageByteFormat를 사용하기 위한 import

class RightView extends StatefulWidget {
  const RightView({Key? key, required this.selectedImg}) : super(key: key);
  final String selectedImg;

  @override
  RightViewState createState() => RightViewState();
}

class RightViewState extends State<RightView> {
  double weight = 0.2;
  final TextEditingController placeController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Offset position = Offset(0, 0);
  final double magnetThreshold = 20.0; // 자석 기능이 발동하는 거리
  final double distanceThreshold = 2.24; // 5 제곱미터의 루트 (약 2.24mm)

  Offset initialPosition = Offset(0, 0); // 초기 위치를 저장할 변수 추가

  @override
  Widget build(BuildContext context) {
    return SplitView(
      viewMode: SplitViewMode.Vertical,
      indicator: const SplitIndicator(viewMode: SplitViewMode.Vertical),
      activeIndicator: const SplitIndicator(
        viewMode: SplitViewMode.Vertical,
        isActive: true,
      ),
      controller: SplitViewController(
          weights: [null, weight],
          limits: [null, WeightLimit(min: 0.2, max: 3)]),
      onWeightChanged: (w) {
        double? wei = List.of(w)[1];
        if (wei != null) {
          setState(() {
            weight = wei;
          });
        } else {
          setState(() {
            weight = 0.2;
          });
        }
      },
      children: [
        widget.selectedImg.isEmpty
            ? const Center(child: Text("이미지를 선택하세요"))
            : Stack(
                children: [
                  Center(child: Image.file(File(widget.selectedImg))),
                  _draggableShell(context),
                ],
              ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: const Color.fromARGB(255, 130, 228, 228),
                child: Column(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text("파일명", style: TextStyle(fontSize: 18)),
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
                                RegExp(r'[a-zA-Z0-9_]'))
                          ],
                          decoration: const InputDecoration(
                            hintText: "파일명 입력",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final single = ItemSingleton();
                            single.saveName = value;
                          },
                        ),
                      ),
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
                color: Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            textStyle: const TextStyle(fontSize: 20),
                            padding: const EdgeInsets.all(3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () {
                            ItemSingleton().saveAll(context);
                          },
                          child: const Text("저장 후 폴더 열기"),
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

  Widget _draggableShell(BuildContext context) {
    double imageWidth = MediaQuery.of(context).size.width;
    double imageHeight = MediaQuery.of(context).size.height;

    return Positioned(
      top: position.dy,
      left: position.dx,
      child: GestureDetector(
        onPanStart: (details) {
          initialPosition = position; // 자석 기능 시작 시 초기 위치 저장
        },
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
            // 자석 기능 적용 시작
            double distance = (position - initialPosition).distance;
            if (distance > distanceThreshold) {
              // 자석 기능 비활성화
              initialPosition = position;
            } else {
              // 자석 기능 활성화
              if (position.dx < magnetThreshold) {
                position = Offset(0, position.dy);
              } else if (position.dx > imageWidth - 600 - magnetThreshold) {
                position = Offset(imageWidth - 600, position.dy);
              }
              if (position.dy < magnetThreshold) {
                position = Offset(position.dx, 0);
              } else if (position.dy > imageHeight - 150 - magnetThreshold) {
                position = Offset(position.dx, imageHeight - 150);
              }
            }
            // 자석 기능 적용 끝
            // 이동 범위를 실제 이미지 크기로 한정 시작
            if (position.dx < 0) {
              position = Offset(0, position.dy);
            } else if (position.dx > imageWidth - 600) {
              position = Offset(imageWidth - 600, position.dy);
            }
            if (position.dy < 0) {
              position = Offset(position.dx, 0);
            } else if (position.dy > imageHeight - 150) {
              position = Offset(position.dx, imageHeight - 150);
            }
            // 이동 범위를 실제 이미지 크기로 한정 끝
          });
        },
        child: _buildShell(),
      ),
    );
  }

  Widget _buildShell() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
        color: Colors.white, // 짙은 흰색 배경 설정
        borderRadius: BorderRadius.circular(5), // 바깥 선 부분을 둥글게 처리
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5), // 테두리를 둥글게 처리
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Table(
                border: TableBorder(
                  top: BorderSide(color: Colors.black, width: 3),
                  bottom: BorderSide(color: Colors.black, width: 3),
                  left: BorderSide(color: Colors.black, width: 3),
                  right: BorderSide(color: Colors.black, width: 3),
                  horizontalInside: BorderSide(color: Colors.black),
                  verticalInside: BorderSide(color: Colors.black),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(3),
                },
                children: [
                  TableRow(
                    children: [
                      const Center(
                        child: Text('날    짜',
                            style: TextStyle(fontSize: 14), // 텍스트 크기 조정
                            textAlign: TextAlign.center),
                      ),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != selectedDate) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Text(
                            "${selectedDate.toLocal()}".split(' ')[0],
                            style: TextStyle(fontSize: 14), // 텍스트 크기 조정
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Center(
                        child: Text('장    소',
                            style: TextStyle(fontSize: 14), // 텍스트 크기 조정
                            textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: placeController,
                          maxLines: null, // 줄바꿈 허용
                          textAlign: TextAlign.left, // 텍스트 좌측 정렬
                          decoration: const InputDecoration(
                            hintText: '장소 입력',
                            border: InputBorder.none, // 입력 박스의 테두리 선을 투명으로 설정
                          ),
                          style: TextStyle(fontSize: 14), // 텍스트 크기 조정
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Center(
                        child: Text('내    용',
                            style: TextStyle(fontSize: 14), // 텍스트 크기 조정
                            textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: contentController,
                          maxLines: null, // 줄바꿈 허용
                          textAlign: TextAlign.left, // 텍스트 좌측 정렬
                          decoration: const InputDecoration(
                            hintText: '내용 입력',
                            border: InputBorder.none, // 입력 박스의 테두리 선을 투명으로 설정
                          ),
                          style: TextStyle(fontSize: 14), // 텍스트 크기 조정
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveImageWithTable() async {
    try {
      // 1.이미지 파일 불러오기
      //   선택된 이미지를 파일에서 읽어와 img.decodeImage 함수로 디코딩하여 이미지 객체를 생성한다.
      final image =
          img.decodeImage(await File(widget.selectedImg).readAsBytes());
      // 이미지 불러오기 끝

      if (image != null) {
        // 2.이미지 객체가 null이 아닌경우 처리
        //   이미지가 정상적으로 디코딩된 경우에만 다음 단계를 진행한다.

        // 3.Table을 이미지로 변환
        //   RenderRepaintBoundary 객체를 찾아 테이블을 이미지로 변환한다.
        //   변환된 이미지를 toByteData 함수로 PNG 형식의 바이트 데이터로 변환합니다.
        //   바이트 데이터를 Uint8List로 변환하여 저장합니다.
        RenderRepaintBoundary? boundary =
            context.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null)
          throw Exception(
              'RenderObject is null'); // RenderRepaintBoundary를 찾을 수 없을 때 예외 처리

        final tableImage = await boundary.toImage();
        final byteData =
            await tableImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null)
          throw Exception(
              'Failed to convert table image to byte data'); // 이미지 변환 실패 예외 처리

        final Uint8List tablePngBytes = byteData.buffer.asUint8List();

        // 4.img 라이브러리를 사용하여 이미지와 표 합치기
        //   테이블 이미지를 디코딩하여 tableImg 객체를 생성한다.
        //   원본 이미지와 테이블 이미지를 합칠 combinedImage 객체를 생성한다.
        //   img.copyInto 함수를 사용하여 원본 이미지와 테이블 이미지를 합친다.
        final tableImg = img.decodeImage(tablePngBytes);
        if (tableImg == null)
          throw Exception(
              'Failed to decode table image'); // 테이블 이미지 디코딩 실패 예외 처리

        final combinedImage =
            img.Image(image.width, image.height + tableImg.height);
        img.copyInto(combinedImage, image, dstX: 0, dstY: 0);
        img.copyInto(combinedImage, tableImg, dstX: 0, dstY: image.height);

        // 5.파일 저장
        //   애플리케이션의 문서 디렉토리 경로를 가져온다.
        //   파일 경로를 설정하고, 합쳐진 이미지를 PNG 형식으로 저장한다.
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/${ItemSingleton().saveName}.png';
        await File(path).writeAsBytes(img.encodePng(combinedImage));

        // 6.저장 성공 메시지 표시:
        //   이미지가 성공적으로 저장되었음을 사용자에게 알리기 위해 스낵바 메시지를 표시한다.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지와 표가 저장되었습니다: $path')), // 저장 성공 메시지
          );
        }
      }
      // 7.오류 처리:
      //   예외가 발생할 경우 이를 캐치하여 사용자에게 오류 메시지를 표시한다.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')), // 예외 발생 시 오류 메시지
        );
      }
    }
  }

/*
  Future<void> _saveImageWithTable() async {
    try {
      // 이미지 파일 불러오기
      final image =
          img.decodeImage(await File(widget.selectedImg).readAsBytes());

      if (image != null) {
        // Table을 이미지로 변환
        RenderRepaintBoundary? boundary =
            context.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) throw Exception('RenderObject is null');

        final tableImage = await boundary.toImage();
        final byteData =
            await tableImage.toByteData(format: ImageByteFormat.png);
        if (byteData == null)
          throw Exception('Failed to convert table image to byte data');

        final Uint8List tablePngBytes = byteData.buffer.asUint8List();

        // img 라이브러리를 사용하여 이미지와 표 합치기
        final tableImg = img.decodeImage(tablePngBytes);
        if (tableImg == null) throw Exception('Failed to decode table image');

        final combinedImage =
            img.Image(image.width, image.height + tableImg.height);
        img.copyInto(combinedImage, image, dstX: 0, dstY: 0);
        img.copyInto(combinedImage, tableImg, dstX: 0, dstY: image.height);

        // 파일 저장
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/${ItemSingleton().saveName}.png';
        await File(path).writeAsBytes(img.encodePng(combinedImage));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지와 표가 저장되었습니다: $path')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
*/
}
