class Client {
  final int? id;
  String name;
  String phone;
  String address;
  String email;

  Client({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
  });

  // Converte de Map (Banco) para Objeto (Dart)
  factory Client.fromMap(Map<String, dynamic> json) => Client(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        address: json['address'],
        email: json['email'],
      );

  // Converte de Objeto (Dart) para Map (Banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
    };
  }
}