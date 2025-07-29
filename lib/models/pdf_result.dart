import 'dart:typed_data';
import 'candidature_pdf_data.dart';

/// Résultat de la génération PDF avec information sur le mode (sauvegarde ou partage)
class PdfResult {
  final bool isSaved;
  final String? filePath;
  final Uint8List? bytes;
  final CandidaturePdfData? data;

  PdfResult._({
    required this.isSaved,
    this.filePath,
    this.bytes,
    this.data,
  });

  /// PDF sauvegardé avec succès sur le téléphone
  factory PdfResult.saved(String filePath) {
    return PdfResult._(
      isSaved: true,
      filePath: filePath,
    );
  }

  /// PDF généré mais non sauvegardé - prêt pour partage
  factory PdfResult.forSharing(Uint8List bytes, CandidaturePdfData data) {
    return PdfResult._(
      isSaved: false,
      bytes: bytes,
      data: data,
    );
  }

  /// Retourne le nom du fichier suggéré pour le partage
  String get suggestedFileName {
    if (data != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'Candidature_ENA_${data!.nom}_${data!.postnom}_$timestamp.pdf';
    }
    return 'Candidature_ENA.pdf';
  }
}
