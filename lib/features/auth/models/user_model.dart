class UserModel {
  final String idUser;
  final String nama;
  final String username;
  final String levelUser;

  const UserModel({
    required this.idUser,
    required this.nama,
    required this.username,
    required this.levelUser,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        idUser:    json['id_user']?.toString() ?? '',
        nama:      json['nama'] ?? '',
        username:  json['username'] ?? '',
        levelUser: json['level_user']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id_user':    idUser,
        'nama':       nama,
        'username':   username,
        'level_user': levelUser,
      };
}
