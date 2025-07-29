import 'package:ena_mobile_front/features/apply/candidature_process_screen.dart';
import 'package:ena_mobile_front/features/recours/recours_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_navigator.dart';

class PostulerContent extends StatelessWidget {
  const PostulerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainBlue = theme.colorScheme.primary;
    final accentBlue = theme.colorScheme.secondary;
    final redAccent = theme.colorScheme.error;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      children: [
        Text(
          "Postuler à l'ENA RDC",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: mainBlue,
          ),
        ),
        const SizedBox(height: 18),

        // ---- Conditions ----
        Card(
          color: accentBlue.withValues(alpha: .09),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Conditions pour postuler",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: mainBlue,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ...[
                  {
                    "icon": Icons.flag_rounded,
                    "txt": "Être de nationalité congolaise",
                  },
                  {
                    "icon": Icons.check_rounded,
                    "txt": "Jouir de la plénitude de ses droits civiques",
                  },
                  {
                    "icon": Icons.cake_outlined,
                    "txt": "Avoir entre 18 et 35 ans à la date du recrutement",
                  },
                  {
                    "icon": Icons.school_rounded,
                    "txt": "Être titulaire d'un diplôme Bac+5 ou équivalent",
                  },
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          item["icon"] as IconData,
                          color: accentBlue,
                          size: 19,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            item["txt"] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ---- Pièces à fournir ----
        Card(
          color: theme.colorScheme.surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pièces à fournir (à déposer en ligne)",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: redAccent,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 11),
                _fileRow(
                  "Carte d'électeur certifiée ou passeport",
                  Icons.credit_card,
                  theme,
                ),
                _fileRow(
                  "Lettre de motivation manuscrite\n(adressée au Directeur Général)",
                  Icons.description_outlined,
                  theme,
                ),
                _fileRow("CV avec photo", Icons.person_rounded, theme),
                _fileRow(
                  "Acte d'admission sous statut (si fonctionnaire)",
                  Icons.assignment_ind_outlined,
                  theme,
                ),
                _fileRow(
                  "Diplôme Bac+5 ou équivalent (ou relevé dernière année)",
                  Icons.school_outlined,
                  theme,
                ),
                _fileRow(
                  "Attestation d'aptitude physique de moins de 3 mois\n(par hôpital public)",
                  Icons.health_and_safety_outlined,
                  theme,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ---- Processus ----
        Card(
          color: theme.colorScheme.surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Processus de candidature",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: mainBlue,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 11),
                _stepWidget(
                  "1. Créer un compte",
                  "Enregistre-toi avec ton email pour créer ton profil candidat.",
                  accentBlue,
                  theme,
                ),
                _stepWidget(
                  "2. Remplir le formulaire",
                  "Complète toutes les informations personnelles et académiques requises.",
                  accentBlue,
                  theme,
                ),
                _stepWidget(
                  "3. Joindre les documents",
                  "Télécharge tous les documents demandés au format PDF ou image.",
                  accentBlue,
                  theme,
                ),
                _stepWidget(
                  "4. Soumettre la candidature",
                  "Vérifie et valide définitivement ta candidature avant la date limite.",
                  accentBlue,
                  theme,
                ),
                _stepWidget(
                  "5. Suivi du dossier",
                  "Consulte l'évolution de ton dossier via ton espace candidat.",
                  accentBlue,
                  theme,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ---- CTA Principal ----
        Card(
          color: theme.colorScheme.surface,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              children: [
                Text(
                  "Prêt(e) à postuler ?",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: mainBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Commence dès maintenant ta candidature en ligne.",
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    AppNavigator.pushForm(
                      context,
                      const CandidatureProcessScreen(),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text("Commencer ma candidature"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Aide
        Card(
          color: accentBlue.withValues(alpha: .09),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          child: ListTile(
            leading: Icon(Icons.info_outline, color: accentBlue, size: 30),
            title: Text(
              "Besoin d'aide ?",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: mainBlue,
              ),
            ),
            subtitle: Text(
              "Consultez notre FAQ ou contactez l'assistance via la page Contact.",
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Recours
        Card(
          color: redAccent.withValues(alpha: .09),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.gavel_rounded, color: redAccent, size: 30),
            title: Text(
              "Faire un recours",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: redAccent,
              ),
            ),
            subtitle: Text(
              "Candidature éliminée ? Vous pouvez faire un recours dans les 48h.",
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: redAccent, size: 16),
            onTap: () {
              AppNavigator.push(context, const RecoursScreen());
            },
          ),
        ),
      ],
    );
  }

  Widget _fileRow(String text, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepWidget(
    String step,
    String description,
    Color color,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
