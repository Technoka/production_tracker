import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/organization_settings_model.dart';
import '../../services/user_preferences_service.dart';
import '../../services/auth_service.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final AuthService _authService = AuthService();

  UserPreferences? _preferences;
  List<String> _supportedLanguages = ['es', 'en'];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final prefs = await _preferencesService.getUserPreferences(user.uid);
      
      // Obtener usuario para sacar organizationId
      final userDoc = await _authService.getUserData();
      if (userDoc != null) {
        final supportedLangs = await _preferencesService.getSupportedLanguages(
          userDoc.organizationId!,
        );
        setState(() {
          _supportedLanguages = supportedLangs;
        });
      }

      setState(() {
        _preferences = prefs ?? UserPreferences.defaultPreferences();
      });
    } catch (e) {
      print('Error al cargar preferencias: $e');
      setState(() {
        _preferences = UserPreferences.defaultPreferences();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await Provider.of<LocaleProvider>(context, listen: false).changeLanguage(
        userId: user.uid,
        languageCode: languageCode,
      );

      setState(() {
        _preferences = _preferences!.copyWith(
          language: languageCode,
          useSystemLanguage: false,
        );
      });

      _showSuccess(AppLocalizations.of(context)!.settingsSaved);
    } catch (e) {
      _showError('Error al cambiar idioma: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleSystemLanguage(bool value) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final userDoc = await _authService.getUserData();
      if (userDoc == null) return;

      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;

      await Provider.of<LocaleProvider>(context, listen: false).toggleSystemLanguage(
        userId: user.uid,
        useSystemLanguage: value,
        organizationId: userDoc.organizationId!,
        systemLocale: systemLocale,
      );

      setState(() {
        _preferences = _preferences!.copyWith(
          useSystemLanguage: value,
        );
      });

      _showSuccess(AppLocalizations.of(context)!.settingsSaved);
    } catch (e) {
      _showError('Error al actualizar configuración: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateNotificationPreferences(String key, bool value) async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final notifications = Map<String, bool>.from(_preferences!.notifications);
      notifications[key] = value;

      await _preferencesService.updateNotificationPreferences(
        userId: user.uid,
        notifications: notifications,
      );

      setState(() {
        _preferences = _preferences!.copyWith(notifications: notifications);
      });

      _showSuccess(AppLocalizations.of(context)!.settingsSaved);
    } catch (e) {
      _showError('Error al actualizar preferencias: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_preferences == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: Center(child: Text(l10n.error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(l10n.languageSettings),
          
          // Usar idioma del sistema
          SwitchListTile(
            title: Text(l10n.useSystemLanguage),
            subtitle: const Text('Detectar automáticamente el idioma del dispositivo'),
            value: _preferences!.useSystemLanguage,
            onChanged: _isSaving ? null : _toggleSystemLanguage,
          ),

          // Selector de idioma manual
          if (!_preferences!.useSystemLanguage)
            ListTile(
              title: Text(l10n.language),
              subtitle: Text(_getLanguageName(_preferences!.language ?? 'es')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isSaving ? null : _showLanguageSelector,
            ),

          // const Divider(),

          // _buildSectionHeader(l10n.notificationPreferences),

          // Email notifications
          // SwitchListTile(
          //   title: Text(l10n.emailNotifications),
          //   subtitle: const Text('Recibir notificaciones por correo electrónico'),
          //   value: _preferences!.notifications['email'] ?? true,
          //   onChanged: _isSaving 
          //       ? null 
          //       : (value) => _updateNotificationPreferences('email', value),
          // ),

          // // Push notifications
          // SwitchListTile(
          //   title: Text(l10n.pushNotifications),
          //   subtitle: const Text('Recibir notificaciones en tiempo real'),
          //   value: _preferences!.notifications['push'] ?? true,
          //   onChanged: _isSaving 
          //       ? null 
          //       : (value) => _updateNotificationPreferences('push', value),
          // ),

          // const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.selectLanguage,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(),
          ..._supportedLanguages.map((lang) {
            final isSelected = _preferences!.language == lang;
            return ListTile(
              leading: Text(_getLanguageFlag(lang), style: const TextStyle(fontSize: 24)),
              title: Text(_getLanguageName(lang)),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
              selected: isSelected,
              onTap: () {
                Navigator.pop(context);
                _changeLanguage(lang);
              },
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return code.toUpperCase();
    }
  }

  String _getLanguageFlag(String code) {
    switch (code) {
      case 'es':
        return '🇪🇸';
      case 'en':
        return '🇬🇧';
      default:
        return '🌐';
    }
  }
}