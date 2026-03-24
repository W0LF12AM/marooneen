import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marooneen/models/class_model.dart';
import 'package:marooneen/models/user_profile_model.dart';
import 'package:marooneen/services/attendance_service.dart';
import 'package:marooneen/services/face_recognition_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FaceVerificationScreen extends StatefulWidget {
  final ClassModel kelas;
  final UserProfileModel userProfile;

  const FaceVerificationScreen({super.key, required this.kelas, required this.userProfile});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  CameraController? _cameraController;
  final FaceRecognitionService _faceLogic = FaceRecognitionService();
  final AttendanceService _attendanceService = AttendanceService();
  bool _isProcessing = false;
  String _statusMessage = 'Arahkan wajah Anda ke dalam lingkaran...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceLogic.loadModel();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _verifyFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Memverifikasi... Jangan bergerak';
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final capturedEmbedding = await _faceLogic.extractEmbedding(imageFile);

      if (capturedEmbedding == null) {
        throw Exception('Wajah tidak terdeteksi. Paskan dengan layar dan pastikan terang.');
      }

      // Hitung perbedaan Euclidean Distance (Threshold aman sekitar 1.0)
      final registeredEmbedding = widget.userProfile.faceEmbedding!;
      final distance = _faceLogic.calculateEuclideanDistance(registeredEmbedding, capturedEmbedding);

      if (distance < 1.0) {
        // MATCH: Absen lolos
        setState(() => _statusMessage = 'Wajah Cocok! Menyimpan presensi...');
        
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await _attendanceService.submitAttendance(
           widget.kelas, 
           uid, 
           widget.userProfile.name, 
           widget.userProfile.npm,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Presensi berhasil terekam!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Kembali ke halaman absen kelas
        }

      } else {
        // NOT MATCH
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('❌ Wajah tidak mirip! (Score Diff: ${distance.toStringAsFixed(2)})'), backgroundColor: Colors.red),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() {
        _isProcessing = false;
        _statusMessage = 'Coba lagi jika gagal';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Verifikasi Wajah', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // Custom Mask Overlay (Bulat ditengah)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(150),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status & Capture Button
          Positioned(
            bottom: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusMessage, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isProcessing ? null : _verifyFace,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isProcessing ? Colors.grey : Colors.white,
                      border: Border.all(color: Colors.grey.shade400, width: 4),
                    ),
                    child: _isProcessing
                        ? const Center(child: CircularProgressIndicator(color: Colors.black))
                        : const Icon(LucideIcons.camera, size: 36, color: Colors.black),
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
