class CompanyProfile {
  final int? id;
  String companyName;
  String responsibleName;
  String phone;
  String email;
  String cnpj;
  String? logoBase64;

  CompanyProfile({
    this.id,
    required this.companyName,
    required this.responsibleName,
    required this.phone,
    required this.email,
    this.cnpj = '',
    this.logoBase64,
  });

  factory CompanyProfile.fromMap(Map<String, dynamic> json) => CompanyProfile(
        id: json['id'],
        companyName: json['companyName'] ?? '',
        responsibleName: json['responsibleName'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        cnpj: json['cnpj'] ?? '',
        logoBase64: json['logoBase64'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'responsibleName': responsibleName,
      'phone': phone,
      'email': email,
      'cnpj': cnpj,
      'logoBase64': logoBase64,
    };
  }
}
