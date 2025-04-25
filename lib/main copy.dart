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
  Map<String, dynamic> _data = {};

  static const _endpoint = 'http://192.168.50.47:5000/barcode';
  static const _authHeader = 'HvkhvUVUhvuvuYVUKvukyV';

  @override
  void initState() {
    super.initState();
    // Keep focus on the text field to capture scanner input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Future<void> _onSubmitted(String code) async {
    final uri = Uri.parse(_endpoint).replace(
  queryParameters: {
    'code': code,
  },
);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': _authHeader,
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _data = jsonBody;
        });
      } else {
        // handle non-200
        debugPrint('Error: \${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Request failed: $e');
    } finally {
      _controller.clear();
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Штрихкод Сканер'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 24),
            Expanded(
              child: GridView(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                children: [
                  _buildCard('Остатки на складе', _data['wh'], Colors.green),
                  _buildCard('Остатки WB', _data['wb'], Colors.purple),
                  _buildCard('Остатки Ozon', _data['ozon'], Colors.blue),
                  _buildCard('Заказы WB вчера', _data['wb_yes'], Colors.lightBlueAccent),
                  _buildCard('Заказы WB неделя', _data['wb_week'], Colors.deepPurpleAccent),
                  _buildCard('Заказы Ozon неделя', _data['ozon_week'], Colors.indigo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, dynamic value, Color color) {
    return Container(
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
    );
  }
}
