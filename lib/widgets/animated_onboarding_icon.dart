import 'package:flutter/material.dart';

class AnimatedOnboardingIcon extends StatefulWidget {
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const AnimatedOnboardingIcon({
    super.key,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.size = 120,
  });

  @override
  State<AnimatedOnboardingIcon> createState() => _AnimatedOnboardingIconState();
}

class _AnimatedOnboardingIconState extends State<AnimatedOnboardingIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotate animation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating background circle
          AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * 3.14159,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.primaryColor.withValues(alpha: 0.1),
                        widget.secondaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),

          // Pulsing inner circle
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Icon
          Icon(
            widget.icon,
            size: widget.size * 0.5,
            color: widget.primaryColor,
          ),
        ],
      ),
    );
  }
}
