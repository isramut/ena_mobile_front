import 'dart:convert';
import 'dart:io';
import 'package:ena_mobile_front/models/user_info.dart';
import 'package:ena_mobile_front/services/auth_api_service.dart';
import 'package:ena_mobile_front/services/image_cache_service.dart';
import 'package:ena_mobile_front/services/profile_update_notification_service.dart';
import 'package:ena_mobile_front/widgets/avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  bool editing = false;
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  String firstName = "";
  String lastName = "";
  String middleName = "";
  String email = "";
  String address = "";
  String phone = "";
  String profilePicture = "";
  String initials = "";
  
  // UserInfo pour l'avatar uniforme
  UserInfo? _userInfo;
  
  // Nouvelle image sélectionnée
  XFile? _selectedImage;

  // Pour édition
  late String editFirstName;
  late String editLastName;
  late String editMiddleName;
  late String editEmail;
  late String editAddress;
  late String editPhone;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Essayer de charger depuis le cache en priorité (même cache que le header)
      final cachedUserInfo = prefs.getString('user_info_cache');
      if (cachedUserInfo != null && cachedUserInfo.isNotEmpty) {
        try {
          final data = jsonDecode(cachedUserInfo);
          if (mounted) {
            setState(() {
              firstName = data['first_name'] ?? "";
              lastName = data['last_name'] ?? "";
              middleName = data['middle_name'] ?? "";
              email = data['email'] ?? "";
              address = data['adresse_physique'] ?? "";
              phone = data['telephone'] ?? "";
              profilePicture = data['profile_picture'] ?? "";
              initials = _generateInitials(firstName, lastName);
              _userInfo = UserInfo.fromJson(data);
              loading = false;
            });
          }
          return; // Utiliser le cache et éviter l'appel API
        } catch (e) {
          // Si erreur de parsing du cache, continuer avec l'appel API
        }
      }

      // Si pas de cache valide, faire un appel API
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
        return;
      }

      final result = await AuthApiService.getUserInfo(token: token);
      
      if (mounted && result['success']) {
        final data = result['data'];
        setState(() {
          firstName = data['first_name'] ?? "";
          lastName = data['last_name'] ?? "";
          middleName = data['middle_name'] ?? "";
          email = data['email'] ?? "";
          address = data['adresse_physique'] ?? "";
          phone = data['telephone'] ?? "";
          profilePicture = data['profile_picture'] ?? "";
          initials = _generateInitials(firstName, lastName);
          _userInfo = UserInfo.fromJson(data);
          loading = false;
        });
        
        // Mettre à jour le cache local (même cache que le header)
        await prefs.setString('user_info_cache', jsonEncode(data));
      } else {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String _generateInitials(String firstName, String lastName) {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return (firstName[0] + lastName[0]).toUpperCase();
    } else if ((firstName + lastName).isNotEmpty) {
      return (firstName + lastName)[0].toUpperCase();
    }
    return "";
  }

  String get fullName {
    String n = lastName;
    if (middleName.isNotEmpty) n += " $middleName";
    n += " $firstName";
    return n.trim();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        _showErrorSnackBar("Session expirée. Veuillez vous reconnecter.");
        setState(() => loading = false);
        return;
      }

      // MISE À JOUR EN 2 ÉTAPES : Profil candidat + Informations contact

      // 1️⃣ Mise à jour du profil candidat (nom, prénom, postnom, adresse, photo)
      final profileResult = await AuthApiService.updateUserInfo(
        token: token,
        firstName: editFirstName,        // → prenom
        lastName: editLastName,          // → nom  
        middleName: editMiddleName.isNotEmpty ? editMiddleName : null, // → postnom
        adressePhysique: editAddress.isNotEmpty ? editAddress : null,  // → adresse_physique
        profilePicturePath: _selectedImage?.path, // → photo
      );

      if (!profileResult['success']) {
        setState(() => loading = false);
        _showErrorSnackBar(profileResult['error'] ?? "Erreur lors de la mise à jour du profil");
        return;
      }

      // 2️⃣ Mise à jour des informations de contact (email, téléphone)
      final contactResult = await AuthApiService.updateUserContactInfo(
        token: token,
        email: editEmail,
        telephone: editPhone.isNotEmpty ? editPhone : null,
      );

      if (!contactResult['success']) {
        setState(() => loading = false);
        _showErrorSnackBar(contactResult['error'] ?? "Erreur lors de la mise à jour des informations de contact");
        return;
      }

      // 3️⃣ Combiner les résultats pour la mise à jour de l'interface
      final Map<String, dynamic> combinedData = <String, dynamic>{
        ...profileResult['data'] ?? <String, dynamic>{},
        ...contactResult['data'] ?? <String, dynamic>{},
      };
      
      final Map<String, dynamic> result = {
        'success': true,
        'data': combinedData,
      };

      if (result['success'] == true) {
        setState(() {
          firstName = editFirstName;
          lastName = editLastName;
          middleName = editMiddleName;
          email = editEmail;
          phone = editPhone;
          address = editAddress;
          // Mettre à jour l'URL de la photo de profil
          if (combinedData['photo'] != null) {
            profilePicture = combinedData['photo'];
          } else if (combinedData['profile_picture'] != null) {
            profilePicture = combinedData['profile_picture'];
          }
          // Mettre à jour l'objet UserInfo pour maintenir la cohérence de l'avatar
          _userInfo = UserInfo.fromJson(combinedData);
          // Réinitialiser la sélection d'image
          _selectedImage = null;
          editing = false;
          loading = false;
        });
        
        // Mettre à jour le cache local (même cache que le header)
        await prefs.setString('user_info_cache', jsonEncode(combinedData));
        
        // Invalidater le cache d'images pour forcer le rechargement de la photo de profil
        ImageCacheService.invalidateUserImageCache();
        
        // 🔔 Notifier le header et autres composants de la mise à jour du profil
        ProfileUpdateNotificationService().notifyProfileUpdated(
          photoUpdated: _selectedImage != null,
          personalInfoUpdated: true,
          contactInfoUpdated: true,
          updatedData: combinedData,
        );
        
        _showSuccessSnackBar("Profil mis à jour avec succès !");
      } else {
        setState(() => loading = false);
        _showErrorSnackBar(result['error']?.toString() ?? "Erreur lors de la mise à jour");
      }
    } catch (e) {
      setState(() => loading = false);
      _showErrorSnackBar("Erreur de connexion");
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAvatar(double size) {
    return GestureDetector(
      onTap: editing ? _pickImage : null,
      child: Stack(
        children: [
          _selectedImage != null
              ? CircleAvatar(
                  radius: size,
                  backgroundImage: FileImage(File(_selectedImage!.path)),
                )
              : UserAvatar(
                  userInfo: _userInfo,
                  size: size * 2,
                  borderRadius: size,
                  key: ValueKey('${_userInfo?.fullProfilePictureUrl ?? 'default'}_${ImageCacheService.cacheVersion}'), // Force rebuild avec version cache
                ),
          if (editing)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: size * 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorSnackBar("Erreur lors de la sélection de l'image");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainBlue = theme.colorScheme.primary;
    final lightBlue = theme.colorScheme.secondary;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(context);
          final bottomSafeArea = mediaQuery.padding.bottom;
          final hasNavigationBar = bottomSafeArea > 0;
          
          return ListView(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 12,
              bottom: hasNavigationBar ? bottomSafeArea + 12 : 12,
            ),
        children: [
          Card(
            color: theme.cardColor,
            elevation: 7,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(32),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Profil utilisateur",
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          "$firstName $lastName",
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 5,
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: editing
                  ? Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            initialValue: firstName,
                            decoration: InputDecoration(
                              labelText: "Prénom",
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? "Champ obligatoire"
                                : null,
                            onChanged: (v) => editFirstName = v,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            initialValue: lastName,
                            decoration: InputDecoration(
                              labelText: "Nom",
                              prefixIcon: Icon(
                                Icons.person_2_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? "Champ obligatoire"
                                : null,
                            onChanged: (v) => editLastName = v,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            initialValue: middleName,
                            decoration: InputDecoration(
                              labelText: "Post-nom (optionnel)",
                              prefixIcon: Icon(
                                Icons.person_3_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            onChanged: (v) => editMiddleName = v,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            initialValue: email,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return "Champ obligatoire";
                              if (!v.contains('@')) return "Email invalide";
                              return null;
                            },
                            onChanged: (v) => editEmail = v,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            initialValue: phone,
                            decoration: InputDecoration(
                              labelText: "Téléphone",
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => editPhone = v,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            initialValue: address,
                            decoration: InputDecoration(
                              labelText: "Adresse physique",
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            maxLines: 2,
                            onChanged: (v) => editAddress = v,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_alt_rounded),
                                  label: Text(loading ? "Sauvegarde..." : "Enregistrer"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: mainBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    textStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),                                  onPressed: loading ? null : _saveChanges,
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: loading ? null : () => setState(() {
                                  _selectedImage = null; // Réinitialiser la sélection d'image
                                  editing = false;
                                }),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: mainBlue,
                                  side: BorderSide(color: mainBlue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text("Annuler"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.person_outline_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            "Prénom",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            firstName.isNotEmpty ? firstName : "Non renseigné",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.person_2_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            "Nom",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            lastName.isNotEmpty ? lastName : "Non renseigné",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.person_3_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            "Post-nom",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            middleName.isNotEmpty ? middleName : "Non renseigné",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.email_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            "Email",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            email.isNotEmpty ? email : "Non renseigné",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.phone_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            "Téléphone",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            phone.isNotEmpty ? phone : "Non renseigné",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            "Adresse physique",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            address.isNotEmpty ? address : "Non renseigné",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit, size: 20),
                              label: const Text("Modifier"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: lightBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 15,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  editFirstName = firstName;
                                  editLastName = lastName;
                                  editMiddleName = middleName;
                                  editEmail = email;
                                  editPhone = phone;
                                  editAddress = address;
                                  _selectedImage = null; // Réinitialiser la sélection d'image
                                  editing = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
          );
        },
      ),
    );
  }
}
