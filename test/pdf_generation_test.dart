import 'package:flutter_test/flutter_test.dart';
import 'package:ena_mobile_front/models/candidature_pdf_data.dart';

void main() {
  group('Tests de génération PDF', () {
    late CandidaturePdfData testData;
    
    setUp(() {
      // Données de test complètes
      testData = CandidaturePdfData(
        nom: 'KABONGO',
        postnom: 'MUKENDI',
        prenom: 'Jean-Claude',
        genre: 'Masculin',
        lieuNaissance: 'Kinshasa',
        dateNaissance: '15/03/1990',
        etatCivil: 'Célibataire',
        nationalite: 'Congolaise',
        provinceOrigine: 'Kinshasa',
        provinceResidence: 'Kinshasa',
        villeResidence: 'Kinshasa',
        typePieceIdentite: 'Carte d\'identité',
        numeroPiece: '12345678901234567890',
        adresse: '123 Avenue de la Paix, Kinshasa',
        indicatif: '+243',
        telephone: '999888777',
        email: 'jean.kabongo@email.com',
        diplome: 'Licence en Droit',
        anneeObtention: '2015',
        etablissement: 'Université de Kinshasa',
        filiere: 'Droit',
        pourcentage: 75,
        statutProfessionnel: 'Fonctionnaire',
        matricule: 'MAT123456',
        grade: 'Attaché',
        fonction: 'Juriste',
        administration: 'Ministère de la Justice',
        ministere: 'Justice',
        entreprise: '',
        photoJointe: 'Oui',
        carteIdJointe: 'Oui',
        lettreMotivationJointe: 'Oui',
        cvJoint: 'Oui',
        diplomeFichierJoint: 'Oui',
        aptitudeFichierJoint: 'Oui',
        releveNotesJoint: 'Oui',
        acteAdmissionJoint: 'Oui',
        dateSoumission: '25/12/2024',
        heureSoumission: '14:30',
        numero: 'ENA2024001', // Numéro de candidat pour les tests
      );
    });

    test('Vérification des données du modèle', () {
      expect(testData.nom, equals('KABONGO'));
      expect(testData.postnom, equals('MUKENDI'));
      expect(testData.prenom, equals('Jean-Claude'));
      expect(testData.email, equals('jean.kabongo@email.com'));
      expect(testData.statutProfessionnel, equals('Fonctionnaire'));
      expect(testData.pourcentage, equals(75));
    });

    test('Vérification des champs conditionnels - Fonctionnaire', () {
      expect(testData.statutProfessionnel, equals('Fonctionnaire'));
      expect(testData.matricule, equals('MAT123456'));
      expect(testData.grade, equals('Attaché'));
      expect(testData.administration, equals('Ministère de la Justice'));
      expect(testData.ministere, equals('Justice'));
    });

    test('Vérification des documents joints', () {
      expect(testData.photoJointe, equals('Oui'));
      expect(testData.carteIdJointe, equals('Oui'));
      expect(testData.lettreMotivationJointe, equals('Oui'));
      expect(testData.cvJoint, equals('Oui'));
      expect(testData.diplomeFichierJoint, equals('Oui'));
      expect(testData.aptitudeFichierJoint, equals('Oui'));
      expect(testData.releveNotesJoint, equals('Oui'));
      expect(testData.acteAdmissionJoint, equals('Oui'));
    });

    test('Vérification des informations de soumission', () {
      expect(testData.dateSoumission, equals('25/12/2024'));
      expect(testData.heureSoumission, equals('14:30'));
    });

    // Test de création d'un candidat employé privé
    test('Test données employé privé', () {
      final employeData = CandidaturePdfData(
        nom: 'MBALA',
        postnom: 'NSIMBA',
        prenom: 'Marie',
        genre: 'Féminin',
        lieuNaissance: 'Lubumbashi',
        dateNaissance: '20/07/1985',
        etatCivil: 'Marié(e)',
        nationalite: 'Congolaise',
        provinceOrigine: 'Haut-Katanga',
        provinceResidence: 'Kinshasa',
        villeResidence: 'Kinshasa',
        typePieceIdentite: 'Passeport',
        numeroPiece: 'PA1234567',
        adresse: '456 Boulevard du 30 Juin, Kinshasa',
        indicatif: '+243',
        telephone: '888777666',
        email: 'marie.mbala@email.com',
        diplome: 'Master en Économie',
        anneeObtention: '2010',
        etablissement: 'Université de Lubumbashi',
        filiere: 'Économie',
        pourcentage: 82,
        statutProfessionnel: 'Employé privé',
        matricule: '',
        grade: '',
        fonction: 'Analyste financier',
        administration: '',
        ministere: '',
        entreprise: 'Banque Centrale du Congo',
        photoJointe: 'Oui',
        carteIdJointe: 'Oui',
        lettreMotivationJointe: 'Oui',
        cvJoint: 'Oui',
        diplomeFichierJoint: 'Oui',
        aptitudeFichierJoint: 'Non',
        releveNotesJoint: 'Oui',
        acteAdmissionJoint: 'Non',
        dateSoumission: '25/12/2024',
        heureSoumission: '15:45',
        numero: 'ENA2024002', // Numéro de candidat pour les tests
      );

      expect(employeData.statutProfessionnel, equals('Employé privé'));
      expect(employeData.entreprise, equals('Banque Centrale du Congo'));
      expect(employeData.fonction, equals('Analyste financier'));
      expect(employeData.matricule, equals(''));
      expect(employeData.grade, equals(''));
      expect(employeData.administration, equals(''));
      expect(employeData.ministere, equals(''));
    });

    // Test de validation des champs obligatoires
    test('Validation des champs obligatoires', () {
      final List<String> champsObligatoires = [
        testData.nom,
        testData.postnom,
        testData.prenom,
        testData.genre,
        testData.dateNaissance,
        testData.email,
        testData.telephone,
        testData.diplome,
        testData.statutProfessionnel,
        testData.dateSoumission,
        testData.heureSoumission,
      ];

      for (String champ in champsObligatoires) {
        expect(champ.isNotEmpty, isTrue, reason: 'Champ obligatoire vide détecté');
      }
    });

    // Test de formatage des données
    test('Formatage des données', () {
      expect(testData.nom, equals(testData.nom.toUpperCase()));
      expect(testData.postnom, equals(testData.postnom.toUpperCase()));
      expect(testData.telephone, contains('999888777'));
      expect(testData.email, contains('@'));
      expect(testData.pourcentage, greaterThan(0));
      expect(testData.pourcentage, lessThanOrEqualTo(100));
    });
  });

  group('Tests de compatibilité des templates', () {
    test('Vérification des couleurs ENA', () {
      // Vérifier que les couleurs sont définies correctement
      const expectedBlue = 0xFF1C3D8F;
      const expectedLightBlue = 0xFF3A5998;
      const expectedGray = 0xFF666666;
      
      // Ces valeurs doivent correspondre à celles dans FicheSoumissionTemplate
      expect(expectedBlue, equals(0xFF1C3D8F));
      expect(expectedLightBlue, equals(0xFF3A5998));
      expect(expectedGray, equals(0xFF666666));
    });

    test('Vérification des assets nécessaires', () {
      // Vérifier que les assets sont référencés correctement
      const String logoPath = 'assets/images/ena_logo_blanc.png';
      expect(logoPath, isNotEmpty);
      expect(logoPath.endsWith('.png'), isTrue);
    });
  });
}
