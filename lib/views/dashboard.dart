import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goatcheck/services/kambing_service.dart';
import 'package:goatcheck/controllers/auth.dart';
import 'package:goatcheck/controllers/kambing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goatcheck/services/notification_service.dart';
import 'package:goatcheck/views/edit_profile.dart';
import 'package:goatcheck/views/widgets/add_kambing_sheet.dart';
import 'package:goatcheck/views/widgets/detail_kambing_sheet.dart';
import 'package:goatcheck/views/riwayat_notifikasi.dart';

class dashboard extends StatefulWidget {
  const dashboard({super.key});

  @override
  State<dashboard> createState() => _dashboardState();
}

class _dashboardState extends State<dashboard> {
  final KambingService _kambingService = KambingService();
  final AuthController _authController = AuthController();
  final KambingController _kambingController = KambingController();
  final NotificationService _notificationService = NotificationService();
  Timer? _timer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(
          () {},
        ); // Periodic rebuild to refresh dynamic status calculation
      }
    });
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
    await _notificationService.requestPermissions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFFC8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFFFC8),
        elevation: 0,
        titleSpacing: 30,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfilePage()),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_outline, color: Colors.black),
              ),
              const SizedBox(width: 12),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('peternak')
                    .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                    .snapshots(),
                builder: (context, userSnapshot) {
                  String userName = "User";
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    userName = userData['nama'] ?? "User";
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _authController.getGreeting(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('riwayat_notifikasi').snapshots(),
            builder: (context, snapshot) {
              final int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RiwayatNotifikasiPage()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Keluar"),
                  content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog
                        await _authController.logout(context: context);
                      },
                      child: const Text(
                        "Keluar",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 25),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _kambingService.getKambingStream(),
        builder: (context, snapshot) {
          int totalHewan = 0;
          List<QueryDocumentSnapshot> listKambing = [];

          if (snapshot.hasData) {
            listKambing = snapshot.data!.docs;
            totalHewan = listKambing.length;
          }

          List<QueryDocumentSnapshot> filteredListKambing = listKambing;
          if (_searchQuery.isNotEmpty) {
            filteredListKambing = listKambing.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final nama = (data['nama'] ?? '').toString().toLowerCase();
              return nama.contains(_searchQuery.toLowerCase());
            }).toList();
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Dashboard Goatcheck",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 20),

                  // Container Ringkasan Utama
                  StreamBuilder<QuerySnapshot>(
                    stream: _kambingService.getPerangkatListStream(),
                    builder: (context, iotSnapshot) {
                      double avgTemp = 0.0;
                      int tempCount = 0;

                      int diamCount = 0;
                      int lambatCount = 0;
                      int aktifCount = 0;
                      int sangatAktifCount = 0;

                      if (iotSnapshot.hasData) {
                        for (var doc in iotSnapshot.data!.docs) {
                          var iotData = doc.data() as Map<String, dynamic>;

                          // Parse suhu
                          double? suhuVal = _kambingController.parseMetricValue(iotData['suhu']);
                          if (suhuVal != null) {
                            avgTemp += suhuVal;
                            tempCount++;
                          }

                          // Klasifikasikan aktivitas ke kategori
                          String? category = _kambingController.classifyActivity(
                            iotData['aktivitas'],
                          );
                          if (category == 'diam') {
                            diamCount++;
                          } else if (category == 'lambat') {
                            lambatCount++;
                          } else if (category == 'sangat aktif') {
                            sangatAktifCount++;
                          } else if (category == 'aktif') {
                            aktifCount++;
                          }
                        }
                      }

                      String displayTemp = tempCount > 0
                          ? "${(avgTemp / tempCount).toStringAsFixed(1)}°C"
                          : "-";

                      int totalCategorized =
                          diamCount +
                          lambatCount +
                          aktifCount +
                          sangatAktifCount;
                      String displayActivity;
                      if (totalCategorized == 0) {
                        displayActivity = "-";
                      } else {
                        // Hitung rata-rata tertimbang (skor numerik) dari aktivitas
                        double avgScore =
                            ((diamCount * 1) +
                                (lambatCount * 2) +
                                (aktifCount * 3) +
                                (sangatAktifCount * 4)) /
                            totalCategorized;

                        int roundedScore = avgScore.round();
                        if (roundedScore == 1) {
                          displayActivity = "Banyak Diam";
                        } else if (roundedScore == 2) {
                          displayActivity = "Lambat";
                        } else if (roundedScore == 3) {
                          displayActivity = "Aktif";
                        } else {
                          displayActivity = "Sangat Aktif";
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bar_chart, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  "Ringkasan Parameter Utama",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildSmallInfoCard(
                                  "Jumlah Hewan",
                                  totalHewan.toString(),
                                ),
                                const SizedBox(width: 10),
                                _buildSmallInfoCard(
                                  "Rata-rata Suhu",
                                  displayTemp,
                                ),
                                const SizedBox(width: 10),
                                _buildSmallInfoCard(
                                  "Rata-rata Aktivitas",
                                  displayActivity,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 25),

                  // Bagian Daftar Kambing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Daftar Kambing",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 23,
                        ),
                      ),

                      // KODE SEARCH BAR & TOMBOL TAMBAH SESUAI PERMINTAAN KAMBU
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 45,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: "Cari Kambing",
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 20,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 20),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    const AddKambingBottomSheet(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B341F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              "Tambah Kambing",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // STREAMBUILDER DATA UTAMA
                      _buildKambingListSection(snapshot, filteredListKambing, isSearching: _searchQuery.isNotEmpty),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper Widget to render kambing list based on snapshot state
  Widget _buildKambingListSection(
    AsyncSnapshot<QuerySnapshot> snapshot,
    List<QueryDocumentSnapshot> listKambing, {
    required bool isSearching,
  }) {
    if (snapshot.hasError) {
      return const Center(child: Text("Terjadi kesalahan memuat data"));
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (listKambing.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            isSearching
                ? "Kambing dengan nama tersebut tidak ditemukan."
                : "Belum ada data kambing.",
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listKambing.length,
      itemBuilder: (context, index) {
        var data = listKambing[index].data() as Map<String, dynamic>;
        String docId = listKambing[index].id;

        return _buildGreenKambingCard(context, docId: docId, data: data);
      },
    );
  }

  // Helper Widget: Kartu Putih Kecil di Ringkasan Utama
  Widget _buildSmallInfoCard(String title, String value) {
    return Expanded(
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Card Hijau Kambing
  Widget _buildGreenKambingCard(
    BuildContext context, {
    required String docId,
    required Map<String, dynamic> data,
  }) {
    String nama = data['nama'] ?? 'Tanpa Nama';

    return StreamBuilder<DocumentSnapshot>(
      stream: _kambingService.getPerangkatStream(docId),
      builder: (context, snapshot) {
        Map<String, dynamic> iotData = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          iotData = snapshot.data!.data() as Map<String, dynamic>;
        }

        String status = iotData['status'] ?? 'Terputus';
        String suhu = iotData['suhu']?.toString() ?? '-';
        String aktivitas = iotData['aktivitas'] ?? '-';

        // Check temperature warning
        double? suhuVal = _kambingController.parseMetricValue(suhu);
        if (suhuVal != null) {
          _kambingController.checkAndNotifyTemp(
            context: context,
            docId: docId,
            name: nama,
            temp: suhuVal,
            notificationService: _notificationService,
          );
        }

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
        status = isConnected ? "Tersambung" : "Terputus";

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF8ED83F),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2205),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7C2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              status,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
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
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7C2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 0.8),
                    ),
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DetailKambingBottomSheet(
                            docId: docId,
                            data: data,
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Lihat Detail",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.more_vert, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildMetricBox("Suhu Kambing", suhu),
                  const SizedBox(width: 8),
                  _buildMetricBox("Aktivitas Kambing", aktivitas),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper Widget: Kotak Nilai di dalam Card Hijau
  Widget _buildMetricBox(String label, String value) {
    return Expanded(
      child: Container(
        height: 75,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F6DC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
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
