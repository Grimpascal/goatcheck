import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goatcheck/services/kambing_service.dart';
import 'package:goatcheck/controllers/kambing.dart';
import 'package:goatcheck/views/widgets/temperature_chart.dart';
import 'package:goatcheck/views/widgets/edit_kambing_sheet.dart';

// Detail Bottom Sheet
class DetailKambingBottomSheet extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const DetailKambingBottomSheet({
    super.key,
    required this.docId,
    required this.data,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFEFFFC8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 1.5),
          ),
          title: const Text(
            "Hapus Kambing",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Apakah Anda yakin ingin menghapus kambing ${data['nama'] ?? ''}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                await KambingController().deleteKambing(
                  context: context,
                  docId: docId,
                  nama: data['nama'] ?? 'Tanpa Nama',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black, width: 1),
                ),
              ),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String nama = data['nama'] ?? 'Tanpa Nama';
    String kelamin = data['jenis_kelamin'] ?? '-';

    return StreamBuilder<DocumentSnapshot>(
      stream: KambingService().getPerangkatStream(docId),
      builder: (context, snapshot) {
        Map<String, dynamic> iotData = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          iotData = snapshot.data!.data() as Map<String, dynamic>;
        }

        String status = iotData['status'] ?? 'disconnected';
        String suhu = iotData['suhu']?.toString() ?? '-';
        String aktivitas = iotData['aktivitas'] ?? '-';

        // Check timeout of 1 minute (60 seconds)
        bool isConnected = status.toLowerCase() == 'tersambung';
        final timestampField = iotData['updated_at'] ?? iotData['last_update'];
        if (isConnected &&
            timestampField != null &&
            timestampField is Timestamp) {
          final lastUpdateTime = timestampField.toDate().toUtc();
          final nowUtc = DateTime.now().toUtc();
          final diffSeconds = nowUtc.difference(lastUpdateTime).inSeconds;
          if (diffSeconds > 60) {
            isConnected = false;
          }
        }
        status = isConnected ? "Tersambung" : "disconnected";

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFEFFFC8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Colors.black, width: 1.5),
              left: BorderSide(color: Colors.black, width: 1.5),
              right: BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.only(
            left: 25.0,
            right: 25.0,
            top: 15.0,
            bottom: 25.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Center(
                child: const Text(
                  "Detail Kambing",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B341F),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Goat Name
              Center(
                child: Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B341F),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Connection Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Status - ",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7C2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Parameter section
              const Text(
                "Parameter",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // Parameter boxes
              Row(
                children: [
                  _buildDetailMetricBox("Suhu Kambing", suhu),
                  const SizedBox(width: 15),
                  _buildDetailMetricBox("Aktivitas Kambing", aktivitas),
                ],
              ),
              const SizedBox(height: 25),

              // Riwayat Suhu
              const Text(
                "Riwayat Suhu",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: KambingController().getHistory(docId, suhu),
                builder: (context, historySnapshot) {
                  if (historySnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 175,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      ),
                    );
                  }
                  final history = historySnapshot.data ?? [];
                  return TemperatureChartWidget(history: history);
                },
              ),
              const SizedBox(height: 25),

              // Info Fields (Nama, kelamin)
              const Text(
                "Nama",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                nama,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B341F),
                ),
              ),
              const SizedBox(height: 15),

              const Text(
                "kelamin",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                kelamin,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B341F),
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  // Hapus Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _confirmDelete(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444), // Red
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Hapus",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Edit Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close detail bottom sheet
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (sheetCtx) => EditKambingBottomSheet(
                              docId: docId,
                              data: data,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8ED83F), // Green
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              "Edit",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailMetricBox(String label, String value) {
    return Expanded(
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
