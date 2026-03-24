import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

class FaceRecognitionService {
  Interpreter? _interpreter;
  
  // Detektor Wajah dari ML Kit
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Load file TFLite dari folder assets
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
    } catch (e) {
      print("Error loading model: \$e");
    }
  }

  /// Menghitung tingkat kemiripan vektor antar 2 wajah dengan Euclidean distance
  double calculateEuclideanDistance(List<double> embeddings1, List<double> embeddings2) {
    if (embeddings1.length != embeddings2.length) return 999.0;
    
    double sum = 0.0;
    for (int i = 0; i < embeddings1.length; i++) {
        double diff = embeddings1[i] - embeddings2[i];
        sum += diff * diff;
    }
    return sqrt(sum); // Nilai < 1.0 biasanya sama, > 1.0 beda orang.
  }

  /// Eksekusi: XFile kamera $\rightarrow$ Cari wajah $\rightarrow$ Crop & Resize $\rightarrow$ Balikin Embedding
  Future<List<double>?> extractEmbedding(XFile file) async {
    // 1. Deteksi Box Wajah pake ML Kit
    final inputImage = InputImage.fromFilePath(file.path);
    final faces = await _faceDetector.processImage(inputImage);

    // Kalo gaada muka yang ke-detect, balikin null
    if (faces.isEmpty) return null;

    // Ambil muka terdepan / terbesar (karena absen muka sendiri)
    final face = faces.first; 

    // 2. Decode foto jadi bytes
    final imageBytes = await file.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);
    
    if (originalImage == null) return null;

    // 3. Crop muka berdasarkan kotak (BoundingBox) yang dapet dari ML Kit
    final boundingBox = face.boundingBox;
    img.Image croppedFace = img.copyCrop(
      originalImage,
      x: boundingBox.left.toInt(),
      y: boundingBox.top.toInt(),
      width: boundingBox.width.toInt(),
      height: boundingBox.height.toInt(),
    );

    // 4. Resize ke 112x112 (Syarat wajib MobileFaceNet)
    img.Image resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

    // 5. Konversi Pixel image jadi List<List<List<double>>> khusus input model TFLite
    // Biasanya RGB Pixel dinormalisasi: (pixel - 127.5) / 128.0
    var input = List.generate(
      1,
      (i) => List.generate(
        112,
        (y) => List.generate(
           112,
           (x) {
             final pixel = resizedFace.getPixel(x, y);
             return [
               (pixel.r - 127.5) / 128.0,
               (pixel.g - 127.5) / 128.0,
               (pixel.b - 127.5) / 128.0,
             ];
           }
        ),
      ),
    );

    // 6. Wadah Array Output. Standarnya MobileFaceNet output [1, 192] (Array sepanjang 192)
    var output = List.generate(1, (i) => List.filled(192, 0.0));

    // 7. Lariin Inference Model-nya
    if (_interpreter != null) {
      _interpreter!.run(input, output);
      return output[0]; // Balikin langsung Array Angkanya, bukan array dalem array
    }
    
    return null;
  }
}
