import 'package:flutter/material.dart';
import 'package:ena_mobile_front/models/user_info.dart';
import '../services/image_cache_service.dart';
import '../services/image_cache_service.dart';

class UserAvatar extends StatefulWidget {
  final UserInfo? userInfo;
  final double size;
  final double borderRadius;

  const UserAvatar({
    super.key,
    this.userInfo,
    this.size = 40,
    this.borderRadius = 20,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _imageError = false;
  String? _lastImageUrl;

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Réinitialiser l'erreur si l'URL de l'image a changé
    if (oldWidget.userInfo?.fullProfilePictureUrl != widget.userInfo?.fullProfilePictureUrl) {
      setState(() {
        _imageError = false;
        _lastImageUrl = widget.userInfo?.fullProfilePictureUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProfilePicture = widget.userInfo?.fullProfilePictureUrl != null && 
        widget.userInfo!.fullProfilePictureUrl!.isNotEmpty && 
        !_imageError;

    // Debug pour voir l'URL de l'image
    print('=== AVATAR WIDGET DEBUG ===');
    print('Profile picture URL: ${widget.userInfo?.fullProfilePictureUrl}');
    print('Has profile picture: $hasProfilePicture');
    print('Image error: $_imageError');
    print('===========================');

    if (hasProfilePicture) {
      // Utiliser le service de cache-busting
      final imageUrl = widget.userInfo!.fullProfilePictureUrl!;
      final cacheBustedUrl = ImageCacheService.getCacheBustedUrl(imageUrl);
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.network(
          cacheBustedUrl,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
          errorBuilder: (context, error, stackTrace) {
            print('=== IMAGE LOADING ERROR ===');
            print('URL: $imageUrl');
            print('Cache-busted URL: $cacheBustedUrl');
            print('Exception: $error');
            print('===========================');
            
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _imageError = true;
                  });
                }
              });
            }
            return _buildInitialsAvatar();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      );
    } else {
      return _buildInitialsAvatar();
    }
  }

  Widget _buildInitialsAvatar() {
    String initials = _getInitials();
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    return widget.userInfo?.initials ?? 'U';
  }
}
