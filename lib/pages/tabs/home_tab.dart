import 'package:flutter/material.dart';
import 'package:marooneen/models/class_model.dart';
import 'package:marooneen/models/user_profile_model.dart';
import 'package:marooneen/pages/components/class_card.dart';
import 'package:marooneen/pages/components/user_profile_card.dart';
import 'package:marooneen/services/class_service.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.profile});

  final UserProfileModel profile;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ClassService _classService = ClassService();
  String search = '';

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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  ShadButton.outline(
                    width: 48,
                    height: 48,
                    padding: EdgeInsets.zero,
                    decoration: ShadDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: ShadBorder.all(color: Colors.grey.shade200),
                    ),
                    onPressed: () {},
                    child: Icon(
                      LucideIcons.bell,
                      size: 20,
                      color: primaryColor,
                    ),
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
