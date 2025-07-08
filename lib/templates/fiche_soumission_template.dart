import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../models/candidature_pdf_data.dart';

class FicheSoumissionTemplate {
  static const PdfColor enaBlue = PdfColor.fromInt(0xFF1C3D8F);
  static const PdfColor enaLightBlue = PdfColor.fromInt(0xFF3A5998);
  static const PdfColor enaGray = PdfColor.fromInt(0xFF666666);

  Future<pw.Page> buildPage(CandidaturePdfData data) async {
    // Charger le logo ENA
    final logoBytes = await rootBundle.load('assets/images/ena_logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    
    // Charger le badge gouvernemental
    final badgeBytes = await rootBundle.load('assets/images/badge.png');
    final badgeImage = pw.MemoryImage(badgeBytes.buffer.asUint8List());

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête avec logo ENA et badge
            _buildHeaderWithLogos(logoImage, badgeImage),
            pw.SizedBox(height: 20),
            
            // Titre centré
            _buildCenteredTitle(),
            pw.SizedBox(height: 10),
            
            // Numéro de candidat (si disponible)
            if (data.numero != null && data.numero!.isNotEmpty)
              _buildNumeroCandidat(data.numero!),
            pw.SizedBox(height: 20),
            
            // Message de remerciement
            _buildThankYouMessage(),
            pw.SizedBox(height: 20),
            
            // Informations personnelles
            _buildSection('INFORMATIONS PERSONNELLES', [
              _buildInfoRow('Nom:', data.nom),
              _buildInfoRow('Post-nom:', data.postnom),
              _buildInfoRow('Prénom:', data.prenom),
              _buildInfoRow('Genre:', data.genre),
              _buildInfoRow('Lieu de naissance:', data.lieuNaissance),
              _buildInfoRow('Date de naissance:', data.dateNaissance),
              _buildInfoRow('État civil:', data.etatCivil),
              _buildInfoRow('Nationalité:', data.nationalite),
              _buildInfoRow('Province d\'origine:', data.provinceOrigine),
              _buildInfoRow('Province de résidence:', data.provinceResidence),
              _buildInfoRow('Ville de résidence:', data.villeResidence),
            ]),
            
            pw.SizedBox(height: 15),
            
            // Contact
            _buildSection('CONTACT', [
              _buildInfoRow('${data.typePieceIdentite}:', data.numeroPiece),
              _buildInfoRow('Adresse:', data.adresse),
              _buildInfoRow('Téléphone:', '${data.indicatif} ${data.telephone}'),
              _buildInfoRow('Email:', data.email),
            ]),
            
            pw.SizedBox(height: 15),
            
            // Formation
            _buildSection('FORMATION ACADÉMIQUE', [
              _buildInfoRow('Diplôme:', data.diplome),
              _buildInfoRow('Année d\'obtention:', data.anneeObtention),
              _buildInfoRow('Établissement:', data.etablissement),
              _buildInfoRow('Filière:', data.filiere),
              _buildInfoRow('Pourcentage:', '${data.pourcentage}%'),
            ]),
            
            pw.SizedBox(height: 15),
            
            // Statut professionnel
            _buildSection('STATUT PROFESSIONNEL', [
              _buildInfoRow('Statut:', data.statutProfessionnel),
              if (data.statutProfessionnel == 'Fonctionnaire') ...[
                _buildInfoRow('Matricule:', data.matricule),
                _buildInfoRow('Grade:', data.grade),
                _buildInfoRow('Fonction:', data.fonction),
                _buildInfoRow('Administration:', data.administration),
                _buildInfoRow('Ministère:', data.ministere),
              ] else if (data.statutProfessionnel == 'Employé privé') ...[
                _buildInfoRow('Fonction:', data.fonction),
                _buildInfoRow('Entreprise:', data.entreprise),
              ],
            ]),
            
            pw.SizedBox(height: 15),
            
            // Documents joints
            _buildDocumentsSection(data),
            
            pw.Spacer(),
            
            // Pied de page
            _buildFooter(data),
          ],
        );
      },
    );
  }

  pw.Widget _buildHeaderWithLogos(pw.MemoryImage logoImage, pw.MemoryImage badgeImage) {
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Logo ENA à gauche (taille triplée)
          pw.Container(
            width: 192, // Taille triplée : 64 * 3 = 192
            height: 786, // Taille triplée : 262 * 3 = 786
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),
          // Badge gouvernemental à droite (2,61 cm * 2,76 cm selon spécifications)
          pw.Container(
            width: 74, // Équivalent à ~2,61 cm
            height: 78, // Équivalent à ~2,76 cm
            child: pw.Image(badgeImage, fit: pw.BoxFit.contain),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCenteredTitle() {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(
        'FICHE DE CANDIDATURE',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: FicheSoumissionTemplate.enaBlue,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildNumeroCandidat(String numero) {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(
        'N° Candidat: $numero',
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: FicheSoumissionTemplate.enaBlue,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildThankYouMessage() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.green300, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Cher(e) candidat(e),',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: FicheSoumissionTemplate.enaBlue,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Nous vous remercions pour votre candidature à l\'École Nationale d\'Administration. '
            'Votre dossier a été reçu avec succès et sera examiné par notre commission d\'admission. '
            'Nous vous tiendrons informé(e) de l\'évolution de votre candidature dans les meilleurs délais.',
            style: const pw.TextStyle(
              fontSize: 10,
              color: FicheSoumissionTemplate.enaGray,
            ),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'L\'équipe ENA vous souhaite bonne chance !',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: FicheSoumissionTemplate.enaBlue,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSection(String title, List<pw.Widget> content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: FicheSoumissionTemplate.enaLightBlue,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: content,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isNotEmpty ? value : '-',
              style: const pw.TextStyle(
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(CandidaturePdfData data) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'École Nationale d\'Administration',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: FicheSoumissionTemplate.enaBlue,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Adresse : Avenue des Aviateurs, Commune de la Gombe, Kinshasa',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            'Site web : www.ena.cd',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            'Email : info@ena.cd',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Document généré le ${data.dateSoumission} à ${data.heureSoumission}',
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDocumentsSection(CandidaturePdfData data) {
    // Liste des documents avec leurs libellés détaillés
    List<Map<String, String>> documents = [
      {
        'libelle': 'Photo d\'identité',
        'champ': 'Photo passeport (4x4 cm)',
        'fichier': data.photoJointe,
      },
      {
        'libelle': 'Pièce d\'identité',
        'champ': 'Carte d\'identité nationale ou passeport',
        'fichier': data.carteIdJointe,
      },
      {
        'libelle': 'Lettre de motivation',
        'champ': 'Lettre de motivation manuscrite',
        'fichier': data.lettreMotivationJointe,
      },
      {
        'libelle': 'Curriculum Vitae',
        'champ': 'CV détaillé et actualisé',
        'fichier': data.cvJoint,
      },
      {
        'libelle': 'Diplôme',
        'champ': 'Copie certifiée conforme du diplôme',
        'fichier': data.diplomeFichierJoint,
      },
      {
        'libelle': 'Attestation d\'aptitude',
        'champ': 'Attestation d\'aptitude physique et mentale',
        'fichier': data.aptitudeFichierJoint,
      },
      {
        'libelle': 'Relevés de notes',
        'champ': 'Relevés de notes des années d\'études',
        'fichier': data.releveNotesJoint,
      },
    ];

    // Ajouter l'acte d'admission si c'est un fonctionnaire
    if (data.statutProfessionnel == 'Fonctionnaire') {
      documents.add({
        'libelle': 'Acte d\'admission',
        'champ': 'Acte d\'admission à la fonction publique',
        'fichier': data.acteAdmissionJoint,
      });
    }

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Titre de la section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: enaBlue,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'DOCUMENTS SOUMIS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          
          pw.SizedBox(height: 8),
          
          // Tableau des documents
          pw.Table(
            border: pw.TableBorder.all(color: enaGray, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(100),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
            },
            children: [
              // En-tête du tableau
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8F9FA),
                ),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'N°',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: enaBlue,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'LIBELLÉ DU DOCUMENT',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: enaBlue,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'FICHIER SOUMIS',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: enaBlue,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              
              // Lignes des documents
              ...documents.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, String> doc = entry.value;
                
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: index % 2 == 0 
                        ? PdfColors.white 
                        : PdfColor.fromInt(0xFFF8F9FA),
                  ),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${index + 1}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: enaGray,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            doc['libelle']!,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: enaBlue,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            doc['champ']!,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: enaGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        doc['fichier']!.isNotEmpty 
                            ? doc['fichier']!
                            : 'Non fourni',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: doc['fichier']!.isNotEmpty 
                              ? PdfColors.black 
                              : PdfColors.red,
                          fontWeight: doc['fichier']!.isNotEmpty 
                              ? pw.FontWeight.normal 
                              : pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          
          pw.SizedBox(height: 10),
          
          // Note explicative
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF3F4F6),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: enaLightBlue, width: 1),
            ),
            child: pw.Text(
              '📋 Note: Cette section présente tous les documents requis pour la candidature avec leurs libellés officiels et les fichiers effectivement soumis par le candidat.',
              style: pw.TextStyle(
                fontSize: 8,
                color: enaGray,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}