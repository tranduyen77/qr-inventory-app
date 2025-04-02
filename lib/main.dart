import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const QRInventoryApp());
}

class QRInventoryApp extends StatelessWidget {
  const QRInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Inventory',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const QRScannerScreen(),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  Product? currentProduct;
  final TextEditingController qtyController = TextEditingController();
  bool isLoading = false;
  String lastScannedCode = '';

  Future<void> fetchProduct(String code) async {
    if (code == lastScannedCode) return;
    
    setState(() {
      isLoading = true;
      lastScannedCode = code;
    });

    try {
      final response = await http.get(
        Uri.parse('http://product.vvn.com.vn/api/decode.php?code=$code&token=abc123xyz')
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          showToast('Lỗi: ${data['error']}');
        } else {
          setState(() {
            currentProduct = Product.fromJson(data);
            qtyController.text = currentProduct!.quantity.toString();
          });
        }
      } else {
        showToast('Lỗi kết nối: ${response.statusCode}');
      }
    } catch (e) {
      showToast('Lỗi: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateQuantity() async {
    if (currentProduct == null) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://product.vvn.com.vn/api/update.php'),
        body: {
          'code': currentProduct!.code,
          'qty': qtyController.text,
          'token': 'abc123xyz'
        }
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          showToast('Cập nhật thành công!');
          setState(() {
            currentProduct!.quantity = int.parse(qtyController.text);
          });
        } else {
          showToast('Lỗi: ${data['message']}');
        }
      } else {
        showToast('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      showToast('Lỗi: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    qtyController.dispose();
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
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        fetchProduct(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                if (isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          if (currentProduct != null) _buildProductInfo(),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              currentProduct!.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Mã: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(currentProduct!.code),
              ],
            ),
            Row(
              children: [
                const Text('Đơn vị: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(currentProduct!.unit),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Số lượng hiện tại: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(currentProduct!.quantity.toString()),
              ],
            ),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nhập số lượng mới',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : updateQuantity,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CẬP NHẬT'),
            ),
          ],
        ),
      ),
    );
  }
}

class Product {
  final String name;
  final String code;
  final String unit;
  int quantity;

  Product({
    required this.name,
    required this.code,
    required this.unit,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['ten_chi_tiet'] ?? 'Không có tên',
      code: json['ma_chi_tiet'] ?? 'Không có mã',
      unit: json['don_vi'] ?? 'N/A',
      quantity: int.tryParse(json['so_luong']?.toString() ?? '0') ?? 0,
    );
  }
}
