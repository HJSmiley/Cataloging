import 'package:flutter/material.dart';
import 'package:fe/presentation/add/add_item.dart/';

main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // 전역 테마에서 강제 배경색을 지정하지 않고, 화면 구성으로 제어
      home: AddItemPage(), // 아이템 추가 페이지로 이동
    );
  }
}
