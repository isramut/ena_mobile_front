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
  
  /// Vérifie les permissions de stockage de manière simple
  Future<bool> _checkStoragePermissions() async {
    if (Platform.isAndroid) {
      try {
        // Essayer d'accéder au dossier Downloads
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          // Tester l'écriture en créant un fichier temporaire
          final testFile = File('${downloadsDir.path}/.test_ena_permission');
          await testFile.writeAsString('test');
          await testFile.delete();
          return true;
        }
      } catch (e) {
        // Si erreur d'accès, permissions non accordées
        return false;
      }
    } else if (Platform.isIOS) {
      // Sur iOS, pas besoin de permissions pour le dossier Documents de l'app
      return true;
    }
    
    return false;
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

  /// Sauvegarde le PDF dans le dossier Downloads/Documents de l'utilisateur
  Future<String> _savePdfToDownloads(pw.Document pdf, CandidaturePdfData data) async {
    try {
      final bytes = await pdf.save();
      
      // Obtenir le dossier approprié selon la plateforme
      Directory? targetDir;
      
      if (Platform.isAndroid) {
        // Sur Android, utiliser le dossier Downloads
        targetDir = Directory('/storage/emulated/0/Download');
        
        // Si le dossier Downloads n'est pas accessible, utiliser le dossier externe
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
          if (targetDir != null) {
            targetDir = Directory('${targetDir.path}/Downloads');
            await targetDir.create(recursive: true);
          } else {
            throw Exception('Impossible d\'accéder au stockage externe');
          }
        }
      } else if (Platform.isIOS) {
        // Sur iOS, utiliser le dossier Documents de l'application
        targetDir = await getApplicationDocumentsDirectory();
      } else {
        // Pour les autres plateformes
        targetDir = await getApplicationDocumentsDirectory();
      }
      
      if (!await targetDir.exists()) {
        throw Exception('Impossible d\'accéder au dossier de téléchargement');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Candidature_ENA_${data.nom}_${data.postnom}_$timestamp.pdf';
      final file = File('${targetDir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }
}
