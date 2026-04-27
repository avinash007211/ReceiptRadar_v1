import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

class CategoryPicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;

  const CategoryPicker({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.taxCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final cat = AppConstants.taxCategories[i];
          final isSelected = cat.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 110,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? cat.color.withValues(alpha: 0.12)
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? cat.color : AppColors.border,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 8),
                  Text(
                    cat.nameDe,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? cat.color : AppColors.textPrimary,
                      letterSpacing: 0,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
