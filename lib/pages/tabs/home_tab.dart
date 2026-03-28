import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marooneen/models/class_model.dart';
import 'package:marooneen/models/user_profile_model.dart';
import 'package:marooneen/pages/components/class_card.dart';
import 'package:marooneen/pages/components/user_profile_card.dart';
import 'package:marooneen/pages/notification_screen.dart';
import 'package:marooneen/services/class_service.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.profile});

  final UserProfileModel profile;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ClassService _classService = ClassService();
  String search = '';
  List<String> _readBroadcasts = [];

  @override
  void initState() {
    super.initState();
    _loadUnreadStatus();
  }

  Future<void> _loadUnreadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readBroadcasts = prefs.getStringList('readBroadcasts') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      // Menggunakan SafeArea & custom header ala modern-apps, tanpa AppBar default
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── CUSTOM HEADER ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Beranda',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('broadcasts')
                        .snapshots(),
                    builder: (context, broadcastSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        // Ambil notifikasi dari Firestore untuk dot merah (biar gak bentrok index kita tidak pakai Where isRead)
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where(
                              'userNpm',
                              whereIn: [widget.profile.npm, 'all'],
                            )
                            .snapshots(),
                        builder: (context, notifSnapshot) {
                          int unreadCount = 0;

                          // 1. Cek dari Notifikasi Biasa
                          if (notifSnapshot.hasData) {
                            for (var doc in notifSnapshot.data!.docs) {
                              var data = doc.data() as Map<String, dynamic>;
                              if (data['isRead'] == false) {
                                unreadCount++;
                              }
                            }
                          }

                          // 2. Cek dari Broadcasts
                          if (broadcastSnapshot.hasData) {
                            for (var doc in broadcastSnapshot.data!.docs) {
                              if (!_readBroadcasts.contains(doc.id)) {
                                unreadCount++;
                              }
                            }
                          }

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ShadButton.outline(
                                width: 48,
                                height: 48,
                                padding: EdgeInsets.zero,
                                decoration: ShadDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: ShadBorder.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NotificationScreen(
                                        userNpm: widget.profile.npm,
                                      ),
                                    ),
                                  ).then((_) {
                                    _loadUnreadStatus(); // Refresh badge saat kembali
                                  });
                                },
                                child: Icon(
                                  LucideIcons.bell,
                                  size: 20,
                                  color: primaryColor,
                                ),
                              ),

                              // UNREAD DOT MERAH + COUNT
                              if (unreadCount > 0)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // ─── USER PROFILE CARD ───
            UserProfileCard(profile: widget.profile),
            const SizedBox(height: 24),

            // ─── SEARCH / FILTER BAR ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShadInput(
                onChanged: (value) {
                  setState(() {
                    search = value.toLowerCase();
                  });
                },
                selectionColor: primaryColor,
                leading: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(LucideIcons.search, size: 20, color: Colors.grey),
                ),
                placeholder: Text(
                  'Cari Kelas atau Mata Kuliah...',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                trailing: const Icon(LucideIcons.slidersHorizontal, size: 20),
                decoration: ShadDecoration(
                  border: ShadBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                    radius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  color: Colors.white,
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── DAFTAR KELAS TITLE ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Jadwal Kelas Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),

            // ─── KELAS LISTVIEW ───
            Expanded(
              child: StreamBuilder<List<ClassModel>>(
                stream: _classService.streamKelas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final kelasList = snapshot.data ?? [];
                  final now = DateTime.now();
                  final filteredKelas = kelasList.where((kelas) {
                    final isToday =
                        kelas.tanggal.year == now.year &&
                        kelas.tanggal.month == now.month &&
                        kelas.tanggal.day == now.day;

                    final matchesSearch = kelas.kelas.toLowerCase().contains(
                      search,
                    );

                    return isToday && matchesSearch;
                  }).toList();

                  if (kelasList.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada jadwal kelas',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      top: 4,
                    ),
                    itemCount: filteredKelas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final kelas = filteredKelas[index];
                      return ClassCard(
                        kelas: kelas,
                      ); // Udah pakai corner radius di dalem classnya
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
