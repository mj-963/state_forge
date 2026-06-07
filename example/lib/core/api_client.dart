import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/show.dart';

class ApiClient {
  static const _baseUrl = 'https://api.tvmaze.com';

  Future<List<Show>> getShows({int page = 0}) async {
    final response = await http.get(Uri.parse('$_baseUrl/shows?page=$page'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Show.fromJson(json)).toList();
    }
    throw Exception('Failed to load shows');
  }

  Future<List<Show>> searchShows(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl/search/shows?q=$query'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Show.fromJson(json['show'])).toList();
    }
    throw Exception('Failed to search shows');
  }

  Future<(Show, List<CastMember>)> getShowDetails(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/shows/$id?embed=cast'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final show = Show.fromJson(data);
      final List castData = data['_embedded']?['cast'] ?? [];
      final cast = castData.map((json) => CastMember.fromJson(json)).toList();
      return (show, cast);
    }
    throw Exception('Failed to load show details');
  }
}
