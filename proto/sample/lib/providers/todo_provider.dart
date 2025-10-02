import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/vo/todo.dart';

class TodoProvider extends ChangeNotifier {
  Todo? _todo;
  Todo? get todo => _todo;

  Future<void> getTodo() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/todos/2');
    final response = await http.get(url, headers: {
      'Accept': 'application/json',
      'User-Agent': 'FlutterApp',
    });
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    _todo = Todo.fromJson(map);
    notifyListeners();
  }
}