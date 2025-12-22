import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';

import '../models/makeup_guide_models.dart';
import '../services/makeup_guide_service.dart';
import '../widgets/comparison_widget.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/makeup_selection_widget.dart';
import '../widgets/step_guide_widget.dart';

class MakeupGuideScreen extends StatefulWidget {
  const MakeupGuideScreen({super.key});

  @override
  State<MakeupGuideScreen> createState() => _MakeupGuideScreenState();
}

class _MakeupGuideScreenState extends State<MakeupGuideScreen> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes; // BEFORE image
  Uint8List? _afterBytes; // AFTER image

  List<String> _selectedLooks = [];
  List<MakeupGuideStep> _guideSteps = [];

  int _currentStep = 0;
  bool _isLoading = false;
  String _loadingMessage = '';
  bool _showComparison = false;

  MakeupComparisonData? _comparisonData;

  Color _lipstickColor = Colors.red;
  String? _lipstickHex;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  // ==========================================================
  // HEALTH CHECK
  // ==========================================================
  Future<void> _checkBackendHealth() async {
    final ok = await MakeupGuideService.checkHealth();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Makeup Guide API not reachable")),
      );
    }
  }

  // ==========================================================
  // PICK BEFORE IMAGE
  // ==========================================================
  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return;

      _imageBytes = await file.readAsBytes();

      setState(() {
        _guideSteps = [];
        _selectedLooks = [];
        _currentStep = 0;
        _showComparison = false;
        _afterBytes = null;
        _comparisonData = null;
      });

      _analyzeFace();
    } catch (e) {
      _showError("Image selection error: $e");
    }
  }

  // ==========================================================
  // ANALYZE FACE
  // ==========================================================
  Future<void> _analyzeFace() async {
    if (_imageBytes == null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "Analyzing face…";
    });

    try {
      await MakeupGuideService.analyzeFace(_imageBytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✨ Face detected! Choose looks.")),
        );
      }
    } catch (e) {
      _showError("Face analysis failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = "";
        });
      }
    }
  }

  // ==========================================================
  // GENERATE MAKEUP GUIDE
  // ==========================================================
  Future<void> _generateGuide() async {
    if (_imageBytes == null || _selectedLooks.isEmpty) {
      _showError("Pick an image + select at least one makeup type");
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = "Creating makeup guide…";
    });

    try {
      final data = await MakeupGuideService.getMakeupGuide(
        _imageBytes!,
        _selectedLooks,
        lipstickHex: _lipstickHex,
      );

      setState(() {
        _guideSteps = (data["guides"] as List)
            .map((e) => MakeupGuideStep.fromJson(e))
            .toList();
        _currentStep = 0;
      });
    } catch (e) {
      _showError("Guide generation failed: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = "";
      });
    }
  }

  // ==========================================================
  // PICK AFTER-MAKEUP IMAGE
  // ==========================================================
  Future<void> _pickAfterMakeupImage() async {
    try {
      final XFile? file =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);

      if (file == null) return;

      _afterBytes = await file.readAsBytes();
      _compareImages();
    } catch (e) {
      _showError("After-makeup photo error: $e");
    }
  }

  // ==========================================================
  // COMPARE BEFORE/AFTER
  // ==========================================================
  Future<void> _compareImages() async {
    if (_imageBytes == null || _afterBytes == null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "Comparing makeup…";
    });

    try {
      final res = await MakeupGuideService.compareMakeup(
        _imageBytes!,
        _afterBytes!,
      );

      setState(() {
        _comparisonData = MakeupComparisonData.fromJson(res);
        _showComparison = true;
      });
    } catch (e) {
      _showError("Comparison failed: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = "";
      });
    }
  }

  // ==========================================================
  // LIPSTICK COLOR PICKER
  // ==========================================================
  void _openColorPicker() {
    Color tempColor = _lipstickColor;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pick Lipstick Color"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tempColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                ),
                ColorPicker(
                  pickerColor: tempColor,
                  onColorChanged: (c) => setStateDialog(() => tempColor = c),
                  enableAlpha: false,
                  displayThumbColor: true,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _lipstickColor = tempColor;
                final hex = _lipstickColor.value
                    .toRadixString(16)
                    .padLeft(8, '0')
                    .substring(2);
                _lipstickHex = hex;
              });
              Navigator.pop(ctx);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SHOW ERROR MESSAGE
  // ==========================================================
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(msg)),
    );
  }

  // ==========================================================
  // MAIN UI BUILDER
  // ==========================================================
  Widget _buildBody() {
    if (_showComparison && _comparisonData != null) {
      return ComparisonWidget(
        comparisonData: _comparisonData!,
        onTryAgain: () => setState(() => _afterBytes = null),
        onStartOver: () {
          setState(() {
            _imageBytes = null;
            _selectedLooks = [];
            _guideSteps = [];
            _afterBytes = null;
            _comparisonData = null;
            _showComparison = false;
          });
        },
      );
    }

    if (_guideSteps.isNotEmpty) {
      return StepGuideWidget(
        currentStep: _guideSteps[_currentStep],
        currentIndex: _currentStep,
        totalSteps: _guideSteps.length,
        canGoPrevious: _currentStep > 0,
        isLastStep: _currentStep == _guideSteps.length - 1,
        onPrevious: () => setState(() => _currentStep--),
        onNext: () {
          if (_currentStep < _guideSteps.length - 1) {
            setState(() => _currentStep++);
          } else {
            _showFinishDialog();
          }
        },
      );
    }

    if (_imageBytes != null) {
      return MakeupSelectionWidget(
        selectedImageBytes: _imageBytes!,
        selectedLooks: _selectedLooks,
        onLookToggle: (look) {
          setState(() {
            if (_selectedLooks.contains(look)) {
              _selectedLooks.remove(look);
            } else {
              _selectedLooks.add(look);
            }
          });
        },
        onGenerateGuide: _generateGuide,
        onChangePhoto: () => _pickImage(),
        onColorPicker: _openColorPicker,
      );
    }

    return ImageUploadWidget(
      onCameraPressed: () => _pickImage(fromCamera: true),
      onGalleryPressed: () => _pickImage(),
    );
  }

  // ==========================================================
  // FINISH POPUP
  // ==========================================================
  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Great Job!"),
        content:
            const Text("Take a selfie of your final look to get feedback."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text("Take Photo"),
            onPressed: () {
              Navigator.pop(context);
              _pickAfterMakeupImage();
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _loadingMessage,
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "💄 Makeup Guide",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
