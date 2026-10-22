import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../shared/providers/auth_provider.dart';
import '../logging/app_logger.dart';

/// Provider for AdService
final adServiceProvider = Provider<AdService>((ref) {
  return AdService(ref);
});

class AdService {
  final Ref _ref;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;
  DateTime? _lastInterstitialShownTime;

  AdService(this._ref) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _loadInterstitialAd();
      _loadRewardedAd();
    }
  }

  // Google Official Test Ad Unit IDs (replace with your real IDs from AdMob console in production)
  static String get bannerAdUnitId {
    if (!kIsWeb && Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (!kIsWeb && Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (!kIsWeb && Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (!kIsWeb && Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (!kIsWeb && Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (!kIsWeb && Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  bool get isUserVip {
    final profile = _ref.read(authProvider).profile;
    return profile?.isVipActive ?? false;
  }

  /// Initialize Google Mobile Ads SDK (called from bootstrap)
  static Future<void> initialize() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await MobileAds.instance.initialize();
        AppLogger.info('Google Mobile Ads initialized successfully.');
      } catch (e) {
        AppLogger.warning('AdMob init failed: $e');
      }
    }
  }

  void _loadInterstitialAd() {
    try {
      if (isUserVip || _isInterstitialLoading) return;
      _isInterstitialLoading = true;

      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialLoading = false;
          },
          onAdFailedToLoad: (error) {
            _interstitialAd = null;
            _isInterstitialLoading = false;
            AppLogger.warning('Interstitial ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      _isInterstitialLoading = false;
      AppLogger.warning('Error initiating interstitial ad load: $e');
    }
  }

  /// Show Interstitial ad between episodes (with 8-min frequency cap to avoid annoying users)
  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (isUserVip) {
      onDismissed?.call();
      return;
    }

    final now = DateTime.now();
    if (_lastInterstitialShownTime != null &&
        now.difference(_lastInterstitialShownTime!).inMinutes < 8) {
      onDismissed?.call();
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _lastInterstitialShownTime = DateTime.now();
          _loadInterstitialAd();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
          onDismissed?.call();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      _loadInterstitialAd();
      onDismissed?.call();
    }
  }

  void _loadRewardedAd() {
    try {
      if (_isRewardedLoading) return;
      _isRewardedLoading = true;

      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedLoading = false;
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _isRewardedLoading = false;
            AppLogger.warning('Rewarded ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      _isRewardedLoading = false;
      AppLogger.warning('Error initiating rewarded ad load: $e');
    }
  }

  /// Show Rewarded video ad for unlocking exclusive episodes or bonus rewards
  void showRewardedAd({
    required void Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailed,
  }) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadRewardedAd();
          onAdFailed?.call();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward);
      });
      _rewardedAd = null;
    } else {
      _loadRewardedAd();
      onAdFailed?.call();
    }
  }
}

/// Reusable Banner Ad Widget that automatically hides if user is VIP
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

      final isVip = ref.read(authProvider).profile?.isVipActive ?? false;
      if (isVip) return; // VIP users see ZERO ads

      _bannerAd = BannerAd(
        adUnitId: AdService.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            AppLogger.warning('Banner ad failed to load: $error');
          },
        ),
      )..load();
    } catch (e) {
      AppLogger.warning('Banner ad load caught exception: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVip = ref.watch(authProvider).profile?.isVipActive ?? false;
    if (isVip || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    try {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF160D23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E1A47)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AdWidget(ad: _bannerAd!),
            Positioned(
              top: 2,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
