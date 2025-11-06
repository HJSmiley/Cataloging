import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/catalog_controller.dart';
import 'catalog_edit_screen.dart';
import 'catalog_detail_screen.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추가'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 80,
                color: Color(0xFF6200EE),
              ),
              const SizedBox(height: 32),
              const Text(
                '새로운 콘텐츠 추가',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => const CatalogEditScreen());
                  },
                  icon: const Icon(Icons.collections_bookmark),
                  label: const Text('새 카탈로그 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showCatalogSelector(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('기존 카탈로그에 새 아이템 추가'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6200EE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCatalogSelector(BuildContext context) {
    final controller = Get.find<CatalogController>();
    controller.loadMyCatalogs();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return GetX<CatalogController>(
          builder: (controller) {
            if (controller.isLoading && controller.myCatalogs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.myCatalogs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('카탈로그가 없습니다. 먼저 카탈로그를 생성하세요.'),
              );
            }

            return ListView.builder(
              itemCount: controller.myCatalogs.length,
              itemBuilder: (context, index) {
                final catalog = controller.myCatalogs[index];
                return ListTile(
                  leading: const Icon(Icons.collections_bookmark),
                  title: Text(catalog.title),
                  subtitle: Text('${catalog.itemCount}개 아이템'),
                  onTap: () {
                    Get.back();
                    Get.to(() => CatalogDetailScreen(
                          catalogId: catalog.catalogId,
                        ));
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
