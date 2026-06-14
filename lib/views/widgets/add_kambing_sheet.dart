import 'package:flutter/material.dart';
import 'package:goatcheck/controllers/kambing.dart';

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
                  backgroundColor: const Color(0xFF8ED83F), // Matching theme green
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF8ED83F).withOpacity(0.5),
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
