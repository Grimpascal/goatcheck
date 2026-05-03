import 'package:cloud_firestore/cloud_firestore.dart';

class PeternakModel {
  String? uid;
  String? nama;
  String? email;
  String? password;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Constructor
  PeternakModel({
    this.uid,
    this.nama,
    this.email,
    this.password,
    this.createdAt,
    this.updatedAt,
  });

  // 1. Mengubah data dari Map (Firestore) ke dalam Object Dart (Model)
  // Digunakan saat kita mengambil data (Fetch) dari database
  factory PeternakModel.fromMap(Map<String, dynamic> map) {
    return PeternakModel(
      uid: map['uid'],
      nama: map['nama'],
      email: map['email'],
      password: map['password'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  // 2. Mengubah Object Dart ke dalam Map (JSON)
  // Digunakan saat kita ingin mengirim/menyimpan data ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'password': password,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
      'updated_at': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}