import 'dart:io';
import 'package:excel/excel.dart';
import '../domain/entities.dart';

class BagRepository {
  Future<List<Bag>> parseFile(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final Map<String, Bag> map = {};
    final sheet = excel.tables.values.first;
    for (var row in sheet.rows.skip(1)) {
      if (row.length < 7) continue;
      final cz = row[0]?.value?.toString() ?? '';
      final sscc = row[1]?.value?.toString() ?? '';
      final article = row[5]?.value?.toString() ?? '';
      final title = row[6]?.value?.toString() ?? '';
      if (sscc.isEmpty) continue;
      map.putIfAbsent(sscc, () => Bag(sscc: sscc, czPrefixes: [], items: []));
      final bag = map[sscc]!;
      if (cz.isNotEmpty) bag.czPrefixes.add(cz.substring(0, cz.length < 31 ? cz.length : 31));
      bag.items.add(BagItem(article: article, title: title, czPrefix: cz));
    }
    return map.values.toList();
  }
}
