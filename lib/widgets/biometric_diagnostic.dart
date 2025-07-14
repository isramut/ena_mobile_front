import 'dart:io';
import 'package:flutter/material.dart';
import '../services/biometric_service.dart';

/// Widget de test pour diagnostiquer la détection biométrique sur différents appareils
class BiometricDiagnosticPage extends StatefulWidget {
  const BiometricDiagnosticPage({super.key});

  @override
  State<BiometricDiagnosticPage> createState() => _BiometricDiagnosticPageState();
}

class _BiometricDiagnosticPageState extends State<BiometricDiagnosticPage> {
  Map<String, dynamic> _diagnosticResults = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() => _loading = true);

    try {
      final results = <String, dynamic>{};
      
      // Test 1: Support de l'appareil
      results['Platform'] = Platform.operatingSystem;
      results['isDeviceSupported'] = await BiometricAuthService.isDeviceSupported();
      
      // Test 2: Biométries disponibles
      results['availableBiometrics'] = await BiometricAuthService.getAvailableBiometrics();
      
      // Test 3: Disponibilité globale
      results['isBiometricAvailableOnDevice'] = await BiometricAuthService.isBiometricAvailableOnDevice();
      
      // Test 4: Type principal
      results['primaryBiometricType'] = await BiometricAuthService.getPrimaryBiometricType();
      
      // Test 5: État d'activation
      results['isBiometricEnabled'] = await BiometricAuthService.isBiometricEnabled();
      
      // Test 6: Credentials stockés
      results['hasStoredCredentials'] = await BiometricAuthService.hasStoredCredentials();
      
      // Test 7: Diagnostic complet
      results['fullDiagnosis'] = await BiometricAuthService.diagnoseBiometric();

      setState(() {
        _diagnosticResults = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _diagnosticResults = {'error': e.toString()};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Biométrique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostic,
          ),
        ],
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résultats du diagnostic',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          ..._diagnosticResults.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${entry.key}:',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      entry.value.toString(),
                                      style: TextStyle(
                                        color: _getStatusColor(entry.key, entry.value),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions de test',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _testBiometric,
                            child: const Text('Tester l\'authentification'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _showSupportInfo,
                            child: const Text('Infos de support'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getStatusColor(String key, dynamic value) {
    if (key.contains('Available') || key.contains('Enabled') || key.contains('Supported')) {
      return value == true ? Colors.green : Colors.red;
    }
    return Colors.black87;
  }

  Future<void> _testBiometric() async {
    try {
      final result = await BiometricAuthService.testBiometricAuth();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['success'] ? 'Test réussi!' : 'Test échoué: ${result['error']}'),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSupportInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plateforme: ${Platform.operatingSystem}'),
            Text('Version: ${Platform.operatingSystemVersion}'),
            const SizedBox(height: 8),
            const Text('Types d\'authentification supportés:'),
            const Text('• Empreinte digitale'),
            const Text('• Face ID / Face Unlock'),
            const Text('• Reconnaissance iris'),
            const Text('• Schéma de déverrouillage'),
            const Text('• Code PIN'),
            const Text('• Mot de passe de verrouillage'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
