import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:gestion_produccion/widgets/app_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/organization_settings_model.dart';
import '../../services/organization_settings_service.dart';
import '../../services/organization_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  final String organizationId;

  const OrganizationSettingsScreen({
    Key? key,
    required this.organizationId,
  }) : super(key: key);

  @override
  State<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends State<OrganizationSettingsScreen>
    with SingleTickerProviderStateMixin {
  final OrganizationSettingsService _settingsService =
      OrganizationSettingsService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;
  OrganizationSettings? _currentSettings;
  OrganizationSettings? _previewSettings;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasPermission = false;
  bool _isPreviewMode = false;

  // Controladores de texto
  final _orgNameController = TextEditingController();
  final _welcomeMessageEsController = TextEditingController();
  final _welcomeMessageEnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orgNameController.dispose();
    _welcomeMessageEsController.dispose();
    _welcomeMessageEnController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _hasPermission = false);
      return;
    }

    final hasPermission = await _settingsService.hasAdminPermissions(
      organizationId: widget.organizationId,
      userId: user.uid,
    );

    setState(() => _hasPermission = hasPermission);
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings =
          await _settingsService.getOrganizationSettings(widget.organizationId);

      if (settings != null) {
        setState(() {
          _currentSettings = settings;
          _previewSettings = settings;

          // Inicializar controladores
          _orgNameController.text = settings.branding.organizationName;
          _welcomeMessageEsController.text =
              settings.branding.welcomeMessage['es'] ?? '';
          _welcomeMessageEnController.text =
              settings.branding.welcomeMessage['en'] ?? '';
        });
      } else {
        // Inicializar con valores por defecto
        await _settingsService.initializeDefaultSettings(widget.organizationId);
        await _loadSettings();
      }
    } catch (e) {
      if (mounted) _showError('${AppLocalizations.of(context)!.error}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_hasPermission) {
      _showError(AppLocalizations.of(context)!.noPermission);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _settingsService.updateOrganizationSettings(
        organizationId: widget.organizationId,
        settings: _previewSettings!,
      );

      // Actualizar tema global
      if (mounted) {
        Provider.of<ThemeProvider>(context, listen: false)
            .updateBranding(_previewSettings!.branding);
      }

      _showSuccess(AppLocalizations.of(context)!.settingsSaved);
      setState(() {
        _currentSettings = _previewSettings;
        _isPreviewMode = false;
      });
    } catch (e) {
      _showError('${AppLocalizations.of(context)!.settingsError}: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickLogo() async {
    try {
      // image_picker devuelve un XFile, que es perfecto
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image == null) return;

      setState(() => _isSaving = true);

      final orgService =
          Provider.of<OrganizationService>(context, listen: false);

      // ✅ PASAMOS EL XFILE DIRECTAMENTE (image), NO File(image.path)
      final logoUrl = await orgService.uploadOrganizationLogo(
        widget.organizationId,
        image,
      );

      if (logoUrl != null) {
        setState(() {
          _previewSettings = _previewSettings!.copyWith(
            branding: _previewSettings!.branding.copyWith(logoUrl: logoUrl),
          );
        });
        _showSuccess(AppLocalizations.of(context)!.logoUploaded);
      } else {
        _showError(AppLocalizations.of(context)!.logoUploadError);
      }
    } catch (e) {
      _showError('${AppLocalizations.of(context)!.logoUploadError}: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _removeLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirm),
        content: Text(AppLocalizations.of(context)!.confirmRemoveLogo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await _settingsService.deleteOrganizationLogo(widget.organizationId);
      setState(() {
        _previewSettings = _previewSettings!.copyWith(
          branding: _previewSettings!.branding.copyWith(logoUrl: null),
        );
      });
      _showSuccess(AppLocalizations.of(context)!.logoRemoved);
    } catch (e) {
      _showError('${AppLocalizations.of(context)!.error}: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _togglePreview() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;

      if (_isPreviewMode) {
        // Aplicar preview al tema
        Provider.of<ThemeProvider>(context, listen: false)
            .updateBranding(_previewSettings!.branding);
      } else {
        // Restaurar tema actual
        Provider.of<ThemeProvider>(context, listen: false)
            .updateBranding(_currentSettings!.branding);
      }
    });
  }

  void _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirm),
        content: Text(AppLocalizations.of(context)!.confirmResetSettings),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.resetToDefault),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _previewSettings = OrganizationSettings.defaultSettings();
      _orgNameController.text = _previewSettings!.branding.organizationName;
      _welcomeMessageEsController.text =
          _previewSettings!.branding.welcomeMessage['es'] ?? '';
      _welcomeMessageEnController.text =
          _previewSettings!.branding.welcomeMessage['en'] ?? '';
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
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
      return AppScaffold(
        title: l10n.organizationSettings,
        currentIndex: AppNavIndex.organization,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return AppScaffold(
        title: l10n.organizationSettings,
        currentIndex: AppNavIndex.organization,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l10n.adminOnly,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_previewSettings == null) {
      return AppScaffold(
        title: l10n.organizationSettings,
        currentIndex: AppNavIndex.organization,
        body: Center(child: Text(l10n.error)),
      );
    }

    return AppScaffold(
      title: l10n.organizationSettings,
      currentIndex: AppNavIndex.organization,
      actions: [
        if (_isPreviewMode)
          IconButton(
            icon: const Icon(Icons.visibility_off),
            onPressed: _togglePreview,
            tooltip: 'Salir de vista previa',
          )
        else
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _togglePreview,
            tooltip: l10n.preview,
          ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: const Icon(Icons.palette), text: l10n.brandingSettings),
              Tab(
                  icon: const Icon(Icons.language),
                  text: l10n.languageSettings),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBrandingTab(),
                _buildLanguageTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveSettings,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? l10n.loading : l10n.save),
      ),
    );
  }

  Widget _buildBrandingTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Section
          _buildSectionTitle(l10n.logo),
          _buildLogoSection(),
          const SizedBox(height: 24),

          // Organization Name
          _buildSectionTitle(l10n.organizationName),
          TextField(
            controller: _orgNameController,
            decoration: InputDecoration(
              hintText: l10n.organizationName,
            ),
            onChanged: (value) {
              setState(() {
                _previewSettings = _previewSettings!.copyWith(
                  branding: _previewSettings!.branding.copyWith(
                    organizationName: value,
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 24),

          // Colors Section
          _buildSectionTitle(l10n.primaryColor),
          _buildColorPicker(
            currentColor: Color(int.parse(
              _previewSettings!.branding.primaryColor.replaceFirst('#', '0xff'),
            )),
            onColorChanged: (color) {
              setState(() {
                _previewSettings = _previewSettings!.copyWith(
                  branding: _previewSettings!.branding.copyWith(
                    primaryColor:
                        '#${color.value.toRadixString(16).substring(2)}',
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          _buildSectionTitle(l10n.secondaryColor),
          _buildColorPicker(
            currentColor: Color(int.parse(
              _previewSettings!.branding.secondaryColor
                  .replaceFirst('#', '0xff'),
            )),
            onColorChanged: (color) {
              setState(() {
                _previewSettings = _previewSettings!.copyWith(
                  branding: _previewSettings!.branding.copyWith(
                    secondaryColor:
                        '#${color.value.toRadixString(16).substring(2)}',
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          _buildSectionTitle(l10n.accentColor),
          _buildColorPicker(
            currentColor: Color(int.parse(
              _previewSettings!.branding.accentColor.replaceFirst('#', '0xff'),
            )),
            onColorChanged: (color) {
              setState(() {
                _previewSettings = _previewSettings!.copyWith(
                  branding: _previewSettings!.branding.copyWith(
                    accentColor:
                        '#${color.value.toRadixString(16).substring(2)}',
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 24),

          // Font Family
          _buildSectionTitle(l10n.fontFamily),
          _buildFontFamilySelector(),
          const SizedBox(height: 24),

          // Welcome Messages
          _buildSectionTitle('${l10n.welcomeMessage} (${l10n.spanish})'),
          TextField(
            controller: _welcomeMessageEsController,
            decoration: InputDecoration(
              hintText: l10n.welcomeMessage,
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                final messages = Map<String, String>.from(
                  _previewSettings!.branding.welcomeMessage,
                );
                messages['es'] = value;
                _previewSettings = _previewSettings!.copyWith(
                  branding: _previewSettings!.branding.copyWith(
                    welcomeMessage: messages,
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('${l10n.welcomeMessage} (${l10n.english})'),
          TextField(
            controller: _welcomeMessageEnController,
            decoration: InputDecoration(
              hintText: l10n.welcomeMessage,
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                final messages = Map<String, String>.from(
                  _previewSettings!.branding.welcomeMessage,
                );
                messages['en'] = value;
                _previewSettings = _previewSettings!.copyWith(
                  branding: _previewSettings!.branding.copyWith(
                    welcomeMessage: messages,
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 24),

          // Reset button
          Center(
            child: OutlinedButton.icon(
              onPressed: _resetToDefault,
              icon: const Icon(Icons.restore),
              label: Text(l10n.resetToDefault),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLanguageTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.defaultLanguage),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _previewSettings!.language.defaultLanguage,
            decoration: InputDecoration(
              hintText: l10n.selectLanguage,
            ),
            items: const [
              DropdownMenuItem(value: 'es', child: Text('🇪🇸 Español')),
              DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _previewSettings = _previewSettings!.copyWith(
                    language: _previewSettings!.language.copyWith(
                      defaultLanguage: value,
                    ),
                  );
                });
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.supportedLanguages),
          const SizedBox(height: 8),
          Text(
            l10n.currentLanguagesLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final logoUrl = _previewSettings!.branding.logoUrl;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (logoUrl != null)
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(logoUrl),
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business, size: 48, color: Colors.grey),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _pickLogo,
                icon: Icon(logoUrl != null ? Icons.edit : Icons.upload),
                label:
                    Text(logoUrl != null ? l10n.changeLogo : l10n.uploadLogo),
              ),
              if (logoUrl != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _removeLogo,
                  icon: const Icon(Icons.delete),
                  label: Text(l10n.removeLogo),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker({
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () async {
        final Color? picked = await showDialog<Color>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.selectColorTitle),
            content: SingleChildScrollView(
              child: ColorPicker(
                color: currentColor,
                onColorChanged: onColorChanged,
                pickersEnabled: const {
                  ColorPickerType.primary: true,
                  ColorPickerType.accent: true,
                  ColorPickerType.wheel: true,
                },
                showColorCode: true,
                colorCodeHasColor: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildFontFamilySelector() {
    final availableFonts = [
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Poppins',
      'Raleway',
      'Ubuntu',
      'Nunito',
      'Inter',
      'Source Sans 3',
      'DM Sans',
      'Work Sans',
      'Fira Sans',
      'Manrope',
      'Rubik',
      'IBM Plex Sans',
      'Heebo',
      'Karla',
    ];

    return DropdownButtonFormField<String>(
      value: _previewSettings!.branding.fontFamily,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.fontFamily,
      ),
      items: availableFonts.map((font) {
        return DropdownMenuItem(
          value: font,
          child: Text(
            font,
            style: GoogleFonts.getFont(font,
                textStyle: const TextStyle(fontSize: 16)),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _previewSettings = _previewSettings!.copyWith(
              branding: _previewSettings!.branding.copyWith(
                fontFamily: value,
              ),
            );
          });
        }
      },
    );
  }
}
