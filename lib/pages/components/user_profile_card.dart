import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marooneen/models/user_profile_model.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class UserProfileCard extends StatefulWidget {
  UserProfileCard({super.key, required this.profile});

  final UserProfileModel profile;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              ShadAvatar(
                size: const Size(40, 40),
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.profile.name)}&background=ffffff&color=000000',
                placeholder: Text(
                  widget.profile.name.isNotEmpty ? widget.profile.name[0] : '?',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.profile.npm}  •  Kelas ${widget.profile.kelas}',
                      style: TextStyle(color: accentColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
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
                            widget._auth.signOut(); // Log out eksekusi
                          },
                        ),
                        // TextButton(
                        //   onPressed: () => Navigator.pop(context),
                        //   child: const Text('Batal', style: TextStyle(color: Colors.black)),
                        // ),
                        // TextButton(
                        //   onPressed: () {
                        //     Navigator.pop(context); // Tutup dialog
                        //     widget._auth.signOut(); // Log out eksekusi
                        //   },
                        //   child: const Text('Ya, Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        // ),
                      ],
                    ),
                  );
                },
                icon: Icon(LucideIcons.logOut, color: secondaryColor, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
