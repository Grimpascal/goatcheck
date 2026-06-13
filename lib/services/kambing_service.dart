import 'package:cloud_firestore/cloud_firestore.dart';

class KambingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getKambingStream() {
    return _db.collection('kambing').snapshots();
  }

  Stream<QuerySnapshot> getPerangkatListStream() {
    return _db.collection('perangkat_iot').snapshots();
  }

  Stream<DocumentSnapshot> getPerangkatStream(String docId) {
    return _db.collection('perangkat_iot').doc(docId).snapshots();
  }

  Future<void> addKambing({
    required String idPerangkat,
    required String nama,
    required String jenisKelamin,
    required String tanggalLahir,
  }) async {
    await _db.collection('kambing').doc(idPerangkat).set({
      'nama': nama,
      'jenis_kelamin': jenisKelamin,
      'tanggal_lahir': tanggalLahir,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    final docSnapshot = await _db.collection('perangkat_iot').doc(idPerangkat).get();
    if (!docSnapshot.exists) {
      await _db.collection('perangkat_iot').doc(idPerangkat).set({
        'status': 'disconnected',
        'suhu': '-',
        'aktivitas': '-',
        'gyro': '-',
        'kondisi': '-',
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteKambing(String docId) async {
    await _db.collection('kambing').doc(docId).delete();
    await _db.collection('perangkat_iot').doc(docId).delete();
  }

  Future<void> updateKambing({
    required String docId,
    required String nama,
    required String jenisKelamin,
    required String tanggalLahir,
  }) async {
    await _db.collection('kambing').doc(docId).update({
      'nama': nama,
      'jenis_kelamin': jenisKelamin,
      'tanggal_lahir': tanggalLahir,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}