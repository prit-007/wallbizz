import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme_config.dart';

class CategoryTabs extends StatefulWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  final List<Map<String, String>> _categories = [
    {'label': 'Trending', 'value': 'trending', 'icon': '🔥'},
    {'label': 'Anime', 'value': 'anime', 'icon': '🌸'},
    {'label': 'AMOLED', 'value': 'amoled', 'icon': '⬛'},
    {'label': 'Desktop', 'value': 'desktop', 'icon': '🖥'},
    {'label': 'Mobile', 'value': 'mobile', 'icon': '📱'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = widget.selectedCategory == cat['value'];

          return GestureDetector(
            onTap: () => widget.onCategorySelected(cat['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : vk.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: cs.primary, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cat['icon']!,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat['label']!,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                      letterSpacing: 1.2,
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
