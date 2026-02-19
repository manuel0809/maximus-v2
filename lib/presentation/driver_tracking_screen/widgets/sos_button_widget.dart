import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class SOSButtonWidget extends StatefulWidget {
  final VoidCallback onPressed;

  const SOSButtonWidget({super.key, required this.onPressed});

  @override
  State<SOSButtonWidget> createState() => _SOSButtonWidgetState();
}

class _SOSButtonWidgetState extends State<SOSButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePress() {
    HapticFeedback.heavyImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handlePress,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70 + (_pulseController.value * 15),
                height: 70 + (_pulseController.value * 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(
                    alpha: 0.3 * (1 - _pulseController.value),
                  ),
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 28),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
