class Show {
  const Show({
    required this.id,
    required this.name,
    required this.summary,
    required this.image,
    required this.rating,
    required this.genres,
  });

  final int id;
  final String name;
  final String summary;
  final String? image;
  final double rating;
  final List<String> genres;

  factory Show.fromJson(Map<String, dynamic> json) {
    return Show(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      summary: (json['summary'] ?? '').replaceAll(RegExp(r'<[^>]*>'), ''),
      image: json['image']?['medium'],
      rating: (json['rating']?['average'] ?? 0.0).toDouble(),
      genres: List<String>.from(json['genres'] ?? []),
    );
  }
}

class CastMember {
  const CastMember({required this.personName, required this.characterName, this.image});
  final String personName;
  final String characterName;
  final String? image;

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      personName: json['person']['name'],
      characterName: json['character']['name'],
      image: json['person']['image']?['medium'],
    );
  }
}
