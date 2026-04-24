class UserModel {
  final String id;
  final String fullName;
  final String email;
  final int monthlySalaryCents;
  final String householdType;
  final int childrenCount;
  final int createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.monthlySalaryCents,
    required this.householdType,
    required this.childrenCount,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'monthlySalaryCents': monthlySalaryCents,
    'householdType': householdType,
    'childrenCount': childrenCount,
    'createdAt': createdAt,
  };

  static UserModel fromMap(Map<String, Object?> map) => UserModel(
    id: map['id'] as String,
    fullName: map['fullName'] as String,
    email: map['email'] as String,
    monthlySalaryCents: map['monthlySalaryCents'] as int,
    householdType: (map['householdType'] as String?) ?? 'single',
    childrenCount: (map['childrenCount'] as int?) ?? 0,
    createdAt: map['createdAt'] as int,
  );
}
