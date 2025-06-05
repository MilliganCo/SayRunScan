import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:provider/provider.dart';

import '../bags_bloc.dart';
import 'bag_scanner_screen.dart';

class BagListScreen extends StatefulWidget {
  final VoidCallback onModeChange;
  const BagListScreen({super.key, required this.onModeChange});

  @override
  State<BagListScreen> createState() => _BagListScreenState();
}

class _BagListScreenState extends State<BagListScreen> {
  static const _endpoint = 'http://194.32.248.34:51000/bags';
  static const _authHeader = 'HvkhvUVUhvuvuYVUKvukyV';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDefaultFile);
  }

  Future<void> _loadDefaultFile() async {
    final bloc = context.read<BagsBloc>();
    try {
      await bloc.loadFromServer(Uri.parse(_endpoint), authToken: _authHeader);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить файл: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<BagsBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Приёмка мешков'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Сменить режим',
            onPressed: widget.onModeChange,
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
