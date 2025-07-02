class GasCard {
  final String? id;
  final String? cardNumber;
  final String? balance;
  final String? vehicleId;
  final List<ConsumptionEntry>? consumption;

  GasCard({
    this.id,
    this.cardNumber,
    this.balance,
    this.vehicleId,
    this.consumption,
  });

  factory GasCard.fromJson(Map<String, dynamic> json) {
    return GasCard(
      id: json['_id'] as String?,
      cardNumber: json['card_number'] as String?,
      balance: json['balance'] as String?,
      vehicleId: json['vehicle'] is String
          ? json['vehicle'] as String
          : json['vehicle']?['_id'] as String?,
      consumption: (json['consumption'] as List<dynamic>?)?.map((item) => ConsumptionEntry.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'card_number': cardNumber,
      'balance': balance,
      'vehicle': vehicleId,
      'consumption': consumption?.map((item) => item.toJson()).toList(),
    };
  }
}

class ConsumptionEntry {
  final DateTime? date;
  final double? amount;

  ConsumptionEntry({
    this.date,
    this.amount,
  });

  factory ConsumptionEntry.fromJson(Map<String, dynamic> json) {
    return ConsumptionEntry(
      date: json['date'] != null ? DateTime.parse(json['date'].toString()) : null,
      amount: json['amount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date?.toIso8601String(),
      'amount': amount,
    };
  }
}