import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import 'package:country_picker/country_picker.dart';

class CreateClientScreen extends StatefulWidget {
  const CreateClientScreen({super.key});

  @override
  State<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _CreateClientScreenState extends State<CreateClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCountryCode = "+34";

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final clientService = Provider.of<ClientService>(context, listen: false);

    final user = authService.currentUserData;
    if (user == null || user.organizationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mustBelongToOrganization), // Usando clave existente
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final clientId = await clientService.createClient(
      name: _nameController.text.trim(),
      company: _companyController.text.trim(),
      email: _emailController.text.trim(),
      phone: (_phoneController.text.trim().startsWith('+') ? _phoneController.text.trim() : '$_selectedCountryCode${_phoneController.text.trim()}'),
      
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      organizationId: user.organizationId!,
      createdBy: user.uid,
    );

    if (mounted) {
      if (clientId != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clientCreatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(clientService.error ?? l10n.createClientError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientService = Provider.of<ClientService>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newClientTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Información básica
                Text(
                  l10n.basicInfoSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.contactNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterNameError;
                    }
                    if (value.length < 2) {
                      return l10n.nameLengthError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _companyController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.companyLabel,
                    prefixIcon: const Icon(Icons.business),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterCompanyError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterEmailError;
                    }
                    if (!value.contains('@')) {
                      return l10n.enterValidEmailError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phoneLabel,
                    hintText: '123 456 789',
                    border: const OutlineInputBorder(),
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            favorite: <String>['ES'],
                            showPhoneCode: true,
                            onSelect: (Country country) {
                              setState(() {
                                _selectedCountryCode = "+${country.phoneCode}";
                              });
                            },
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCountryCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Dirección
                Text(
                  l10n.addressLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.addressLabel,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: const OutlineInputBorder(),
                    helperText: l10n.addressHelper,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.cityLabel,
                          prefixIcon: const Icon(Icons.location_city),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _postalCodeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.zipCodeLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryController,
                  readOnly: true,
                  onTap: () {
                    showCountryPicker(
                      context: context,
                      favorite: <String>['ES'],
                      showPhoneCode: false,
                      onSelect: (Country country) {
                        setState(() {
                          _countryController.text = "${country.flagEmoji} ${country.nameLocalized ?? country.name}";
                        });
                      },
                      countryListTheme: CountryListThemeData(
                        borderRadius: BorderRadius.circular(15),
                        inputDecoration: InputDecoration(
                          labelText: l10n.searchCountryHint,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    labelText: l10n.countryLabel,
                    prefixIcon: const Icon(Icons.public),
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                ),
                const SizedBox(height: 24),

                // Notas
                Text(
                  l10n.additionalNotesSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.notesSection,
                    prefixIcon: const Icon(Icons.note_outlined),
                    border: const OutlineInputBorder(),
                    helperText: l10n.additionalNotesHelper,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                // Botones
                FilledButton(
                  onPressed: clientService.isLoading ? null : () => _handleCreate(l10n),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: clientService.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.createClientButton,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}