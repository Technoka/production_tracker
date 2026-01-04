import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/client_service.dart';
import '../../models/client_model.dart';
import 'package:country_picker/country_picker.dart';

class EditClientScreen extends StatefulWidget {
  final ClientModel client;

  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _notesController;
  String _selectedCountryCode = "+34";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _companyController = TextEditingController(text: widget.client.company);
    _emailController = TextEditingController(text: widget.client.email);
    _phoneController = TextEditingController(text: widget.client.phone ?? '');
    _addressController = TextEditingController(text: widget.client.address ?? '');
    _cityController = TextEditingController(text: widget.client.city ?? '');
    _postalCodeController = TextEditingController(text: widget.client.postalCode ?? '');
    _countryController = TextEditingController(text: widget.client.country ?? '');
    _notesController = TextEditingController(text: widget.client.notes ?? '');
  }

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

  Future<void> _handleUpdate(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final clientService = Provider.of<ClientService>(context, listen: false);

    final success = await clientService.updateClient(
      organizationId: widget.client.organizationId,
      clientId: widget.client.id,
      name: _nameController.text.trim(),
      company: _companyController.text.trim(),
      email: _emailController.text.trim(),
      phone: (_phoneController.text.trim().startsWith('+') ? _phoneController.text.trim() : '$_selectedCountryCode${_phoneController.text.trim()}'),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clientUpdatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(clientService.error ?? l10n.updateClientError),
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
        title: Text(l10n.editClientTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.basicInfoSection, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                    if (value == null || value.isEmpty) return l10n.enterNameError;
                    if (value.length < 2) return l10n.nameLengthError;
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
                  validator: (value) => (value == null || value.isEmpty) ? l10n.enterCompanyError : null,
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
                    if (value == null || value.isEmpty) return l10n.enterEmailError;
                    if (!value.contains('@')) return l10n.enterValidEmailError;
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
                Text(l10n.addressLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.addressLabel,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: const OutlineInputBorder(),
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
                Text(l10n.additionalNotesSection, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.notesSection,
                    prefixIcon: const Icon(Icons.note_outlined),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: clientService.isLoading ? null : () => _handleUpdate(l10n),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: clientService.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l10n.saveChangesButton, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
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