import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/candidature_pdf_data.dart';
import '../templates/fiche_soumission_template.dart';

class PdfGeneratorService {
  /// Génère et prévisualise le PDF de candidature
  Future<void> generateAndPreviewPdf(CandidaturePdfData data) async {
    try {
      // Générer le PDF
      final pdf = await _generatePdf(data);
      
      // Sauvegarder dans un fichier temporaire
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/candidature_ENA_${data.nom}_${data.postnom}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Partager le fichier (ouvre la prévisualisation)
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Candidature ENA - ${data.nom} ${data.postnom}',
        text: 'Voici ma fiche de candidature pour l\'École Nationale d\'Administration.',
      );
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  /// Génère le document PDF
  Future<pw.Document> _generatePdf(CandidaturePdfData data) async {
    final pdf = pw.Document();
    
    // Créer la fiche de soumission
    final template = FicheSoumissionTemplate();
    final page = await template.buildPage(data);
    
    pdf.addPage(page);
    
    return pdf;
  }

  /// Sauvegarde le PDF dans le dossier Documents de l'utilisateur
  Future<String> savePdfToDocuments(CandidaturePdfData data) async {
    try {
      final pdf = await _generatePdf(data);
      final bytes = await pdf.save();
      
      // Obtenir le dossier Documents
      Directory? documentsDir;
      if (Platform.isAndroid) {
        documentsDir = await getExternalStorageDirectory();
      } else {
        documentsDir = await getApplicationDocumentsDirectory();
      }
      
      if (documentsDir == null) {
        throw Exception('Impossible d\'accéder au dossier Documents');
      }
      
      final fileName = 'candidature_ENA_${data.nom}_${data.postnom}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${documentsDir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }
}
