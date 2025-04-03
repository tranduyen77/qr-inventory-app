import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product.dart';
import 'api_service.dart';

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
  Product? _currentProduct;
  final TextEditingController _qtyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _fetchProduct(String code) async {
    setState(() => _isLoading = true);
    try {
      final product = await ApiService.fetchProduct(code);
      setState(() {
        _currentProduct = product;
        _qtyController.text = product.quantity.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR Kiểm Kho')),
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
          if (_currentProduct != null) 
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(_currentProduct!.name, style: const TextStyle(fontSize: 18)),
                  TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        await ApiService.updateQuantity(
                          _currentProduct!.code, 
                          int.parse(_qtyController.text)
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Cập nhật thành công!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Lỗi: ${e.toString()}')),
                        );
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                    child: const Text('CẬP NHẬT'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
