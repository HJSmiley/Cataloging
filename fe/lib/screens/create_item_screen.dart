import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';

class CreateItemScreen extends StatefulWidget {
  final String catalogId;

  const CreateItemScreen({super.key, required this.catalogId});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _owned = false;
  bool _isLoading = false;

  final List<MapEntry<String, String>> _userFields = [];
  final _fieldKeyController = TextEditingController();
  final _fieldValueController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _fieldKeyController.dispose();
    _fieldValueController.dispose();
    super.dispose();
  }

  void _addUserField() {
    if (_fieldKeyController.text.trim().isNotEmpty &&
        _fieldValueController.text.trim().isNotEmpty) {
      setState(() {
        _userFields.add(
          MapEntry(
            _fieldKeyController.text.trim(),
            _fieldValueController.text.trim(),
          ),
        );
        _fieldKeyController.clear();
        _fieldValueController.clear();
      });
    }
  }

  void _removeUserField(int index) {
    setState(() {
      _userFields.removeAt(index);
    });
  }

  Future<void> _createItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userFieldsMap = Map<String, String>.fromEntries(_userFields);

      final itemCreate = ItemCreate(
        catalogId: widget.catalogId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        owned: _owned,
        userFields: userFieldsMap,
      );

      await context.read<ItemProvider>().createItem(itemCreate);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('아이템이 생성되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아이템 추가'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '아이템명 *',
                hintText: '예: 미쿠 피규어 Ver.1',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '아이템명을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명 *',
                hintText: '아이템에 대한 설명을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '설명을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('보유 여부'),
              subtitle: Text(_owned ? '보유 중' : '미보유'),
              value: _owned,
              onChanged: (value) {
                setState(() {
                  _owned = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '사용자 정의 필드',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fieldKeyController,
                    decoration: const InputDecoration(
                      labelText: '필드명',
                      hintText: '예: 제조사',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _fieldValueController,
                    decoration: const InputDecoration(
                      labelText: '값',
                      hintText: '예: 굿스마일컴퍼니',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addUserField,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_userFields.isNotEmpty) ...[
              const Text('추가된 필드:'),
              const SizedBox(height: 8),
              ..._userFields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(field.key),
                    subtitle: Text(field.value),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeUserField(index),
                    ),
                  ),
                );
              }).toList(),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createItem,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('아이템 추가'),
            ),
          ],
        ),
      ),
    );
  }
}
