class Profile {
  final String id;
  final String? fullName;
  final String? phoneNumber;
  final String role; // 'admin' or 'user'

  Profile({
    required this.id,
    this.fullName,
    this.phoneNumber,
    required this.role,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      fullName: map['full_name'],
      phoneNumber: map['phone_number'],
      role: map['role'] ?? 'user',
    );
  }
}