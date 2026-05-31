import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../providers/economy_provider.dart';
import '../../providers/auth_provider.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String _activeTab = 'avatarFrame';
  bool _busy = false;

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _buy(Map<String, dynamic> item) async {
    final profile = ref.read(profileProvider);
    if (profile == null || !profile.isGoogle) {
      _showToast('Mağazadan satın alım yapmak için Google ile giriş yapmalısınız.');
      return;
    }

    setState(() => _busy = true);
    try {
      final success = await ref.read(economyProvider.notifier).buyItem(item['id']?.toString() ?? '');
      if (success) {
        _showToast('${item['name']} başarıyla satın alındı!');
      } else {
        _showToast('Satın alma başarısız. Yeterli altınınız olmayabilir.');
      }
    } catch (e) {
      _showToast('Satın alma hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _equip(Map<String, dynamic> item) async {
    final slot = YGHelpers.slotForType(item['type']?.toString() ?? '');
    setState(() => _busy = true);
    try {
      final success = await ref.read(economyProvider.notifier).equipCosmetic(item['id']?.toString() ?? '', slot);
      if (success) {
        _showToast('${item['name']} profile takıldı!');
      } else {
        _showToast('Kullanılamadı.');
      }
    } catch (e) {
      _showToast('Hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final economy = ref.watch(economyProvider);
    final profile = ref.watch(profileProvider);

    final wallet = economy.wallet;
    final balance = wallet['balance'] as int? ?? 0;
    
    // Convert inventory list to set of IDs
    final inventory = economy.inventory.map((e) {
      if (e is Map) return e['id']?.toString();
      return e.toString();
    }).whereType<String>().toSet();

    // Map categories matching backend JSON structure
    final allItems = economy.storeItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Custom fallbacks if Firebase empty
    final displayItems = allItems.isNotEmpty ? allItems.where((item) {
      final type = item['type']?.toString() ?? '';
      if (_activeTab == 'discount') {
        final pricing = Map<String, dynamic>.from(item['pricing']?['permanent'] ?? {});
        final finalPrice = pricing['finalPrice'] ?? item['price'] ?? 0;
        final basePrice = pricing['basePrice'] ?? item['price'] ?? 0;
        return finalPrice < basePrice;
      }
      if (_activeTab == 'avatarFrame') {
        return type == 'avatarFrame' || type == 'frame';
      }
      return type == _activeTab;
    }).toList() : [];

    return Scaffold(
      body: Column(
        children: [
          // 1. Balance Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: YGColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✦', style: TextStyle(color: YGColors.gold, fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '$balance Altın',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: YGColors.gold),
                  ),
                ],
              ),
            ),
          ),

          // 2. Tab selection
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AppConstants.marketTabs.length,
              itemBuilder: (context, i) {
                final tab = AppConstants.marketTabs[i];
                final active = _activeTab == tab[0];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(tab[1], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    selected: active,
                    onSelected: (_) => setState(() => _activeTab = tab[0]),
                    side: BorderSide.none,
                    selectedColor: YGColors.gold.withOpacity(0.18),
                    backgroundColor: isDark ? YGColors.darkSurface : YGColors.lightSurface,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 3. Grid/List of items
          Expanded(
            child: displayItems.isEmpty
                ? const Center(child: Text('Bu kategoride ürün bulunamadı.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: displayItems.length,
                    itemBuilder: (context, i) {
                      final item = displayItems[i];
                      final itemId = item['id']?.toString() ?? '';
                      final owned = inventory.contains(itemId);
                      final price = item['price'] ?? 0;
                      final name = item['name']?.toString() ?? 'Ürün';
                      final desc = item['description']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.premiumBoxDecoration(isDark: isDark, radius: 20),
                        child: Row(
                          children: [
                            // Visual Preview Box
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: isDark ? YGColors.darkSurface2 : YGColors.lightSurface2,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: item['borderColor'] != null
                                      ? Color(int.parse(item['borderColor'].toString().replaceAll('#', '0xff')))
                                      : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item['badgeEmoji']?.toString() ?? '✦',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Item details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Buy/Equip buttons
                            const SizedBox(width: 10),
                            owned
                                ? SizedBox(
                                    height: 38,
                                    child: OutlinedButton(
                                      onPressed: _busy ? null : () => _equip(item),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: YGColors.green, width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Kullan', style: TextStyle(color: YGColors.green, fontWeight: FontWeight.w900)),
                                    ),
                                  )
                                : SizedBox(
                                    height: 38,
                                    child: ElevatedButton(
                                      onPressed: _busy || profile?.isGoogle != true ? null : () => _buy(item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: YGColors.gold,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('$price ✦', style: const TextStyle(fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
