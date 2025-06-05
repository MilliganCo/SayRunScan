import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:barcode_app/features/bags/data/bag_repository.dart';
import 'package:excel/excel.dart';

void main() {
  test('parse xls to bags', () async {
    final excel = Excel.createExcel();
    final sheet = excel.sheets.values.first;
    sheet.appendRow([
      'cz',
      'sscc',
      '',
      '',
      '',
      'article',
      'title'
    ]);
    sheet.appendRow([
      'CZ1234567890123456789012345678901',
      '123456789012345678',
      '',
      '',
      '',
      'ART1',
      'Product 1'
    ]);
    sheet.appendRow([
      'CZ2234567890123456789012345678901',
      '123456789012345679',
      '',
      '',
      '',
      'ART2',
      'Product 2'
    ]);
    final bytes = excel.encode()!;
    final file = File(
        '${Directory.systemTemp.path}/bags.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    final repo = BagRepository();
    final bags = await repo.parseFile(file);
    expect(bags.length, 2);
    expect(bags.first.sscc, '123456789012345678');

    await file.delete();
  });
}
