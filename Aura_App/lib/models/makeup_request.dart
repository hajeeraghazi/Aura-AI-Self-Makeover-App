class MakeupRequest {
  final String faceShape;
  final String skinTone;
  final String? category;
  final String? gender;
  final String? bodyType;

  MakeupRequest({
    required this.faceShape,
    required this.skinTone,
    this.category,
    this.gender,
    this.bodyType,
  });

  Map<String, dynamic> toJson() => {
        "face_shape": faceShape,
        "skin_tone": skinTone,
        if (category != null) "category": category,
        if (gender != null) "gender": gender,
        if (bodyType != null) "body_type": bodyType,
      };
}
