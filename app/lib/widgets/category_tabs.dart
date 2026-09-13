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
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _categories = [
    {'label': 'Trending', 'value': 'trending', 'icon': '\u{1F525}'},
    {'label': 'Anime', 'value': 'anime', 'icon': '\u{1F338}'},
    {'label': 'Nature', 'value': 'nature', 'icon': '\u{1F331}'},
    {'label': 'Cyberpunk', 'value': 'cyberpunk', 'icon': '\u{1F916}'},
    {'label': 'Space', 'value': 'space', 'icon': '\u{1F680}'},
    {'label': 'Desktop', 'value': 'desktop', 'icon': '\u{1F5A5}'},
    {'label': 'Mobile', 'value': 'mobile', 'icon': '\u{1F4F1}'},
  ];

  @override
  void didUpdateWidget(CategoryTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      final idx = _categories.indexWhere(
        (c) => c['value'] == widget.selectedCategory,
      );
      if (idx >= 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          idx * 90.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return SizedBox(
      height: 54,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = widget.selectedCategory == cat['value'];

          return Semantics(
            label: '${cat['label']} category${isSelected ? ', selected' : ''}',
            button: true,
            selected: isSelected,
            child: GestureDetector(
              onTap: () => widget.onCategorySelected(cat['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : vk.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? cs.primary
                        : vk.glassBorder.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(cat['icon']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      cat['label']!.toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? cs.onPrimary : cs.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
