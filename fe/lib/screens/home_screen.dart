/**
 * 메인 홈 화면 (탭 네비게이션)
 * - 4개 탭으로 구성: 홈, 탐색, 추가, 마이
 * - BottomNavigationBar로 탭 전환
 * - 각 탭별로 데이터 새로고침 처리
 * - 로그인 후 첫 화면으로 표시
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/catalog.dart';
import '../services/platform_config.dart';
import 'explore_screen.dart';
import 'add_screen.dart';
import 'my_screen.dart';
import 'catalog_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 현재 선택된 탭 인덱스

  // 각 탭에 해당하는 화면들
  final List<Widget> _screens = [
    const HomeTab(), // 0: 홈 탭 (내 카탈로그 목록)
    const ExploreScreen(), // 1: 탐색 탭 (공개 카탈로그 목록)
    const AddScreen(), // 2: 추가 탭 (새 카탈로그 생성)
    const MyScreen(), // 3: 마이 탭 (프로필 및 설정)
  ];

  /**
   * 화면 초기화
   * - JWT 토큰을 CatalogController에 설정
   * - 내 카탈로그 목록 로드
   */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Get.find<AuthController>();
      final catalogController = Get.find<CatalogController>();

      // catalog-api 인증을 위해 JWT 토큰 설정
      catalogController.setApiToken(authController.token);

      // 홈 탭 초기 데이터 로드
      catalogController.loadMyCatalogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);

          // 탭 전환 시 해당 탭의 데이터 새로고침
          final catalogController = Get.find<CatalogController>();

          if (index == 1) {
            // 탐색 탭: 내 카탈로그 + 공개 카탈로그 로드
            catalogController.loadMyCatalogs(); // 저장 상태 확인용
            catalogController.loadPublicCatalogs(); // 공개 카탈로그 목록
          } else if (index == 0) {
            // 홈 탭: 내 카탈로그만 로드
            catalogController.loadMyCatalogs();
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: '탐색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: '추가',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}

/**
 * 홈 탭 위젯
 * - 내 카탈로그 목록을 그리드 형태로 표시
 * - 각 카탈로그의 수집률 진행바 표시
 * - 카탈로그 클릭 시 상세 화면으로 이동
 * - 당겨서 새로고침 지원
 */
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
      ),
      body: GetX<CatalogController>(
        builder: (controller) {
          // 로딩 상태 (첫 로드 시)
          if (controller.isLoading && controller.myCatalogs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // 에러 상태 (데이터 없을 때만)
          if (controller.error.isNotEmpty && controller.myCatalogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('오류: ${controller.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadMyCatalogs(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // 빈 상태 (카탈로그 없음)
          if (controller.myCatalogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.collections_bookmark_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    '아직 카탈로그가 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Get.to(() => const AddScreen()); // 추가 화면으로 이동
                    },
                    child: const Text('새 카탈로그 추가하기'),
                  ),
                ],
              ),
            );
          }

          // 카탈로그 목록 표시 (그리드 형태)
          return RefreshIndicator(
            onRefresh: () => controller.loadMyCatalogs(), // 당겨서 새로고침
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2열 그리드
                crossAxisSpacing: 16, // 가로 간격
                mainAxisSpacing: 16, // 세로 간격
                childAspectRatio: 0.8, // 카드 비율 (세로가 더 김)
              ),
              itemCount: controller.myCatalogs.length,
              itemBuilder: (context, index) {
                final catalog = controller.myCatalogs[index];
                return _CatalogCard(catalog: catalog); // 카탈로그 카드 위젯
              },
            ),
          );
        },
      ),
    );
  }
}

/**
 * 카탈로그 카드 위젯
 * - 홈 화면의 그리드에서 각 카탈로그를 표시
 * - 썸네일 이미지, 제목, 수집률 진행바 포함
 * - 클릭 시 카탈로그 상세 화면으로 이동
 * - 수집률에 따라 진행바 색상 변경 (완료 시 녹색)
 */
class _CatalogCard extends StatelessWidget {
  final Catalog catalog;

  const _CatalogCard({required this.catalog});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // 카드 모서리 클리핑
      elevation: 2, // 그림자 효과
      child: InkWell(
        onTap: () {
          // 카탈로그 상세 화면으로 이동
          Get.to(() => CatalogDetailScreen(catalogId: catalog.catalogId));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 썸네일 이미지 영역
            Expanded(
              child: catalog.thumbnailUrl != null
                  ? Image.network(
                      PlatformConfig.getImageUrl(
                          catalog.thumbnailUrl), // catalog-api 이미지 URL
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // 이미지 로드 실패 시 기본 아이콘 표시
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported,
                              size: 48, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      // 썸네일이 없는 경우 기본 아이콘
                      color: Colors.grey[300],
                      child: const Icon(Icons.collections_bookmark,
                          size: 48, color: Colors.grey),
                    ),
            ),
            // 카탈로그 정보 영역
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목과 '내 카탈로그' 태그
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          catalog.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // 긴 제목 생략
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.blue, width: 0.5),
                        ),
                        child: const Text(
                          '내 카탈로그',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 수집률 진행바
                  LinearProgressIndicator(
                    value: catalog.completionRate / 100, // 0.0 ~ 1.0 범위
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      catalog.completionRate == 100
                          ? Colors.green // 100% 완료 시 녹색
                          : Colors.blue, // 진행 중일 때 파란색
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 수집률 텍스트 (보유/전체 개수와 퍼센트)
                  Text(
                    '${catalog.ownedCount}/${catalog.itemCount} (${catalog.completionRate.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
