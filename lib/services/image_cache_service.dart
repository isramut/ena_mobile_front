import 'package:flutter/material.dart';

/// Service pour gérer le cache des images utilisateur
class ImageCacheService {
  static int _cacheVersion = 0;
  
  /// Incrémente la version du cache pour forcer le rechargement de toutes les images
  static void invalidateUserImageCache() {
    _cacheVersion++;
    // Vider le cache d'images Flutter
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    print('=== IMAGE CACHE INVALIDATED ===');
    print('New cache version: $_cacheVersion');
    print('===============================');
  }
  
  /// Obtient l'URL avec cache-busting
  static String getCacheBustedUrl(String originalUrl) {
    final separator = originalUrl.contains('?') ? '&' : '?';
    final cacheBustedUrl = '$originalUrl${separator}v=$_cacheVersion&t=${DateTime.now().millisecondsSinceEpoch}';
    print('Cache-busted URL: $cacheBustedUrl');
    return cacheBustedUrl;
  }
  
  /// Obtient la version actuelle du cache
  static int get cacheVersion => _cacheVersion;
}
