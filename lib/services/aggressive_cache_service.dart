import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de cache agressif pour accélérer le chargement des données
class AggressiveCacheService {
  static const Duration defaultCacheExpiry = Duration(minutes: 5);
  static const Duration fastCacheExpiry = Duration(minutes: 1);
  static const Duration longCacheExpiry = Duration(hours: 1);

  /// Cache les données avec une clé et une durée d'expiration
  static Future<void> cacheData(
    String key,
    Map<String, dynamic> data, {
    Duration expiry = defaultCacheExpiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheItem = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': expiry.inMilliseconds,
      };
      
      await prefs.setString('cache_$key', jsonEncode(cacheItem));
      print('🗄️ Cache saved: $key (expires in ${expiry.inMinutes}min)');
    } catch (e) {
      print('❌ Cache save failed for $key: $e');
    }
  }

  /// Récupère les données du cache si elles sont encore valides
  static Future<Map<String, dynamic>?> getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('cache_$key');
      
      if (cachedString == null) {
        print('🗄️ Cache miss: $key');
        return null;
      }

      final cacheItem = jsonDecode(cachedString);
      final timestamp = cacheItem['timestamp'] as int;
      final expiry = cacheItem['expiry'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp > expiry) {
        print('🗄️ Cache expired: $key');
        await prefs.remove('cache_$key');
        return null;
      }

      print('🗄️ Cache hit: $key');
      return Map<String, dynamic>.from(cacheItem['data']);
    } catch (e) {
      print('❌ Cache read failed for $key: $e');
      return null;
    }
  }

  /// Invalide le cache pour une clé spécifique
  static Future<void> invalidateCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
      print('🗄️ Cache invalidated: $key');
    } catch (e) {
      print('❌ Cache invalidation failed for $key: $e');
    }
  }

  /// Invalide tout le cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      print('🗄️ All cache cleared (${keys.length} items)');
    } catch (e) {
      print('❌ Cache clear failed: $e');
    }
  }

  /// Vérifie si des données sont en cache et encore valides
  static Future<bool> hasFreshCache(String key) async {
    final data = await getCachedData(key);
    return data != null;
  }

  /// Met à jour le cache avec de nouvelles données sans changer l'expiration
  static Future<void> updateCache(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('cache_$key');
      
      Duration expiry = defaultCacheExpiry;
      if (cachedString != null) {
        final cacheItem = jsonDecode(cachedString);
        expiry = Duration(milliseconds: cacheItem['expiry'] as int);
      }
      
      await cacheData(key, data, expiry: expiry);
    } catch (e) {
      // Si erreur, utiliser la méthode normale
      await cacheData(key, data);
    }
  }

  /// Clés de cache predéfinies pour l'application
  static const String userInfoKey = 'user_info';
  static const String notificationsKey = 'notifications';
  static const String candidatureStatusKey = 'candidature_status';
  static const String programEventsKey = 'program_events';
  static const String dashboardKey = 'dashboard_data';
  
  /// Cache spécialisé pour les informations utilisateur
  static Future<void> cacheUserInfo(Map<String, dynamic> data) async {
    await cacheData(userInfoKey, data, expiry: longCacheExpiry);
  }
  
  /// Cache spécialisé pour les notifications
  static Future<void> cacheNotifications(Map<String, dynamic> data) async {
    await cacheData(notificationsKey, data, expiry: fastCacheExpiry);
  }
  
  /// Cache spécialisé pour le statut de candidature
  static Future<void> cacheCandidatureStatus(Map<String, dynamic> data) async {
    await cacheData(candidatureStatusKey, data, expiry: defaultCacheExpiry);
  }

  /// Récupère toutes les données dashboard depuis le cache
  static Future<Map<String, Map<String, dynamic>?>> getAllDashboardCache() async {
    final futures = await Future.wait([
      getCachedData(userInfoKey),
      getCachedData(notificationsKey),
      getCachedData(candidatureStatusKey),
    ]);

    return {
      'userInfo': futures[0],
      'notifications': futures[1],
      'candidatureStatus': futures[2],
    };
  }
}
