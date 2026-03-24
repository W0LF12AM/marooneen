import 'package:flutter/material.dart';
import 'package:marooneen/models/user_profile_model.dart';
import 'package:marooneen/pages/tabs/history_tab.dart';
import 'package:marooneen/pages/tabs/home_tab.dart';
import 'package:marooneen/pages/tabs/profile_tab.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, required this.profile});

  final UserProfileModel profile;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(profile: widget.profile),
      const HistoryTab(),
      ProfileTab(profile: widget.profile),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      body: _pages[_selectedIndex],
      // Container sebagai pembungkus bikin border tipis di atas navbar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: secondaryColor,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0, // Hilangin efek bayangan default Material
          backgroundColor: secondaryColor,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.house, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.house, size: 24),
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.history, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.history, size: 24),
              ),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.user, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(LucideIcons.user, size: 24),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
