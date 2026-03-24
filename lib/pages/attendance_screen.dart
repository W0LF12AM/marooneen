import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marooneen/models/class_model.dart';
import 'package:marooneen/models/attendance_model.dart';
import 'package:marooneen/services/attendance_service.dart';
import 'package:marooneen/services/location_service.dart';
import 'package:marooneen/services/user_profile_service.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:marooneen/pages/face_verification_screen.dart';
import 'package:marooneen/pages/face_registration_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final ClassModel kelas;
  const AttendanceScreen({super.key, required this.kelas});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final LocationService _locationService = LocationService();
  final UserProfileService _userProfileService = UserProfileService();
  bool _isProcessing = false;

  Future<void> _handleAbsen() async {
    setState(() => _isProcessing = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userProfile = await _userProfileService.getProfile(uid);

      if (userProfile == null) {
        throw Exception("Profil data tak ditemukan!");
      }

      // 1. Cek Data Wajah
      if (userProfile.faceEmbedding == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Anda belum memiliki data Rekam Wajah! Arahkan ke Profil.',
            ),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FaceRegistrationScreen()),
        );
        return;
      }

      // 2. Cek Radius Lokasi
      final locationResult = await _locationService.checkInRadius(widget.kelas);
      if (locationResult['success'] == false) {
        throw Exception(locationResult['error']);
      }

      if (locationResult['isInside'] == false) {
        double dist = locationResult['distance'];
        throw Exception(
          'Anda berada diluar batas kelas! Jarak: ${dist.toStringAsFixed(1)}m. Batas GPS Kelas: ${widget.kelas.radius}m',
        );
      }

      // 3. Masuk Ke Proses Validasi Wajah
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FaceVerificationScreen(
              kelas: widget.kelas,
              userProfile: userProfile,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(LucideIcons.arrowLeft, color: secondaryColor),
        ),
        title: Text(
          widget.kelas.kelas,
          style: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Presensi Kelas',
                  style: TextStyle(color: accentColor4, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.kelas.tempat,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(LucideIcons.clock, color: accentColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Jadwal: ${widget.kelas.jam} WIB',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<AttendanceModel>>(
              stream: _attendanceService.getAttendeesForClass(widget.kelas.id),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text('Gagal Load Data Absensi'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final attendees = snapshot.data!;
                if (attendees.isEmpty) {
                  return const Center(
                    child: Text('Belum ada mahasiswa yang presensi.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: attendees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = attendees[index];
                    final isTelat = data.status == 'Telat';

                    final timeFormatted =
                        "${data.timestamp.hour.toString().padLeft(2, '0')}:${data.timestamp.minute.toString().padLeft(2, '0')}";

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
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
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: ShadAvatar(
                          size: const Size(44, 44),
                          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(data.userName)}&background=000000&color=ffffff',
                          placeholder: Text(
                            data.userName.isNotEmpty ? data.userName[0] : '?',
                          ),
                        ),
                        title: Text(
                          data.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${data.userNpm}  •  $timeFormatted WIB',
                            style: TextStyle(color: primaryColor, fontSize: 13),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isTelat
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            border: Border.all(
                              color: isTelat
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isTelat
                                    ? LucideIcons.clockAlert
                                    : LucideIcons.check,
                                size: 14,
                                color: isTelat
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                data.status,
                                style: TextStyle(
                                  color: isTelat
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Tombol Sticky Bawah
          Padding(
            padding: const EdgeInsets.all(20),
            child: ShadButton(
              height: 56,
              backgroundColor: Colors.black,
              width: double.infinity,
              onPressed: _isProcessing ? null : _handleAbsen,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Presensi Sekarang',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
