import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample/providers/todo_provider.dart';
import 'package:provider/provider.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  @override
  void initState() {
    super.initState();
    // todo 요청
    Future.microtask(() =>
        Provider.of<TodoProvider>(context, listen: false).getTodo());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff6527F5),
        title: const Text('TODO 페이지',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Consumer<TodoProvider>(
          builder: (context, todoProvider, child) {
            final t = todoProvider.todo;
            if (t == null) return const CircularProgressIndicator();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.title ?? ''),
                Text('${t.userId ?? ''}'),
                Text('${t.id ?? ''}'),
                Text('${t.completed ?? ''}'),
              ],
            );
          },
        ),
      ),
    );
  }
}