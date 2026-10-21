import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/category_model.dart';

class CategoryPills extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedSlug;
  final ValueChanged<String?> onSelect;

  const CategoryPills({
    super.key,
    required this.categories,
    this.selectedSlug,
    required this.onSelect,
  });

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'ghost':
        return Icons.sentiment_very_dissatisfied_rounded;
      case 'book-open':
        return Icons.auto_stories_rounded;
      case 'trees':
        return Icons.forest_rounded;
      case 'search':
        return Icons.search_rounded;
      case 'moon':
        return Icons.bedtime_rounded;
      default:
        return Icons.headphones_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedSlug == null;
            return ChoiceChip(
              label: const Text('ទាំងអស់ (All)'),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              side: const BorderSide(color: AppColors.glassBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (_) => onSelect(null),
            );
          }

          final category = categories[index - 1];
          final isSelected = selectedSlug == category.slug;

          return ChoiceChip(
            avatar: Icon(
              _getCategoryIcon(category.iconName),
              size: 16,
              color: isSelected ? Colors.white : AppColors.secondary,
            ),
            label: Text(category.name),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            side: const BorderSide(color: AppColors.glassBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (_) => onSelect(isSelected ? null : category.slug),
          );
        },
      ),
    );
  }
}
