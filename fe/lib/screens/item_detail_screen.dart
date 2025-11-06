import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dart:math';
import '../controllers/catalog_controller.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../widgets/slide_to_act_button.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  final bool? isOwnedCatalog;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
    this.isOwnedCatalog,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isCompleting = false;
  bool _showCelebration = false;
  bool _isOwnedCatalog = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _checkCatalogOwnership();
  }

  Future<void> _checkCatalogOwnership() async {
    if (widget.isOwnedCatalog != null) {
      setState(() {
        _isOwnedCatalog = widget.isOwnedCatalog!;
      });
      return;
    }

    // 현재 아이템의 카탈로그 ID를 통해 소유권 확인
    final controller = Get.find<CatalogController>();
    try {
      final item = controller.currentCatalogItems
          .firstWhere((i) => i.itemId == widget.itemId);

      final isOwned = await controller.checkCatalogOwnership(item.catalogId);
      setState(() {
        _isOwnedCatalog = isOwned;
      });
    } catch (e) {
      // 아이템을 찾을 수 없는 경우 소유하지 않은 것으로 처리
      setState(() {
        _isOwnedCatalog = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleOwned() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
      _showCelebration = true;
    });

    final controller = Get.find<CatalogController>();
    await controller.toggleItemOwned(widget.itemId);

    if (mounted) {
      setState(() {
        _isCompleting = false;
      });

      // 축하 효과 표시 후 자동으로 숨김
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showCelebration = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아이템 상세'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: '뒤로가기',
        ),
      ),
      body: GetX<CatalogController>(
        builder: (controller) {
          final item = controller.currentCatalogItems
              .firstWhere((i) => i.itemId == widget.itemId,
                  orElse: () => Item(
                        itemId: widget.itemId,
                        catalogId: '',
                        name: '로딩 중...',
                        description: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ));

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 이미지 슬라이드
                    if (item.imageUrl != null)
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                        ),
                        child: Image.network(
                          ApiService.getImageUrl(item.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported,
                                  size: 64, color: Colors.grey),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(
                          child:
                              Icon(Icons.image, size: 64, color: Colors.grey),
                        ),
                      ),
                    // 기본 정보
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          // 사용자 정의 필드
                          if (item.userFields.isNotEmpty) ...[
                            const Text(
                              '상세 정보',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...item.userFields.entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(entry.value),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // 버튼 공간 확보
                  ],
                ),
              ),
              // 하단 버튼 (소유한 카탈로그인 경우에만 표시)
              if (_isOwnedCatalog)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SlideToActButton(
                        text: item.owned ? '수집 해제하기' : '슬라이드하여 수집하기',
                        completedText: item.owned ? '수집 해제됨!' : '수집 완료!',
                        icon: item.owned
                            ? Icons.remove_circle_outline
                            : Icons.arrow_forward_ios,
                        completedIcon: item.owned
                            ? Icons.remove_circle
                            : Icons.check_circle,
                        backgroundColor: item.owned
                            ? Colors.orange
                            : const Color(0xFF6200EE),
                        completedBackgroundColor:
                            item.owned ? Colors.red : Colors.green,
                        onSlideComplete: _handleToggleOwned,
                        isCompleted: _showCelebration,
                        isLoading: _isCompleting,
                      ),
                    ),
                  ),
                )
              else
                // 소유하지 않은 카탈로그인 경우 안내 메시지
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              '카탈로그를 저장한 후 수집할 수 있습니다',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // 축하 애니메이션
              if (_showCelebration)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _CelebrationAnimation(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CelebrationAnimation extends StatefulWidget {
  @override
  State<_CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<_CelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _particles = List.generate(
      20,
      (index) => Particle(
        x: 0.5,
        y: 0.5,
        vx: (Random().nextDouble() - 0.5) * 0.02,
        vy: (Random().nextDouble() - 0.5) * 0.02,
        color: [
          Colors.yellow,
          Colors.orange,
          Colors.pink,
          Colors.purple,
          Colors.blue,
        ][Random().nextInt(5)],
      ),
    );

    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CelebrationPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
  });
}

class CelebrationPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  CelebrationPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1 - progress)
        ..style = PaintingStyle.fill;

      final x = (particle.x + particle.vx * progress * 100) * size.width;
      final y = (particle.y + particle.vy * progress * 100) * size.height;

      canvas.drawCircle(Offset(x, y), 10 * (1 - progress), paint);
    }

    // 별과 하트 아이콘
    if (progress < 0.5) {
      final starPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 1 - progress * 2)
        ..style = PaintingStyle.fill;

      final centerX = size.width / 2;
      final centerY = size.height / 2;

      // 별 그리기
      final starPath = Path();
      for (int i = 0; i < 5; i++) {
        final angle = (i * 2 * pi / 5) - pi / 2;
        final x = centerX + cos(angle) * 50 * (1 - progress * 2);
        final y = centerY + sin(angle) * 50 * (1 - progress * 2);
        if (i == 0) {
          starPath.moveTo(x, y);
        } else {
          starPath.lineTo(x, y);
        }
      }
      starPath.close();
      canvas.drawPath(starPath, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
