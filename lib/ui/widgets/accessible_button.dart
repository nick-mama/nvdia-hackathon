import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:visionaid/core/theme/app_theme.dart';

/// Accessible Button following WCAG guidelines
/// - Minimum 44x44pt touch target
/// - High contrast colors
/// - Proper semantic labels
class AccessibleButton extends StatelessWidget {
  final String label;
  final String? semanticHint;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  
  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticHint,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: semanticHint,
      enabled: !isLoading,
      child: SizedBox(
        height: AppConstants.minTouchTargetSize,
        child: isPrimary
            ? ElevatedButton(
                onPressed: isLoading ? null : () {
                  HapticFeedback.selectionClick();
                  onPressed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accessibilityTeal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _buildContent(context),
              )
            : OutlinedButton(
                onPressed: isLoading ? null : () {
                  HapticFeedback.selectionClick();
                  onPressed();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accessibilityTeal,
                  side: const BorderSide(color: AppColors.accessibilityTeal),
                  minimumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _buildContent(context),
              ),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    
    return Text(label);
  }
}

/// Large circular action button for main screen actions
class CircularActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final double size;
  
  const CircularActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.accessibilityTeal,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (backgroundColor ?? AppColors.accessibilityTeal).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: size * 0.45,
            color: Colors.white,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}

/// Icon button with proper accessibility
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: size * 0.55,
            color: color ?? AppColors.accessibilityTeal,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}
