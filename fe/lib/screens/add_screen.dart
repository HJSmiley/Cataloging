import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../models/catalog.dart';
import 'create_catalog_screen.dart';
import 'create_item_screen.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 카탈로그 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadCatalogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추가'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 텍스트
            Text(
              '무엇을 추가하시겠습니까?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 카탈로그를 만들거나 기존 카탈로그에 아이템을 추가할 수 있습니다.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),

            // 새 카탈로그 추가 카드
            _buildAddOptionCard(
              context: context,
              icon: Icons.add_box,
              title: '새 카탈로그 추가',
              description: '새로운 수집 카탈로그를 만들어보세요',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCatalogScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 기존 카탈로그에 아이템 추가 카드
            _buildAddOptionCard(
              context: context,
              icon: Icons.add_circle,
              title: '기존 카탈로그에 아이템 추가',
              description: '보유하고 있는 카탈로그에 새 아이템을 추가하세요',
              color: Colors.green,
              onTap: () {
                _showCatalogSelectionBottomSheet(context);
              },
            ),

            const SizedBox(height: 32),

            // 최근 카탈로그 섹션
            Text(
              '최근 카탈로그',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 최근 카탈로그 목록
            Expanded(
              child: Consumer<CatalogProvider>(
                builder: (context, catalogProvider, child) {
                  if (catalogProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (catalogProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '카탈로그를 불러오는데 실패했습니다',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => catalogProvider.loadCatalogs(),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );
                  }

                  final recentCatalogs = catalogProvider.catalogs
                      .take(5) // 최근 5개만 표시
                      .toList();

                  if (recentCatalogs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.collections_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '아직 카탈로그가 없습니다',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '첫 번째 카탈로그를 만들어보세요!',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: recentCatalogs.length,
                    itemBuilder: (context, index) {
                      final catalog = recentCatalogs[index];
                      return _buildRecentCatalogTile(context, catalog);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCatalogTile(BuildContext context, Catalog catalog) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade200,
        ),
        child: catalog.thumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  catalog.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.collections, color: Colors.grey);
                  },
                ),
              )
            : const Icon(Icons.collections, color: Colors.grey),
      ),
      title: Text(catalog.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${catalog.itemCount}개 아이템 • ${catalog.completionRate.toInt()}% 완료',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
      ),
      trailing: IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateItemScreen(catalogId: catalog.catalogId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        tooltip: '아이템 추가',
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreateItemScreen(catalogId: catalog.catalogId),
          ),
        );
      },
    );
  }

  void _showCatalogSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // 핸들
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 헤더
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '카탈로그 선택',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 카탈로그 목록
                Expanded(
                  child: Consumer<CatalogProvider>(
                    builder: (context, catalogProvider, child) {
                      if (catalogProvider.catalogs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.collections_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text('카탈로그가 없습니다'),
                              SizedBox(height: 8),
                              Text(
                                '먼저 카탈로그를 만들어주세요',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: catalogProvider.catalogs.length,
                        itemBuilder: (context, index) {
                          final catalog = catalogProvider.catalogs[index];
                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: catalog.thumbnailUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        catalog.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.collections,
                                                color: Colors.grey,
                                              );
                                            },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.collections,
                                      color: Colors.grey,
                                    ),
                            ),
                            title: Text(catalog.title),
                            subtitle: Text(
                              '${catalog.itemCount}개 아이템',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateItemScreen(
                                    catalogId: catalog.catalogId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
