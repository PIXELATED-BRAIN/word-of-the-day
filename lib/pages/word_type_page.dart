import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WordTypePage extends StatelessWidget {
  final Function(String) onCategorySelected;
  const WordTypePage({super.key, required this.onCategorySelected});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'ሁሉም', 'icon': Icons.all_inclusive_rounded, 'color': Colors.blueGrey},
    {'name': 'መጽሐፍ ቅዱሳዊ', 'icon': Icons.menu_book_rounded, 'color': Colors.amber},
    {'name': 'አባባሎች', 'icon': Icons.format_quote_rounded, 'color': Colors.blue},
    {'name': 'ስሞች', 'icon': Icons.person_rounded, 'color': Colors.green},
    {'name': 'አጠራር', 'icon': Icons.record_voice_over_rounded, 'color': Colors.purple},
    {'name': 'ስድቦች', 'icon': Icons.gavel_rounded, 'color': Colors.red},
    {'name': 'ቁሳቁሶች', 'icon': Icons.category_rounded, 'color': Colors.orange},
    {'name': 'ዕፅዋት እና እንስሳት', 'icon': Icons.nature_rounded, 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ዘርፎች',
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'የተለያዩ የአማርኛ ቃላትን ለመቃኘት ዘርፍ ይምረጡ።',
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 15,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = categories[index];
                  final Color color = cat['color'] as Color;
                  return InkWell(
                    onTap: () => onCategorySelected(cat['name'] as String),
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.15),
                            color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: color.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              size: 32,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            cat['name'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
