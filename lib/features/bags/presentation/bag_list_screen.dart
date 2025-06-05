import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bags_bloc.dart';
import '../domain/entities.dart';
import 'bag_scanner_screen.dart';

class BagListScreen extends StatelessWidget {
  const BagListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<BagsBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Приёмка мешков'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles();
              if (result != null) {
                final file = File(result.files.single.path!);
                await bloc.loadFromFile(file);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () async {
              final csv = bloc.bags
                  .map((b) => '${b.sscc},${b.scanned},${DateTime.now()}')
                  .join('\n');
              final dir = await FilePicker.platform.getDirectoryPath();
              if (dir != null) {
                final f = File('$dir/BagChecks_${DateTime.now().millisecondsSinceEpoch}.csv');
                await f.writeAsString(csv);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Экспорт завершен')));
                }
              }
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final code = await Navigator.push<String>(
              context, MaterialPageRoute(builder: (_) => const BagScannerScreen()));
          if (code != null) {
            bloc.markScanned(code);
          }
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: ListView.builder(
        itemCount: bloc.bags.length,
        itemBuilder: (context, index) {
          final bag = bloc.bags[index];
          return ListTile(
            title: Text(bag.sscc),
            subtitle: Text('ЧЗ: ${bag.czPrefixes.length}'),
            trailing: Icon(
              bag.scanned ? Icons.check_circle : Icons.circle_outlined,
              color: bag.scanned ? Colors.green : null,
            ),
          );
        },
      ),
    );
  }
}
