import 'package:flutter/material.dart';

class AnimatedLinearProgress extends StatefulWidget {
  final double value;
  final Color? backgroundColor;
  final Color? valueColor;
  final double? minHeight;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool animate;

  const AnimatedLinearProgress({
    super.key,
    required this.value,
    this.backgroundColor,
    this.valueColor,
    this.minHeight,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationCurve = Curves.easeOutCubic,
    this.animate = true,
  });

  @override
  State<AnimatedLinearProgress> createState() => _AnimatedLinearProgressState();
}

class _AnimatedLinearProgressState extends State<AnimatedLinearProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    if (widget.animate) {
      // Delay the animation slightly to create a staggered effect
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedLinearProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));

      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: _progressAnimation.value,
          backgroundColor: widget.backgroundColor,
          valueColor: widget.valueColor != null 
              ? AlwaysStoppedAnimation<Color>(widget.valueColor!)
              : null,
          minHeight: widget.minHeight,
        );
      },
    );
  }
}