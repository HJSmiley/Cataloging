import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/catalog.dart';
import '../services/platform_config.dart';
import 'catalog_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'popular', 'new'
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 첫 로드가 아닌 경우에만 새로고침 (탭 전환 시)
    if (!_isFirstLoad) {
      _loadData();
    }
    _isFirstLoad = false;
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<CatalogController>();
      // 저장 상태 확인을 위해 내 카탈로그도 로드
      controller.loadMyCatalogs();
      controller.loadPublicCatalogs();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 포그라운드로 돌아올 때 새로고침
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadData();
    } else {
      // 검색 기능은 나중에 구현
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카탈로그 탐색'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '검색 (예: 스니커즈, TCG)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _FilterChip(
                  label: '전체',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '인기 카탈로그',
                  isSelected: _selectedFilter == 'popular',
                  onTap: () => setState(() => _selectedFilter = 'popular'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '신규 카탈로그',
                  isSelected: _selectedFilter == 'new',
                  onTap: () => setState(() => _selectedFilter = 'new'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GetX<CatalogController>(
              builder: (controller) {
                if (controller.isLoading && controller.publicCatalogs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.error.isNotEmpty &&
                    controller.publicCatalogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('오류: ${controller.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.publicCatalogs.isEmpty) {
                  return const Center(
                    child: Text('검색 결과가 없습니다'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await controller.loadMyCatalogs();
                    await controller.loadPublicCatalogs();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.publicCatalogs.length,
                    itemBuilder: (context, index) {
                      final catalog = controller.publicCatalogs[index];
                      return _CatalogListItem(catalog: catalog);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _CatalogListItem extends StatelessWidget {
  final Catalog catalog;

  const _CatalogListItem({required this.catalog});

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (authController) {
        final currentUserId = authController.user?.id.toString();
        final isMyOwnCatalog = currentUserId == catalog.userId;

        return GetX<CatalogController>(
          builder: (catalogController) {
            final isSaved = catalogController.isCatalogSaved(catalog.catalogId);
            final copiedCatalogId =
                catalogController.getCopiedCatalogId(catalog.catalogId);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (isMyOwnCatalog) {
                    // 자신이 생성한 카탈로그 - 원본 ID로 편집 모드
                    Get.to(() => CatalogDetailScreen(
                          catalogId: catalog.catalogId,
                          isPublic: false,
                        ));
                  } else if (isSaved && copiedCatalogId != null) {
                    // 저장된 카탈로그 - 복사본 ID로 편집 모드
                    Get.to(() => CatalogDetailScreen(
                          catalogId: copiedCatalogId,
                          isPublic: false,
                        ));
                  } else {
                    // 저장하지 않은 카탈로그 - 원본 ID로 공개 모드
                    Get.to(() => CatalogDetailScreen(
                          catalogId: catalog.catalogId,
                          isPublic: true,
                        ));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // 카탈로그 썸네일
                      catalog.thumbnailUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                PlatformConfig.getImageUrl(catalog.thumbnailUrl),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported,
                                        color: Colors.grey),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.collections_bookmark,
                                  color: Colors.grey),
                            ),
                      const SizedBox(width: 16),
                      // 카탈로그 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catalog.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              catalog.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.collections,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${catalog.itemCount}개 아이템',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                // 상태 표시만 (저장 버튼 제거)
                                if (isMyOwnCatalog)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                          color: Colors.blue, width: 0.5),
                                    ),
                                    child: const Text(
                                      '내가 생성',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                else if (isSaved)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                          color: Colors.green, width: 0.5),
                                    ),
                                    child: const Text(
                                      '저장됨',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
