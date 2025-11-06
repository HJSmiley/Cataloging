import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/catalog.dart';
import '../services/api_service.dart';
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
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const ExploreScreen(),
    const AddScreen(),
    const MyScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Get.find<AuthController>();
      final catalogController = Get.find<CatalogController>();
      catalogController.setApiToken(authController.token);
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

          // 탐색 탭으로 전환 시 데이터 새로고침
          if (index == 1) {
            // ExploreScreen
            final catalogController = Get.find<CatalogController>();
            catalogController.loadMyCatalogs();
            catalogController.loadPublicCatalogs();
          }
          // 홈 탭으로 전환 시 내 카탈로그 새로고침
          else if (index == 0) {
            // HomeTab
            final catalogController = Get.find<CatalogController>();
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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        automaticallyImplyLeading: false,
      ),
      body: GetX<CatalogController>(
        builder: (controller) {
          if (controller.isLoading && controller.myCatalogs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

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
                      Get.to(() => const AddScreen());
                    },
                    child: const Text('새 카탈로그 추가하기'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadMyCatalogs(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: controller.myCatalogs.length,
              itemBuilder: (context, index) {
                final catalog = controller.myCatalogs[index];
                return _CatalogCard(catalog: catalog);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final Catalog catalog;

  const _CatalogCard({required this.catalog});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Get.to(() => CatalogDetailScreen(catalogId: catalog.catalogId));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: catalog.thumbnailUrl != null
                  ? Image.network(
                      ApiService.getImageUrl(catalog.thumbnailUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported,
                              size: 48, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.collections_bookmark,
                          size: 48, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          overflow: TextOverflow.ellipsis,
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
                  LinearProgressIndicator(
                    value: catalog.completionRate / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      catalog.completionRate == 100
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
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
