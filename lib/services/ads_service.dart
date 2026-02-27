import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  RewardedAd? rewardedAd;

  Future<void> loadRewarded() async {
    await RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => rewardedAd = ad,
        onAdFailedToLoad: (_) => rewardedAd = null,
      ),
    );
  }
}
