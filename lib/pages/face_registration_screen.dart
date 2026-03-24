import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:marooneen/services/face_recognition_service.dart';
import 'package:marooneen/widget/const.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final FaceRecognitionService _faceService = FaceRecognitionService();
  bool _isInit = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _faceService.loadModel(); // Langsung load model TFLite saat UI dibuka
  }

  Future<void> _initCamera() async {
    // Cari daftar semua kamera di HP
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) return;

    // Cari kamera depan (front-facing)
    CameraDescription? frontCamera;
    for (var camera in _cameras!) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }
    
    // Kalau gada kamera depan, pake back camera aja
    frontCamera ??= _cameras!.first;

    // Inisialisasi controller
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium, 
      enableAudio: false,
    );

    await _cameraController!.initialize();
    
    if (mounted) {
      setState(() {
        _isInit = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessing) return; // Mencegah double tap

    setState(() => _isProcessing = true);

    try {
      // 1. Ambil foto
      final XFile image = await _cameraController!.takePicture();
      debugPrint("📷 Foto berhasil diambil: ${image.path}");
      
      // 2. Extraks wajah ke bentuk Angka (192 float)
      final embedding = await _faceService.extractEmbedding(image);

      if (embedding == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('Wajah tidak terdeteksi dengan jelas. Coba lagi!'),
               backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // 3. Tembak langsung ke Firestore
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set(
            {'faceEmbedding': embedding},
            SetOptions(merge: true),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Data Wajah berhasil diregister & tersimpan!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Balik ke profil tab
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error capture: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _cameraController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text('Daftarkan Wajah', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Feed Kamera
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),

          // Overlay (Lingkaran pembantu)
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.greenAccent, width: 4),
              ),
            ),
          ),
          const Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Text(
              "Posisikan wajah Anda\ndi dalam lingkaran",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),

          // Tombol Capture
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: InkWell(
                onTap: _isProcessing ? null : _captureFace,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: const Icon(LucideIcons.camera, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay waktu proses ML ngeriting
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memproses Wajah...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
