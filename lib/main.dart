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
  String _errorMessage = '';

  Future<void> _fetchProduct(String code) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://product.vvn.com.vn/api/decode.php?code=$code&token=abc123xyz')
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _product = Product.fromJson(data);
          _qtyController.text = _product!.quantity.toString();
        });
      } else {
        throw Exception('Lỗi kết nối: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProduct() async {
    if (_product == null) return;

    setState(() => _isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('http://product.vvn.com.vn/api/update.php'),
        body: {
          'code': _product!.code,
          'qty': _qtyController.text,
          'token': 'abc123xyz'
        }
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cập nhật thành công!'))
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét QR Kiểm Kho'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (_, state, __) => Icon(
                state == TorchState.on ? Icons.flash_on : Icons.flash_off,
              ),
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first;
                    if (barcode.rawValue != null) {
                      _fetchProduct(barcode.rawValue!);
                    }
                  },
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (_errorMessage.isNotEmpty)
                  Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red))),
              ],
            ),
          ),
          if (_product != null) _buildProductForm(),
        ],
      ),
    );
  }

  Widget _buildProductForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_product!.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Mã: ${_product!.code}'),
          Text('Đơn vị: ${_product!.unit}'),
          const Divider(),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số lượng mới',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateProduct,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('CẬP NHẬT'),
          ),
        ],
      ),
    );
  }
}
