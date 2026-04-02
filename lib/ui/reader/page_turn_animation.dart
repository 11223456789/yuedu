import 'package:flutter/material.dart';
import 'reader_theme.dart';

/// 翻页模式枚举
enum PageTurnMode {
  cover,      // 覆盖
  simulation, // 仿真
  slide,      // 滑动
  scroll,     // 滚动
  none,       // 无动画
}

extension PageTurnModeExtension on PageTurnMode {
  String get displayName {
    switch (this) {
      case PageTurnMode.cover:
        return '覆盖';
      case PageTurnMode.simulation:
        return '仿真';
      case PageTurnMode.slide:
        return '滑动';
      case PageTurnMode.scroll:
        return '滚动';
      case PageTurnMode.none:
        return '无动画';
    }
  }

  int get value {
    switch (this) {
      case PageTurnMode.cover:
        return 0;
      case PageTurnMode.simulation:
        return 1;
      case PageTurnMode.slide:
        return 2;
      case PageTurnMode.scroll:
        return 3;
      case PageTurnMode.none:
        return 4;
    }
  }

  static PageTurnMode fromValue(int value) {
    switch (value) {
      case 0:
        return PageTurnMode.cover;
      case 1:
        return PageTurnMode.simulation;
      case 2:
        return PageTurnMode.slide;
      case 3:
        return PageTurnMode.scroll;
      case 4:
        return PageTurnMode.none;
      default:
        return PageTurnMode.cover;
    }
  }
}

/// 翻页动画包装器
class PageTurnAnimation extends StatelessWidget {
  final Widget child;
  final PageTurnMode mode;
  final Animation<double> animation;
  final bool isForward;
  final ReaderTheme readerTheme;

  const PageTurnAnimation({
    super.key,
    required this.child,
    required this.mode,
    required this.animation,
    required this.isForward,
    required this.readerTheme,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case PageTurnMode.cover:
        return _buildCoverAnimation();
      case PageTurnMode.simulation:
        return _buildSimulationAnimation();
      case PageTurnMode.slide:
        return _buildSlideAnimation();
      case PageTurnMode.scroll:
        return _buildScrollAnimation();
      case PageTurnMode.none:
        return child;
    }
  }

  /// 覆盖动画
  Widget _buildCoverAnimation() {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = isForward ? animation.value : 1 - animation.value;
        return ClipRect(
          child: Align(
            alignment: isForward ? Alignment.centerLeft : Alignment.centerRight,
            widthFactor: value,
            child: this.child,
          ),
        );
      },
    );
  }

  /// 仿真翻页动画
  Widget _buildSimulationAnimation() {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = isForward ? animation.value : 1 - animation.value;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(isForward ? -value * 0.5 : (1 - value) * 0.5),
          alignment: isForward ? Alignment.centerLeft : Alignment.centerRight,
          child: this.child,
        );
      },
    );
  }

  /// 滑动动画
  Widget _buildSlideAnimation() {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = isForward ? animation.value : 1 - animation.value;
        return Transform.translate(
          offset: Offset(
            isForward ? (1 - value) * 100 : -(1 - value) * 100,
            0,
          ),
          child: Opacity(
            opacity: value,
            child: this.child,
          ),
        );
      },
    );
  }

  /// 滚动动画
  Widget _buildScrollAnimation() {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = isForward ? animation.value : 1 - animation.value;
        return Transform.translate(
          offset: Offset(0, (1 - value) * 50),
          child: Opacity(
            opacity: value,
            child: this.child,
          ),
        );
      },
    );
  }
}

/// 翻页手势检测器
class PageTurnGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTapCenter;
  final VoidCallback? onTapLeft;
  final VoidCallback? onTapRight;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const PageTurnGestureDetector({
    super.key,
    required this.child,
    this.onTapCenter,
    this.onTapLeft,
    this.onTapRight,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final width = MediaQuery.of(context).size.width;
        final x = details.localPosition.dx;
        
        if (x < width * 0.3) {
          onTapLeft?.call();
        } else if (x > width * 0.7) {
          onTapRight?.call();
        } else {
          onTapCenter?.call();
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        
        if (details.primaryVelocity! > 100) {
          onSwipeRight?.call();
        } else if (details.primaryVelocity! < -100) {
          onSwipeLeft?.call();
        }
      },
      child: child,
    );
  }
}

/// 翻页动画控制器
class PageTurnController extends ChangeNotifier {
  AnimationController? _animationController;
  PageTurnMode _mode = PageTurnMode.cover;
  bool _isAnimating = false;

  PageTurnMode get mode => _mode;
  bool get isAnimating => _isAnimating;
  Animation<double>? get animation => _animationController?.view;

  void attach(TickerProvider vsync) {
    _animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
    _animationController?.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _isAnimating = false;
        notifyListeners();
      }
    });
  }

  void detach() {
    _animationController?.dispose();
    _animationController = null;
  }

  void setMode(PageTurnMode mode) {
    _mode = mode;
    notifyListeners();
  }

  Future<void> animateForward() async {
    if (_animationController == null || _mode == PageTurnMode.none) return;
    _isAnimating = true;
    notifyListeners();
    await _animationController?.forward(from: 0);
  }

  Future<void> animateBackward() async {
    if (_animationController == null || _mode == PageTurnMode.none) return;
    _isAnimating = true;
    notifyListeners();
    await _animationController?.reverse(from: 1);
  }
}
