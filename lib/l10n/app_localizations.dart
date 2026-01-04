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
  /// **'Created:'**
  String get createdLabel;

  /// No description provided for @updatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated:'**
  String get updatedLabel;

  /// No description provided for @noProductsInProject.
  ///
  /// In en, this message translates to:
  /// **'No products in this project'**
  String get noProductsInProject;

  /// No description provided for @batchLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch:'**
  String get batchLabel;

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
  /// **'Please enter your name'**
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

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @completeDetails.
  ///
  /// In en, this message translates to:
  /// **'Complete your details'**
  String get completeDetails;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @nameMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get nameMinLengthError;

  /// No description provided for @passwordMinLengthHelper.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get passwordMinLengthHelper;

  /// No description provided for @enterPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get enterPasswordError;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLengthError;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchError;

  /// No description provided for @hideOptionalFields.
  ///
  /// In en, this message translates to:
  /// **'Hide optional fields'**
  String get hideOptionalFields;

  /// No description provided for @showOptionalFields.
  ///
  /// In en, this message translates to:
  /// **'Add additional info (optional)'**
  String get showOptionalFields;

  /// No description provided for @phoneOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptionalLabel;

  /// No description provided for @phoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Ex: +34 123 456 789'**
  String get phoneHelper;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreatedSuccess;

  /// No description provided for @registerError.
  ///
  /// In en, this message translates to:
  /// **'Error registering user'**
  String get registerError;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to our Terms and Conditions and Privacy Policy'**
  String get termsAndConditions;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Error logging in'**
  String get loginError;

  /// No description provided for @accountTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountTypeTitle;

  /// No description provided for @selectAccountTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Select the type of account you want to create:'**
  String get selectAccountTypeMessage;

  /// No description provided for @roleClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get roleClient;

  /// No description provided for @roleClientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View products'**
  String get roleClientSubtitle;

  /// No description provided for @roleManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get roleManufacturer;

  /// No description provided for @roleManufacturerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage production'**
  String get roleManufacturerSubtitle;

  /// No description provided for @roleOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get roleOperator;

  /// No description provided for @roleOperatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Operate processes'**
  String get roleOperatorSubtitle;

  /// No description provided for @roleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get roleAccountant;

  /// No description provided for @roleAccountantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Financial management'**
  String get roleAccountantSubtitle;

  /// No description provided for @googleLoginError.
  ///
  /// In en, this message translates to:
  /// **'Error logging in with Google'**
  String get googleLoginError;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Production Management'**
  String get appTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @recoverPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover Password'**
  String get recoverPasswordTitle;

  /// No description provided for @recoverPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a link to reset your password'**
  String get recoverPasswordSubtitle;

  /// No description provided for @emailAssociatedHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the email associated with your account'**
  String get emailAssociatedHelper;

  /// No description provided for @sendRecoveryLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send recovery link'**
  String get sendRecoveryLinkButton;

  /// No description provided for @backToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLoginButton;

  /// No description provided for @recoveryEmailSentError.
  ///
  /// In en, this message translates to:
  /// **'Error sending recovery email'**
  String get recoveryEmailSentError;

  /// No description provided for @emailSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Email sent!'**
  String get emailSentTitle;

  /// No description provided for @emailSentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We have sent a recovery link to:'**
  String get emailSentSubtitle;

  /// No description provided for @checkInboxMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and follow the instructions to reset your password.'**
  String get checkInboxMessage;

  /// No description provided for @checkSpamMessage.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t receive the email in a few minutes, check your spam folder.'**
  String get checkSpamMessage;

  /// No description provided for @sendToAnotherEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Send to another email'**
  String get sendToAnotherEmailButton;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Catalog'**
  String get catalogTitle;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @showInactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive'**
  String get showInactive;

  /// No description provided for @hideInactive.
  ///
  /// In en, this message translates to:
  /// **'Hide inactive'**
  String get hideInactive;

  /// No description provided for @searchCatalogHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, reference or description...'**
  String get searchCatalogHint;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @noProductsInCatalog.
  ///
  /// In en, this message translates to:
  /// **'No products in the catalog'**
  String get noProductsInCatalog;

  /// No description provided for @tryOtherSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try with other search terms'**
  String get tryOtherSearchTerms;

  /// No description provided for @createFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Create your first product'**
  String get createFirstProduct;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProduct;

  /// No description provided for @deactivateProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate product'**
  String get deactivateProductTitle;

  /// No description provided for @reactivateProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate product'**
  String get reactivateProductTitle;

  /// No description provided for @deactivateProductMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to deactivate \"{name}\"? It will not be deleted, just hidden.'**
  String deactivateProductMessage(Object name);

  /// No description provided for @reactivateProductMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to reactivate \"{name}\"?'**
  String reactivateProductMessage(Object name);

  /// No description provided for @productDeactivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deactivated successfully'**
  String get productDeactivatedSuccess;

  /// No description provided for @productReactivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product reactivated successfully'**
  String get productReactivatedSuccess;

  /// No description provided for @productUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating product'**
  String get productUpdateError;

  /// No description provided for @inactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveStatus;

  /// No description provided for @skuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU: {sku}'**
  String skuLabel(Object sku);

  /// No description provided for @usedCount.
  ///
  /// In en, this message translates to:
  /// **'Used {count, plural, =1{1 time} other{{count} times}}'**
  String usedCount(num count);

  /// No description provided for @usedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get usedLabel;

  /// No description provided for @timeUsageSingle.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get timeUsageSingle;

  /// No description provided for @timeUsageMultiple.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get timeUsageMultiple;

  /// No description provided for @editProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProductTitle;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get productNameLabel;

  /// No description provided for @productNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Rustic dining table'**
  String get productNameHint;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @referenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference/SKU *'**
  String get referenceLabel;

  /// No description provided for @referenceHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: TABLE-001'**
  String get referenceHint;

  /// No description provided for @referenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Reference is required'**
  String get referenceRequired;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the product...'**
  String get descriptionHint;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Furniture'**
  String get categoryHint;

  /// No description provided for @availabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityTitle;

  /// No description provided for @publicProduct.
  ///
  /// In en, this message translates to:
  /// **'Public Product'**
  String get publicProduct;

  /// No description provided for @privateProduct.
  ///
  /// In en, this message translates to:
  /// **'Private Product'**
  String get privateProduct;

  /// No description provided for @publicProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available to all clients'**
  String get publicProductSubtitle;

  /// No description provided for @privateProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only for specific client'**
  String get privateProductSubtitle;

  /// No description provided for @specificClientLabel.
  ///
  /// In en, this message translates to:
  /// **'Specific Client *'**
  String get specificClientLabel;

  /// No description provided for @specificClientHelper.
  ///
  /// In en, this message translates to:
  /// **'This product will only be available to this client'**
  String get specificClientHelper;

  /// No description provided for @noClientsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No clients available. Create a client first.'**
  String get noClientsAvailable;

  /// No description provided for @privateProductInfo.
  ///
  /// In en, this message translates to:
  /// **'Only this client will be able to add this product to their production batches.'**
  String get privateProductInfo;

  /// No description provided for @selectClientError.
  ///
  /// In en, this message translates to:
  /// **'You must select a client'**
  String get selectClientError;

  /// No description provided for @productCreatedPublicSuccess.
  ///
  /// In en, this message translates to:
  /// **'Public product created successfully'**
  String get productCreatedPublicSuccess;

  /// No description provided for @productCreatedPrivateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product created for {client}'**
  String productCreatedPrivateSuccess(Object client);

  /// No description provided for @productEditedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product edited for {client}'**
  String productEditedSuccess(Object client);

  /// No description provided for @createProductError.
  ///
  /// In en, this message translates to:
  /// **'Error creating product'**
  String get createProductError;

  /// No description provided for @dimensionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Dimensions ({unit})'**
  String dimensionsLabel(Object unit);

  /// No description provided for @widthLabel.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get widthLabel;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// No description provided for @depthLabel.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get depthLabel;

  /// No description provided for @materialTitle.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get materialTitle;

  /// No description provided for @primaryMaterialLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Material'**
  String get primaryMaterialLabel;

  /// No description provided for @primaryMaterialHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Oak wood'**
  String get primaryMaterialHint;

  /// No description provided for @secondaryMaterialsLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary Materials'**
  String get secondaryMaterialsLabel;

  /// No description provided for @secondaryMaterialsHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Stainless steel'**
  String get secondaryMaterialsHint;

  /// No description provided for @finishLabel.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishLabel;

  /// No description provided for @finishHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Varnished'**
  String get finishHint;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @colorHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Walnut'**
  String get colorHint;

  /// No description provided for @additionalDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional Data'**
  String get additionalDataTitle;

  /// No description provided for @estimatedWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Weight'**
  String get estimatedWeightLabel;

  /// No description provided for @basePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get basePriceLabel;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Premium, Modern'**
  String get tagsHint;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional information...'**
  String get notesHint;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to discard changes?'**
  String get unsavedChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @productDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Detail'**
  String get productDetailTitle;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @duplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate product'**
  String get duplicateTitle;

  /// No description provided for @duplicateConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to create a copy of \"{name}\"? A new reference will be generated automatically.'**
  String duplicateConfirmMessage(Object name);

  /// No description provided for @productDuplicatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product duplicated successfully'**
  String get productDuplicatedSuccess;

  /// No description provided for @duplicateError.
  ///
  /// In en, this message translates to:
  /// **'Error duplicating product'**
  String get duplicateError;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get deleteTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \"{name}\"? This action cannot be undone.'**
  String deleteConfirmMessage(Object name);

  /// No description provided for @productDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully'**
  String get productDeletedSuccess;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting product'**
  String get deleteError;

  /// No description provided for @productIsInactiveMessage.
  ///
  /// In en, this message translates to:
  /// **'This product is deactivated'**
  String get productIsInactiveMessage;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @systemInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get systemInfoTitle;

  /// No description provided for @createProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get createProductBtn;
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
