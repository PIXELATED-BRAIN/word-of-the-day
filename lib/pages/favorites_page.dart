import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/daily_word.dart';
import '../data/words_data.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String> _favoriteWordStrings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteWordStrings = prefs.getStringList('favorite_words') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String word) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteWordStrings.remove(word);
    });
    await prefs.setStringList('favorite_words', _favoriteWordStrings);
  }

  @override
  Widget build(BuildContext context) {
    final favoriteWords = localWords
        .where((w) => _favoriteWordStrings.contains(w.word))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ተወዳጆች',
          style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteWords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      Text(
                        'እስካሁን ምንም ተወዳጅ የለም',
                        style: GoogleFonts.notoSansEthiopic(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: favoriteWords.length,
                  itemBuilder: (context, index) {
                    final word = favoriteWords[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.share_rounded, size: 20, color: Colors.blueAccent),
                              onPressed: () {
                                Share.share(
                                  '🇪🇹 የአማርኛ የቀኑ ቃል 🇪🇹\n\n'
                                  'ቃል: ${word.word} [${word.pronunciation}]\n'
                                  'ትርጉም: ${word.translation}\n'
                                  'ምሳሌ: ${word.example}\n\n'
                                  '#Amharic #LanguageLearning #Ethiopia'
                                );
                              },
                            ),
                          ),
                          title: Text(
                            word.word,
                            style: GoogleFonts.notoSansEthiopic(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.translation,
                                  style: GoogleFonts.notoSansEthiopic(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueAccent.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  word.pronunciation,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.favorite_rounded, size: 20, color: Colors.redAccent),
                              onPressed: () => _removeFavorite(word.word),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
