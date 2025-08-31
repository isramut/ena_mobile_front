import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
//import 'package:flutter/foundation.dart';
import '../models/candidature_pdf_data.dart';
import '../models/pdf_result.dart';
import '../templates/fiche_soumission_template.dart';

class PdfGeneratorService {
  /// Génère et télécharge automatiquement le PDF de candidature avec gestion des permissions
  Future<PdfResult> generateAndDownloadPdf(CandidaturePdfData data) async {
    try {
      // Vérifier les permissions de stockage
      final hasPermissions = await _checkStoragePermissions();
      
      // Générer le PDF dans tous les cas
      final pdf = await _generatePdf(data);
      
      if (hasPermissions) {
        // Si permissions accordées : sauvegarder uniquement
        final filePath = await _savePdfToDownloads(pdf, data);
        return PdfResult.saved(filePath);
      } else {
        // Si permissions refusées : préparer pour partage
        final bytes = await pdf.save();
        return PdfResult.forSharing(bytes, data);
      }
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }
  
  /// Vérifie les permissions de stockage (toujours true maintenant car dossier privé)
  Future<bool> _checkStoragePermissions() async {
    // Plus besoin de vérifier les permissions - dossier privé de l'app toujours accessible
    return true;
  }

  /// Génère et prévisualise le PDF de candidature (ancienne méthode pour compatibilité)
  Future<void> generateAndPreviewPdf(CandidaturePdfData data) async {
    try {
      // Générer le PDF avec gestion des permissions
      final result = await generateAndDownloadPdf(data);
      
      if (result.isSaved && result.filePath != null) {
        // Si sauvegardé, partager le fichier depuis le stockage
        await Share.shareXFiles(
          [XFile(result.filePath!)],
          subject: 'Candidature ENA - ${data.nom} ${data.postnom}',
          text: 'Voici ma fiche de candidature pour l\'École Nationale d\'Administration.',
        );
      } else if (!result.isSaved && result.bytes != null && result.data != null) {
        // Si non sauvegardé, partager directement les bytes
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${result.suggestedFileName}');
        await tempFile.writeAsBytes(result.bytes!);
        
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: 'Candidature ENA - ${data.nom} ${data.postnom}',
          text: 'Voici ma fiche de candidature pour l\'École Nationale d\'Administration.',
        );
        
        // Nettoyer le fichier temporaire après partage
        await tempFile.delete();
      }
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  /// Génère le document PDF
  Future<pw.Document> _generatePdf(CandidaturePdfData data) async {
    final pdf = pw.Document();
    
    // Créer la fiche de soumission
    final template = FicheSoumissionTemplate();
    final multiPage = await template.buildPage(data);
    
    pdf.addPage(multiPage);
    
    return pdf;
  }

  /// Sauvegarde le PDF dans le dossier privé de l'app et propose le partage
  Future<String> _savePdfToDownloads(pw.Document pdf, CandidaturePdfData data) async {
    try {
      final bytes = await pdf.save();
      
      // Sauvegarder dans le dossier privé de l'application
      final appDir = await getApplicationDocumentsDirectory();
      
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Candidature_ENA_${data.nom}_${data.postnom}_$timestamp.pdf';
      final file = File('${appDir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      // Proposer le partage automatiquement
      await _offerPdfOptions(file);
      
      return file.path;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Propose les options de partage/sauvegarde du PDF à l'utilisateur
  Future<void> _offerPdfOptions(File pdfFile) async {
    try {
      // Partager automatiquement le PDF via le menu de partage Android/iOS
      await Share.shareXFiles([XFile(pdfFile.path)], 
        text: 'Voici votre PDF de candidature ENA');
    } catch (e) {
      // En cas d'erreur de partage, le fichier reste disponible dans l'app
      // Note: En production, utiliser un système de logging approprié
    }
  }
}
