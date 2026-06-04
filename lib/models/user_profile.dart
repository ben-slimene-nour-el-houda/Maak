class UserProfile {
  int? id;
  String fullName;
  String cin;
  String address;
  String dob;
  String phone;

  UserProfile({
    this.id,
    required this.fullName,
    required this.cin,
    required this.address,
    required this.dob,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'cin': cin,
      'address': address,
      'birth_date': dob,
      'phone': phone,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      fullName: (map['fullName'] ?? map['full_name'] ?? '').toString(),
      cin: (map['cin'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      dob: (map['dob'] ?? map['birth_date'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
    );
  }
}
