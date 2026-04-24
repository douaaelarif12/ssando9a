class FixedCharge {
  final String id;
  final String name;
  int amount;
  final List<int> activeMonths;

  FixedCharge({
    required this.id,
    required this.name,
    required this.amount,
    required this.activeMonths,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'activeMonths': activeMonths,
    };
  }

  factory FixedCharge.fromMap(Map<String, dynamic> map) {
    return FixedCharge(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toInt(),
      activeMonths: (map['activeMonths'] as List)
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}