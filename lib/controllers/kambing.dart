import 'package:flutter/material.dart';
import 'package:goatcheck/services/kambing_service.dart';

class KambingController {
  final KambingService _kambingService = KambingService();

  // Parse metric value
  double? parseMetricValue(dynamic value) {
    if (value == null) return null;
    String str = value.toString().trim();
    if (str == '-' || str.isEmpty) return null;

    // Ganti koma dengan titik untuk standarisasi format desimal
    str = str.replaceAll(',', '.');

    // Ambil pola angka desimal/bulat pertama dari string
    final match = RegExp(r'[+-]?\d+(?:\.\d+)?').firstMatch(str);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    return null;
  }

  // Classify activity
  String? classifyActivity(dynamic value) {
    if (value == null) return null;
    String str = value.toString().trim().toLowerCase();
    if (str == '-' || str.isEmpty) return null;

    // 'sangat aktif' harus dicek SEBELUM 'aktif' agar tidak salah klasifikasi
    if (str.contains('sangat aktif') ||
        str.contains('very active') ||
        str.contains('sangat bergerak')) {
      return 'sangat aktif';
    }

    if (str == 'diam' ||
        str.contains('diam') ||
        str.contains('tidur') ||
        str.contains('sleep') ||
        str.contains('istirahat') ||
        str.contains('rest')) {
      return 'diam';
    }
    if (str == 'lambat' ||
        str.contains('lambat') ||
        str.contains('jalan') ||
        str.contains('pelan') ||
        str.contains('slow') ||
        str.contains('walk')) {
      return 'lambat';
    }
    if (str == 'aktif' ||
        str.contains('aktif') ||
        str.contains('lari') ||
        str.contains('berlari') ||
        str.contains('run') ||
        str.contains('makan') ||
        str.contains('eat') ||
        str.contains('active') ||
        str.contains('bergerak')) {
      return 'aktif';
    }

    // Jika berupa angka, gunakan threshold
    str = str.replaceAll(',', '.');
    final match = RegExp(r'[+-]?\d+(?:\.\d+)?').firstMatch(str);
    if (match != null) {
      double? numVal = double.tryParse(match.group(0)!);
      if (numVal != null) {
        if (numVal < 10.0) return 'diam';
        if (numVal < 30.0) return 'lambat';
        if (numVal < 60.0) return 'aktif';
        return 'sangat aktif';
      }
    }
    return null;
  }

  // Add goat (replacing _saveKambing)
  Future<void> saveKambing({
    required BuildContext context,
    required String deviceId,
    required String nama,
    required String? jenisKelamin,
    required DateTime? tanggalLahir,
    required VoidCallback onStartLoading,
    required VoidCallback onEndLoading,
  }) async {
    if (deviceId.isEmpty ||
        nama.isEmpty ||
        jenisKelamin == null ||
        tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap lengkapi semua data kambing"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    onStartLoading();

    try {
      final String formattedDate =
          "${tanggalLahir.day.toString().padLeft(2, '0')}/${tanggalLahir.month.toString().padLeft(2, '0')}/${tanggalLahir.year}";

      await _kambingService.addKambing(
        idPerangkat: deviceId,
        nama: nama,
        jenisKelamin: jenisKelamin,
        tanggalLahir: formattedDate,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kambing berhasil ditambahkan!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menambahkan kambing: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      onEndLoading();
    }
  }

  // Update goat (replacing _updateKambing)
  Future<void> updateKambing({
    required BuildContext context,
    required String docId,
    required String deviceId,
    required String nama,
    required String? jenisKelamin,
    required DateTime? tanggalLahir,
    required VoidCallback onStartLoading,
    required VoidCallback onEndLoading,
  }) async {
    if (deviceId.isEmpty ||
        nama.isEmpty ||
        jenisKelamin == null ||
        tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap lengkapi semua data kambing"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    onStartLoading();

    try {
      final String formattedDate =
          "${tanggalLahir.day.toString().padLeft(2, '0')}/${tanggalLahir.month.toString().padLeft(2, '0')}/${tanggalLahir.year}";

      await _kambingService.updateKambing(
        docId: docId,
        nama: nama,
        jenisKelamin: jenisKelamin,
        tanggalLahir: formattedDate,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close edit bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kambing berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memperbarui kambing: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      onEndLoading();
    }
  }

  // Delete goat (replacing direct delete)
  Future<void> deleteKambing({
    required BuildContext context,
    required String docId,
    required String nama,
  }) async {
    try {
      await _kambingService.deleteKambing(docId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kambing berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
