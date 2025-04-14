class Cv {
  final String id;
  final String user;
  final String summary;
  final String? education;
  final String? experience;
  final String? certification;
  final String? projet;
  final String? skill;
  final String? language;

  Cv({
    required this.id,
    required this.user,
    required this.summary,
    this.education,
    this.experience,
    this.certification,
    this.projet,
    this.skill,
    this.language,
  });

  factory Cv.fromJson(Map<String, dynamic> json) {
    return Cv(
      id: json['_id'],
      user: json['user'],
      summary: json['summary'] ?? '',
      education: json['education'],
      experience: json['experience'],
      certification: json['certification'],
      projet: json['projet'],
      skill: json['skill'],
      language: json['language'],
    );
  }
}