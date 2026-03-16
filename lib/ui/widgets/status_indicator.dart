import 'package:flutter/material.dart';
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:visionaid/core/theme/app_theme.dart';

/// Status indicator showing current mode and processing state
class StatusIndicator extends StatelessWidget {
  final AppMode mode;
  final bool isProcessing;
  
  const StatusIndicator({
    super.key,
    required this.mode,
    required this.isProcessing,
  });

  IconData get _modeIcon {
    switch (mode) {
      case AppMode.scene:
        return Icons.visibility;
      case AppMode.read:
        return Icons.menu_book;
      case AppMode.navigate:
        return Icons.directions_walk;
      case AppMode.explore:
        return Icons.explore;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${mode.displayName} mode. ${isProcessing ? "Processing." : "Ready."}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accessibilityTeal.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _modeIcon,
                  size: 20,
                  color: AppColors.accessibilityTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  mode.displayName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Processing indicator
          if (isProcessing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.deepNavy.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.warmAmber.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.warmAmber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Active',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.warmAmber,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Alert banner for critical notifications
class AlertBanner extends StatelessWidget {
  final String message;
  final AlertPriority priority;
  final VoidCallback? onDismiss;
  
  const AlertBanner({
    super.key,
    required this.message,
    required this.priority,
    this.onDismiss,
  });

  Color get _backgroundColor {
    switch (priority) {
      case AlertPriority.critical:
        return AppColors.danger;
      case AlertPriority.warning:
        return AppColors.warmAmber;
      case AlertPriority.info:
        return AppColors.accessibilityTeal;
    }
  }

  IconData get _icon {
    switch (priority) {
      case AlertPriority.critical:
        return Icons.warning;
      case AlertPriority.warning:
        return Icons.info;
      case AlertPriority.info:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '${priority.name} alert: $message',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Dismiss',
              ),
          ],
        ),
      ),
    );
  }
}
