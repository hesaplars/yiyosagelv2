import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'firebase_service.dart';

class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  // RevenueCat API Keys
  static const _googleApiKey = "goog_abc123xyzPlaceholder"; // Google Play API Key
  static const _iosApiKey = "appl_abc123xyzPlaceholder";     // App Store API Key (Future)

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return; // RevenueCat is not supported on Web
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final currentUser = FirebaseService.instance.currentUser;
      final appUserId = currentUser?.uid;

      late PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_iosApiKey);
      } else {
        return;
      }

      if (appUserId != null) {
        configuration.appUserID = appUserId;
      }

      await Purchases.configure(configuration);
      _initialized = true;
    } catch (_) {
      // Failed to initialize in emulator / debug
    }
  }

  // Identify User to RevenueCat on Login
  Future<void> identifyUser(String uid) async {
    if (kIsWeb || !_initialized) return;
    try {
      await Purchases.logIn(uid);
    } catch (_) {}
  }

  // Fetch Offerings (Subscriptions and Gold Packages)
  Future<Offerings?> getOfferings() async {
    if (kIsWeb || !_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  // Purchase Package (Google Play / App Store)
  Future<bool> purchasePackage(Package package) async {
    if (kIsWeb || !_initialized) return false;
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      // Check if user unlocked the premium entitlement
      if (customerInfo.entitlements.all["premium"]?.isActive == true) {
        // Entitled to ad-free experience
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Check active subscriptions (Premium Ad-Free status)
  Future<bool> isPremiumActive() async {
    if (kIsWeb) {
      // Mock Stripe web premium check via cloud function / firestore user state
      try {
        final state = await FirebaseService.instance.callFunction('checkUserPremiumStatus');
        return state['isPremium'] == true;
      } catch (_) {
        return false;
      }
    }
    if (!_initialized) return false;

    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all["premium"]?.isActive == true;
    } catch (_) {
      return false;
    }
  }

  // Web Checkout URL generation (Stripe Link)
  Future<String?> generateStripeCheckoutLink(String planId) async {
    if (!kIsWeb) return null;
    try {
      final res = await FirebaseService.instance.callFunction('createStripeCheckoutSession', {
        'planId': planId,
        'successUrl': Uri.base.toString(),
        'cancelUrl': Uri.base.toString(),
      });
      return res['url']?.toString();
    } catch (_) {
      return null;
    }
  }
}
