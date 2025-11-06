import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'profile_edit_screen.dart';
import 'login_screen.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이'),
        automaticallyImplyLeading: false,
      ),
      body: GetX<AuthController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = controller.user;
          if (user == null) {
            return const Center(child: Text('사용자 정보를 불러올 수 없습니다'));
          }

          return ListView(
            children: [
              // 프로필 섹션
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: user.profileImage != null
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: user.profileImage == null
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.nickname,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    if (user.introduction != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.introduction!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.to(() => const ProfileEditScreen());
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('프로필 편집'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 설정 메뉴
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('설정'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // 설정 화면으로 이동 (나중에 구현)
                  Get.snackbar('알림', '설정 기능은 준비 중입니다');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('로그아웃'),
                      content: const Text('정말로 로그아웃하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('로그아웃'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await controller.logout();
                    if (context.mounted) {
                      Get.offAll(() => const LoginScreen());
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  '회원 탈퇴',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('회원 탈퇴'),
                      content: const Text(
                        '정말로 회원 탈퇴하시겠습니까? 모든 데이터가 삭제됩니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('탈퇴'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    final success = await controller.deleteAccount();
                    if (context.mounted) {
                      if (success) {
                        Get.offAll(() => const LoginScreen());
                      } else {
                        Get.snackbar('실패', '탈퇴 실패: ${controller.error}',
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                      }
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
