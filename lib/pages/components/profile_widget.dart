import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 48,
            width: 48,
            child: Center(
              child: Text(
                'M',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Lengkapi Profil Kamu',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Profil wajib diisi sebelum menggunakan aplikasi',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        SizedBox(height: 4),
        Text(
          'Masukkan data asli, data tidak dapat diubah!',
          style: TextStyle(color: Colors.red.shade400, fontSize: 13),
        ),
      ],
    );
  }
}
