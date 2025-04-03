class Product {
  final String name;
  final String code;
  final String unit;
  final int quantity;

  Product({
    required this.name,
    required this.code,
    required this.unit,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['ten_chi_tiet'] ?? '',
      code: json['ma_chi_tiet'] ?? '',
      unit: json['don_vi'] ?? '',
      quantity: int.tryParse(json['so_luong']?.toString() ?? '0') ?? 0,
    );
  }
}
