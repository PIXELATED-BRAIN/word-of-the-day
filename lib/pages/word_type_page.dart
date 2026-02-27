import 'package:flutter/material.dart';

class WordTypePage extends StatelessWidget {
  final Function(String) onCategorySelected;
  const WordTypePage({super.key, required this.onCategorySelected});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'All', 'icon': Icons.all_inclusive, 'color': Colors.grey},
    {'name': 'Biblical', 'icon': Icons.menu_book, 'color': Colors.amber},
    {'name': 'Sayings', 'icon': Icons.format_quote, 'color': Colors.blue},
    {'name': 'Names', 'icon': Icons.person, 'color': Colors.green},
    {'name': 'Pronunciation', 'icon': Icons.record_voice_over, 'color': Colors.purple},
    {'name': 'Insults', 'icon': Icons.gavel, 'color': Colors.red},
    {'name': 'Objects', 'icon': Icons.category, 'color': Colors.orange},
    {'name': 'Plants & Animals', 'icon': Icons.nature, 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () => onCategorySelected(cat['name'] as String),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: (cat['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (cat['color'] as Color).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, size: 40, color: cat['color'] as Color),
                  const SizedBox(height: 12),
                  Text(
                    cat['name'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
