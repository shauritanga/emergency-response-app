import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class LocationAccuracyWidget extends StatefulWidget {
  final String status;
  final double? accuracy;
  final bool isLoading;
  final VoidCallback? onRetry;

  const LocationAccuracyWidget({
    super.key,
    required this.status,
    this.accuracy,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  State<LocationAccuracyWidget> createState() => _LocationAccuracyWidgetState();
}

class _LocationAccuracyWidgetState extends State<LocationAccuracyWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.isLoading) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(LocationAccuracyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading && !oldWidget.isLoading) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _pulseController.stop();
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(isDarkMode),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: widget.isLoading ? _pulseAnimation : 
                          const AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: AnimatedBuilder(
                      animation: widget.isLoading ? _rotationAnimation :
                                const AlwaysStoppedAnimation(0.0),
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getIconBackgroundColor(isDarkMode),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              HugeIcons.strokeRoundedGps01,
                              color: _getIconColor(isDarkMode),
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Accuracy',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.status,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.accuracy != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAccuracyBackgroundColor(widget.accuracy!, isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '±${widget.accuracy!.toStringAsFixed(1)}m',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getAccuracyTextColor(widget.accuracy!, isDarkMode),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (widget.isLoading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(isDarkMode),
              ),
            ),
          ],
          if (!widget.isLoading && widget.onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(HugeIcons.strokeRoundedRefresh, size: 16),
                label: Text(
                  'Retry Location',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _getProgressColor(isDarkMode),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBorderColor(bool isDarkMode) {
    if (widget.accuracy != null) {
      if (widget.accuracy! <= 5) return Colors.green;
      if (widget.accuracy! <= 10) return Colors.orange;
      return Colors.red;
    }
    return isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
  }

  Color _getIconBackgroundColor(bool isDarkMode) {
    if (widget.accuracy != null) {
      if (widget.accuracy! <= 5) return Colors.green.withValues(alpha: 0.2);
      if (widget.accuracy! <= 10) return Colors.orange.withValues(alpha: 0.2);
      return Colors.red.withValues(alpha: 0.2);
    }
    return isDarkMode ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1);
  }

  Color _getIconColor(bool isDarkMode) {
    if (widget.accuracy != null) {
      if (widget.accuracy! <= 5) return Colors.green;
      if (widget.accuracy! <= 10) return Colors.orange;
      return Colors.red;
    }
    return Colors.blue;
  }

  Color _getAccuracyBackgroundColor(double accuracy, bool isDarkMode) {
    if (accuracy <= 5) return Colors.green.withValues(alpha: isDarkMode ? 0.3 : 0.2);
    if (accuracy <= 10) return Colors.orange.withValues(alpha: isDarkMode ? 0.3 : 0.2);
    return Colors.red.withValues(alpha: isDarkMode ? 0.3 : 0.2);
  }

  Color _getAccuracyTextColor(double accuracy, bool isDarkMode) {
    if (accuracy <= 5) return isDarkMode ? Colors.green[300]! : Colors.green[700]!;
    if (accuracy <= 10) return isDarkMode ? Colors.orange[300]! : Colors.orange[700]!;
    return isDarkMode ? Colors.red[300]! : Colors.red[700]!;
  }

  Color _getProgressColor(bool isDarkMode) {
    return Colors.blue;
  }
}
