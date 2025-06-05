import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
              final controller = TextEditingController();
              final path = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Путь к XLS-файлу'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: '/path/file.xlsx'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      child: const Text('Загрузить'),
                    ),
                  ],
                ),
              );
              if (path != null && path.isNotEmpty) {
                final file = File(path);
                if (await file.exists()) {
                  await bloc.loadFromFile(file);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () async {
              final csv = bloc.bags
                  .map((b) => '${b.sscc},${b.scanned},${DateTime.now()}')
                  .join('\n');
              
              final dir = await getApplicationDocumentsDirectory();
              final f = File('${dir.path}/BagChecks_${DateTime.now().millisecondsSinceEpoch}.csv');
              await f.writeAsString(csv);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Экспорт завершен')));

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
