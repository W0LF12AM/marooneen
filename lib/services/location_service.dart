import 'package:geolocator/geolocator.dart';
import 'package:marooneen/models/class_model.dart';
import 'package:flutter/material.dart';

class LocationService {
  /// Meminta izin lokasi dan mendapatkan posisi titik tengah HP User saat ini
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah servis GPS HP nyala?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('GPS tidak diaktifkan.');
      return Future.error('GPS tidak diaktifkan. Silakan nyalakan lokasi Anda.');
    }

    // 2. Cek status izin akses lokasi ke aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Kalo belum diizinin, minta izin!
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin akses lokasi ditolak.');
      }
    }
    
    // Kalo di-"Don't ask again"
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak permanen. Ubah melalui Setting HP.');
    } 

    // 3. Ambil koordinat saat ini kalau semuanya aman (Pake akurasi tinggi)
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Mengecek perhitungan jarak Haversine antara user dan koordinat kelas
  Future<Map<String, dynamic>> checkInRadius(ClassModel kelasData) async {
    try {
      final Position? position = await getCurrentLocation();

      if (position == null) {
        return {
          'success': false,
          'error': 'Tidak dapat mendapatkan posisi. Pastikan GPS aktif.',
        };
      }
      
      if (position.isMocked) {
        return {
          'success': false,
          'error': 'Aplikasi Fake GPS (Tuyul) terdeteksi! Harap matikan aplikasi pemalsu lokasi Anda untuk presensi.',
        };
      }

      // Hitung jarak (keluarnya dalam satuan meter)
      // Parameter: StartLat, StartLng, EndLat, EndLng
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        kelasData.latitude,
        kelasData.longitude,
      );

      bool isInside = distanceInMeters <= kelasData.radius;
      
      return {
        'success': true,
        'isInside': isInside,
        'distance': distanceInMeters,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
