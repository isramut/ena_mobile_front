import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../config/api_config.dart';
import '../../widgets/ena_twitter_widget.dart';

// --------------------------------------------
// --------------------------------------------
// PARAMS : Channel ID, autres liens
// --------------------------------------------
const String enaYtChannelId = "UCxgeB2LaWwcnbTgdxHk2L_A";
const String youtubeChannelUrl = "https://www.youtube.com/@ena-rdc";

const String facebookUrl = 'https://www.facebook.com/ENARDCOfficiel';
const String linkedinUrl = 'https://www.linkedin.com/company/ena-rdc';
const String twitterUrl = 'https://x.com/EnaRDC_Officiel';
const String whatsappUrl =
    'https://whatsapp.com/channel/0029Vb6Na5uK5cDKslzxom3L';

// --------- YOUTUBE API ---------
Future<List<Map<String, String>>> fetchLatestYoutubeVideos({
  int maxResults = 5,
}) async {
  final apiUrl =
      "https://www.googleapis.com/youtube/v3/search?key=${ApiConfig.youtubeApiKey}&channelId=$enaYtChannelId&part=snippet,id&order=date&type=video&maxResults=$maxResults";
  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode != 200) return [];
  final data = json.decode(response.body);
  if (data == null || data["items"] == null || data["items"].isEmpty) return [];

  return (data["items"] as List)
      .where((item) => item["id"]?["videoId"] != null)
      .map<Map<String, String>>(
        (item) => {
          "videoId": item["id"]["videoId"],
          "title": item["snippet"]["title"] ?? "",
          "date": item["snippet"]["publishedAt"]?.substring(0, 10) ?? "",
          "thumbnail": item["snippet"]["thumbnails"]?["high"]?["url"] ?? "",
        },
      )
      .toList();
}

// --------- X/TWITTER API ---------
Future<List<Map<String, String>>> fetchLatestTweets({
  int maxResults = 5,
}) async {
  const String username = "EnaRDC_Officiel"; // Sans le @

  try {
    // API v2 de Twitter pour récupérer les tweets d'un utilisateur
    final apiUrl = "https://api.twitter.com/2/users/by/username/$username";

    // D'abord, récupérer l'ID de l'utilisateur
    final userResponse = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer ${ApiConfig.twitterBearerToken}',
        'Content-Type': 'application/json',
      },
    );

    if (userResponse.statusCode != 200) {
      // Fallback avec des données de test pour l'ENA-RDC
      return getMockTweets();
    }

    final userData = json.decode(userResponse.body);
    if (userData['data'] == null) {
      return getMockTweets();
    }

    final userId = userData['data']['id'];

    // Maintenant récupérer les tweets de l'utilisateur
    final tweetsUrl =
        "https://api.twitter.com/2/users/$userId/tweets?max_results=$maxResults&tweet.fields=created_at,public_metrics,text";

    final tweetsResponse = await http.get(
      Uri.parse(tweetsUrl),
      headers: {
        'Authorization': 'Bearer ${ApiConfig.twitterBearerToken}',
        'Content-Type': 'application/json',
      },
    );

    if (tweetsResponse.statusCode != 200) {
      return getMockTweets();
    }

    final tweetsData = json.decode(tweetsResponse.body);
    if (tweetsData['data'] == null) {
      return getMockTweets();
    }

    final tweets = (tweetsData['data'] as List).map<Map<String, String>>((
      tweet,
    ) {
      final metrics = tweet['public_metrics'] ?? {};
      final createdAt = tweet['created_at'] ?? '';
      final date = createdAt.isNotEmpty ? createdAt.substring(0, 10) : '';

      return {
        'id': tweet['id'] ?? '',
        'text': tweet['text'] ?? '',
        'date': date,
        'likes': (metrics['like_count'] ?? 0).toString(),
        'retweets': (metrics['retweet_count'] ?? 0).toString(),
        'url': 'https://x.com/EnaRDC_Officiel/status/${tweet['id'] ?? ''}',
      };
    }).toList();

    return tweets;
  } catch (e) {
    return getMockTweets();
  }
}

// Données de test pour l'ENA-RDC
List<Map<String, String>> getMockTweets() {
  return [
    {
      'id': '1',
      'text':
          '🎓 Félicitations aux nouveaux diplômés de l\'ENA-RDC ! Votre parcours académique exemplaire vous ouvre les portes de l\'excellence dans l\'administration publique. #ENRDC #Graduation2024',
      'date': '2024-01-15',
      'likes': '145',
      'retweets': '67',
      'url': 'https://x.com/EnaRDC_Officiel/status/1',
    },
    {
      'id': '2',
      'text':
          '📚 Lancement de la nouvelle formation en Management Public Digital. Inscriptions ouvertes dès maintenant ! Préparez-vous aux défis de l\'administration moderne. #FormationENA #DigitalGov',
      'date': '2024-01-12',
      'likes': '89',
      'retweets': '34',
      'url': 'https://x.com/EnaRDC_Officiel/status/2',
    },
    {
      'id': '3',
      'text':
          '🏛️ Conférence exceptionnelle sur la gouvernance moderne en Afrique. Intervenants de haut niveau confirmés. Réservez votre place ! #Gouvernance #AfriqueModerne',
      'date': '2024-01-10',
      'likes': '203',
      'retweets': '78',
      'url': 'https://x.com/EnaRDC_Officiel/status/3',
    },
    {
      'id': '4',
      'text':
          '🌟 L\'ENA-RDC s\'engage pour l\'excellence académique et l\'innovation dans la formation des futurs leaders de l\'administration publique congolaise. #Excellence #Leadership',
      'date': '2024-01-08',
      'likes': '167',
      'retweets': '92',
      'url': 'https://x.com/EnaRDC_Officiel/status/4',
    },
    {
      'id': '5',
      'text':
          '📈 Résultats remarquables de nos étudiants aux examens nationaux ! L\'ENA-RDC maintient son rang d\'excellence dans l\'enseignement supérieur. #Résultats #Fierté',
      'date': '2024-01-05',
      'likes': '189',
      'retweets': '56',
      'url': 'https://x.com/EnaRDC_Officiel/status/5',
    },
  ];
}

// ---------- SOCIAL CARD GENERIC ----------
Widget socialCard({
  required String title,
  String? image,
  IconData? icon,
  required Color color,
  required VoidCallback onTap,
  String? description,
  required BuildContext context,
}) {
  final theme = Theme.of(context);
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
    color: theme.colorScheme.surface,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Row(
          children: [
            // Afficher soit l'image soit l'icône
            if (image != null)
              Image.asset(image, width: 38, height: 38)
            else if (icon != null)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              )
            else
              const SizedBox(
                width: 38,
                height: 38,
              ), // Placeholder si ni image ni icône
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13.7,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
          ],
        ),
      ),
    ),
  );
}

class ActualitesScreen extends StatefulWidget {
  const ActualitesScreen({super.key});
  @override
  State<ActualitesScreen> createState() => _ActualitesScreenState();
}

class _ActualitesScreenState extends State<ActualitesScreen> {
  List<Map<String, String>> lastVideos = [];
  List<Map<String, String>> lastTweets = [];
  int currentVideoIndex = 0;
  int currentTweetIndex = 0;
  bool loading = true;
  bool tweetsLoading = true;
  YoutubePlayerController? ytController;

  @override
  void initState() {
    super.initState();

    // Charger les vidéos YouTube
    fetchLatestYoutubeVideos().then((videos) {
      setState(() {
        lastVideos = videos;
        loading = false;
        if (lastVideos.isNotEmpty) {
          ytController = YoutubePlayerController.fromVideoId(
            videoId: lastVideos[0]["videoId"]!,
            autoPlay: false,
            params: const YoutubePlayerParams(showFullscreenButton: true),
          );
          ytController!.listen((event) {
            if (event.playerState == PlayerState.ended) {
              playNextVideo();
            }
          });
        }
      });
    });

    // Charger les tweets X/Twitter
    fetchLatestTweets().then((tweets) {
      setState(() {
        lastTweets = tweets;
        tweetsLoading = false;
      });
    });
  }

  @override
  void dispose() {
    ytController?.close();
    super.dispose();
  }

  Future<void> openUrlInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Si aucune app spécifique n'est trouvée, force l'ouverture dans le navigateur
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // En cas d'erreur, affiche un message à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible d'ouvrir le lien: $url"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void playNextVideo() {
    if (lastVideos.isNotEmpty && currentVideoIndex < lastVideos.length - 1) {
      setState(() {
        currentVideoIndex += 1;
        ytController?.loadVideoById(
          videoId: lastVideos[currentVideoIndex]["videoId"]!,
        );
      });
    }
  }

  void playPreviousVideo() {
    if (lastVideos.isNotEmpty && currentVideoIndex > 0) {
      setState(() {
        currentVideoIndex -= 1;
        ytController?.loadVideoById(
          videoId: lastVideos[currentVideoIndex]["videoId"]!,
        );
      });
    }
  }

  void nextTweet() {
    if (lastTweets.isNotEmpty && currentTweetIndex < lastTweets.length - 1) {
      setState(() {
        currentTweetIndex += 1;
      });
    }
  }

  void previousTweet() {
    if (lastTweets.isNotEmpty && currentTweetIndex > 0) {
      setState(() {
        currentTweetIndex -= 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 2,
        centerTitle: true,
        title: Text(
          "Actualités",
          style: GoogleFonts.poppins(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        children: [
          // ---------- YOUTUBE ----------
          Text(
            "YouTube",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFFCD201F),
            ),
          ),
          const SizedBox(height: 9),
          if (loading)
            Center(child: CircularProgressIndicator())
          else if (lastVideos.isNotEmpty && ytController != null)
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17),
                    ),
                    child: YoutubePlayer(
                      controller: ytController!,
                      aspectRatio: 16 / 9,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastVideos[currentVideoIndex]["title"] ?? "",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1C3D8F),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                lastVideos[currentVideoIndex]["date"] ?? "",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  // Navigation vidéos
                                  if (lastVideos.length > 1)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (currentVideoIndex > 0)
                                          IconButton(
                                            icon: Icon(
                                              Icons.skip_previous,
                                              color: Color(0xFFCD201F),
                                            ),
                                            onPressed: playPreviousVideo,
                                            constraints: BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsets.all(4),
                                          ),
                                        Text(
                                          "${currentVideoIndex + 1}/${lastVideos.length}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (currentVideoIndex <
                                            lastVideos.length - 1)
                                          IconButton(
                                            icon: Icon(
                                              Icons.skip_next,
                                              color: Color(0xFFCD201F),
                                            ),
                                            onPressed: playNextVideo,
                                            constraints: BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsets.all(4),
                                          ),
                                      ],
                                    ),
                                  // Bouton YouTube responsive
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => openUrlInBrowser(
                                        "https://www.youtube.com/watch?v=${lastVideos[currentVideoIndex]["videoId"]}",
                                      ),
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        size: 16,
                                      ),
                                      label: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Voir sur YouTube",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFCD201F,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size(0, 32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Card(
              color: Colors.red[50],
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 35),
                    const SizedBox(height: 9),
                    Text(
                      "Aucune vidéo n'est disponible pour le moment.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => openUrlInBrowser(youtubeChannelUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text("Voir la chaîne"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCD201F),
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ---------- X / TWITTER ----------
          EnaTwitterWidget(title: "X / Twitter", showTitle: true, maxTweets: 5),

          // ---------- FACEBOOK ----------
          socialCard(
            title: "Facebook",
            icon: Icons.facebook,
            color: const Color(0xFF1877F3),
            description:
                "Suivez les actualités et photos sur la page officielle ENA RDC.",
            onTap: () => openUrlInBrowser(facebookUrl),
            context: context,
          ),

          // ---------- WHATSAPP ----------
          socialCard(
            title: "WhatsApp",
            icon: Icons.chat,
            color: const Color(0xFF25D366),
            description:
                "Rejoignez la chaîne WhatsApp officielle de l'ENA-RDC.",
            onTap: () => openUrlInBrowser(whatsappUrl),
            context: context,
          ),

          // ---------- LINKEDIN ----------
          socialCard(
            title: "LinkedIn",
            icon: Icons.business,
            color: const Color(0xFF0077B5),
            description:
                "Actualités, annonces, opportunités et publications institutionnelles.",
            onTap: () => openUrlInBrowser(linkedinUrl),
            context: context,
          ),

          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Center(
              child: Text(
                "Restez connectés à l'ENA-RDC sur tous les réseaux pour ne manquer aucune actualité.",
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
