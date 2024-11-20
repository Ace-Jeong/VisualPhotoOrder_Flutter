// 이미지 리스트 (이미지별 경로및 크기를 알기 위한) 관리를 위한 아이템 클래스
// ->이미지 경로와 이미지 크기를 알기 위한 키를 가지고 있는 클래스
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