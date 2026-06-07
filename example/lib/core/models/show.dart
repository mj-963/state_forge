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
    final image = json['image'];
    return Show(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      summary: (json['summary'] ?? '').replaceAll(RegExp(r'<[^>]*>'), ''),
      image: image is Map ? image['medium'] : image as String?,
      rating: (json['rating']?['average'] ?? 0.0).toDouble(),
      genres: List<String>.from(json['genres'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'image': image,
      'rating': {'average': rating},
      'genres': genres,
    };
  }
}

class CastMember {
  const CastMember({
    required this.personName,
    required this.characterName,
    this.image,
  });
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
