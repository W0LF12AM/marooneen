import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marooneen/models/class_model.dart';
import 'package:marooneen/models/attendance_model.dart';
import 'package:marooneen/models/user_profile_model.dart';
import 'package:marooneen/services/attendance_service.dart';
import 'package:marooneen/services/location_service.dart';
import 'package:marooneen/services/user_profile_service.dart';
import 'package:marooneen/services/fraud_service.dart';
import 'package:marooneen/services/device_service.dart';
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
  final FraudService _fraudService = FraudService();
  final DeviceService _deviceService = DeviceService();
  bool _isProcessing = false;
  String _selectedStatus = 'Hadir';
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleAbsen() async {
    setState(() => _isProcessing = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      var currentProfile = await _userProfileService.getProfile(uid);

      if (currentProfile == null) {
        throw Exception("Profil data tak ditemukan!");
      }

      UserProfileModel userProfile = currentProfile; // cast to non-nullable

      // 1. Cek Device Binding (Fraud Device Mapping)
      final deviceInfo = await _deviceService.getDeviceInfo();
      final currentDeviceId = deviceInfo['deviceId'];
      final currentDeviceName = deviceInfo['deviceName'];

      if (userProfile.deviceId == null || userProfile.deviceId!.isEmpty) {
        // Auto-bind device pertama kali saat presensi
        final updatedProfile = UserProfileModel(
          name: userProfile.name,
          kelas: userProfile.kelas,
          npm: userProfile.npm,
          fakultas: userProfile.fakultas,
          jurusan: userProfile.jurusan,
          phone: userProfile.phone,
          gender: userProfile.gender,
          email: userProfile.email,
          birthDate: userProfile.birthDate,
          faceEmbedding: userProfile.faceEmbedding,
          deviceId: currentDeviceId,
          deviceName: currentDeviceName,
        );
        await _userProfileService.saveProfile(uid, updatedProfile);
        userProfile =
            updatedProfile; // pake profil terupdate di proses selanjutnya
      } else {
        // Jika sudah di-bind, cek apakah beda
        if (userProfile.deviceId != currentDeviceId) {
          // Kalo beda, lempar exception dan masukkan ke fraud reports
          await _fraudService.logFraud(
            userId: uid,
            userName: userProfile.name,
            userNpm: userProfile.npm,
            classId: widget.kelas.id,
            className: widget.kelas.kelas,
            fraudType: 'device_mismatch',
            description:
                'Mencoba presensi menggunakan perangkat yang berbeda. '
                'Perangkat terdaftar: ${userProfile.deviceName ?? "Unknown"}, '
                'Perangkat sekarang: $currentDeviceName.',
          );
          throw Exception(
            'Akses ditolak! Anda terdeteksi menggunakan perangkat yang berbeda '
            'dari perangkat utama Anda. Harap gunakan perangkat utama Anda '
            'atau hubungi Admin jika Anda telah mengganti perangkat.',
          );
        }
      }

      // 2. Validasi Alasan
      if (_selectedStatus != 'Hadir' && _reasonController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Harap masukkan alasan/keterangan!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Jika bukan Hadir/Telat, langsung simpan DB tanpa Face/Radius Check
      if (_selectedStatus != 'Hadir' && _selectedStatus != 'Telat') {
        await _attendanceService.submitAttendance(
          widget.kelas,
          uid,
          userProfile.name,
          userProfile.npm,
          statusOverride: _selectedStatus,
          keterangan: _reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Keterangan presensi berhasil dikirim!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // 2. Cek Data Wajah (Hadir / Telat)
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

      // 3. Cek Radius Lokasi (Hadir / Telat)
      final locationResult = await _locationService.checkInRadius(widget.kelas);

      // Fake GPS terdeteksi
      if (locationResult['success'] == false) {
        final errMsg = locationResult['error'] as String;
        final isFakeGps =
            errMsg.toLowerCase().contains('tuyul') ||
            errMsg.toLowerCase().contains('fake') ||
            errMsg.toLowerCase().contains('pemalsu');

        if (isFakeGps) {
          await _fraudService.logFraud(
            userId: uid,
            userName: userProfile.name,
            userNpm: userProfile.npm,
            classId: widget.kelas.id,
            className: widget.kelas.kelas,
            fraudType: 'fake_gps',
            description: 'Aplikasi Fake GPS terdeteksi saat mencoba presensi.',
          );
        }
        throw Exception(errMsg);
      }

      // Di luar radius
      if (locationResult['isInside'] == false) {
        double dist = locationResult['distance'];
        final double? lat = locationResult['latitude'] as double?;
        final double? lng = locationResult['longitude'] as double?;

        await _fraudService.logFraud(
          userId: uid,
          userName: userProfile.name,
          userNpm: userProfile.npm,
          classId: widget.kelas.id,
          className: widget.kelas.kelas,
          fraudType: 'out_of_radius',
          description:
              'Presensi ditolak: berada diluar radius kelas. Jarak: ${dist.toStringAsFixed(1)}m, Radius Kelas: ${widget.kelas.radius}m.',
          latitude: lat,
          longitude: lng,
          distanceFromClass: dist,
        );

        throw Exception(
          'Anda berada diluar batas kelas! Jarak: ${dist.toStringAsFixed(1)}m. Batas GPS Kelas: ${widget.kelas.radius}m',
        );
      }

      // 4. Masuk Ke Proses Validasi Wajah (Hadir / Telat)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FaceVerificationScreen(
              kelas: widget.kelas,
              userProfile: userProfile,
              statusOverride: _selectedStatus == 'Hadir'
                  ? null
                  : _selectedStatus,
              keterangan: _selectedStatus == 'Hadir'
                  ? null
                  : _reasonController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data.userNpm}  •  $timeFormatted WIB',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13,
                                ),
                              ),
                              if (data.keterangan != null &&
                                  data.keterangan!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    data.keterangan!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: data.status == 'Hadir'
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            border: Border.all(
                              color: data.status == 'Hadir'
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                data.status == 'Hadir'
                                    ? LucideIcons.check
                                    : LucideIcons.clockAlert,
                                size: 14,
                                color: data.status == 'Hadir'
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                data.status,
                                style: TextStyle(
                                  color: data.status == 'Hadir'
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown Status
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      icon: const Icon(LucideIcons.chevronDown, size: 16),
                      items: ['Hadir', 'Telat', 'Izin', 'Sakit', 'Pindah Kelas']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedStatus = v!;
                        _reasonController.clear();
                      }),
                    ),
                  ),
                ),
                if (_selectedStatus != 'Hadir') ...[
                  const SizedBox(height: 12),
                  ShadInput(
                    controller: _reasonController,
                    placeholder: const Text(
                      'Masukkan alasan / keterangan (Wajib)',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ShadButton(
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
                      : Text(
                          _selectedStatus == 'Hadir' ||
                                  _selectedStatus == 'Telat'
                              ? 'Presensi Sekarang'
                              : 'Kirim Keterangan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
