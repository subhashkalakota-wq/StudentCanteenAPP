class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final bool isVeg;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.isVeg,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'isVeg': isVeg,
  };
}

class OrderModel {
  final String id;
  final int orderNumber;
  final String tenantId;
  final String userStudentName;
  final String studentRollNo;
  final String studentPhone;
  final String studentEmail;
  final List<CartItem> items;
  final double subtotal;
  final double platformFee;
  final double totalAmount;
  final String qrToken;
  final String status;
  final String? qrUsedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.tenantId,
    required this.userStudentName,
    required this.studentRollNo,
    required this.studentPhone,
    required this.studentEmail,
    required this.items,
    required this.subtotal,
    required this.platformFee,
    required this.totalAmount,
    required this.qrToken,
    required this.status,
    this.qrUsedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<CartItem> parsedItems = rawItems.map((i) => CartItem(
      id: i['id'] ?? '',
      name: i['name'] ?? '',
      price: (i['price'] ?? 0).toDouble(),
      quantity: i['quantity'] ?? 1,
      isVeg: i['isVeg'] ?? true,
    )).toList();

    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? 100,
      tenantId: json['tenantId'] ?? '',
      userStudentName: json['userStudentName'] ?? json['studentName'] ?? 'Student',
      studentRollNo: json['studentRollNo'] ?? '',
      studentPhone: json['studentPhone'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
      items: parsedItems,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      qrToken: json['qrToken'] ?? '',
      status: json['status'] ?? 'PAID',
      qrUsedAt: json['qrUsedAt'],
    );
  }
}
