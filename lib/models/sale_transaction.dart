class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }
}

class SaleTransaction {
  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final double total;
  final String paymentMethod;
  final String status;
  final String processedBy;

  final double discountAmount;
  final String discountType;
  final bool isVoided;
  final DateTime? voidedAt;
  final String? voidReason;

  const SaleTransaction({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.status = 'pending',
    this.processedBy = 'Pending review',
    this.discountAmount = 0,
    this.discountType = 'None',
    this.isVoided = false,
    this.voidedAt,
    this.voidReason,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  SaleTransaction copyWith({
    bool? isVoided,
    DateTime? voidedAt,
    String? voidReason,
    String? status,
    String? processedBy,
  }) {
    return SaleTransaction(
      id: id,
      date: date,
      items: items,
      total: total,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      processedBy: processedBy ?? this.processedBy,
      discountAmount: discountAmount,
      discountType: discountType,
      isVoided: isVoided ?? this.isVoided,
      voidedAt: voidedAt ?? this.voidedAt,
      voidReason: voidReason ?? this.voidReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'total': total,
    'paymentMethod': paymentMethod,
    'status': status,
    'processedBy': processedBy,
    'discountAmount': discountAmount,
    'discountType': discountType,
    'isVoided': isVoided,
    'voidedAt': voidedAt?.toIso8601String(),
    'voidReason': voidReason,
  };

  factory SaleTransaction.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String? ?? 'pending').toLowerCase();
    final bool isVoided = json['isVoided'] as bool? ?? (rawStatus == 'voided');

    return SaleTransaction(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>)
          .map((item) => SaleItem.fromJson(
        Map<String, dynamic>.from(item as Map),
      ))
          .toList(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      status: rawStatus,
      processedBy: json['processedBy'] as String? ?? 'Pending review',
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      discountType: json['discountType'] as String? ?? 'None',
      isVoided: isVoided,
      voidedAt: json['voidedAt'] == null
          ? null
          : DateTime.parse(json['voidedAt'] as String),
      voidReason: json['voidReason'] as String?,
    );
  }
}