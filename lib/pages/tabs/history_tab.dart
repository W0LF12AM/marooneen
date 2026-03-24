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
  String _currentFilter = 'Semua';

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

                // Kalkulasi Stat
                int totalHadir = attendances
                    .where((e) => e.status == 'Hadir')
                    .length;
                int totalTelat = attendances
                    .where((e) => e.status == 'Telat')
                    .length;

                // Fitur Filter Lokal
                List<AttendanceModel> filteredAttendances = attendances.where((
                  e,
                ) {
                  if (_currentFilter == 'Semua') return true;
                  if (_currentFilter == 'Bulan Ini') {
                    final now = DateTime.now();
                    return e.timestamp.month == now.month &&
                        e.timestamp.year == now.year;
                  }
                  if (_currentFilter == 'Hadir Saja')
                    return e.status == 'Hadir';
                  if (_currentFilter == 'Telat Saja')
                    return e.status == 'Telat';
                  return true;
                }).toList();

                return Column(
                  children: [
                    // --- STATISTICS CARD ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Hadir',
                              count: totalHadir.toString(),
                              icon: LucideIcons.check,
                              color: Colors.green,
                              bgColor: Colors.green.shade50,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Terlambat',
                              count: totalTelat.toString(),
                              icon: LucideIcons.clockAlert,
                              color: Colors.red,
                              bgColor: Colors.red.shade50,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- FILTER CHIPS ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children:
                            [
                              'Semua',
                              'Bulan Ini',
                              'Hadir Saja',
                              'Telat Saja',
                            ].map((filter) {
                              final isSelected = _currentFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  backgroundColor: isSelected
                                      ? primaryColor
                                      : Colors.white,
                                  side: BorderSide(
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.grey.shade300,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _currentFilter = filter;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                      ),
                    ),

                    // --- LISTVIEW ---
                    Expanded(
                      child: filteredAttendances.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada riwayat untuk filter "$_currentFilter"',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 20,
                                top: 4,
                              ),
                              itemCount: filteredAttendances.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final data = filteredAttendances[index];
                                final isTelat = data.status == 'Telat';
                                final dateFormatted =
                                    "${data.timestamp.day.toString().padLeft(2, '0')}/${data.timestamp.month.toString().padLeft(2, '0')}/${data.timestamp.year}";
                                final timeFormatted =
                                    "${data.timestamp.hour.toString().padLeft(2, '0')}:${data.timestamp.minute.toString().padLeft(2, '0')}";

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
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
                                        color: isTelat
                                            ? Colors.red.shade50
                                            : Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isTelat
                                            ? LucideIcons.clockAlert
                                            : LucideIcons.check,
                                        color: isTelat
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      "${data.className} (Pertemuan ${data.pertemuan})",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '$dateFormatted • Pukul $timeFormatted',
                                      ),
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
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
