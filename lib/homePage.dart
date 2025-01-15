import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago; // Import timeago package

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> posts = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchRankedPosts();
  }

  Future<void> fetchRankedPosts() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.hive.blog/'),
        headers: {
          'accept': 'application/json, text/plain, /',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          "id": 1,
          "jsonrpc": "2.0",
          "method": "bridge.get_ranked_posts",
          "params": {"sort": "trending", "tag": "", "observer": "hive.blog"}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          posts = data['result'] as List<dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load posts. Status Code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  String formatTimeAgo(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return timeago.format(dateTime, locale: 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ALL Posts')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final imageUrl = post['json_metadata'] != null &&
                            post['json_metadata']['image'] != null &&
                            post['json_metadata']['image'].isNotEmpty
                        ? post['json_metadata']['image'][0] as String
                        : 'N/A'; // Default placeholder image url;

                    final timeAgo = formatTimeAgo(post['created']);

                    final voteCount = post['stats'] != null &&
                            post['stats']['total_votes'] != null
                        ? post['stats']['total_votes'].toString()
                        : '0';
                    final commentsCount = post['children'].toString();
                    final description = (post['json_metadata'] != null &&
                            post['json_metadata']['description'] != null)
                        ? post['json_metadata']['description'] as String
                        : 'No description available';

                    return Card(
                        color: Colors.white,
                        margin: EdgeInsets.all(8),
                        elevation: 3,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                children: [
                                  Text(' ${post['community'] ?? 'N/A'} | '),
                                  Text(
                                      ' ${post['community_title'] ?? 'N/A'} | '),
                                  Text(timeAgo),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Image.network(
                                    imageUrl,
                                    width: 200,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(post['title'] ?? 'No Title',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text(description),
                                        Text(
                                            "Votes: $voteCount | Comments: $commentsCount"),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ));
                  },
                ),
    );
  }
}
