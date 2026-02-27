import 'dart:io';
import 'dart:ui';
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
  String _selectedCategory = 'All';

  String _timeLeft = '';
  late final Stream<String> _timerStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (_) => _calculateTimeLeft()).asBroadcastStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DailyWord> get filteredWords {
    if (_selectedCategory == 'All') {
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
      return 'Missed this word?';
    } else {
      return 'Unlock Tomorrow\'s Word';
    }
  }

  String _getLockSubtitle() {
    if (_isAdFree) {
      return 'Your ad-free subscription is active!';
    }
    if (_displayedDays < _todayDays) {
      return 'Watch a quick ad to catch up';
    } else {
      return 'Watch an ad to see what\'s next!';
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
          const SnackBar(content: Text('Ad not ready yet, try again in a moment.')),
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
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For your $plan plan ($price)',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              _paymentOptionTile(plan, 'Telebirr', Icons.phone_android, Colors.blue),
              _paymentOptionTile(plan, 'CBE Birr', Icons.account_balance, Colors.orange),
              _paymentOptionTile(plan, 'E-Birr', Icons.wallet, Colors.green),
              _paymentOptionTile(plan, 'Bank Transfer', Icons.account_balance_wallet, Colors.purple),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentOptionTile(String plan, String name, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
        case 'WEEKLY':
          duration = const Duration(days: 7);
          break;
        case 'MONTHLY':
          duration = const Duration(days: 30);
          break;
        case 'YEARLY':
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
          content: Text('Payment Successful! You are now Ad-Free! 🎉'),
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
🇪🇹 Amharic Word of the Day 🇪🇹

Word: ${word!.word} [${word!.pronunciation}]
Translation: ${word!.translation}
Example: ${word!.example}

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
    
    Share.share('Check out this Amharic Word of the Day app! 🇪🇹\n\nDownload here: $appUrl');
  }

  String _getBadgeText() {
    if (_displayedDays == _todayDays) {
      return '🔥 $streak DAY STREAK';
    }
    if (_displayedDays > _todayDays) {
      return '✨ UPCOMING WORD';
    }
    if (!_unlockedDays.contains(_displayedDays)) {
      return '📅 MISSED DAY';
    }
    return 'PAST WORD';
  }

  String _getFormattedDate() {
    if (_firstLaunchTime == null) return '';
    final date = _firstLaunchTime!.add(Duration(days: _displayedDays));
    return DateFormat('EEEE, MMM d').format(date);
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
          tooltip: 'Favorites',
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesPage()),
            );
            _loadFavorites();
          },
        ),
        title: Text(
          _selectedCategory == 'All' ? 'Word of the Day' : _selectedCategory,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share App',
            icon: const Icon(Icons.share),
            onPressed: _shareApp,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: WORD
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              children: [
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildWordCard(),
                const SizedBox(height: 48),
                if (_displayedDays != _todayDays)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _displayedDays = _todayDays;
                        word = filteredWords.isEmpty ? null : filteredWords[(_displayedDays % filteredWords.length + filteredWords.length) % filteredWords.length];
                        _updateUnlockedStatus();
                      });
                    },
                    icon: const Icon(Icons.today),
                    label: const Text('BACK TO TODAY'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                  ),
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
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 25,
                offset: const Offset(0, 12),
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
            indicator: UnderlineTabIndicator(
              borderSide: const BorderSide(color: Colors.blueAccent, width: 3),
              insets: const EdgeInsets.symmetric(horizontal: 8),
            ),
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey[500],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
            tabs: const [
              Tab(
                height: 52,
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'WORD', 
                icon: Icon(Icons.menu_book_rounded, size: 22)
              ),
              Tab(
                height: 52,
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'TYPE', 
                icon: Icon(Icons.grid_view_rounded, size: 22)
              ),
              Tab(
                height: 52,
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'TIMER', 
                icon: Icon(Icons.timer_outlined, size: 22)
              ),
              Tab(
                height: 52,
                iconMargin: EdgeInsets.only(bottom: 4),
                text: 'UPGRADE', 
                icon: Icon(Icons.stars_rounded, size: 22)
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard() {
    if (word == null) {
      return const Center(
        child: Text(
          'No words found in this category.',
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      );
    }
    return SizedBox(
      width: 340,
      height: 460, // Increased height
      child: Card(
        elevation: 8,
        shadowColor: Colors.blue.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _goToPrevious,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: Colors.grey,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getBadgeText().contains('MISSED') 
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getBadgeText(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _getBadgeText().contains('MISSED') 
                                ? Colors.orangeAccent
                                : Colors.blueAccent,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _goToNext,
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: _isUnlocked ? 1.0 : 0.3,
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            word!.word,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '[ ${word!.pronunciation} ]',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 40,
                          height: 2,
                          color: Colors.blueAccent.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            word!.translation,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '"${word!.example}"',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[300],
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Spacer(), // Pushes icons to the bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Favorite',
                        iconSize: 28,
                        icon: Icon(
                          _isFavorite() ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite() ? Colors.red : Colors.grey[600],
                        ),
                        onPressed: _toggleFavorite,
                      ),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 24, color: Colors.white10),
                      const SizedBox(width: 4),
                      _socialIconButton('instagram', FontAwesomeIcons.instagram, Colors.purpleAccent),
                      _socialIconButton('facebook', FontAwesomeIcons.facebook, Colors.blueAccent),
                      _socialIconButton('telegram', FontAwesomeIcons.telegram, Colors.blue),
                      _socialIconButton('twitter', FontAwesomeIcons.twitter, Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            if (!_isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 64, color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      Text(
                        _getLockTitle(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLockSubtitle(),
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _isAdFree ? _unlockCurrentDay : _showAdToUnlock,
                        icon: Icon(_isAdFree ? Icons.lock_open : Icons.play_circle_fill, size: 28),
                        label: Text(_isAdFree ? 'UNLOCK NOW' : 'WATCH AD TO UNLOCK'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerTab() {
    return Center(
      child: SingleChildScrollView(
        child: StreamBuilder<String>(
          stream: _timerStream,
          builder: (context, snapshot) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.hourglass_empty_rounded, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 32),
                Text(
                  'NEXT WORD IN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[600],
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    snapshot.data ?? '--:--:--',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
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
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.withOpacity(0.15), Colors.purpleAccent.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.blueAccent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 64),
              const SizedBox(height: 24),
              Text(
                _isAdFree ? 'PREMIUM ACTIVE' : 'REMOVE ALL ADS',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Support the app and unlock everything instantly!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 40),
              if (_isAdFree)
                Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Thank you for your support! 💎',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We will notify you when your subscription ends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _dealItem('WEEKLY', '100 ETB'),
                    const SizedBox(height: 16),
                    _dealItem('MONTHLY', '400 ETB'),
                    const SizedBox(height: 16),
                    _dealItem('YEARLY', '800 ETB'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dealItem(String title, String price) {
    return InkWell(
      onTap: () => _showPaymentSelection(title, price),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
        tooltip: 'Share on ${platform[0].toUpperCase()}${platform.substring(1)}',
      ),
    );
  }
}
