import 'dart:io'; // 파일 입출력을 위한 라이브러리

import 'package:flutter/material.dart'; // Flutter의 기본 UI 라이브러리
import 'package:desktop_drop/desktop_drop.dart'; // 데스크탑 드래그 앤 드롭 기능을 위한 라이브러리
import 'package:cross_file/cross_file.dart'; // 파일 선택을 위한 라이브러리
import 'package:file_picker/file_picker.dart'; // 파일/디렉토리 선택을 위한 라이브러리
import 'package:desktop_window/desktop_window.dart'; // 데스크탑 창 크기 설정을 위한 라이브러리
import 'package:mime/mime.dart'; // MIME 타입을 확인하기 위한 라이브러리

import 'Model/ItemClass.dart'; // ItemClass 모델
import 'sort_view.dart'; // sort_view 파일

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 위젯 바인딩 초기화
  await DesktopWindow.setWindowSize(const Size(400, 200)); // 초기 창 크기 설정
  await DesktopWindow.setMinWindowSize(const Size(400, 200)); // 최소 창 크기 설정

  runApp(const MyApp()); // 애플리케이션 시작
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 애플리케이션의 루트 위젯
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisualPhotoOrder', // 애플리케이션 제목
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // 테마 색상 설정
        useMaterial3: true, // Material 3 사용
      ),
      home: const Scaffold(
        appBar: null, // 앱바 비활성화
        backgroundColor: Colors.grey, // 배경색 설정
        body: FileDragAndDrop(), // 드래그 앤 드롭 위젯 설정
      ),
      routes: {
        SortView.routeName: (context) => const SortView() // 경로 설정
      },
    );
  }
}

class FileDragAndDrop extends StatefulWidget {
  const FileDragAndDrop({Key? key}) : super(key: key);

  @override
  FileDragAndDropState createState() => FileDragAndDropState(); // 상태 생성
}

class FileDragAndDropState extends State<FileDragAndDrop> {
  String _path = ""; // 선택된 경로 저장
  String _showFileName = "경로가 선택되지 않았습니다"; // 화면에 보여질 경로 텍스트
  bool _dragging = false; // 드래그 상태

  Color uploadingColor = Colors.blue[100]!; // 업로드 시 색상
  Color defaultColor = Colors.black; // 기본 색상

  Container makeDropZone() {
    Color color = _dragging ? uploadingColor : defaultColor; // 드래그 상태에 따른 색상 설정
    return Container(
      height: 200, // 드롭존 높이
      width: 400, // 드롭존 너비
      decoration: BoxDecoration(
        border: Border.all(width: 5, color: color), // 테두리 설정
        borderRadius: const BorderRadius.all(Radius.circular(20)), // 둥근 모서리 설정
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.end, // 아래쪽 정렬
            children: [
              Text(
                "여기에 폴더를 드래그하세요", // 안내 문구
                style: TextStyle(color: color, fontSize: 20),
              ),
            ],
          ),
          InkWell(
            onTap: () async {
              String? result = await FilePicker.platform.getDirectoryPath(); // 디렉토리 선택 다이얼로그 표시
              if (result != null) {
                setState(() {
                  _path = result; // 선택된 경로 저장
                  _showFileName = result; // 화면에 경로 표시
                });
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
              children: [
                Text("또는", style: TextStyle(color: color)),
                Text(
                  "여기를 클릭해 폴더를 선택하세요", // 클릭 안내 문구
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10), // 간격 추가
          Text(
            _showFileName, // 선택된 경로 표시
            style: TextStyle(color: defaultColor),
          ),
          ElevatedButton(
            onPressed: () {
              List<ItemClass> imageFiles = []; // 이미지 파일 리스트 초기화
              List<FileSystemEntity> file = Directory(_path).listSync(); // 디렉토리 내 파일 리스트
              for (FileSystemEntity s in file) {
                final mimeType = lookupMimeType(s.path); // MIME 타입 확인
                if (mimeType != null && mimeType.startsWith('image/')) {
                  imageFiles.add(ItemClass(s.path)); // 이미지 파일만 추가
                }
              }

              if (imageFiles.isEmpty) {
                // 이미지 파일이 없을 경우 다이얼로그 표시
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0)),
                        title: const Column(
                          children: <Widget>[
                            Text("Error"),
                          ],
                        ),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text("Dialog Content"),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text("확인"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              } else {
                Navigator.pushNamed(
                  context,
                  '/sort_view',
                  arguments: {'path_list': imageFiles}, // 이미지 파일 경로 전달
                );
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        XFile file = detail.files[0]; // 드롭된 파일 가져오기
        final isDir = FileSystemEntity.isDirectory(file.path); // 디렉토리 여부 확인
        isDir.then((val) {
          if (val) {
            _path = file.path; // 디렉토리 경로 저장

            setState(() {
              _showFileName = file.path; // 화면에 경로 표시
            });
          }
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true; // 드래그 상태 활성화
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false; // 드래그 상태 비활성화
        });
      },
      child: makeDropZone(), // 드롭존 위젯 반환
    );
  }
}
