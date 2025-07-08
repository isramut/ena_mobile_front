import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? readAt;
  final String? link;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.readAt,
    this.link,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'],
      link: json['link'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'read_at': readAt,
      'link': link,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Méthode pour tronquer le message
  String getTruncatedMessage({int maxLength = 50}) {
    if (message.length <= maxLength) {
      return message;
    }
    return '${message.substring(0, maxLength)}...';
  }

  // Vérifier si c'est une notification d'alerte
  bool get isAlert => type == 'alerte';

  /// Getter pour l'icône selon le type
  IconData get typeIcon {
    switch (type.toLowerCase()) {
      case 'alerte':
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'info':
      default:
        return Icons.info;
    }
  }

  /// Getter pour la couleur selon le type
  Color get typeColor {
    switch (type.toLowerCase()) {
      case 'alerte':
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'success':
        return const Color(0xFF10B981);
      case 'error':
        return const Color(0xFFF87171);
      case 'info':
      default:
        return const Color(0xFF3678FF);
    }
  }

  /// Message tronqué pour l'affichage dans la liste
  String get truncatedMessage {
    if (message.length <= 80) return message;
    return '${message.substring(0, 80)}...';
  }

  /// Formatage de la date pour l'affichage
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return "Maintenant";
        }
        return "${difference.inMinutes}min";
      }
      return "${difference.inHours}h";
    } else {
      // Si plus de 24h, afficher la date en format DD/MM/YYYY
      return "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}";
    }
  }

  // Créer une copie avec les propriétés modifiées
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    String? readAt,
    String? link,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      link: link ?? this.link,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
