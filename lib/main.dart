import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Lookup',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const BarcodePage(),
    );
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

  static const _endpoint = 'http://192.168.50.47:5000/barcode';
  static const _refreshEndpoint = 'http://192.168.50.47:5000/refresh';
  static const _authHeader = 'HvkhvUVUhvuvuYVUKvukyV';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Future<void> _onSubmitted(String code) async {
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {'code': code},
    );
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': _authHeader},
      );
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
      final response = await http.post(
        uri,
        headers: {'Authorization': _authHeader},
      );
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body) as Map<String, dynamic>;
        final time = jsonBody['time'] ?? 'unknown';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data refreshed at $time')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Штрихкод Сканер'),
        actions: [
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
    );
  }

  String _calculateWBDays() {
    final wb = (_data['wb'] ?? 0) as num;
    final week = (_data['wb_week'] ?? 0) as num;
    final yesterday = (_data['wb_yes'] ?? 0) as num;
    final sales = week + yesterday;
    if (sales == 0) return '-';
    return (wb * 8 / sales).toStringAsFixed(1);
  }

  Widget _buildCard(String title, dynamic value, Color color) {
  return FractionallySizedBox(
    widthFactor: 0.9,   // 90% ширины ячейки
    heightFactor: 0.9,  // 90% высоты ячейки
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Center(
            child: Text(
              value != null ? value.toString() : '-',
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
//