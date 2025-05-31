import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyButton extends StatelessWidget {
  final String type;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  const EmergencyButton({
    super.key,
    required this.type,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 90,
        height: 120,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? _getTypeColor(type).withOpacity(0.2)
                        : isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _getTypeColor(type) : Colors.transparent,
                  width: 2,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: _getTypeColor(type).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : [],
              ),
              child: Icon(
                icon,
                size: 40,
                color: isSelected ? _getTypeColor(type) : Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? _getTypeColor(type) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Medical':
        return Colors.red;
      case 'Fire':
        return Colors.orange;
      case 'Police':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
