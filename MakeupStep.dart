// ---------------------- MODELS ----------------------
class MakeupStep {
  final String area;
  final String instruction;
  final List<String> products;
  final String tips;

  MakeupStep({
    required this.area,
    required this.instruction,
    required this.products,
    required this.tips,
  });

  factory MakeupStep.fromJson(Map<String, dynamic> json) {
    return MakeupStep(
      area: json['area'],
      instruction: json['instruction'],
      products: List<String>.from(json['products']),
      tips: json['tips'],
    );
  }
}

class MakeupLook {
  final String id;
  final String name;
  final String occasion;
  final String difficulty;
  final String duration;
  final String description;
  final List<MakeupStep> steps;

  MakeupLook({
    required this.id,
    required this.name,
    required this.occasion,
    required this.difficulty,
    required this.duration,
    required this.description,
    required this.steps,
  });

  factory MakeupLook.fromJson(Map<String, dynamic> json) {
    return MakeupLook(
      id: json['id'],
      name: json['name'],
      occasion: json['occasion'],
      difficulty: json['difficulty'],
      duration: json['duration'],
      description: json['description'],
      steps: (json['steps'] as List)
          .map((step) => MakeupStep.fromJson(step))
          .toList(),
    );
  }
}
