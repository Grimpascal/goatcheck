import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goatcheck/services/kambing_service.dart';
import 'package:goatcheck/services/notification_service.dart';

class KambingController {
  final KambingService _kambingService = KambingService();
  final Set<String> _notifiedGoats = {};

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

  // Check temperature and trigger snackbar + local notification
  void checkAndNotifyTemp({
    required BuildContext context,
    required String docId,
    required String name,
    required double temp,
    required NotificationService notificationService,
  }) {
    if (temp >= 35.0) {
      if (!_notifiedGoats.contains(docId)) {
        _notifiedGoats.add(docId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showTempWarningNotification(context, name, temp);
          notificationService.showNotification(
            id: docId.hashCode,
            title: "PERINGATAN SUHU TINGGI!",
            body: "Kambing $name memiliki suhu tinggi: ${temp.toStringAsFixed(1)}°C (>= 35°C)",
          );
        });
      }
    } else {
      _notifiedGoats.remove(docId);
    }
  }

  // Display temperature warning in a floating SnackBar
  void showTempWarningNotification(BuildContext context, String name, double temp) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "PERINGATAN SUHU TINGGI!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  Text(
                    "Kambing $name memiliki suhu tinggi: ${temp.toStringAsFixed(1)}°C (>= 35°C)",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444), // Danger Red
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 1.2),
        ),
      ),
    );
  }

  // Fetch temperature history for DetailKambingBottomSheet
  Future<List<Map<String, dynamic>>> getHistory(String docId, String currentSuhu) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('perangkat_iot')
          .doc(docId)
          .collection('riwayat_suhu')
          .orderBy('timestamp', descending: true)
          .limit(6)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) => doc.data()).toList();
        return list.reversed.toList(); // Return chronological
      }
    } catch (e) {
      // Fallback silently
    }

    // Fallback to local simulated data
    double latestTemp = parseMetricValue(currentSuhu) ?? 38.2;
    List<Map<String, dynamic>> mockData = [];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final time = now.subtract(Duration(minutes: i * 20)); // 20-minute intervals
      double temp;
      if (i == 0) {
        temp = latestTemp;
      } else {
        double offset = (i % 2 == 0 ? 0.25 : -0.15) * (0.8 / i);
        temp = latestTemp + offset;
      }

      mockData.add({
        'timestamp': Timestamp.fromDate(time),
        'suhu': double.parse(temp.toStringAsFixed(1)),
      });
    }
    return mockData;
  }
}
