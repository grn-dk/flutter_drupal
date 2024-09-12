import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Drupal App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NodeListScreen(),
    );
  }
}

class NodeListScreen extends StatefulWidget {
  const NodeListScreen({super.key});

  @override
  NodeListScreenState createState() => NodeListScreenState();
}

class NodeListScreenState extends State<NodeListScreen> {
  final String baseUrl = 'https://webapp.grn.dk';
  late Future<List<dynamic>> nodes;

  @override
  void initState() {
    super.initState();
    nodes = fetchNodes();
  }

  Future<List<dynamic>> fetchNodes() async {
    final response = await http.get(Uri.parse('$baseUrl/jsonapi/node/article'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']; // Return list of nodes
    } else {
      throw Exception('Failed to load nodes');
    }
  }

  Future<String> fetchFileEntityUrl(String fileId) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drupal Nodes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                nodes = fetchNodes();  // Refresh the nodes
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: nodes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          final nodes = snapshot.data!;

          return ListView.builder(
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              final node = nodes[index];
              final title = node['attributes']['title'];
              final bodyHtml = node['attributes']['body']['processed'];

              return Card(
                margin: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: getImageUrl(node),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();  // Loading indicator
                        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return Image.asset('assets/placeholder.png');  // Show placeholder on error
                        } else {
                          return Image.network(
                            snapshot.data!,
                            errorBuilder: (context, error, stackTrace) => Image.asset('assets/placeholder.png'),
                          );
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: HtmlWidget(
                        bodyHtml,
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
