class BagItem {
  final String article;
  final String title;
  final String czPrefix;

  BagItem({required this.article, required this.title, required this.czPrefix});
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
}
