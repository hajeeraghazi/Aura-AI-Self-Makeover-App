import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show MakeupAppState;
// ignore: unused_import
import '../models/MakeupStep.dart';
import 'TutorialScreen.dart';

class StepScreen extends StatefulWidget {
  const StepScreen({super.key});

  @override
  State<StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends State<StepScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Fetch looks safely after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<MakeupAppState>();
      if (appState.looks.isEmpty) {
        appState.fetchLooks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MakeupAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Makeup Tutor'),
        backgroundColor: Colors.pink,
      ),
      body: appState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : appState.looks.isEmpty
              ? const Center(
                  child: Text(
                    "No makeup looks available",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appState.looks.length,
                  itemBuilder: (context, index) {
                    final look = appState.looks[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          look.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(look.description),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          appState.selectLook(look);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TutorialScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
