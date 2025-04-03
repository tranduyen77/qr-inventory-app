import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product.dart';

void main() => runApp(const QRInventoryApp());

class QRInventoryApp extends StatelessWidget {
  const QRInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Inventory',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const QRScannerScreen(),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  Product? _product;
  final TextEditingController _qtyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _fetchProduct(String code) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://product.vvn.com.vn/api/decode.php?code=$code&token=abc123xyz')
      );
      if (response.statusCode == 200) {
        setState(() {
          _product = Product.fromJson(json.decode(response.body));
          _qtyController.text = _product!.quantity.toString();
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Inventory')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  _fetchProduct(barcode.rawValue!);
                }
              },
            ),
          ),
          if (_product != null) 
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(_product!.name, style: const TextStyle(fontSize: 18)),
                  TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Xử lý cập nhật
                    },
                    child: const Text('Cập nhật'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
