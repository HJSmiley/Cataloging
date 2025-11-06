import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _introductionController = TextEditingController();
  final _apiService = ApiService();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    final user = authController.user;
    if (user != null) {
      _nicknameController.text = user.nickname;
      _emailController.text = user.email;
      _introductionController.text = user.introduction ?? '';
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _introductionController.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authController = Get.find<AuthController>();
    _apiService.setToken(authController.token);

    String? imageUrl;

    // 이미지 업로드
    if (_selectedImage != null) {
      try {
        final uploadResult = await _apiService.uploadFile(_selectedImage!.path);
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

    // 프로필 업데이트
    final success = await authController.updateUser(
      nickname: _nicknameController.text.trim(),
      introduction: _introductionController.text.trim(),
      profileImage: imageUrl,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        Get.snackbar('성공', '프로필이 저장되었습니다');
        Get.back();
      } else {
        Get.snackbar('실패', '저장 실패: ${authController.error}',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
      ),
      body: GetX<AuthController>(
        builder: (controller) {
          final user = controller.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 프로필 이미지
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (user?.profileImage != null
                                  ? NetworkImage(user!.profileImage!)
                                  : null) as ImageProvider?,
                          child: (_selectedImage == null &&
                                  (user?.profileImage == null))
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF6200EE),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  size: 20, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '닉네임을 입력하세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      helperText: '이메일은 변경할 수 없습니다',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: false, // 읽기 전용으로 설정
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _introductionController,
                    decoration: const InputDecoration(
                      labelText: '자기소개',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
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
            ),
          );
        },
      ),
    );
  }
}
