import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import 'features/bags/bags_bloc.dart';
import 'features/bags/data/bag_repository.dart';
import 'features/bags/presentation/bag_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BagsBloc(BagRepository()),
      child: MaterialApp(
        title: 'Barcode Lookup',
        theme: ThemeData(
          primarySwatch: Colors.grey,
        ),
        home: const _ModeSelector(),
      ),
    );
  }
}

enum AppMode { sales, bags }

class _ModeSelector extends StatefulWidget {
  const _ModeSelector();

  @override
  State<_ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<_ModeSelector> {
  AppMode? mode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _chooseMode());
  }

  Future<void> _chooseMode() async {
    final selected = await showDialog<AppMode>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Выберите режим'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, AppMode.sales),
            child: const Text('Продажи'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, AppMode.bags),
            child: const Text('Приёмка'),
          ),
        ],
      ),
    );
    if (selected != null) {
      setState(() => mode = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mode == null) return const SizedBox.shrink();
    if (mode == AppMode.bags) return const BagListScreen();
    return const BarcodePage();
  }
}

class BarcodePage extends StatefulWidget {
  const BarcodePage({Key? key}) : super(key: key);

  @override
  _BarcodePageState createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _productName = '';
  Map<String, dynamic> _data = {};

  static const _endpoint = 'http://194.32.248.34:51000/barcode';
  static const _refreshEndpoint = 'http://194.32.248.34:51000/refresh';
  static const _authHeader = 'HvkhvUVUhvuvuYVUKvukyV';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  // ---------------- NETWORK ----------------
  Future<void> _onSubmitted(String code) async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: {'code': code});
    try {
      final response = await http.get(uri, headers: {'Authorization': _authHeader});
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _data = jsonBody;
          _productName = jsonBody['name'] ?? '';
        });
      } else {
        debugPrint('Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Request failed: $e');
    } finally {
      _controller.clear();
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  Future<void> _onRefresh() async {
    final uri = Uri.parse(_refreshEndpoint);
    try {
      final response = await http.post(uri, headers: {'Authorization': _authHeader});
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body) as Map<String, dynamic>;
        final time = jsonBody['time'] ?? 'unknown';
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Data refreshed at $time')));
      } else {
        _showSnack('Refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnack('Refresh error: $e');
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---------------- CAMERA SCANNER ----------------
  Future<void> _openCameraScanner() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScanScreen()),
    );
    if (scanned != null && scanned.isNotEmpty) {
      _onSubmitted(scanned);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _openCameraScanner,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Штрихкод Сканер'),
          actions: [
            IconButton(
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Сканер камеры',
              onPressed: _openCameraScanner,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _onRefresh,
              tooltip: 'Обновить данные',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_productName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _productName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  labelText: 'Сканируйте штрихкод',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _onSubmitted,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.2,
                  ),
                  children: [
                    _buildCard('Остатки на складе', _data['wh'], Colors.green),
                    _buildCard('Заказы WB вчера', _data['wb_yes'], const Color.fromARGB(255, 125, 24, 150)),
                    _buildCard('Остатки WB', _data['wb'], const Color.fromARGB(255, 199, 34, 111)),
                    _buildCard('Заказы WB неделя', _data['wb_week'], const Color.fromARGB(255, 212, 120, 255)),
                    _buildCard('Остатки Ozon', _data['ozon'], Colors.blue),
                    _buildCard('Заказы Ozon неделя', _data['ozon_week'], Colors.indigo),
                    _buildCard('Остатки дней WB', _calculateWBDays(), const Color.fromARGB(255, 247, 121, 190)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateWBDays() {
    final wb = (_data['wb'] ?? 0) as num;
    final supply = (_data['wb_supply'] ?? 0) as num;
    final yesterday = (_data['wb_yes'] ?? 0) as num;
    final totalStock = wb + supply;
    if (yesterday == 0) return '-';
    return (totalStock / yesterday).toStringAsFixed(1);
  }

  Widget _buildCard(String title, dynamic value, Color color) {
    return FractionallySizedBox(
      widthFactor: 0.9,
      heightFactor: 0.9,
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            Center(
              child: Text(
                value != null ? value.toString() : '-',
                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// FULL‑SCREEN CAMERA SCANNER
// ------------------------------------------------------------------
class _ScanScreen extends StatefulWidget {
  const _ScanScreen({Key? key}) : super(key: key);

  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen> {
  bool _torchOn = false;
  String? _lastScannedCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final code = capture.barcodes.first.rawValue ?? '';
              if (code.isNotEmpty && code != _lastScannedCode) {
                _lastScannedCode = code;
                Navigator.pop(context, code);
              }
            },
          ),
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 32),
              onPressed: () {
                MobileScannerController().toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
