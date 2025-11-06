import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/catalog_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';
import 'catalog_detail_screen.dart';

class CatalogEditScreen extends StatefulWidget {
  final String? catalogId;

  const CatalogEditScreen({super.key, this.catalogId});

  @override
  State<CatalogEditScreen> createState() => _CatalogEditScreenState();
}

class _CatalogEditScreenState extends State<CatalogEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController(text: '미분류');
  final _tagsController = TextEditingController();
  final _apiService = ApiService();
  File? _selectedImage;
  String _visibility = 'public';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.catalogId != null) {
      _loadCatalog();
    }
  }

  Future<void> _loadCatalog() async {
    final controller = Get.find<CatalogController>();
    await controller.loadCatalog(widget.catalogId!);
    final catalog = controller.currentCatalog;

    if (catalog != null && mounted) {
      setState(() {
        _titleController.text = catalog.title;
        _descriptionController.text = catalog.description;
        _categoryController.text = catalog.category;
        _tagsController.text = catalog.tags.join(', ');
        _visibility = catalog.visibility;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveCatalog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final controller = Get.find<CatalogController>();
    final authController = Get.find<AuthController>();
    _apiService.setToken(authController.token);

    String? imageUrl;

    // 이미지 업로드
    if (_selectedImage != null) {
      try {
        Map<String, dynamic> uploadResult;

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

          uploadResult = await _apiService.uploadFileBytes(bytes, fileName);
        } else {
          // 모바일 환경에서는 파일 경로 사용
          uploadResult = await _apiService.uploadFile(_selectedImage!.path);
        }

        imageUrl = uploadResult['file_url'] as String?;
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

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (widget.catalogId != null) {
      // 수정
      final success = await controller.updateCatalog(
        widget.catalogId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        tags: tags,
        visibility: _visibility,
        thumbnailUrl: imageUrl,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (success) {
          Get.snackbar('성공', '카탈로그가 수정되었습니다');
          // 수정된 카탈로그 상세 페이지로 이동
          Get.off(() => CatalogDetailScreen(
                catalogId: widget.catalogId!,
                isPublic: false,
              ));
        } else {
          Get.snackbar('실패', '저장 실패: ${controller.error}',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } else {
      // 생성
      final newCatalog = await controller.createCatalog(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        tags: tags,
        visibility: _visibility,
        thumbnailUrl: imageUrl,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (newCatalog != null) {
          Get.snackbar('성공', '카탈로그가 생성되었습니다');
          // 생성된 카탈로그의 상세 페이지로 이동 (현재 화면 교체)
          Get.off(() => CatalogDetailScreen(
                catalogId: newCatalog.catalogId,
              ));
        } else {
          Get.snackbar('실패', '저장 실패: ${controller.error}',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.catalogId != null ? '카탈로그 수정' : '새 카탈로그'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: '뒤로가기',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 썸네일 이미지
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text(
                              '썸네일 이미지 추가',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '설명을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: '카테고리',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: '태그 (쉼표로 구분)',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                  hintText: '예: 스니커즈, 운동화, 나이키',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: const InputDecoration(
                  labelText: '공개 여부',
                  prefixIcon: Icon(Icons.visibility),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'public',
                    child: Text('공개'),
                  ),
                  DropdownMenuItem(
                    value: 'private',
                    child: Text('비공개'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _visibility = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCatalog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6200EE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.catalogId != null ? '수정' : '생성',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
