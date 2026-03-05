import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/daily_word.dart';
import '../services/ads_service.dart';
import '../services/streak_service.dart';
import '../services/notification_service.dart';
import '../data/words_data.dart';
import 'favorites_page.dart';
import 'word_type_page.dart';

class WordOfTheDayPage extends StatefulWidget {
  const WordOfTheDayPage({super.key});

  @override
  State<WordOfTheDayPage> createState() => _WordOfTheDayPageState();
}

class _WordOfTheDayPageState extends State<WordOfTheDayPage> with SingleTickerProviderStateMixin {
  final _streakService = StreakService();
  final _adsService = AdsService();
  final _notificationService = NotificationService();
  late TabController _tabController;

  int _todayDays = 0;
  int _displayedDays = 0;
  List<String> _favoriteWords = [];
  List<int> _unlockedDays = [];
  DateTime? _lastSeenDate;
  DailyWord? word;
  int streak = 0;
  bool loading = true;
  bool _isUnlocked = false;
  bool _isAdFree = false;
  DateTime? _firstLaunchTime;
  String _selectedCategory = 'ሁሉም';

  late ValueNotifier<String> _timeLeftNotifier;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _timeLeftNotifier = ValueNotifier<String>('--:--:--');
    _load();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeLeftNotifier.value = _calculateTimeLeft();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _timeLeftNotifier.dispose();
    super.dispose();
  }

  List<DailyWord> get filteredWords {
    if (_selectedCategory == 'ሁሉም') {
      return localWords;
    }
    return localWords.where((w) => w.category == _selectedCategory).toList();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _displayedDays = _todayDays; // Reset to the latest word in that category
      word = filteredWords.isEmpty ? null : filteredWords[(_displayedDays % filteredWords.length + filteredWords.length) % filteredWords.length];
      _updateUnlockedStatus();
    });
    _tabController.animateTo(0); // Switch to the WORD tab
  }

  String _calculateTimeLeft() {
    if (_firstLaunchTime == null) return '24:00:00';
    
    final now = DateTime.now();
    final diffSinceLaunch = now.difference(_firstLaunchTime!);
    final msSinceLaunch = diffSinceLaunch.inMilliseconds;
    final msIn24h = 24 * 60 * 60 * 1000;
    
    final msUntilNextWord = msIn24h - (msSinceLaunch % msIn24h);
    final diff = Duration(milliseconds: msUntilNextWord);
    
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    
    return '$hours:$minutes:$seconds';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Set first launch time if not exists
    final firstLaunchMs = prefs.getInt('first_launch_time');
    if (firstLaunchMs == null) {
      _firstLaunchTime = DateTime.now();
      await prefs.setInt('first_launch_time', _firstLaunchTime!.millisecondsSinceEpoch);
    } else {
      _firstLaunchTime = DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
    }

    final now = DateTime.now();
    final diffSinceLaunch = now.difference(_firstLaunchTime!);
    _todayDays = diffSinceLaunch.inDays; // Increments every 24 hours from first launch
    _displayedDays = _todayDays;
    
    final streakData = await _streakService.updateStreak();
    streak = streakData['streak'];
    _lastSeenDate = streakData['lastSeen'];
    
    await _loadFavorites();
    await _loadUnlockedDays();
    
    if (!_unlockedDays.contains(_todayDays)) {
      await _persistUnlock(_todayDays);
    }
    
    if (Platform.isAndroid || Platform.isIOS) {
      await _adsService.loadRewarded();
      await _notificationService.init();
    }

    setState(() {
      word = filteredWords.isEmpty ? null : filteredWords[(_displayedDays % filteredWords.length + filteredWords.length) % filteredWords.length];
      loading = false;
      _updateUnlockedStatus();
    });
  }

  void _updateUnlockedStatus() {
    _isUnlocked = _isAdFree || _unlockedDays.contains(_displayedDays) || (_displayedDays == _todayDays);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteWords = prefs.getStringList('favorite_words') ?? [];
    _isAdFree = prefs.getBool('is_ad_free') ?? false;
  }

  Future<void> _loadUnlockedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('unlocked_days') ?? [];
    _unlockedDays = list.map(int.parse).toList();
  }

  Future<void> _persistUnlock(int day) async {
    if (!_unlockedDays.contains(day)) {
      _unlockedDays.add(day);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('unlocked_days', _unlockedDays.map((e) => e.toString()).toList());
    }
  }

  Future<void> _unlockCurrentDay() async {
    await _persistUnlock(_displayedDays);
    setState(() {
      _isUnlocked = true;
    });
  }

  void _goToPrevious() {
    setState(() {
      _displayedDays--;
      word = filteredWords.isEmpty ? null : filteredWords[(_displayedDays % filteredWords.length + filteredWords.length) % filteredWords.length];
      _updateUnlockedStatus();
    });
  }

  void _goToNext() {
    setState(() {
      _displayedDays++;
      word = filteredWords.isEmpty ? null : filteredWords[(_displayedDays % filteredWords.length + filteredWords.length) % filteredWords.length];
      _updateUnlockedStatus();
    });
  }

  String _getLockTitle() {
    if (_displayedDays < _todayDays) {
      return 'ይህ ቃል አምልጦዎታል?';
    } else {
      return 'የነገውን ቃል ይክፈቱ';
    }
  }

  String _getLockSubtitle() {
    if (_isAdFree) {
      return 'ፕሪሚየም አገልግሎትዎ ገቢር ነው!';
    }
    if (_displayedDays < _todayDays) {
      return 'ለመከታተል አጭር ማስታወቂያ ይመልከቱ';
    } else {
      return 'የሚቀጥለውን ለማየት ማስታወቂያ ይመልከቱ!';
    }
  }

  void _showAdToUnlock() {
    if (Platform.isAndroid || Platform.isIOS) {
      if (_adsService.rewardedAd != null) {
        _adsService.rewardedAd!.show(onUserEarnedReward: (ad, reward) {
          _unlockCurrentDay();
          _adsService.loadRewarded();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ማስታወቂያው ገና አልተዘጋጀም፣ እባክዎ ጥቂት ቆይተው እንደገና ይሞክሩ።')),
        );
        _adsService.loadRewarded();
      }
    } else {
      _unlockCurrentDay();
    }
  }

  void _showPaymentSelection(String plan, String price) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'የክፍያ ዘዴ ይምረጡ',
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ለ$plan ዕቅድዎ ($price)',
                style: GoogleFonts.notoSansEthiopic(color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              _paymentOptionTile(plan, 'ቴሌ ብር', Icons.phone_android_rounded, Colors.blue),
              _paymentOptionTile(plan, 'ሲቢኢ ብር', Icons.account_balance_rounded, Colors.orange),
              _paymentOptionTile(plan, 'ኢ-ብር', Icons.wallet_rounded, Colors.green),
              _paymentOptionTile(plan, 'የባንክ ዝውውር', Icons.account_balance_wallet_rounded, Colors.purple),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentOptionTile(String plan, String name, IconData icon, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(name, style: GoogleFonts.notoSansEthiopic(color: Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: () {
        Navigator.pop(context);
        _completePayment(plan);
      },
    );
  }

  Future<void> _completePayment(String plan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_ad_free', true);

    setState(() {
      _isAdFree = true;
      _updateUnlockedStatus();
    });

    // Schedule notification based on plan
    if (Platform.isAndroid || Platform.isIOS) {
      Duration duration;
      switch (plan) {
        case 'ሳምንታዊ':
          duration = const Duration(days: 7);
          break;
        case 'ወርሃዊ':
          duration = const Duration(days: 30);
          break;
        case 'ዓመታዊ':
          duration = const Duration(days: 365);
          break;
        default:
          duration = const Duration(days: 30);
      }
      await _notificationService.scheduleSubscriptionEndNotification(duration);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ክፍያው ተሳክቷል! አሁን ከማስታወቂያ ነፃ ነዎት! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    if (word == null) return;
    final currentWord = word!.word;

    setState(() {
      if (_favoriteWords.contains(currentWord)) {
        _favoriteWords.remove(currentWord);
      } else {
        _favoriteWords.add(currentWord);
      }
    });

    await prefs.setStringList('favorite_words', _favoriteWords);
  }

  bool _isFavorite() {
    if (word == null) return false;
    return _favoriteWords.contains(word!.word);
  }

  String _getShareText() {
    return '''
🇪🇹 የአማርኛ የቀኑ ቃል 🇪🇹

ቃል: ${word!.word} [${word!.pronunciation}]
ትርጉም: ${word!.translation}
ምሳሌ: ${word!.example}

#Amharic #LanguageLearning #Ethiopia
''';
  }

  void _shareVia(String platform) async {
    if (!_isUnlocked) return;
    
    final text = Uri.encodeComponent(_getShareText());
    String url = '';

    switch (platform) {
      case 'instagram':
        Share.share(_getShareText());
        return;
      case 'telegram':
        url = 'https://t.me/share/url?url=$text';
        break;
      case 'twitter':
        url = 'https://twitter.com/intent/tweet?text=$text';
        break;
      case 'facebook':
        url = 'https://www.facebook.com/sharer/sharer.php?u=https://example.com&quote=$text';
        break;
      default:
        Share.share(_getShareText());
        return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Share.share(_getShareText());
    }
  }

  void _shareApp() {
    final String appUrl = Platform.isAndroid 
      ? 'https://play.google.com/store/apps/details?id=com.example.amharicword'
      : 'https://apps.apple.com/app/id123456789';
    
    Share.share('ይህንን የአማርኛ የቀኑ ቃል መተግበሪያ ይመልከቱ! 🇪🇹\n\nከዚህ ያውርዱ: $appUrl');
  }

  String _getBadgeText() {
    if (_displayedDays == _todayDays) {
      return '🔥 የ$streak ቀናት ተከታታይነት';
    }
    if (_displayedDays > _todayDays) {
      return '✨ የሚመጣ ቃል';
    }
    if (!_unlockedDays.contains(_displayedDays)) {
      return '📅 ያለፈ ቀን';
    }
    return 'ያለፈ ቃል';
  }

  String _getFormattedDate() {
    if (_firstLaunchTime == null) return '';
    final date = _firstLaunchTime!.add(Duration(days: _displayedDays));
    return DateFormat('EEEE, MMM d', 'am').format(date); // Note: Requires initialization
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'ተወዳጆች',
          padding: const EdgeInsets.only(left: 12),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesPage()),
            );
            _loadFavorites();
          },
        ),
        title: Text(
          _selectedCategory == 'ሁሉም' ? 'የቀኑ ቃል' : _selectedCategory,
          style: GoogleFonts.notoSansEthiopic(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'መተግበሪያውን ያጋሩ',
            padding: const EdgeInsets.only(right: 12),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.share_rounded, size: 20),
            ),
            onPressed: _shareApp,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: WORD
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Text(
                  _getFormattedDate().toUpperCase(),
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[600],
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_displayedDays),
                    child: _buildWordCard(),
                  ),
                ),
                if (_displayedDays != _todayDays) ...[
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _displayedDays = _todayDays;
                        word = filteredWords.isEmpty ? null : filteredWords[(_displayedDays % filteredWords.length + filteredWords.length) % filteredWords.length];
                        _updateUnlockedStatus();
                      });
                    },
                    icon: const Icon(Icons.today_rounded, size: 20),
                    label: Text(
                      'ወደ ዛሬው ተመለስ',
                      style: GoogleFonts.notoSansEthiopic(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.blueAccent.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // TAB 2: TYPE
          WordTypePage(onCategorySelected: _onCategorySelected),
          
          // TAB 3: TIMER
          _buildTimerTab(),
          
          // TAB 4: UPGRADE
          _buildStoreTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF141414).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.blueAccent, width: 3),
              insets: EdgeInsets.symmetric(horizontal: 8),
            ),
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.notoSansEthiopic(
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: GoogleFonts.notoSansEthiopic(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            tabs: const [
              Tab(
                height: 54,
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'ቃል', 
                icon: Icon(Icons.menu_book_rounded, size: 20)
              ),
              Tab(
                height: 54,
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'ዘርፍ', 
                icon: Icon(Icons.grid_view_rounded, size: 20)
              ),
              Tab(
                height: 54,
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'ሰዓት', 
                icon: Icon(Icons.timer_outlined, size: 20)
              ),
              Tab(
                height: 54,
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'አሻሽል', 
                icon: Icon(Icons.stars_rounded, size: 20)
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard() {
    if (word == null) {
      return Center(
        child: Text(
          'በዚህ ዘርፍ ምንም ቃላት አልተገኙም።',
          style: GoogleFonts.notoSansEthiopic(color: Colors.grey, fontSize: 18),
        ),
      );
    }
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340, maxHeight: 500),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[900]!.withOpacity(0.8),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Decorative background element
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blueAccent.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _navigationButton(Icons.arrow_back_ios_new, _goToPrevious),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getBadgeText().contains('ያለፈ') 
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getBadgeText().contains('ያለፈ') 
                                  ? Colors.orangeAccent.withOpacity(0.2)
                                  : Colors.blueAccent.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            _getBadgeText(),
                            style: GoogleFonts.notoSansEthiopic(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _getBadgeText().contains('ያለፈ') 
                                  ? Colors.orangeAccent
                                  : Colors.blueAccent,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      _navigationButton(Icons.arrow_forward_ios, _goToNext),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Opacity(
                        opacity: _isUnlocked ? 1.0 : 0.2,
                        child: Column(
                          children: [
                            Text(
                              word!.word,
                              style: GoogleFonts.notoSansEthiopic(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '[ ${word!.pronunciation} ]',
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 32,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              word!.translation,
                              style: GoogleFonts.notoSansEthiopic(
                                fontWeight: FontWeight.w600,
                                fontSize: 22,
                                color: Colors.white.withOpacity(0.95),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '"${word!.example}"',
                                style: GoogleFonts.notoSansEthiopic(
                                  fontSize: 15,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'ተወዳጅ',
                          iconSize: 24,
                          icon: Icon(
                            _isFavorite() ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite() ? Colors.redAccent : Colors.grey[600],
                          ),
                          onPressed: _toggleFavorite,
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 16, color: Colors.white10),
                        const SizedBox(width: 4),
                        _socialIconButton('instagram', FontAwesomeIcons.instagram, Colors.purpleAccent),
                        _socialIconButton('facebook', FontAwesomeIcons.facebook, Colors.blueAccent),
                        _socialIconButton('telegram', FontAwesomeIcons.telegram, Colors.lightBlue),
                        _socialIconButton('twitter', FontAwesomeIcons.xTwitter, Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_isUnlocked)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(Icons.lock_rounded, size: 48, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _getLockTitle(),
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getLockSubtitle(),
                          style: GoogleFonts.notoSansEthiopic(color: Colors.grey[400], fontSize: 15),
                        ),
                        const SizedBox(height: 36),
                        ElevatedButton.icon(
                          onPressed: _isAdFree ? _unlockCurrentDay : _showAdToUnlock,
                          icon: Icon(_isAdFree ? Icons.lock_open_rounded : Icons.play_circle_fill_rounded, size: 24),
                          label: Text(_isAdFree ? 'አሁኑኑ ይክፈቱ' : 'ለማየት ማስታወቂያ ይመልከቱ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: Colors.blueAccent.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _navigationButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        color: Colors.grey[400],
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildTimerTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ValueListenableBuilder<String>(
          valueListenable: _timeLeftNotifier,
          builder: (context, time, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.timer_outlined, size: 80, color: Colors.blueAccent),
                ),
                const SizedBox(height: 48),
                Text(
                  'የሚቀጥለው ቃል በ',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[500],
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      time,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'የቀኑ ቃል መተግበሪያውን ለመጀመሪያ ጊዜ ከከፈቱበት ሰዓት ጀምሮ በየ24 ሰዓቱ ይታደሳል።',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansEthiopic(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoreTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A1A),
                Colors.blueAccent.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.blueAccent.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                _isAdFree ? 'ፕሪሚየም ገቢር ሆኗል' : 'ማስታወቂያዎችን ያስወግዱ',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'መተግበሪያውን ይደግፉ እና ሁሉንም ባህሪያት፣ ያለፉ እና የሚመጡ ቃላትን ወዲያውኑ ያግኙ!',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(
                  color: Colors.grey[500],
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (_isAdFree)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ለድጋፍዎ እናመሰግናለን! 💎',
                      style: GoogleFonts.notoSansEthiopic(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ሁሉንም ነገር የመጠቀም መብት አሎት።',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansEthiopic(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _dealItem('ሳምንታዊ', '100 ብር', Colors.blueAccent),
                    const SizedBox(height: 12),
                    _dealItem('ወርሃዊ', '400 ብር', Colors.purpleAccent),
                    const SizedBox(height: 12),
                    _dealItem('ዓመታዊ', '800 ብር', Colors.amber),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dealItem(String title, String price, Color color) {
    return InkWell(
      onTap: () => _showPaymentSelection(title, price),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialIconButton(String platform, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: FaIcon(icon, color: _isUnlocked ? color : Colors.grey[800], size: 20),
        onPressed: _isUnlocked ? () => _shareVia(platform) : null,
        tooltip: 'በ${platform[0].toUpperCase()}${platform.substring(1)} ያጋሩ',
      ),
    );
  }
}
