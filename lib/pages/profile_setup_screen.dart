import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marooneen/models/user_profile_model.dart';
import 'package:marooneen/pages/components/profile_widget.dart';
import 'package:marooneen/services/user_profile_service.dart';
import 'package:marooneen/services/device_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _npmController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _kelasController = TextEditingController();
  final _fakultasController = TextEditingController();
  final _jurusanController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;

  final UserProfileService _profileService = UserProfileService();
  final DeviceService _deviceService = DeviceService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _npmController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _kelasController.dispose();
    _fakultasController.dispose();
    _jurusanController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate Step 1
    if (_nameController.text.trim().isEmpty ||
        _npmController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _birthDateController.text.trim().isEmpty ||
        _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi data diri terlebih dahulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _currentStep = 1;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep = 0;
    });
  }

  void _confirmSave() {
    // Validate Step 2
    if (_kelasController.text.trim().isEmpty ||
        _fakultasController.text.trim().isEmpty ||
        _jurusanController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data akademik wajib diisi ya!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tampilkan Peringatan Gak Bisa Edit
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Data',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah Anda yakin data yang diisi sudah benar?\n\n'
            'Data profil ini (Nama, NPM, Fakultas, Jurusan, dll) '
            'bersifat permanen dan tidak dapat diubah lagi setelah disimpan.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cek Lagi',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _processSaveProfile();
              },
              child: const Text('Yakin & Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processSaveProfile() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final deviceInfo = await _deviceService.getDeviceInfo();

      final profile = UserProfileModel(
        name: _nameController.text.trim(),
        npm: _npmController.text.trim(),
        email: _emailController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        kelas: _kelasController.text.trim(),
        fakultas: _fakultasController.text.trim(),
        jurusan: _jurusanController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender!,
        deviceId: deviceInfo['deviceId'],
        deviceName: deviceInfo['deviceName'],
      );
      await _profileService.saveProfile(uid, profile);
      // Gak perlu navigator pop, AuthRoute stream bakal redirect otomatis
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      children: [
        ShadInput(
          controller: _nameController,
          placeholder: const Text('Nama Lengkap (Sesuai KTP/KTM)'),
          leading: const Icon(LucideIcons.user, size: 20),
        ),
        const SizedBox(height: 12),
        ShadInput(
          controller: _npmController,
          placeholder: const Text('NPM Mahasiswa'),
          leading: const Icon(LucideIcons.hash, size: 20),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        ShadInput(
          controller: _emailController,
          placeholder: const Text('Email'),
          leading: const Icon(LucideIcons.mail, size: 20),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: ShadInput(
              controller: _birthDateController,
              placeholder: const Text('Tanggal Lahir'),
              leading: const Icon(LucideIcons.calendar, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Dropdown Gender
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.users,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    hint: const Text(
                      'Pilih Jenis Kelamin',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    isExpanded: true,
                    icon: const Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Laki-laki',
                        child: Text(
                          'Laki-laki',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Perempuan',
                        child: Text(
                          'Perempuan',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedGender = v!),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ShadButton(
          backgroundColor: Colors.black,
          width: double.infinity,
          onPressed: _nextStep,
          child: const Text(
            'Selanjutnya',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(2),
      children: [
        ShadInput(
          controller: _kelasController,
          placeholder: const Text('Kelas (contoh: A)'),
          leading: const Icon(LucideIcons.school, size: 20),
        ),
        const SizedBox(height: 12),
        ShadInput(
          controller: _fakultasController,
          placeholder: const Text('Fakultas (contoh: FMIPA)'),
          leading: const Icon(LucideIcons.building, size: 20),
        ),
        const SizedBox(height: 12),
        ShadInput(
          controller: _jurusanController,
          placeholder: const Text('Jurusan (contoh: Ilmu Komputer)'),
          leading: const Icon(LucideIcons.bookOpen, size: 20),
        ),
        const SizedBox(height: 12),
        ShadInput(
          controller: _phoneController,
          placeholder: const Text('No Handphone'),
          leading: const Icon(LucideIcons.phone, size: 20),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: ShadButton.outline(
                onPressed: _prevStep,
                child: const Text('Kembali'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ShadButton(
                backgroundColor: Colors.black,
                onPressed: _isLoading ? null : _confirmSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ProfileWidget(),
              const SizedBox(height: 16),
              Text(
                _currentStep == 0 ? 'Langkah 1: Data Diri' : 'Langkah 2: Data Akademik',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
