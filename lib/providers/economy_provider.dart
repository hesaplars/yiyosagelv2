import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/firebase_service.dart';

class EconomyState {
  final Map<String, dynamic> wallet;
  final List<dynamic> storeItems;
  final List<dynamic> inventory;
  final Map<String, dynamic> limits;
  final bool loading;
  final String? error;

  EconomyState({
    required this.wallet,
    required this.storeItems,
    required this.inventory,
    required this.limits,
    this.loading = false,
    this.error,
  });

  factory EconomyState.initial() {
    return EconomyState(
      wallet: {'balance': 0},
      storeItems: [],
      inventory: [],
      limits: {},
      loading: false,
    );
  }

  EconomyState copyWith({
    Map<String, dynamic>? wallet,
    List<dynamic>? storeItems,
    List<dynamic>? inventory,
    Map<String, dynamic>? limits,
    bool? loading,
    String? error,
  }) {
    return EconomyState(
      wallet: wallet ?? this.wallet,
      storeItems: storeItems ?? this.storeItems,
      inventory: inventory ?? this.inventory,
      limits: limits ?? this.limits,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class EconomyNotifier extends StateNotifier<EconomyState> {
  EconomyNotifier() : super(EconomyState.initial()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    try {
      final res = await FirebaseService.instance.callFunction('getEconomyState');
      if (res is Map) {
        final data = Map<String, dynamic>.from(res);
        state = EconomyState(
          wallet: Map<String, dynamic>.from(data['wallet'] ?? {'balance': 0}),
          storeItems: List<dynamic>.from(data['storeItems'] ?? []),
          inventory: List<dynamic>.from(data['inventory'] ?? []),
          limits: Map<String, dynamic>.from(data['limits'] ?? {}),
          loading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // Purchases an item from store (permanent or rental)
  Future<bool> buyItem(String itemId, {String purchaseType = 'permanent'}) async {
    try {
      await FirebaseService.instance.callFunction('purchaseStoreItem', {
        'itemId': itemId,
        'purchaseType': purchaseType,
      });
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Equips cosmetic item (avatar frame, cover etc)
  Future<bool> equipCosmetic(String itemId, String slot) async {
    try {
      await FirebaseService.instance.callFunction('equipCosmetic', {
        'itemId': itemId,
        'slot': slot,
      });
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Unlock/boost action limits using gold
  Future<bool> unlockLimit(String limitId) async {
    try {
      await FirebaseService.instance.callFunction('purchaseLimitBoost', {
        'limitKey': limitId,
      });
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final economyProvider = StateNotifierProvider<EconomyNotifier, EconomyState>((ref) {
  return EconomyNotifier();
});
