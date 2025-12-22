// AI Makeup Tutorial App - Final Connected Version
// Works on Web + Android
// Backend: https://backend-kzoy.onrender.com
// Requires: http, image_picker, provider

import 'dart:convert';
import 'dart:io' show File;

import 'package:aura_mobile_app/models/FeedbackResponse.dart';
import 'package:aura_mobile_app/screens/StepScreen.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // ✅ Make sure provider is imported

import '../models/MakeupStep.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MakeupAppState(),
      child: const MakeupTutorialApp(),
    ),
  );
}

class MakeupTutorialApp extends StatelessWidget {
  const MakeupTutorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Makeup Tutor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const StepScreen(),
    );
  }
}

// ---------------------- STATE ----------------------
class MakeupAppState extends ChangeNotifier {
  /// 🔗 Connect to your live backend here
  static String get baseUrl => 'http://10.16.120.146:8000';

  List<MakeupLook> _looks = [];
  MakeupLook? _selectedLook;
  int _currentStep = 0;
  File? _userImage;
  File? _completedImage;
  FeedbackResponse? _feedback;
  bool _isLoading = false;

  Uint8List? _userWebImage;
  Uint8List? _completedWebImage;

  Uint8List? get userWebImage => _userWebImage;
  Uint8List? get completedWebImage => _completedWebImage;
  List<MakeupLook> get looks => _looks;
  MakeupLook? get selectedLook => _selectedLook;
  int get currentStep => _currentStep;
  File? get userImage => _userImage;
  File? get completedImage => _completedImage;
  FeedbackResponse? get feedback => _feedback;
  bool get isLoading => _isLoading;

  void setWebImage(Uint8List bytes, bool completed) {
    if (completed) {
      _completedWebImage = bytes;
    } else {
      _userWebImage = bytes;
    }
    notifyListeners();
  }

  Future<void> fetchLooks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/looks'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        _looks = data.map((e) => MakeupLook.fromJson(e)).toList();
      } else {
        _looks = [];
      }
    } catch (e) {
      debugPrint("Error fetching looks: $e");
      _looks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectLook(MakeupLook look) {
    _selectedLook = look;
    _currentStep = 0;
    _feedback = null;
    notifyListeners();
  }

  void setUserImage(File image) {
    _userImage = image;
    notifyListeners();
  }

  void setCompletedImage(File image) {
    _completedImage = image;
    notifyListeners();
  }

  Future<void> analyzeMakeup() async {
    if ((_userImage == null && _userWebImage == null) ||
        (_completedImage == null && _completedWebImage == null) ||
        _selectedLook == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/compare-makeup'),
      );

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
            'original_file', _userWebImage!,
            filename: 'original.jpg'));
        request.files.add(http.MultipartFile.fromBytes(
            'current_file', _completedWebImage!,
            filename: 'current.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
            'original_file', _userImage!.path));
        request.files.add(await http.MultipartFile.fromPath(
            'current_file', _completedImage!.path));
      }

      request.fields['step_index'] = _currentStep.toString();
      request.fields['look_id'] = _selectedLook!.id;

      var response = await request.send();
      var body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _feedback = FeedbackResponse.fromJson(json.decode(body));
      } else {
        debugPrint("Error: ${response.statusCode} - $body");
      }
    } catch (e) {
      debugPrint('Error analyzing makeup: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_selectedLook != null &&
        _currentStep < _selectedLook!.steps.length - 1) {
      _currentStep++;
      _feedback = null;
      _completedImage = null;
      _completedWebImage = null;
      notifyListeners();
    }
  }

  void redoStep() {
    _completedImage = null;
    _completedWebImage = null;
    _feedback = null;
    notifyListeners();
  }

  void reset() {
    _selectedLook = null;
    _currentStep = 0;
    _feedback = null;
    _userImage = null;
    _completedImage = null;
    _userWebImage = null;
    _completedWebImage = null;
    _looks.clear();
    notifyListeners();
  }
}
