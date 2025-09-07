import 'dart:io';
import 'dart:math';

class FoodRecognitionService {
  // Mock API call: simulate upload and response
  Future<String> recognizeFood(File imageFile) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Very simple "mock" heuristics based on file size/name or random pick
    final size = await imageFile.length();
    final nameLower = imageFile.path.toLowerCase();
    if (nameLower.contains('apple')) return 'Apple';
    if (nameLower.contains('banana')) return 'Banana';
    if (size % 3 == 0) return 'Pizza';
    if (size % 3 == 1) return 'Salad';
    // fallback random picks
    final options = ['Burger', 'Sushi', 'Pasta', 'Salad'];
    return options[Random().nextInt(options.length)];
  }

  // Example of how a real upload might look (not used by the mock above)
  // Future<String> recognizeFoodViaHttp(File imageFile, Uri endpoint) async {
  //   final request = http.MultipartRequest('POST', endpoint);
  //   request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
  //   final streamedResp = await request.send();
  //   final resp = await http.Response.fromStream(streamedResp);
  //   if (resp.statusCode == 200) {
  //     return resp.body; // parse JSON in a real implementation
  //   } else {
  //     throw Exception('Server error: ${resp.statusCode}');
  //   }
  // }
}
