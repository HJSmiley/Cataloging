import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/catalog_controller.dart';

class ItemAddScreen extends StatefulWidget {
  final String catalogId;

  const ItemAddScreen({
    super.key,
    required this.catalogId,
  });

  @override
  State<ItemAddScreen> createState() => _ItemAddScreenState();
}

class _ItemAddScreenState extends State<ItemAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        '이미지 선택 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final controller = Get.find<CatalogController>();
    String? imageUrl;

    // 이미지 업로드
    if (_selectedImage != null) {
      try {
        if (kIsWeb) {
          // 웹 환경에서는 바이트 배열 사용
          final bytes = await _selectedImage!.readAsBytes();
          // 파일 경로에서 파일명 추출 (간단한 방법)
          final filePath = _selectedImage!.path;
          String fileName = 'image.jpg'; // 기본값

          if (filePath.isNotEmpty) {
            // 경로에서 마지막 부분(파일명) 추출
            final segments = filePath.split(RegExp(r'[/\\]')); // / 또는 \ 로 분할
            if (segments.isNotEmpty) {
              final lastSegment = segments.last;
              if (lastSegment.contains('.')) {
                fileName = lastSegment;
              }
            }
          }

          imageUrl = await controller.uploadImageBytes(bytes, fileName);
        } else {
          // 모바일 환경에서는 파일 경로 사용
          imageUrl = await controller.uploadImage(_selectedImage!.path);
        }

        if (imageUrl == null) {
          if (mounted) {
            Get.snackbar('실패', '이미지 업로드 실패: ${controller.error}',
                backgroundColor: Colors.red, colorText: Colors.white);
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        if (mounted) {
          Get.snackbar('실패', '이미지 업로드 실패: $e',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    final success = await controller.createItem(
      catalogId: widget.catalogId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: imageUrl,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        Get.back();
        Get.snackbar(
          '성공',
          '아이템이 추가되었습니다',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          '오류',
          controller.error.isNotEmpty ? controller.error : '아이템 추가에 실패했습니다',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아이템 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: '뒤로가기',
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '아이템 이름',
                hintText: '예: 포켓몬 카드 #001',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '아이템 이름을 입력하세요';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명',
                hintText: '아이템에 대한 설명을 입력하세요',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '설명을 입력하세요';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // 이미지 업로드 섹션
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '아이템 이미지 (선택사항)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImage == null)
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('이미지 선택'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(
                                    _selectedImage!.path,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image,
                                                size: 48, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text(
                                              '선택된 이미지',
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    _selectedImage!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('이미지 변경'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('이미지 제거'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSubmit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading ? '추가 중...' : '아이템 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
