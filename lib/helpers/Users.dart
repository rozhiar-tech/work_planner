class User {
  final String id;
  final String name;
  final String email;
  final String image;
  final String role;
  // Add other fields as needed

  User(
      {required this.id,
      required this.name,
      required this.email,
      required this.image,
      required this.role});

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      image: data['imageUrl'] ?? '',
      role: data['role'] ?? '',
      // Initialize other fields
    );
  }
}
