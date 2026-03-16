import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visionaid/core/constants/app_constants.dart';
import 'package:visionaid/core/providers/app_state_provider.dart';
import 'package:visionaid/core/theme/app_theme.dart';
import 'package:visionaid/features/tts/tts_service.dart';

/// Mode Selector Bottom Sheet (F-05)
/// Accessible mode selection with large, high-contrast cards
class ModeSelector extends ConsumerStatefulWidget {
  const ModeSelector({super.key});

  @override
  ConsumerState<ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends ConsumerState<ModeSelector> {
  @override
  void initState() {
    super.initState();
    // Announce mode selector opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(
        'Mode selector. Swipe to browse modes. Double tap to select.',
        priority: AlertPriority.warning,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(currentModeProvider);
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.accessibilityTeal.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Semantics(
              header: true,
              child: Text(
                'Select Mode',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mode cards
          ...AppMode.values.map((mode) => _ModeCard(
            mode: mode,
            isSelected: mode == currentMode,
            onSelect: () => _selectMode(mode),
          )),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  void _selectMode(AppMode mode) {
    HapticFeedback.mediumImpact();
    
    ref.read(currentModeProvider.notifier).setMode(mode);
    ref.read(ttsServiceProvider).announceMode(mode);
    
    Navigator.of(context).pop();
  }
}

class _ModeCard extends StatelessWidget {
  final AppMode mode;
  final bool isSelected;
  final VoidCallback onSelect;
  
  const _ModeCard({
    required this.mode,
    required this.isSelected,
    required this.onSelect,
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
      button: true,
      selected: isSelected,
      label: '${mode.displayName}. ${mode.description}. ${isSelected ? "Currently selected." : "Double tap to select."}',
      child: GestureDetector(
        onTap: onSelect,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.accessibilityTeal.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? AppColors.accessibilityTeal 
                  : AppColors.accessibilityTeal.withOpacity(0.3),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.accessibilityTeal 
                      : AppColors.deepNavy,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accessibilityTeal,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _modeIcon,
                  size: 28,
                  color: isSelected ? Colors.white : AppColors.accessibilityTeal,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.accessibilityTeal,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
