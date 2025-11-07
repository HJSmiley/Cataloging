/**
 * 슬라이드 투 액트 버튼 위젯
 * - 아이템 수집 상태 토글을 위한 커스텀 UI 컴포넌트
 * - 사용자가 슬라이더를 80% 이상 드래그하면 액션 실행
 * - 수집/해제에 따른 다른 색상과 아이콘 표시
 * - 로딩 상태와 완료 상태 애니메이션 지원
 * - 실수로 인한 상태 변경 방지 (의도적인 슬라이드 필요)
 */

import 'package:flutter/material.dart';

class SlideToActButton extends StatefulWidget {
  final String text; // 기본 상태 텍스트
  final String completedText; // 완료 상태 텍스트
  final IconData icon; // 기본 상태 아이콘
  final IconData completedIcon; // 완료 상태 아이콘
  final Color backgroundColor; // 기본 배경색
  final Color completedBackgroundColor; // 완료 시 배경색
  final Color sliderColor; // 슬라이더 버튼 색상
  final VoidCallback onSlideComplete; // 슬라이드 완료 시 호출될 함수
  final bool isCompleted; // 완료 상태 여부
  final bool isLoading; // 로딩 상태 여부

  const SlideToActButton({
    super.key,
    required this.text,
    required this.completedText,
    required this.icon,
    required this.completedIcon,
    required this.onSlideComplete,
    this.backgroundColor = const Color(0xFF6200EE),
    this.completedBackgroundColor = Colors.green,
    this.sliderColor = Colors.white,
    this.isCompleted = false,
    this.isLoading = false,
  });

  @override
  State<SlideToActButton> createState() => _SlideToActButtonState();
}

class _SlideToActButtonState extends State<SlideToActButton>
    with TickerProviderStateMixin {
  // 애니메이션 컨트롤러들
  late AnimationController _slideController; // 슬라이드 진행 애니메이션
  late AnimationController _scaleController; // 버튼 스케일 애니메이션
  late Animation<double> _slideAnimation; // 슬라이드 애니메이션
  late Animation<double> _scaleAnimation; // 스케일 애니메이션

  // 드래그 상태 관리
  double _dragPosition = 0.0; // 현재 드래그 위치

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /**
   * 드래그 시작 처리
   * - 로딩 중이면 드래그 무시
   * - 버튼 스케일 애니메이션 시작 (시각적 피드백)
   */
  void _onPanStart(DragStartDetails details) {
    if (widget.isLoading) return;

    _scaleController.forward(); // 버튼 축소 애니메이션
  }

  /**
   * 드래그 업데이트 처리
   * - 슬라이더 위치 업데이트
   * - 드래그 범위 제한 (0 ~ 최대 거리)
   * - 진행률에 따른 애니메이션 업데이트
   */
  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (widget.isLoading) return;

    final sliderWidth = 56.0; // 슬라이더 버튼 크기
    final maxDragDistance = maxWidth - sliderWidth - 8; // 최대 드래그 거리 (패딩 고려)

    setState(() {
      // 드래그 위치 업데이트 (범위 제한)
      _dragPosition =
          (_dragPosition + details.delta.dx).clamp(0.0, maxDragDistance);
    });

    // 슬라이드 진행률 계산 및 애니메이션 업데이트
    final progress = _dragPosition / maxDragDistance;
    _slideController.value = progress;
  }

  /**
   * 드래그 종료 처리
   * - 80% 이상 드래그했으면 액션 실행
   * - 미달 시 원래 위치로 복귀
   * - 스케일 애니메이션 복원
   */
  void _onPanEnd(DragEndDetails details, double maxWidth) {
    if (widget.isLoading) return;

    final sliderWidth = 56.0;
    final maxDragDistance = maxWidth - sliderWidth - 8;
    final threshold = maxDragDistance * 0.8; // 80% 지점에서 완료

    _scaleController.reverse(); // 버튼 스케일 복원

    if (_dragPosition >= threshold) {
      // 슬라이드 완료: 액션 실행 후 리셋
      _slideController.forward().then((_) {
        widget.onSlideComplete(); // 수집 상태 토글 함수 호출
        _resetSlider();
      });
    } else {
      // 슬라이드 미완료: 원래 위치로 복귀
      _resetSlider();
    }
  }

  /**
   * 슬라이더 위치 리셋
   * - 드래그 위치를 0으로 초기화
   * - 슬라이드 애니메이션 리셋
   */
  void _resetSlider() {
    setState(() {
      _dragPosition = 0.0; // 시작 위치로 복귀
    });
    _slideController.reset(); // 애니메이션 리셋
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: widget.isCompleted
                      ? widget.completedBackgroundColor
                      : widget.backgroundColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 배경 텍스트
                    Center(
                      child: AnimatedOpacity(
                        opacity: widget.isCompleted
                            ? 1.0
                            : (_slideAnimation.value < 0.5 ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          widget.isCompleted
                              ? widget.completedText
                              : widget.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 슬라이더 버튼
                    if (!widget.isCompleted)
                      Positioned(
                        left: 4 + _dragPosition,
                        top: 4,
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: (details) =>
                              _onPanUpdate(details, maxWidth),
                          onPanEnd: (details) => _onPanEnd(details, maxWidth),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: widget.sliderColor,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: widget.isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Color(0xFF6200EE),
                                        ),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    widget.icon,
                                    color: widget.backgroundColor,
                                    size: 28,
                                  ),
                          ),
                        ),
                      ),

                    // 완료 상태 아이콘
                    if (widget.isCompleted)
                      Center(
                        child: Icon(
                          widget.completedIcon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
