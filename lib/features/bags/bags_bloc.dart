import 'dart:io';
import 'package:flutter/material.dart';
import 'data/bag_repository.dart';
import 'domain/entities.dart';

class BagsBloc extends ChangeNotifier {
  final BagRepository repo;
  List<Bag> bags = [];
  BagsBloc(this.repo);

  Future<void> loadFromFile(File file) async {
    try {
      bags = await repo.parseFile(file);
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  void markScanned(String code) {
    for (final bag in bags) {
      if (bag.sscc == code || bag.czPrefixes.contains(code)) {
        bag.scanned = true;
        notifyListeners();
        return;
      }
    }
  }
}
