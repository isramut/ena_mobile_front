import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification.dart';
import '../../services/auth_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        final result = await AuthApiService.getUserNotifications(token: token);
        
        if (mounted && result['success'] == true && result['data'] != null) {
          final notificationsData = result['data'];
          List<NotificationModel> notifications = [];
          
          if (notificationsData is List) {
            notifications = notificationsData
                .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
                .toList();
          } else if (notificationsData is Map && notificationsData['results'] != null) {
            final results = notificationsData['results'] as List;
            notifications = results
                .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
                .toList();
          }
          
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
          
          // Sauvegarder en cache
          await prefs.setString('notifications_cache', jsonEncode(notifications.map((n) => n.toJson()).toList()));
        } else {
          await _loadNotificationsFromCache();
        }
      } else {
        await _loadNotificationsFromCache();
      }
    } catch (e) {
      if (mounted) {
        await _loadNotificationsFromCache();
        setState(() {
          _error = 'Erreur lors du chargement des notifications';
        });
      }
    }
  }

  Future<void> _loadNotificationsFromCache() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedNotifications = prefs.getString('notifications_cache');
      
      if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
        final notificationsData = jsonDecode(cachedNotifications) as List;
        final notifications = notificationsData
            .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
            .toList();
        
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
          _error = 'Erreur lors du chargement du cache';
        });
      }
    }
  }

  Future<void> _markNotificationAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        final result = await AuthApiService.markNotificationAsRead(
          token: token,
          notificationId: notification.id,
        );

        if (result['success'] == true && mounted) {
          setState(() {
            final index = _notifications.indexWhere((n) => n.id == notification.id);
            if (index != -1) {
              _notifications[index] = notification.copyWith(isRead: true);
            }
          });
          
          // Mettre à jour le cache
          await prefs.setString('notifications_cache', 
              jsonEncode(_notifications.map((n) => n.toJson()).toList()));
        }
      }
    } catch (e) {
      // Ignorer l'erreur mais marquer localement
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
          }
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        final result = await AuthApiService.markAllNotificationsAsRead(token: token);

        if (result['success'] == true && mounted) {
          setState(() {
            _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
          });
          
          // Mettre à jour le cache
          await prefs.setString('notifications_cache', 
              jsonEncode(_notifications.map((n) => n.toJson()).toList()));
        }
      }
    } catch (e) {
      // Ignorer l'erreur mais marquer localement
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFF013068),
        foregroundColor: Colors.white,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Marquer toutes comme lues',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          IconButton(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF013068),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Vous n\'avez pas encore de notification',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Les nouvelles notifications apparaîtront ici.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? Theme.of(context).cardColor
            : (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                : const Color(0xFFEDF2FD)),
        borderRadius: BorderRadius.circular(16),
        border: notification.isRead 
            ? null 
            : Border.all(
                color: notification.typeColor.withValues(alpha: 0.3),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _markNotificationAsRead(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notification.typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        notification.typeIcon,
                        color: notification.typeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: GoogleFonts.poppins(
                                    fontWeight: notification.isRead 
                                        ? FontWeight.w500 
                                        : FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).textTheme.headlineSmall?.color,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: notification.typeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: notification.typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              notification.type.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: notification.typeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.formattedDate,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (notification.link != null)
                      Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
