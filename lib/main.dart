
// QR Inventory Flutter App (Minimal)

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(QRInventoryApp());

class QRInventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Inventory',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InventoryHomePage(),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  String qrCode = '';
  String productName = '';
  String productCode = '';
  String unit = '';
  int currentQty = 0;
  int inputQty = 0;
  String status = '';

  final qtyController = TextEditingController();
  bool loading = false;

  Future<void> decodeQR(String code) async {
    setState(() { loading = true; });
    final response = await http.get(Uri.parse(
        'http://product.vvn.com.vn/api/decode.php?code=$code&token=abc123xyz'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        productName = data['product_name'] ?? '';
        productCode = data['product_code'] ?? '';
        unit = data['unit'] ?? '';
        currentQty = data['current_quantity'] ?? 0;
        status = 'Đã nạp dữ liệu thành công';
      });
    } else {
      setState(() {
        status = 'Lỗi: Không tìm thấy thông tin';
      });
    }
    setState(() { loading = false; });
  }

  Future<void> updateQty() async {
    final qty = int.tryParse(qtyController.text) ?? 0;
    if (qty <= 0 || qrCode.isEmpty) return;

    setState(() { loading = true; });
    final response = await http.post(
      Uri.parse('http://product.vvn.com.vn/api/update.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': qrCode,
        'qty': qty,
        'token': 'abc123xyz'
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        currentQty = data['updated_total'] ?? currentQty;
        status = 'Cập nhật thành công: Tổng SL mới $currentQty';
      });
    } else {
      setState(() { status = 'Lỗi khi cập nhật'; });
    }
    setState(() { loading = false; });
  }

  void onDetectBarcode(BarcodeCapture capture) {
    final code = capture.barcodes.first.rawValue;
    if (code != null && code != qrCode) {
      setState(() { qrCode = code; });
      decodeQR(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Inventory')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: MobileScanner(onDetect: onDetectBarcode),
            ),
            SizedBox(height: 16),
            Text('Tên SP: $productName'),
            Text('Mã SP: $productCode'),
            Text('Đơn vị: $unit'),
            Text('SL đã nhập: $currentQty'),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Nhập số lượng'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : updateQty,
              child: Text('GỬI'),
            ),
            SizedBox(height: 8),
            if (status.isNotEmpty) Text(status, style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
