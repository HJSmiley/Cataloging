import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../models/catalog.dart';
import 'catalog_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = '전체';

  final List<String> _filters = ['전체', '인기 카탈로그', '신규 카탈로그'];

  @override
  void initState() {
    super.initState();
    // 탐색 화면 진입 시 카탈로그 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadCatalogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('탐색'), automaticallyImplyLeading: false),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '카탈로그 검색 (예: 스니커즈, TCG)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // 필터 칩
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 카탈로그 목록
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
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '카탈로그를 불러오는데 실패했습니다',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          catalogProvider.error!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => catalogProvider.loadCatalogs(),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredCatalogs = _getFilteredCatalogs(
                  catalogProvider.catalogs,
                );

                if (filteredCatalogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? '검색 결과가 없습니다'
                              : '카탈로그가 없습니다',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '"$_searchQuery"에 대한 검색 결과가 없습니다',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => catalogProvider.loadCatalogs(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredCatalogs.length,
                    itemBuilder: (context, index) {
                      final catalog = filteredCatalogs[index];
                      return _buildCatalogCard(context, catalog);
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

  List<Catalog> _getFilteredCatalogs(List<Catalog> catalogs) {
    List<Catalog> filtered = catalogs;

    // 검색어 필터링
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((catalog) {
        return catalog.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            catalog.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            catalog.category.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            catalog.tags.any(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
            );
      }).toList();
    }

    // 필터 적용
    switch (_selectedFilter) {
      case '인기 카탈로그':
        // 아이템 수가 많은 순으로 정렬
        filtered.sort((a, b) => b.itemCount.compareTo(a.itemCount));
        break;
      case '신규 카탈로그':
        // 생성일이 최신 순으로 정렬
        filtered.sort(
          (a, b) => DateTime.parse(
            b.createdAt,
          ).compareTo(DateTime.parse(a.createdAt)),
        );
        break;
      default:
        // 전체: 기본 정렬 (최신순)
        filtered.sort(
          (a, b) => DateTime.parse(
            b.updatedAt,
          ).compareTo(DateTime.parse(a.updatedAt)),
        );
        break;
    }

    return filtered;
  }

  Widget _buildCatalogCard(BuildContext context, Catalog catalog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CatalogDetailScreen(catalog: catalog),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 썸네일
              Container(
                width: 80,
                height: 80,
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
                            return const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.collections,
                        color: Colors.grey,
                        size: 32,
                      ),
              ),

              const SizedBox(width: 16),

              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      catalog.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // 설명
                    Text(
                      catalog.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // 카테고리 및 아이템 수
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            catalog.category,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),

                        const Spacer(),

                        Text(
                          '${catalog.itemCount}개 아이템',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 진행률
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: catalog.itemCount > 0
                                ? catalog.completionRate / 100
                                : 0,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              catalog.completionRate == 100
                                  ? Colors.green
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${catalog.completionRate.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: catalog.completionRate == 100
                                    ? Colors.green
                                    : Theme.of(context).primaryColor,
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
  }
}
