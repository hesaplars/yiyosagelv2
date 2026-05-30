class MarketItem {
  final String id;
  final String name;
  final String type;
  final int price;
  final String? description;
  final String? imageUrl;
  final String? borderColor;
  final String? glowColor;
  final String? backgroundColor;
  final String? badgeEmoji;
  final String? badgeColor;
  final bool active;
  final double sort;

  MarketItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.description,
    this.imageUrl,
    this.borderColor,
    this.glowColor,
    this.backgroundColor,
    this.badgeEmoji,
    this.badgeColor,
    this.active = true,
    this.sort = 0,
  });

  factory MarketItem.fromMap(Map<String, dynamic> map) {
    return MarketItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      price: int.tryParse(map['price']?.toString() ?? '0') ?? 0,
      description: map['description']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      borderColor: map['borderColor']?.toString(),
      glowColor: map['glowColor']?.toString(),
      backgroundColor: map['backgroundColor']?.toString(),
      badgeEmoji: map['badgeEmoji']?.toString(),
      badgeColor: map['badgeColor']?.toString(),
      active: map['active'] != false,
      sort: double.tryParse(map['sort']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price': price,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (borderColor != null) 'borderColor': borderColor,
      if (glowColor != null) 'glowColor': glowColor,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (badgeEmoji != null) 'badgeEmoji': badgeEmoji,
      if (badgeColor != null) 'badgeColor': badgeColor,
      'active': active,
      'sort': sort,
    };
  }
}
