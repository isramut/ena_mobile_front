import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String subject = '';
  String message = '';
  bool loading = false;

  void _launchEmail() async {
    final url = Uri(
      scheme: 'mailto',
      path: 'info@ena.cd',
      query: 'subject=Demande%20d\'information%20ENA',
    );
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir votre application email."),
        ),
      );
    }
  }

  void _launchPhone() async {
    final url = Uri.parse('tel:+243832222920');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de lancer l'appel.")),
      );
    }
  }

  void _launchMaps() async {
    final url = Uri.parse('https://maps.google.com/?q=ENA,+Kinshasa');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir Google Maps.")),
      );
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Votre message a bien été envoyé. Merci !")),
    );
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color mainBlue = theme.colorScheme.primary;
    final Color lightBlue = theme.colorScheme.secondary;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // Bandeau titre (bleu ENA)
            Card(
              color: mainBlue,
              elevation: 7,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contactez-nous",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      "L'équipe ENA est à votre écoute pour toute question ou demande d'information.",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section contact cards
            Card(
              elevation: 4,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.location_on_rounded,
                  color: mainBlue,
                  size: 28,
                ),
                title: Text(
                  "Avenue de la Démocratie, Commune de la Gombe, Kinshasa, RDC",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.map_outlined, color: lightBlue),
                  onPressed: _launchMaps,
                  tooltip: "Voir sur Google Maps",
                ),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 4,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: ListTile(
                leading: Icon(Icons.email_rounded, color: mainBlue, size: 26),
                title: Text(
                  "contact@ena.cd",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.send_rounded, color: lightBlue),
                  onPressed: _launchEmail,
                  tooltip: "Envoyer un email",
                ),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 4,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: ListTile(
                leading: Icon(Icons.phone_rounded, color: mainBlue, size: 27),
                title: Text(
                  "+243 812 345 678",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.call_rounded, color: lightBlue),
                  onPressed: _launchPhone,
                  tooltip: "Appeler",
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Formulaire de contact
            Card(
              color: theme.colorScheme.surface,
              elevation: 7,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 23,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        "Formulaire de contact",
                        style: GoogleFonts.poppins(
                          color: mainBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Nom
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Nom complet",
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withValues(
                            alpha: 0.05,
                          ),
                        ),
                        onChanged: (v) => name = v,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Champ obligatoire" : null,
                      ),
                      const SizedBox(height: 15),

                      // Email
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withValues(
                            alpha: 0.05,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => email = v,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Champ obligatoire";
                          }
                          if (!v.contains('@')) return "Email invalide";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Objet
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Objet",
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.subject_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withValues(
                            alpha: 0.05,
                          ),
                        ),
                        onChanged: (v) => subject = v,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Champ obligatoire" : null,
                      ),
                      const SizedBox(height: 15),

                      // Message
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Message",
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.message_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withValues(
                            alpha: 0.05,
                          ),
                          counterText: "", // Cacher le compteur par défaut
                        ),
                        maxLines: 5,
                        maxLength: 5000,
                        keyboardType: TextInputType.multiline,
                        onChanged: (v) => message = v,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Champ obligatoire";
                          }
                          if (v.length > 5000) return "Maximum 5000 caractères";
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send_rounded),
                          label: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Envoyer"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainBlue,
                            foregroundColor: Colors.white,
                            textStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: loading ? null : _submitForm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ],
    );
  }
}
