import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ItemClass extends Equatable {
  final String imagePath;
  final GlobalKey globalKey;

  // 생성자에서 필드 초기화
  /*
  ItemClass(this.imagePath) {
   globalKey = GlobalKey();
  }
  */
  ItemClass(this.imagePath) : globalKey = GlobalKey();

  @override
  List<Object> get props => [imagePath, globalKey];
}