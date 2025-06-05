class BagItem {
  final String article;
  final String title;
  final String czPrefix;

  BagItem({required this.article, required this.title, required this.czPrefix});

  factory BagItem.fromJson(Map<String, dynamic> json) => BagItem(
        article: json['article'] as String? ?? '',
        title: json['title'] as String? ?? '',
        czPrefix: json['czPrefix'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'article': article, 'title': title, 'czPrefix': czPrefix};
}

class Bag {
  final String sscc;
  final List<String> czPrefixes;
  final List<BagItem> items;
  bool scanned;

  Bag({
    required this.sscc,
    required this.czPrefixes,
    required this.items,
    this.scanned = false,
  });

  factory Bag.fromJson(Map<String, dynamic> json) => Bag(
        sscc: json['sscc'] as String? ?? '',
        czPrefixes: List<String>.from(json['czPrefixes'] ?? const []),
        items: (json['items'] as List? ?? [])
            .map((e) => BagItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        scanned: json['scanned'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'sscc': sscc,
        'czPrefixes': czPrefixes,
        'items': items.map((e) => e.toJson()).toList(),
        'scanned': scanned,
      };
}
