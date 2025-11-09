/**
 * 카탈로그 상세 화면
 * - 카탈로그 정보와 아이템 목록 표시
 * - 소유자/비소유자에 따른 다른 UI 제공
 * - 아이템 수집 상태 관리 (체크박스 토글)
 * - 카탈로그 저장/편집/삭제 기능
 * - 실시간 수집률 업데이트
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/item.dart';
import '../services/platform_config.dart';

import 'item_detail_screen.dart';
import 'catalog_edit_screen.dart';
import 'item_add_screen.dart';
import 'home_screen.dart';

class CatalogDetailScreen extends StatefulWidget {
  final String catalogId; // 표시할 카탈로그 ID
  final bool isPublic; // 공개 모드 여부 (탐색에서 온 경우 true)

  const CatalogDetailScreen({
    super.key,
    required this.catalogId,
    this.isPublic = false,
  });

  @override
  State<CatalogDetailScreen> createState() => _CatalogDetailScreenState();
}

class _CatalogDetailScreenState extends State<CatalogDetailScreen> {
  // 카탈로그 상태 관리 변수들
  bool _isOwnedCatalog = false; // 내가 소유한 카탈로그인지
  bool _isSavedCatalog = false; // 이미 저장한 카탈로그인지
  bool _isSaving = false; // 저장 중인지

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalogAndCheckOwnership();
    });
  }

  /**
   * 카탈로그 로드 및 소유권 확인
   * - catalog-api에서 카탈로그 상세 정보 및 아이템 목록 조회
   * - 현재 사용자의 소유권 및 저장 상태 확인
   * - UI 상태 업데이트 (편집/저장 버튼 표시 여부 결정)
   */
  Future<void> _loadCatalogAndCheckOwnership() async {
    final controller = Get.find<CatalogController>();

    // 카탈로그 상세 정보 및 아이템 목록 로드
    await controller.loadCatalog(widget.catalogId);

    if (!widget.isPublic) {
      // 내 카탈로그에서 온 경우: 소유권 확인
      final isOwned = await controller.checkCatalogOwnership(widget.catalogId);
      setState(() {
        _isOwnedCatalog = isOwned;
      });
    } else {
      // 탐색에서 온 공개 카탈로그인 경우: 소유자 및 저장 상태 확인
      final authController = Get.find<AuthController>();
      final currentUserId = authController.user?.id.toString();

      // 저장 상태 확인 (중복 저장 방지용)
      final isSaved = await controller.checkCatalogSaved(widget.catalogId);
      setState(() {
        _isSavedCatalog = isSaved;
      });

      final catalog = controller.currentCatalog;

      if (catalog != null && currentUserId == catalog.userId) {
        // 자신이 생성한 공개 카탈로그 - 편집 가능
        setState(() {
          _isOwnedCatalog = true;
        });
      } else {
        // 다른 사람이 생성한 공개 카탈로그 - 저장만 가능
        setState(() {
          _isOwnedCatalog = false;
        });
      }
    }
  }

  /**
   * 카탈로그 저장 처리 (다른 사용자의 카탈로그를 내 컬렉션에 복사)
   * - catalog-api의 /api/user-catalogs/save-catalog 엔드포인트 호출
   * - 원본 카탈로그와 모든 아이템을 완전 복사하여 새 카탈로그 생성
   * - 저장 성공 시 UI 상태 업데이트 (저장됨 표시)
   */
  Future<void> _handleSaveCatalog() async {
    setState(() {
      _isSaving = true; // 저장 중 상태 표시
    });

    final controller = Get.find<CatalogController>();
    final success = await controller.saveCatalog(widget.catalogId);

    if (mounted) {
      setState(() {
        _isSaving = false; // 저장 완료
      });

      if (success) {
        Get.snackbar('성공', '카탈로그가 저장되었습니다');

        // 저장 성공 시 UI 상태 업데이트
        setState(() {
          _isSavedCatalog = true; // 저장됨 상태로 변경
        });

        // 카탈로그 정보를 다시 로드하여 최신 상태 반영
        await controller.loadCatalog(widget.catalogId);
      } else {
        // 저장 실패 (중복 저장, 권한 없음 등)
        Get.snackbar('실패', '저장 실패: ${controller.error}',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _handleDeleteCatalog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카탈로그 삭제'),
        content: const Text('정말로 이 카탈로그를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final controller = Get.find<CatalogController>();
      final success = await controller.deleteCatalog(widget.catalogId);

      if (mounted) {
        if (success) {
          // 삭제 성공 팝업 표시
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('삭제 완료'),
                ],
              ),
              content: const Text('카탈로그가 성공적으로 삭제되었습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );

          // 홈 페이지로 이동 (모든 이전 화면 제거)
          Get.offAll(() => const HomeScreen());
        } else {
          Get.snackbar('실패', '삭제 실패: ${controller.error}',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        // 뒤로가기 시 추가 로직이 필요한 경우 여기에 구현
        // didPop이 true면 이미 뒤로가기가 실행됨
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('카탈로그 상세'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
            tooltip: '뒤로가기',
          ),
        ),
        floatingActionButton: !widget.isPublic
            ? FloatingActionButton(
                onPressed: () {
                  Get.to(() => ItemAddScreen(catalogId: widget.catalogId));
                },
                backgroundColor: const Color(0xFF6200EE),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: GetX<CatalogController>(
          builder: (controller) {
            if (controller.isLoading && controller.currentCatalog == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.error.isNotEmpty &&
                controller.currentCatalog == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('오류: ${controller.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadCatalog(widget.catalogId),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            final catalog = controller.currentCatalog;
            if (catalog == null) {
              return const Center(child: Text('카탈로그를 찾을 수 없습니다'));
            }

            return Column(
              children: [
                // 카탈로그 헤더
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (catalog.thumbnailUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            PlatformConfig.getImageUrl(catalog.thumbnailUrl),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported,
                                    size: 64, color: Colors.grey),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.collections_bookmark,
                              size: 64, color: Colors.grey),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        catalog.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        catalog.description,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.collections,
                              label: '아이템 수',
                              value: '${catalog.itemCount}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle,
                              label: '보유',
                              value: '${catalog.ownedCount}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.percent,
                              label: '수집률',
                              value:
                                  '${catalog.completionRate.toStringAsFixed(1)}%',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isOwnedCatalog)
                        // 자신이 생성한 카탈로그 (편집/삭제 버튼)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Get.to(() => CatalogEditScreen(
                                        catalogId: catalog.catalogId,
                                      ));
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('편집하기'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _handleDeleteCatalog,
                                icon: const Icon(Icons.delete),
                                label: const Text('삭제하기'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        // 다른 사람이 생성한 공개 카탈로그 (저장/저장해제 버튼)
                        Builder(
                          builder: (context) {
                            if (_isSavedCatalog) {
                              // 이미 저장된 카탈로그 - "이미 저장됨" 상태 표시
                              return SizedBox(
                                width: double.infinity,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green),
                                      SizedBox(width: 8),
                                      Text(
                                        '이미 저장된 카탈로그입니다',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              // 아직 저장하지 않은 카탈로그 - 저장 버튼
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isSaving ? null : _handleSaveCatalog,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.add),
                                  label: Text(
                                      _isSaving ? '저장 중...' : '내 카탈로그에 저장'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6200EE),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(),
                // 아이템 리스트
                Expanded(
                  child: controller.currentCatalogItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '아이템이 없습니다',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              if (!widget.isPublic) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    Get.to(() => ItemAddScreen(
                                        catalogId: widget.catalogId));
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('첫 번째 아이템 추가하기'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              controller.loadCatalog(widget.catalogId),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.currentCatalogItems.length,
                            itemBuilder: (context, index) {
                              final item =
                                  controller.currentCatalogItems[index];
                              return _ItemCard(
                                item: item,
                                isOwnedCatalog: _isOwnedCatalog,
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF6200EE)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final bool isOwnedCatalog;

  const _ItemCard({
    required this.item,
    required this.isOwnedCatalog,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Get.to(() => ItemDetailScreen(
                itemId: item.itemId,
                isOwnedCatalog: isOwnedCatalog,
              ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    PlatformConfig.getImageUrl(item.imageUrl),
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
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 수집 상태 표시만 (토글 기능 제거)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.owned
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.owned ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: item.owned ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.owned ? '보유' : '미보유',
                      style: TextStyle(
                        fontSize: 12,
                        color: item.owned ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
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
