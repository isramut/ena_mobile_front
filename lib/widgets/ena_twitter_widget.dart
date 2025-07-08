import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../config/api_config.dart';

class EnaTwitterWidget extends StatefulWidget {
  final String title;
  final bool showTitle;
  final int maxTweets;

  const EnaTwitterWidget({
    super.key,
    this.title = "X / Twitter",
    this.showTitle = true,
    this.maxTweets = 5,
  });

  @override
  State<EnaTwitterWidget> createState() => _EnaTwitterWidgetState();
}

class _EnaTwitterWidgetState extends State<EnaTwitterWidget> {
  List<Map<String, dynamic>> tweets = [];
  bool isLoading = true;
  String? errorMessage;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTweets();
  }

  Future<void> _loadTweets() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      developer.log(
        '🐦 Début de récupération des tweets...',
        name: 'EnaTwitterWidget',
      );

      final fetchedTweets = await _fetchTweetsFromUser(
        "EnaRDC_Officiel",
        widget.maxTweets,
      );

      if (fetchedTweets.isNotEmpty) {
        developer.log(
          '✅ ${fetchedTweets.length} tweets récupérés avec succès',
          name: 'EnaTwitterWidget',
        );
        setState(() {
          tweets = fetchedTweets;
          isLoading = false;
        });
      } else {
        throw Exception('Aucun tweet récupéré depuis l\'API');
      }
    } catch (e) {
      developer.log(
        '❌ Erreur lors de la récupération des tweets: $e',
        name: 'EnaTwitterWidget',
      );

      setState(() {
        tweets = [];
        isLoading = false;
        errorMessage = 'Impossible de charger les tweets';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTweetsFromUser(
    String username,
    int maxResults,
  ) async {
    try {
      developer.log(
        '🔑 Utilisation du Bearer Token: ${ApiConfig.twitterBearerToken.substring(0, 20)}...',
        name: 'EnaTwitterWidget',
      );

      // Récupérer l'ID utilisateur
      final apiUrl = "https://api.twitter.com/2/users/by/username/$username";

      developer.log(
        '📡 Récupération de l\'ID utilisateur: $apiUrl',
        name: 'EnaTwitterWidget',
      );

      final userResponse = await http
          .get(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer ${ApiConfig.twitterBearerToken}',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      developer.log(
        '👤 Réponse utilisateur - Status: ${userResponse.statusCode}',
        name: 'EnaTwitterWidget',
      );

      if (userResponse.statusCode != 200) {
        developer.log(
          '❌ Erreur API utilisateur: ${userResponse.body}',
          name: 'EnaTwitterWidget',
        );
        throw Exception(
          'Erreur API Twitter utilisateur: ${userResponse.statusCode} - ${userResponse.body}',
        );
      }

      final userData = jsonDecode(userResponse.body);
      developer.log(
        '👤 Données utilisateur: $userData',
        name: 'EnaTwitterWidget',
      );

      if (!userData.containsKey('data') || userData['data'] == null) {
        throw Exception('Aucune donnée utilisateur trouvée');
      }

      final userId = userData['data']['id'];
      developer.log(
        '🆔 ID utilisateur trouvé: $userId',
        name: 'EnaTwitterWidget',
      );

      // Récupérer les tweets
      final tweetsUrl =
          "https://api.twitter.com/2/users/$userId/tweets?max_results=$maxResults&tweet.fields=created_at,public_metrics,text&expansions=author_id&user.fields=name,username";

      developer.log(
        '📡 Récupération des tweets: $tweetsUrl',
        name: 'EnaTwitterWidget',
      );

      final tweetsResponse = await http
          .get(
            Uri.parse(tweetsUrl),
            headers: {
              'Authorization': 'Bearer ${ApiConfig.twitterBearerToken}',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      developer.log(
        '🐦 Réponse tweets - Status: ${tweetsResponse.statusCode}',
        name: 'EnaTwitterWidget',
      );

      if (tweetsResponse.statusCode != 200) {
        developer.log(
          '❌ Erreur API tweets: ${tweetsResponse.body}',
          name: 'EnaTwitterWidget',
        );
        throw Exception(
          'Erreur API Twitter tweets: ${tweetsResponse.statusCode} - ${tweetsResponse.body}',
        );
      }

      final tweetsData = jsonDecode(tweetsResponse.body);
      developer.log(
        '🐦 Données tweets reçues: ${tweetsData.toString().length} caractères',
        name: 'EnaTwitterWidget',
      );

      if (!tweetsData.containsKey('data') || tweetsData['data'] == null) {
        developer.log(
          '⚠️ Aucun tweet trouvé dans la réponse',
          name: 'EnaTwitterWidget',
        );
        return [];
      }

      final List<dynamic> rawTweets = tweetsData['data'];
      developer.log(
        '📊 ${rawTweets.length} tweets bruts récupérés',
        name: 'EnaTwitterWidget',
      );

      List<Map<String, dynamic>> processedTweets = [];

      for (var tweet in rawTweets) {
        try {
          final tweetData = {
            'id': tweet['id'] ?? '',
            'text': tweet['text'] ?? '',
            'date': _formatDate(tweet['created_at'] ?? ''),
            'likes': tweet['public_metrics']?['like_count'] ?? 0,
            'retweets': tweet['public_metrics']?['retweet_count'] ?? 0,
            'url': 'https://twitter.com/$username/status/${tweet['id'] ?? ''}',
          };

          processedTweets.add(tweetData);
        } catch (e) {
          developer.log(
            '⚠️ Erreur lors du traitement du tweet: $e',
            name: 'EnaTwitterWidget',
          );
        }
      }

      developer.log(
        '✅ ${processedTweets.length} tweets traités avec succès',
        name: 'EnaTwitterWidget',
      );
      return processedTweets;
    } catch (e) {
      developer.log(
        '❌ Erreur générale dans _fetchTweetsFromUser: $e',
        name: 'EnaTwitterWidget',
      );
      return [];
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return '';
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'maintenant';
      }
    } catch (e) {
      return '';
    }
  }

  void _openTweetUrl() {
    if (tweets.isNotEmpty) {
      final url = tweets[currentIndex]["url"] ?? ApiConfig.twitterUrl;
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _nextTweet() {
    if (tweets.isNotEmpty) {
      setState(() {
        currentIndex = (currentIndex + 1) % tweets.length;
      });
    }
  }

  void _previousTweet() {
    if (tweets.isNotEmpty) {
      setState(() {
        currentIndex = currentIndex > 0 ? currentIndex - 1 : tweets.length - 1;
      });
    }
  }

  void _retryLoadTweets() {
    _loadTweets();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Row(
            children: [
              Icon(
                Icons.article_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        if (isLoading)
          _buildLoadingWidget()
        else if (tweets.isNotEmpty)
          _buildTweetWidget(theme)
        else
          _buildErrorWidget(theme),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildTweetWidget(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.alternate_email,
                color: theme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "EnaRDC_Officiel",
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                tweets[currentIndex]["date"] ?? "",
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Contenu du tweet
          GestureDetector(
            onTap: _openTweetUrl,
            child: Text(
              tweets[currentIndex]["text"] ?? "",
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          // Navigation et stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Navigation
              if (tweets.length > 1)
                Row(
                  children: [
                    IconButton(
                      onPressed: _previousTweet,
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 20,
                      color: theme.colorScheme.primary,
                    ),
                    Text(
                      "${currentIndex + 1}/${tweets.length}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _nextTweet,
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),

              // Stats
              Row(
                children: [
                  _buildStat(
                    icon: Icons.favorite_outline,
                    count: tweets[currentIndex]["likes"] ?? 0,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 12),
                  _buildStat(
                    icon: Icons.repeat,
                    count: tweets[currentIndex]["retweets"] ?? 0,
                    color: Colors.green.shade400,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            "Impossible de charger les tweets",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: _retryLoadTweets,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Réessayer"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(ApiConfig.twitterUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text("Voir sur X"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
