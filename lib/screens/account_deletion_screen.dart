import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/account_deletion_service.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _showReasonField = false;

  // Propriétés responsives
  late bool _isTablet;
  late bool _isLandscape;
  late double _screenWidth;
  late double _screenHeight;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateScreenInfo();
  }

  void _updateScreenInfo() {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _isTablet = _screenWidth > 600;
    _isLandscape = _screenWidth > _screenHeight;
  }

  double _getResponsiveFontSize(double baseSize) {
    if (_isTablet) {
      return baseSize + 2;
    }
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color mainBlue = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Suppression de compte',
          style: GoogleFonts.poppins(
            fontSize: _getResponsiveFontSize(20),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(mainBlue),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: _isTablet ? 24 : 16),
                  Text(
                    'Traitement en cours...',
                    style: GoogleFonts.poppins(
                      fontSize: _getResponsiveFontSize(16),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            )
          : _buildResponsiveBody(),
    );
  }

  Widget _buildResponsiveBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(_isTablet ? 24 : 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1200 && constraints.maxHeight > 800) {
              return _buildDesktopLayout();
            } else if (constraints.maxWidth > 600) {
              return _buildTabletLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 800,
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: _buildInfoCard()),
            SizedBox(width: 32),
            Expanded(flex: 1, child: _buildDeletionCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 700),
        child: Column(
          children: [
            _buildInfoCard(),
            SizedBox(height: 24),
            _buildDeletionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildInfoCard(),
        SizedBox(height: 20),
        _buildDeletionCard(),
      ],
    );
  }

  Widget _buildInfoCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      child: Padding(
        padding: EdgeInsets.all(_isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: _getResponsiveFontSize(24),
                ),
                SizedBox(width: 12),
                Text(
                  'Attention',
                  style: GoogleFonts.poppins(
                    fontSize: _getResponsiveFontSize(20),
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'La suppression de votre compte est définitive.',
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(16),
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '• Toutes vos données seront supprimées\n'
              '• Vous ne pourrez plus accéder à l\'application\n'
              '• Cette action ne peut pas être annulée après 30 jours',
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(14),
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Vous recevrez une confirmation par email et aurez 30 jours pour annuler si vous changez d\'avis.',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(13),
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletionCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      child: Padding(
        padding: EdgeInsets.all(_isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Case à cocher pour afficher le champ de raison
            Row(
              children: [
                Checkbox(
                  value: _showReasonField,
                  onChanged: (bool? value) {
                    setState(() {
                      _showReasonField = value ?? false;
                      if (!_showReasonField) {
                        _reasonController.clear();
                      }
                    });
                  },
                  activeColor: Colors.red,
                ),
                Expanded(
                  child: Text(
                    'Je souhaite préciser la raison de la suppression',
                    style: GoogleFonts.poppins(
                      fontSize: _getResponsiveFontSize(14),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            
            // Champ de raison (visible seulement si la case est cochée)
            if (_showReasonField) ...[
              SizedBox(height: 16),
              Text(
                'Raison de la suppression',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(16),
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Pourquoi souhaitez-vous supprimer votre compte ?',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: _getResponsiveFontSize(14),
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(14),
                ),
              ),
            ],
            
            SizedBox(height: 24),
            
            // Actions
            if (_isTablet && _isLandscape) 
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _showConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: _isTablet ? 24 : 16,
                        vertical: _isTablet ? 14 : 12,
                      ),
                    ),
                    child: Text(
                      'Supprimer mon compte',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: _isTablet ? 16 : 14,
                    ),
                  ),
                  child: Text(
                    'Supprimer mon compte',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.poppins(
                      fontSize: _getResponsiveFontSize(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning, 
                color: Colors.red, 
                size: _isTablet ? 32 : 28,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '⚠️ ATTENTION', 
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: _getResponsiveFontSize(18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _isTablet ? 500 : double.infinity,
              maxHeight: _screenHeight * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cette action va SUPPRIMER DÉFINITIVEMENT votre compte dans 30 jours.',
                    style: GoogleFonts.poppins(
                      fontSize: _getResponsiveFontSize(16),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vous recevrez une confirmation par email et aurez 30 jours pour annuler si vous changez d\'avis.',
                    style: GoogleFonts.poppins(
                      color: Colors.blue[700], 
                      fontSize: _getResponsiveFontSize(13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (_isLandscape) 
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _submitDeletion();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: _isTablet ? 24 : 16,
                        vertical: _isTablet ? 14 : 12,
                      ),
                    ),
                    child: Text(
                      'Confirmer la suppression',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style: GoogleFonts.poppins(
                    fontSize: _getResponsiveFontSize(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _submitDeletion();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: _isTablet ? 24 : 16,
                    vertical: _isTablet ? 14 : 12,
                  ),
                ),
                child: Text(
                  'Confirmer la suppression',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _submitDeletion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AccountDeletionService.requestAccountDeletion(
        reason: _reasonController.text.trim().isEmpty 
            ? null 
            : _reasonController.text.trim(),
      );

      if (result['success']) {
        _showSuccessDialog(result['message'] ?? result['data']?['message'] ?? 'Demande envoyée avec succès');
      } else {
        _showErrorDialog(result['error'] ?? 'Une erreur s\'est produite');
      }
    } catch (e) {
      _showErrorDialog('Une erreur inattendue s\'est produite. Veuillez réessayer.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: _getResponsiveFontSize(24),
              ),
              SizedBox(width: 8),
              Text(
                'Demande envoyée',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(18),
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(14),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
                Navigator.of(context).pop(); // Retourner à l'écran précédent
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
                size: _getResponsiveFontSize(24),
              ),
              SizedBox(width: 8),
              Text(
                'Erreur',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(18),
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(14),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
