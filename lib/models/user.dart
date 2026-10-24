class User {
  final String name;
  final String email;
  final bool isLoggedIn;

  const User({
    required this.name,
    required this.email,
    this.isLoggedIn = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'isLoggedIn': isLoggedIn,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        isLoggedIn: map['isLoggedIn'] as bool? ?? false,
      );

  User copyWith({String? name, String? email, bool? isLoggedIn}) => User(
        name: name ?? this.name,
        email: email ?? this.email,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      );
}
