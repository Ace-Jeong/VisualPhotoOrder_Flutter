import 'dart:io';

import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:mime/mime.dart';

import 'Model/ItemClass.dart';
import 'sort_view.dart';

Future<void> main() async {
	WidgetsFlutterBinding.ensureInitialized();
	await DesktopWindow.setWindowSize(const Size(400, 200));
	await DesktopWindow.setMinWindowSize(const Size(400, 200));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisualPhotoOrder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        appBar: null,
        backgroundColor: Colors.grey,
        body: FileDragAndDrop(),
      ),
      routes: {
        SortView.routeName: (context)=> const SortView()
      },
    );
  }
}

class FileDragAndDrop extends StatefulWidget {
  const FileDragAndDrop({Key? key}) : super(key: key);

  @override
  FileDragAndDropState createState() => FileDragAndDropState();
}

class FileDragAndDropState extends State<FileDragAndDrop> {
  String _path = "";
  String _showFileName = "경로가 선택되지 않았습니다";
  bool _dragging = false;

  Color uploadingColor = Colors.blue[100]!;
  Color defaultColor = Colors.black;

  Container makeDropZone(){
    Color color = _dragging ? uploadingColor : defaultColor;
    return Container(
      height: 200,
      width: 400,
      decoration: BoxDecoration(
        border: Border.all(width: 5, color: color,),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("여기에 폴더를 드래그하세요", style: TextStyle(color: color, fontSize: 20,),),
            ],
          ),
          InkWell(
            onTap: () async {
              String? result = await FilePicker.platform.getDirectoryPath();
              if(result != null) {
                setState(() {
                  _path = result;
                  _showFileName = result;
                });
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("또는", style: TextStyle(color: color,),),
                Text("여기를 클릭해 폴더를 선택하세요", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 20,),),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          Text(_showFileName, style: TextStyle(color: defaultColor,),),
          ElevatedButton(
            onPressed: () {
              List<ItemClass> imageFiles = [];
              List<FileSystemEntity> file = Directory(_path).listSync();
              for(FileSystemEntity s in file) {
                final mimeType = lookupMimeType(s.path);
                if(mimeType != null && mimeType.startsWith('image/')) {
                  imageFiles.add(ItemClass(s.path));
                }
              }

              if(imageFiles.isEmpty) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                      title: const Column(
                        children: <Widget>[
                          Text("Error"),
                        ],
                      ),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Dialog Content",),
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
                  arguments: {'path_list': imageFiles},
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
        XFile file = detail.files[0];
        final isDir = FileSystemEntity.isDirectory(file.path);
        isDir.then((val) {
          if(val) {
            _path = file.path;

            setState(() {
              _showFileName = file.path;
            });
          }
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: makeDropZone(),
    );
  }
}