import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marooneen/models/attendance_model.dart';
import 'package:marooneen/services/attendance_service.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final AttendanceService _attendanceService = AttendanceService();
  String _uid = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uid = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: const Text(
          'Riwayat Presensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: secondaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _uid.isEmpty
          ? const Center(child: Text('User tidak ditemukan'))
          : StreamBuilder<List<AttendanceModel>>(
              stream: _attendanceService.getUserAttendances(_uid),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text('Gagal Load Riwayat'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final attendances = snapshot.data!;
                if (attendances.isEmpty) {
                  return const Center(
                    child: Text(
                      'Anda belum memiliki riwayat presensi.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: attendances.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = attendances[index];
                    final isTelat = data.status == 'Telat';
                    final dateFormatted =
                        "${data.timestamp.day.toString().padLeft(2, '0')}/${data.timestamp.month.toString().padLeft(2, '0')}/${data.timestamp.year}";
                    final timeFormatted =
                        "${data.timestamp.hour.toString().padLeft(2, '0')}:${data.timestamp.minute.toString().padLeft(2, '0')}";

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isTelat ? Colors.red.shade50 : accentColor3,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTelat ? LucideIcons.clock : LucideIcons.check,
                            color: isTelat ? Colors.red : accentColor4,
                          ),
                        ),
                        title: Text(
                          "${data.className} (Pertemuan ${data.pertemuan})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('$dateFormatted • Pukul $timeFormatted'),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isTelat
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data.status,
                            style: TextStyle(
                              color: isTelat
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
