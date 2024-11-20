//객체지향 패턴 중 싱글톤 패턴을 사용하여 ItemClass를 관리하는 클래스
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_dir/open_dir.dart';
import 'package:path/path.dart' as path;
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:visual_photo_order/Model/ItemClass.dart';

class ItemSingleton {
  static final ItemSingleton instance = ItemSingleton._internal();
  factory ItemSingleton() => instance;
  ItemSingleton._internal();
  
  List<ItemClass> list = [];
  String saveName = "";

  Future<void> saveAll(BuildContext context) async {
    String savePath = path.join(path.dirname(list.first.imagePath), 'renamed');
    Directory newDirectory = Directory(savePath);
    if (!await newDirectory.exists()) {
      await newDirectory.create(recursive: true);
    }
    
    if(!context.mounted) return;
    
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(max: list.length, msg: '저장중입니다...');

    int idx = 0;
    for(var file in list) {
      String saveFile = path.join(savePath, saveName + idx.toString().padLeft(3, '0') + path.extension(file.imagePath));
      await File(file.imagePath).copy(saveFile);
      pd.update(value: idx + 1); 
      idx++;
    }

    pd.close();

    await OpenDir().openNativeDir(path: savePath);
  }
}