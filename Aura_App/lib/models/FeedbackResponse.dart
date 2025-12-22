class FeedbackResponse {
  final String area;
  final int score;
  final String positive;
  final String improvement;
  final String tip;
  final Map<String, dynamic> colorAnalysis;
  final double symmetryScore;

  FeedbackResponse({
    required this.area,
    required this.score,
    required this.positive,
    required this.improvement,
    required this.tip,
    required this.colorAnalysis,
    required this.symmetryScore,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      area: json['area'],
      score: json['score'],
      positive: json['positive'],
      improvement: json['improvement'],
      tip: json['tip'],
      colorAnalysis: Map<String, dynamic>.from(json['color_analysis'] ?? {}),
      symmetryScore: (json['symmetry_score'] is num)
          ? (json['symmetry_score'] as num).toDouble()
          : 0.0,
    );
  }
}
