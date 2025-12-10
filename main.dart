// main.dart
import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'models/FeedbackResponse.dart';
import 'models/MakeupStep.dart';
import 'screens/camera_screen.dart';

class MakeupAppState extends ChangeNotifier {
  static String get baseUrl => 'http://localhost:8000';

  List<MakeupLook> _looks = [];
  MakeupLook? _selectedLook;
  int _currentStep = 0;

  File? _userImage;
  File? _completedImage;

  Uint8List? _userWebImage;
  Uint8List? _completedWebImage;

  bool _isLoading = false;
  FeedbackResponse? _feedback;

  // ---------------------- GETTERS ----------------------
  Uint8List? get userWebImage => _userWebImage;
  Uint8List? get completedWebImage => _completedWebImage;
  List<MakeupLook> get looks => _looks;
  MakeupLook? get selectedLook => _selectedLook;
  int get currentStep => _currentStep;
  File? get userImage => _userImage;
  File? get completedImage => _completedImage;
  bool get isLoading => _isLoading;
  FeedbackResponse? get feedback => _feedback;

  // ---------------- SAFE NOTIFY LISTENERS ----------------
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // --------------------- SETTERS ------------------------
  void setWebImage(Uint8List bytes, bool completed) {
    if (completed) {
      _completedWebImage = bytes;
    } else {
      _userWebImage = bytes;
    }
    _safeNotify();
  }

  void setUserImage(File image) {
    _userImage = image;
    _safeNotify();
  }

  void setCompletedImage(File image) {
    _completedImage = image;
    _safeNotify();
  }

  // --------------------- FETCH LOOKS ---------------------
  Future<void> fetchLooks() async {
    _isLoading = true;
    _safeNotify();

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/looks'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        _looks = data.map((e) => MakeupLook.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching looks: $e");
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // ---------------- ANALYZE MAKEUP -----------------------
  Future<void> analyzeMakeup() async {
    if ((_userImage == null && _userWebImage == null) ||
        (_completedImage == null && _completedWebImage == null) ||
        _selectedLook == null) {
      debugPrint('Missing data for analysis');
      return;
    }

    _isLoading = true;
    _safeNotify();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/compare-makeup'),
      );

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'original_file',
          _userWebImage!,
          filename: 'original.jpg',
        ));
        request.files.add(http.MultipartFile.fromBytes(
          'current_file',
          _completedWebImage!,
          filename: 'completed.jpg',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
            'original_file', _userImage!.path));
        request.files.add(await http.MultipartFile.fromPath(
            'current_file', _completedImage!.path));
      }

      request.fields['step_index'] = _currentStep.toString();
      request.fields['look_id'] = _selectedLook!.id;

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(body);
        _feedback = FeedbackResponse.fromJson(jsonData);
      } else {
        debugPrint("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Error analyzing: $e');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // ---------------------- STEPS FLOW ----------------------
  void selectLook(MakeupLook look) {
    _selectedLook = look;
    _currentStep = 0;
    _feedback = null;
    _safeNotify();
  }

  void nextStep() {
    if (_selectedLook != null &&
        _currentStep < _selectedLook!.steps.length - 1) {
      _currentStep++;
      _feedback = null;
      _completedImage = null;
      _completedWebImage = null;
      _safeNotify();
    }
  }

  void redoStep() {
    _completedImage = null;
    _completedWebImage = null;
    _feedback = null;
    _safeNotify();
  }
}

// =====================================================
//              FINAL ENTRY POINT
// =====================================================
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MakeupAppState(),
      child: const AuraApp(),
    ),
  );
}

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura AI Makeover',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        brightness: Brightness.light,
      ),
      home: const CameraScreen(),
    );
  }
}
