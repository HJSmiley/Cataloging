import 'package:flutter/material.dart';

class SlideToActButton extends StatefulWidget {
  final String text;
  final String completedText;
  final IconData icon;
  final IconData completedIcon;
  final Color backgroundColor;
  final Color completedBackgroundColor;
  final Color sliderColor;
  final VoidCallback onSlideComplete;
  final bool isCompleted;
  final bool isLoading;

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
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  double _dragPosition = 0.0;
  bool _isDragging = false;

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

  void _onPanStart(DragStartDetails details) {
    if (widget.isLoading) return;

    setState(() {
      _isDragging = true;
    });
    _scaleController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (widget.isLoading) return;

    final sliderWidth = 56.0; // 슬라이더 버튼 크기
    final maxDragDistance = maxWidth - sliderWidth - 8; // 패딩 고려

    setState(() {
      _dragPosition =
          (_dragPosition + details.delta.dx).clamp(0.0, maxDragDistance);
    });

    // 슬라이드 진행률에 따른 애니메이션
    final progress = _dragPosition / maxDragDistance;
    _slideController.value = progress;
  }

  void _onPanEnd(DragEndDetails details, double maxWidth) {
    if (widget.isLoading) return;

    final sliderWidth = 56.0;
    final maxDragDistance = maxWidth - sliderWidth - 8;
    final threshold = maxDragDistance * 0.8; // 80% 지점에서 완료

    setState(() {
      _isDragging = false;
    });
    _scaleController.reverse();

    if (_dragPosition >= threshold) {
      // 슬라이드 완료
      _slideController.forward().then((_) {
        widget.onSlideComplete();
        _resetSlider();
      });
    } else {
      // 슬라이드 미완료 - 원래 위치로 복귀
      _resetSlider();
    }
  }

  void _resetSlider() {
    setState(() {
      _dragPosition = 0.0;
    });
    _slideController.reset();
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
                      color: Colors.black.withOpacity(0.2),
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
                                  color: Colors.black.withOpacity(0.2),
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
