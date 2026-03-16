import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visionaid/core/providers/app_state_provider.dart';
import 'package:visionaid/core/theme/app_theme.dart';

/// Widget to display current spoken output
/// Provides visual feedback alongside audio for low vision users
class SpokenOutputDisplay extends ConsumerWidget {
  const SpokenOutputDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSpoken = ref.watch(lastSpokenTextProvider);
    final isProcessing = ref.watch(isProcessingProvider);
    
    if (lastSpoken.isEmpty && !isProcessing) {
      return const SizedBox.shrink();
    }
    
    return Semantics(
      liveRegion: true,
      label: isProcessing ? 'Processing' : lastSpoken,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.deepNavy.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accessibilityTeal.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isProcessing) ...[
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accessibilityTeal,
                      semanticsLabel: 'Processing',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accessibilityTeal,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                lastSpoken,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact status indicator showing processing state
class ProcessingIndicator extends ConsumerWidget {
  const ProcessingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(isProcessingProvider);
    
    if (!isProcessing) {
      return const SizedBox.shrink();
    }
    
    return Semantics(
      label: 'AI is processing',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.deepNavy.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accessibilityTeal,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Processing',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.accessibilityTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
