import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goatcheck/services/kambing_service.dart';
import 'package:goatcheck/controllers/auth.dart';
import 'package:goatcheck/controllers/kambing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goatcheck/services/notification_service.dart';

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
  final Set<String> _notifiedGoats = {};

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
        title: Row(
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
                      _getGreeting(),
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
        actions: [
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return "Halo, Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      return "Halo, Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      return "Halo, Selamat Sore";
    } else {
      return "Halo, Selamat Malam";
    }
  }

  void _checkAndNotifyTemp(String docId, String name, double temp) {
    if (temp >= 35.0) {
      if (!_notifiedGoats.contains(docId)) {
        _notifiedGoats.add(docId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTempWarningNotification(name, temp);
          _notificationService.showNotification(
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

  void _showTempWarningNotification(String name, double temp) {
    if (!mounted) return;
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
          _checkAndNotifyTemp(docId, nama, suhuVal);
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

// Bottom Sheet to add new goat details matching user requirements
class AddKambingBottomSheet extends StatefulWidget {
  const AddKambingBottomSheet({super.key});

  @override
  State<AddKambingBottomSheet> createState() => _AddKambingBottomSheetState();
}

class _AddKambingBottomSheetState extends State<AddKambingBottomSheet> {
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _saveKambing() async {
    await KambingController().saveKambing(
      context: context,
      deviceId: _deviceIdController.text.trim(),
      nama: _namaController.text.trim(),
      jenisKelamin: _selectedGender,
      tanggalLahir: _selectedDate,
      onStartLoading: () {
        if (mounted) setState(() => _isLoading = true);
      },
      onEndLoading: () {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
      padding: EdgeInsets.only(
        left: 25.0,
        right: 25.0,
        top: 15.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab Handle
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "Tambah Kambing",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B341F),
              ),
            ),
            const SizedBox(height: 25),

            // Device ID
            TextField(
              controller: _deviceIdController,
              decoration: InputDecoration(
                hintText: 'Id perangkat',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(
                  Icons.vpn_key_outlined,
                  color: Colors.black,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Goat Name
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                hintText: 'nama kambing',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: Colors.black,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Gender & Date picker Row
            Row(
              children: [
                // Gender Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    hint: const Text(
                      'jenis kelamin',
                      style: TextStyle(color: Colors.black38, fontSize: 14),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Jantan', child: Text('Jantan')),
                      DropdownMenuItem(value: 'Betina', child: Text('Betina')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedGender = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 15),

                // Date Picker
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'tanggal lahir'
                                  : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}",
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? Colors.black38
                                    : Colors.black,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveKambing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF8ED83F,
                  ), // Matching theme green
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(
                    0xFF8ED83F,
                  ).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 1.2),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            "Simpan",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  Future<List<Map<String, dynamic>>> _getHistory(String docId, String currentSuhu) async {
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
    double latestTemp = KambingController().parseMetricValue(currentSuhu) ?? 38.2;
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
              const Center(
                child: Text(
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
                future: _getHistory(docId, suhu),
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

// Edit Bottom Sheet
class EditKambingBottomSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditKambingBottomSheet({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditKambingBottomSheet> createState() => _EditKambingBottomSheetState();
}

class _EditKambingBottomSheetState extends State<EditKambingBottomSheet> {
  late final TextEditingController _deviceIdController;
  late final TextEditingController _namaController;
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _deviceIdController = TextEditingController(text: widget.docId);
    _namaController = TextEditingController(text: widget.data['nama'] ?? '');
    _selectedGender = widget.data['jenis_kelamin'];

    // Parse date if possible
    String? dobStr = widget.data['tanggal_lahir'];
    if (dobStr != null && dobStr.contains('/')) {
      try {
        List<String> parts = dobStr.split('/');
        if (parts.length == 3) {
          _selectedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _updateKambing() async {
    await KambingController().updateKambing(
      context: context,
      docId: widget.docId,
      deviceId: _deviceIdController.text.trim(),
      nama: _namaController.text.trim(),
      jenisKelamin: _selectedGender,
      tanggalLahir: _selectedDate,
      onStartLoading: () {
        if (mounted) setState(() => _isLoading = true);
      },
      onEndLoading: () {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
      padding: EdgeInsets.only(
        left: 25.0,
        right: 25.0,
        top: 15.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab Handle
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "Edit Kambing",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B341F),
              ),
            ),
            const SizedBox(height: 25),

            // Device ID
            TextField(
              controller: _deviceIdController,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Id perangkat',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(
                  Icons.vpn_key_outlined,
                  color: Colors.black54,
                ),
                filled: true,
                fillColor: Colors.black12,
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black26, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Goat Name
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                hintText: 'nama kambing',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: Colors.black,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Gender & Date picker Row
            Row(
              children: [
                // Gender Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    hint: const Text(
                      'jenis kelamin',
                      style: TextStyle(color: Colors.black38, fontSize: 14),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Jantan', child: Text('Jantan')),
                      DropdownMenuItem(value: 'Betina', child: Text('Betina')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedGender = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 15),

                // Date Picker
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'tanggal lahir'
                                  : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}",
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? Colors.black38
                                    : Colors.black,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Save/Update Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateKambing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF8ED83F,
                  ), // Matching theme green
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(
                    0xFF8ED83F,
                  ).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 1.2),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            "Simpan Perubahan",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TemperatureChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const TemperatureChartWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("Tidak ada data riwayat suhu")),
      );
    }

    return Container(
      height: 170,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, right: 15, top: 15, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: CustomPaint(
        painter: TemperatureChartPainter(history),
      ),
    );
  }
}

class TemperatureChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> history;

  TemperatureChartPainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    // Dimensions and paddings
    const double leftPadding = 35.0;
    const double bottomPadding = 20.0;
    const double topPadding = 10.0;
    const double rightPadding = 5.0;

    final double plotWidth = size.width - leftPadding - rightPadding;
    final double plotHeight = size.height - topPadding - bottomPadding;

    // Paint styling
    final paintLine = Paint()
      ..color = const Color(0xFF3B341F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFF8ED83F)
      ..style = PaintingStyle.fill;

    final paintDotBorder = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintAxes = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintGrid = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Find min and max values for scaling
    double minTemp = 100.0;
    double maxTemp = 0.0;
    for (var point in history) {
      double temp = (point['suhu'] as num).toDouble();
      if (temp < minTemp) minTemp = temp;
      if (temp > maxTemp) maxTemp = temp;
    }

    // Adjust temperature scale slightly for padding
    if (maxTemp == minTemp) {
      maxTemp += 1.0;
      minTemp -= 1.0;
    } else {
      double diff = maxTemp - minTemp;
      maxTemp += diff * 0.2;
      minTemp -= diff * 0.2;
    }

    // Draw grid lines and Y-axis labels
    const int gridCount = 4;
    for (int i = 0; i < gridCount; i++) {
      double ratio = i / (gridCount - 1);
      double tempVal = minTemp + (maxTemp - minTemp) * ratio;
      double y = topPadding + plotHeight - (ratio * plotHeight);

      // Draw horizontal grid line
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        paintGrid,
      );

      // Draw Y-axis label text
      final textSpan = TextSpan(
        text: "${tempVal.toStringAsFixed(1)}°",
        style: const TextStyle(
          fontSize: 9,
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Calculate plotting points coordinates
    final int count = history.length;
    final double stepX = count > 1 ? plotWidth / (count - 1) : plotWidth;
    final List<Offset> points = [];

    for (int i = 0; i < count; i++) {
      double temp = (history[i]['suhu'] as num).toDouble();
      double x = leftPadding + (i * stepX);
      double y = topPadding + plotHeight - ((temp - minTemp) / (maxTemp - minTemp) * plotHeight);
      points.add(Offset(x, y));

      // Draw X-axis label text (time)
      final timestamp = history[i]['timestamp'] as Timestamp;
      final date = timestamp.toDate();
      final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

      final textSpan = TextSpan(
        text: timeStr,
        style: const TextStyle(
          fontSize: 8,
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 5),
      );
    }

    // Draw gradient fill below line
    final pathFill = Path();
    pathFill.moveTo(points.first.dx, topPadding + plotHeight);
    for (var p in points) {
      pathFill.lineTo(p.dx, p.dy);
    }
    pathFill.lineTo(points.last.dx, topPadding + plotHeight);
    pathFill.close();

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8ED83F).withOpacity(0.4),
          const Color(0xFF8ED83F).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(leftPadding, topPadding, size.width - rightPadding, topPadding + plotHeight));

    canvas.drawPath(pathFill, paintFill);

    // Draw line (smooth bezier)
    final pathLine = Path();
    pathLine.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      pathLine.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p2.dx, p2.dy,
      );
    }
    canvas.drawPath(pathLine, paintLine);

    // Draw axes lines (L-shape)
    // Vertical Y-axis
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + plotHeight),
      paintAxes,
    );
    // Horizontal X-axis
    canvas.drawLine(
      Offset(leftPadding, topPadding + plotHeight),
      Offset(size.width - rightPadding, topPadding + plotHeight),
      paintAxes,
    );

    // Draw dots
    for (var p in points) {
      canvas.drawCircle(p, 5, paintDot);
      canvas.drawCircle(p, 5, paintDotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
