import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marooneen/models/user_profile_model.dart';
import 'package:marooneen/pages/face_registration_screen.dart';
import 'package:marooneen/pages/support_ticket_screen.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.profile});

  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            // ─── AVATAR SECTION ───
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: ShadAvatar(
                      size: const Size(110, 110),
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile.name)}&background=000000&color=ffffff&size=200',
                      placeholder: Text(
                        profile.name.isNotEmpty ? profile.name[0] : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: secondaryColor, width: 3),
                    ),
                    child: Icon(
                      LucideIcons.camera,
                      color: secondaryColor,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── USER INFO SECTION ───
            Text(
              profile.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${profile.jurusan} - ${profile.fakultas}',
              style: TextStyle(
                fontSize: 15,
                color: accentColor4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // ─── DATA KARTU SECTION ───
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(LucideIcons.hash, 'NPM', profile.npm),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildInfoRow(LucideIcons.school, 'Kelas', profile.kelas),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildInfoRow(
                    LucideIcons.building,
                    'Fakultas',
                    profile.fakultas,
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildInfoRow(
                    LucideIcons.bookOpen,
                    'Jurusan',
                    profile.jurusan,
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildInfoRow(
                    LucideIcons.phone,
                    'No. HP',
                    profile.phone.isNotEmpty ? profile.phone : '-',
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildInfoRow(
                    LucideIcons.mail,
                    'Email',
                    profile.email ?? '-',
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildInfoRow(
                    LucideIcons.calendar,
                    'Tgl Lahir',
                    profile.birthDate ?? '-',
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _buildInfoRow(
                    LucideIcons.user,
                    'Gender',
                    profile.gender.isNotEmpty ? profile.gender : '-',
                  ),

                  // Kalau data wajah UDAH ADA, masukin sini nyatu
                  if (profile.faceEmbedding != null) ...[
                    Divider(height: 1, color: Colors.grey.shade100),
                    _buildInfoRow(
                      LucideIcons.check,
                      'Data Wajah',
                      'Terekam',
                      valueColor: Colors.green.shade600,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── SETUP WAJAH JIKA BELUM REKAM ───
            if (profile.faceEmbedding == null) ...[
              Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor3,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.scanFace, color: secondaryColor),
                  ),
                  title: Text(
                    'Data Wajah',
                    style: TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Daftarkan wajah untuk absensi',
                    style: TextStyle(color: accentColor, fontSize: 13),
                  ),
                  trailing: Icon(LucideIcons.chevronRight, color: accentColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaceRegistrationScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],

            // ─── BANTUAN / SUPPORT TICKET ───
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.lifeBuoy, color: primaryColor),
                ),
                title: const Text(
                  'Bantuan & Support',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Pusat bantuan jika ada kendala',
                  style: TextStyle(color: accentColor4, fontSize: 13),
                ),
                trailing: Icon(LucideIcons.chevronRight, color: accentColor4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupportTicketScreen(
                        userName: profile.name,
                        userNpm: profile.npm,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ─── LOGOUT BUTTON ───
            ShadButton.outline(
              width: double.infinity,
              decoration: ShadDecoration(
                shape: BoxShape.rectangle,
                border: ShadBorder.all(
                  radius: const BorderRadius.all(Radius.circular(16)),
                  color: Colors.red.shade200,
                  width: 1.5,
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      'Konfirmasi Keluar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'Apakah Anda yakin ingin keluar dari akun ini?',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      ShadButton.outline(
                        child: const Text('Batal'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),

                      ShadButton.destructive(
                        child: const Text('Ya, Keluar'),
                        onPressed: () {
                          Navigator.pop(context); // Tutup dialog
                          FirebaseAuth.instance.signOut(); // Log out eksekusi
                        },
                      ),
                      // TextButton(
                      //   onPressed: () => Navigator.pop(context),
                      //   child: const Text('Batal', style: TextStyle(color: Colors.black)),
                      // ),
                      // TextButton(
                      //   onPressed: () {
                      //     Navigator.pop(context); // Tutup dialog
                      //     FirebaseAuth.instance.signOut(); // Log out eksekusi
                      //   },
                      //   child: const Text('Ya, Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      // ),
                    ],
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(
                    //   LucideIcons.logOut,
                    //   size: 20,
                    //   color: Colors.red.shade600,
                    // ),
                    // const SizedBox(width: 12),
                    Text(
                      'Keluar Akun',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper widget buat bikin row info (NPM, Kelas, dll)
  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: accentColor4, size: 20),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: accentColor4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color:
                  valueColor ??
                  Colors
                      .black, // Pake default warna hitam kalo valueColor kosong
            ),
          ),
        ],
      ),
    );
  }
}
