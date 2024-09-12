import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> fetchFileEntityUrl(String fileId) async {
  const String baseUrl = 'https://webapp.grn.dk';
  final String fileApiUrl = '$baseUrl/jsonapi/file/file/$fileId';

  final response = await http.get(Uri.parse(fileApiUrl));

  if (response.statusCode == 200) {
    final fileData = json.decode(response.body);
    final imageUrl = fileData['data']['attributes']['uri']['url'];

    if (imageUrl != null) {
      // Construct the full image URL
      return '$baseUrl$imageUrl';
    } else {
      return '';  // Return empty string if no image URL
    }
  } else {
    throw Exception('Failed to load file entity');
  }
}

Future<String> getImageUrl(Map<String, dynamic> node) async {
  final imageField = node['relationships']?['field_image']?['data'];

  if (imageField != null) {
    final fileId = imageField['id'];

    if (fileId != null) {
      // Make an additional request to get the file details and extract the image URL
      try {
        final imageUrl = await fetchFileEntityUrl(fileId);
        print('Fetched image URL: $imageUrl');
        return imageUrl;
      } catch (e) {
        print('Failed to fetch image URL: $e');
        return '';  // Return empty string in case of failure
      }
    }
  }

  print('No valid image URL found');
  return '';  // Return empty if no valid image is found
}
