import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Marsot Production'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @production.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get production;

  /// No description provided for @kanban.
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get kanban;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @organizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get organizations;

  /// No description provided for @createOrganization.
  ///
  /// In en, this message translates to:
  /// **'Create Organization'**
  String get createOrganization;

  /// No description provided for @organizationName.
  ///
  /// In en, this message translates to:
  /// **'Organization Name'**
  String get organizationName;

  /// No description provided for @organizationSettings.
  ///
  /// In en, this message translates to:
  /// **'Organization Settings'**
  String get organizationSettings;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @inviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get inviteMembers;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editProject;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery Date'**
  String get deliveryDate;

  /// No description provided for @estimatedDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery Date'**
  String get estimatedDeliveryDate;

  /// No description provided for @actualDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Actual Delivery Date'**
  String get actualDeliveryDate;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @assignedMembers.
  ///
  /// In en, this message translates to:
  /// **'Assigned Members'**
  String get assignedMembers;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @customization.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get customization;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @phases.
  ///
  /// In en, this message translates to:
  /// **'Phases'**
  String get phases;

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @phaseProgress.
  ///
  /// In en, this message translates to:
  /// **'Phase Progress'**
  String get phaseProgress;

  /// No description provided for @currentPhase.
  ///
  /// In en, this message translates to:
  /// **'Current Phase'**
  String get currentPhase;

  /// No description provided for @startPhase.
  ///
  /// In en, this message translates to:
  /// **'Start Phase'**
  String get startPhase;

  /// No description provided for @completePhase.
  ///
  /// In en, this message translates to:
  /// **'Complete Phase'**
  String get completePhase;

  /// No description provided for @phaseName.
  ///
  /// In en, this message translates to:
  /// **'Phase Name'**
  String get phaseName;

  /// No description provided for @phaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Phase Order'**
  String get phaseOrder;

  /// No description provided for @productionBatch.
  ///
  /// In en, this message translates to:
  /// **'Production Batch'**
  String get productionBatch;

  /// No description provided for @batches.
  ///
  /// In en, this message translates to:
  /// **'Batches'**
  String get batches;

  /// No description provided for @createBatch.
  ///
  /// In en, this message translates to:
  /// **'Create Batch'**
  String get createBatch;

  /// No description provided for @batchName.
  ///
  /// In en, this message translates to:
  /// **'Batch Name'**
  String get batchName;

  /// No description provided for @inProduction.
  ///
  /// In en, this message translates to:
  /// **'In Production'**
  String get inProduction;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @createClient.
  ///
  /// In en, this message translates to:
  /// **'Create Client'**
  String get createClient;

  /// No description provided for @editClient.
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClient;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @mustBelongToOrganization.
  ///
  /// In en, this message translates to:
  /// **'You must belong to an organization'**
  String get mustBelongToOrganization;

  /// No description provided for @newClient.
  ///
  /// In en, this message translates to:
  /// **'New Client'**
  String get newClient;

  /// No description provided for @searchClientsHint.
  ///
  /// In en, this message translates to:
  /// **'Search clients...'**
  String get searchClientsHint;

  /// No description provided for @noClientsRegistered.
  ///
  /// In en, this message translates to:
  /// **'No clients registered'**
  String get noClientsRegistered;

  /// No description provided for @errorLoadingClients.
  ///
  /// In en, this message translates to:
  /// **'Error loading clients'**
  String get errorLoadingClients;

  /// No description provided for @tapToAddClient.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add one'**
  String get tapToAddClient;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @forSearch.
  ///
  /// In en, this message translates to:
  /// **'for'**
  String get forSearch;

  /// No description provided for @visualSettings.
  ///
  /// In en, this message translates to:
  /// **'Visual Settings'**
  String get visualSettings;

  /// No description provided for @brandingSettings.
  ///
  /// In en, this message translates to:
  /// **'Branding Settings'**
  String get brandingSettings;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get primaryColor;

  /// No description provided for @secondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Secondary Color'**
  String get secondaryColor;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @uploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo'**
  String get uploadLogo;

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change Logo'**
  String get changeLogo;

  /// No description provided for @removeLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get removeLogo;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome Message'**
  String get welcomeMessage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @defaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default Language'**
  String get defaultLanguage;

  /// No description provided for @supportedLanguages.
  ///
  /// In en, this message translates to:
  /// **'Supported Languages'**
  String get supportedLanguages;

  /// No description provided for @useSystemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Use System Language'**
  String get useSystemLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @applyChanges.
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get applyChanges;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @settingsError.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get settingsError;

  /// No description provided for @logoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Logo uploaded successfully'**
  String get logoUploaded;

  /// No description provided for @logoUploadError.
  ///
  /// In en, this message translates to:
  /// **'Error uploading logo'**
  String get logoUploadError;

  /// No description provided for @logoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Logo removed successfully'**
  String get logoRemoved;

  /// No description provided for @confirmRemoveLogo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the logo?'**
  String get confirmRemoveLogo;

  /// No description provided for @confirmResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset to default settings?'**
  String get confirmResetSettings;

  /// No description provided for @noPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action'**
  String get noPermission;

  /// No description provided for @adminOnly.
  ///
  /// In en, this message translates to:
  /// **'Only administrators can access this section'**
  String get adminOnly;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @invalidColor.
  ///
  /// In en, this message translates to:
  /// **'Invalid color format'**
  String get invalidColor;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdLabel(Object date);

  /// No description provided for @updatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated: {date}'**
  String updatedLabel(Object date);

  /// No description provided for @noProductsInProject.
  ///
  /// In en, this message translates to:
  /// **'No products in this project'**
  String get noProductsInProject;

  /// No description provided for @batchLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch: {batch}'**
  String batchLabel(Object batch);

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {quantity} units'**
  String quantityLabel(Object quantity);

  /// No description provided for @clientDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Client Detail'**
  String get clientDetailTitle;

  /// No description provided for @contactInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfoSection;

  /// No description provided for @cityZipLabel.
  ///
  /// In en, this message translates to:
  /// **'City / Zip Code'**
  String get cityZipLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @notesSection.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesSection;

  /// No description provided for @registrationInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Registration Information'**
  String get registrationInfoSection;

  /// No description provided for @creationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Creation Date'**
  String get creationDateLabel;

  /// No description provided for @lastUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdateLabel;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @cantDeleteClientError.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete client. Organization not found.'**
  String get cantDeleteClientError;

  /// No description provided for @deleteClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Client'**
  String get deleteClientTitle;

  /// No description provided for @deleteClientConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? This action cannot be undone.'**
  String deleteClientConfirm(Object name);

  /// No description provided for @clientDeleted.
  ///
  /// In en, this message translates to:
  /// **'Client deleted'**
  String get clientDeleted;

  /// No description provided for @deleteClientError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting client'**
  String get deleteClientError;

  /// No description provided for @newClientTitle.
  ///
  /// In en, this message translates to:
  /// **'New Client'**
  String get newClientTitle;

  /// No description provided for @basicInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfoSection;

  /// No description provided for @contactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Name *'**
  String get contactNameLabel;

  /// No description provided for @enterNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get enterNameError;

  /// No description provided for @nameLengthError.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameLengthError;

  /// No description provided for @companyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company *'**
  String get companyLabel;

  /// No description provided for @enterCompanyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter company'**
  String get enterCompanyError;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email *'**
  String get emailLabel;

  /// No description provided for @enterEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get enterEmailError;

  /// No description provided for @enterValidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmailError;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @addressHelper.
  ///
  /// In en, this message translates to:
  /// **'Street, number, etc.'**
  String get addressHelper;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @zipCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Zip Code'**
  String get zipCodeLabel;

  /// No description provided for @searchCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountryHint;

  /// No description provided for @additionalNotesSection.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotesSection;

  /// No description provided for @additionalNotesHelper.
  ///
  /// In en, this message translates to:
  /// **'Additional info about client'**
  String get additionalNotesHelper;

  /// No description provided for @createClientButton.
  ///
  /// In en, this message translates to:
  /// **'Create Client'**
  String get createClientButton;

  /// No description provided for @clientCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Client created successfully'**
  String get clientCreatedSuccess;

  /// No description provided for @createClientError.
  ///
  /// In en, this message translates to:
  /// **'Error creating client'**
  String get createClientError;

  /// No description provided for @editClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClientTitle;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @clientUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Client updated successfully'**
  String get clientUpdatedSuccess;

  /// No description provided for @updateClientError.
  ///
  /// In en, this message translates to:
  /// **'Error updating client'**
  String get updateClientError;

  /// No description provided for @myProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get myProjectsTitle;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get logoutConfirmMessage;

  /// No description provided for @exitButton.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitButton;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String welcomeUser(Object name);

  /// No description provided for @clientDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here you can see the status of your products in real time'**
  String get clientDashboardSubtitle;

  /// No description provided for @noAssignedProjects.
  ///
  /// In en, this message translates to:
  /// **'You have no assigned projects'**
  String get noAssignedProjects;

  /// No description provided for @noAssignedProjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Projects will appear when a manufacturer\nassigns you as a client'**
  String get noAssignedProjectsSubtitle;

  /// No description provided for @currentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatusLabel;

  /// No description provided for @lastUpdateDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Last update: {date}'**
  String lastUpdateDateLabel(Object date);

  /// No description provided for @productionProgressSection.
  ///
  /// In en, this message translates to:
  /// **'Production Progress'**
  String get productionProgressSection;

  /// No description provided for @stagesHistorySection.
  ///
  /// In en, this message translates to:
  /// **'Stage History'**
  String get stagesHistorySection;

  /// No description provided for @stageStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start: {date}'**
  String stageStartLabel(Object date);

  /// No description provided for @stageEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End: {date}'**
  String stageEndLabel(Object date);

  /// No description provided for @stagesProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} stages completed'**
  String stagesProgress(Object completed, Object total);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
