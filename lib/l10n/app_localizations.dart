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
  /// **'Quantity'**
  String get quantityLabel;

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
  /// **'SKU:'**
  String get skuLabel;

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
  /// **'Reference'**
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
  /// **'Optional remarks'**
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
  /// **'Error al eliminar:'**
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

  /// No description provided for @kanbanBoardGlobal.
  ///
  /// In en, this message translates to:
  /// **'Tablero Kanban Global'**
  String get kanbanBoardGlobal;

  /// No description provided for @noOrganizationAssigned.
  ///
  /// In en, this message translates to:
  /// **'No tienes una organización asignada'**
  String get noOrganizationAssigned;

  /// No description provided for @searchByNameOrRef.
  ///
  /// In en, this message translates to:
  /// **'Buscar por nombre o referencia...'**
  String get searchByNameOrRef;

  /// No description provided for @wipLimitReachedIn.
  ///
  /// In en, this message translates to:
  /// **'Límite WIP alcanzado en'**
  String get wipLimitReachedIn;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'Límite alcanzado'**
  String get limitReached;

  /// No description provided for @moveProductForward.
  ///
  /// In en, this message translates to:
  /// **'Avanzar producto'**
  String get moveProductForward;

  /// No description provided for @moveProductBackward.
  ///
  /// In en, this message translates to:
  /// **'Retroceder producto'**
  String get moveProductBackward;

  /// No description provided for @moveWarningPart1.
  ///
  /// In en, this message translates to:
  /// **'Se marcarán como pendientes todas las fases posteriores a'**
  String get moveWarningPart1;

  /// No description provided for @moveForward.
  ///
  /// In en, this message translates to:
  /// **'Avanzar'**
  String get moveForward;

  /// No description provided for @moveBackward.
  ///
  /// In en, this message translates to:
  /// **'Retroceder'**
  String get moveBackward;

  /// No description provided for @productMovedTo.
  ///
  /// In en, this message translates to:
  /// **'Producto movido a'**
  String get productMovedTo;

  /// No description provided for @phaseUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error al actualizar fase'**
  String get phaseUpdateError;

  /// No description provided for @noPhasesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No hay fases configuradas'**
  String get noPhasesConfigured;

  /// No description provided for @configurePhasesFirst.
  ///
  /// In en, this message translates to:
  /// **'Configura las fases de producción primero'**
  String get configurePhasesFirst;

  /// No description provided for @emptyColumnState.
  ///
  /// In en, this message translates to:
  /// **'Sin productos'**
  String get emptyColumnState;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Añadir Producto'**
  String get addProduct;

  /// No description provided for @pleaseSelectProduct.
  ///
  /// In en, this message translates to:
  /// **'Por favor selecciona un producto'**
  String get pleaseSelectProduct;

  /// No description provided for @productAddedToProject.
  ///
  /// In en, this message translates to:
  /// **'Producto añadido al proyecto'**
  String get productAddedToProject;

  /// No description provided for @errorAddingProduct.
  ///
  /// In en, this message translates to:
  /// **'Error al añadir producto'**
  String get errorAddingProduct;

  /// No description provided for @selectFromCatalog.
  ///
  /// In en, this message translates to:
  /// **'Seleccionar del Catálogo'**
  String get selectFromCatalog;

  /// No description provided for @noProductSelected.
  ///
  /// In en, this message translates to:
  /// **'Ningún producto seleccionado'**
  String get noProductSelected;

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Toca para seleccionar'**
  String get tapToSelect;

  /// No description provided for @quantityAndPrice.
  ///
  /// In en, this message translates to:
  /// **'Cantidad y Precio'**
  String get quantityAndPrice;

  /// No description provided for @quantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Cantidad inválida'**
  String get quantityInvalid;

  /// No description provided for @unitsSuffix.
  ///
  /// In en, this message translates to:
  /// **'uds'**
  String get unitsSuffix;

  /// No description provided for @customDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensiones Personalizadas (cm)'**
  String get customDimensions;

  /// No description provided for @specialDetails.
  ///
  /// In en, this message translates to:
  /// **'Detalles Especiales'**
  String get specialDetails;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Detalles'**
  String get detailsLabel;

  /// No description provided for @additionalSpecsHint.
  ///
  /// In en, this message translates to:
  /// **'Especificaciones adicionales...'**
  String get additionalSpecsHint;

  /// No description provided for @internalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Notas internas...'**
  String get internalNotesHint;

  /// No description provided for @addToProject.
  ///
  /// In en, this message translates to:
  /// **'Añadir al Proyecto'**
  String get addToProject;

  /// No description provided for @selectProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Seleccionar Producto'**
  String get selectProductTitle;

  /// No description provided for @searchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Buscar producto...'**
  String get searchProductHint;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No hay productos disponibles.'**
  String get noProductsAvailable;

  /// No description provided for @addProductsToCatalogFirst.
  ///
  /// In en, this message translates to:
  /// **'Debes añadir primero productos al catálogo.'**
  String get addProductsToCatalogFirst;

  /// No description provided for @productionProgress.
  ///
  /// In en, this message translates to:
  /// **'PROGRESO DE PRODUCCIÓN'**
  String get productionProgress;

  /// No description provided for @phaseTracking.
  ///
  /// In en, this message translates to:
  /// **'Seguimiento por fases'**
  String get phaseTracking;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Gestionar'**
  String get manage;

  /// No description provided for @catalogProduct.
  ///
  /// In en, this message translates to:
  /// **'Producto del Catálogo'**
  String get catalogProduct;

  /// No description provided for @statusAndQuantity.
  ///
  /// In en, this message translates to:
  /// **'Estado y Cantidad'**
  String get statusAndQuantity;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Cambiar Estado'**
  String get changeStatus;

  /// No description provided for @systemInfo.
  ///
  /// In en, this message translates to:
  /// **'Información del Sistema'**
  String get systemInfo;

  /// No description provided for @confirmDuplicateProductMessage.
  ///
  /// In en, this message translates to:
  /// **'¿Deseas crear una copia de este producto en el proyecto?'**
  String get confirmDuplicateProductMessage;

  /// No description provided for @duplicateProductError.
  ///
  /// In en, this message translates to:
  /// **'Error al duplicar producto'**
  String get duplicateProductError;

  /// No description provided for @confirmDeleteProjectProductMessagePart1.
  ///
  /// In en, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar'**
  String get confirmDeleteProjectProductMessagePart1;

  /// No description provided for @confirmDeleteProjectProductMessagePart2.
  ///
  /// In en, this message translates to:
  /// **'del proyecto?'**
  String get confirmDeleteProjectProductMessagePart2;

  /// No description provided for @deleteProductError.
  ///
  /// In en, this message translates to:
  /// **'Error al eliminar producto'**
  String get deleteProductError;

  /// No description provided for @statusUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Estado actualizado correctamente'**
  String get statusUpdatedSuccess;

  /// No description provided for @statusUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating status'**
  String get statusUpdateError;

  /// No description provided for @detailsAndNotes.
  ///
  /// In en, this message translates to:
  /// **'Detalles y Notas'**
  String get detailsAndNotes;

  /// No description provided for @productUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Producto actualizado correctamente'**
  String get productUpdatedSuccess;

  /// No description provided for @phasesInitializedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phases initialized successfully'**
  String get phasesInitializedSuccess;

  /// No description provided for @initPhaseError.
  ///
  /// In en, this message translates to:
  /// **'Error al inicializar:'**
  String get initPhaseError;

  /// No description provided for @resetPhases.
  ///
  /// In en, this message translates to:
  /// **'Reiniciar Fases'**
  String get resetPhases;

  /// No description provided for @resetPhasesWarning.
  ///
  /// In en, this message translates to:
  /// **'¿Estás seguro? Esto borrará el progreso actual y volverá a copiar las fases activas de la organización. Esta acción no se puede deshacer.'**
  String get resetPhasesWarning;

  /// No description provided for @resetSyncPhases.
  ///
  /// In en, this message translates to:
  /// **'Reiniciar/Sincronizar fases'**
  String get resetSyncPhases;

  /// No description provided for @productNoFlow.
  ///
  /// In en, this message translates to:
  /// **'Producto sin flujo de producción'**
  String get productNoFlow;

  /// No description provided for @productNoPhasesMessage.
  ///
  /// In en, this message translates to:
  /// **'Este producto aún no tiene fases asignadas. Inicialízalo para comenzar el seguimiento.'**
  String get productNoPhasesMessage;

  /// No description provided for @initProductionPhases.
  ///
  /// In en, this message translates to:
  /// **'Inicializar Fases de Producción'**
  String get initProductionPhases;

  /// No description provided for @contactAdminPhasesPart1.
  ///
  /// In en, this message translates to:
  /// **'Contacta con un administrador'**
  String get contactAdminPhasesPart1;

  /// No description provided for @contactAdminPhasesPart2.
  ///
  /// In en, this message translates to:
  /// **'para configurar las fases.'**
  String get contactAdminPhasesPart2;

  /// No description provided for @chatInfo.
  ///
  /// In en, this message translates to:
  /// **'Info del chat'**
  String get chatInfo;

  /// No description provided for @muteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Silenciar notificaciones'**
  String get muteNotifications;

  /// No description provided for @pinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'Mensajes fijados'**
  String get pinnedMessages;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No hay mensajes aún'**
  String get noMessagesYet;

  /// No description provided for @beFirstToMessage.
  ///
  /// In en, this message translates to:
  /// **'Sé el primero en enviar un mensaje'**
  String get beFirstToMessage;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Responder'**
  String get reply;

  /// No description provided for @react.
  ///
  /// In en, this message translates to:
  /// **'Reaccionar'**
  String get react;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copiar'**
  String get copy;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Texto copiado'**
  String get textCopied;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Desfijar'**
  String get unpin;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Fijar'**
  String get pin;

  /// No description provided for @messageUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Mensaje desfijado'**
  String get messageUnpinned;

  /// No description provided for @messagePinned.
  ///
  /// In en, this message translates to:
  /// **'Mensaje fijado'**
  String get messagePinned;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Editar mensaje'**
  String get editMessage;

  /// No description provided for @newContentHint.
  ///
  /// In en, this message translates to:
  /// **'Nuevo contenido...'**
  String get newContentHint;

  /// No description provided for @messageEdited.
  ///
  /// In en, this message translates to:
  /// **'Mensaje editado'**
  String get messageEdited;

  /// No description provided for @editError.
  ///
  /// In en, this message translates to:
  /// **'Error al editar:'**
  String get editError;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Eliminar mensaje'**
  String get deleteMessage;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar este mensaje?'**
  String get deleteMessageConfirm;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Mensaje eliminado'**
  String get messageDeleted;

  /// No description provided for @sendMessageError.
  ///
  /// In en, this message translates to:
  /// **'Error al enviar mensaje:'**
  String get sendMessageError;

  /// No description provided for @reactionError.
  ///
  /// In en, this message translates to:
  /// **'Error al reaccionar:'**
  String get reactionError;

  /// No description provided for @assignPhasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Phases'**
  String get assignPhasesTitle;

  /// No description provided for @cleanSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get cleanSelection;

  /// No description provided for @selectPhasesInstruction.
  ///
  /// In en, this message translates to:
  /// **'Select phases they can manage'**
  String get selectPhasesInstruction;

  /// No description provided for @noRestrictionsLabel.
  ///
  /// In en, this message translates to:
  /// **'No restrictions (can manage all)'**
  String get noRestrictionsLabel;

  /// No description provided for @phasesSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected phases'**
  String get phasesSelectedLabel;

  /// No description provided for @assignmentsSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Assignments saved successfully'**
  String get assignmentsSavedSuccess;

  /// No description provided for @errorLoadingAssignments.
  ///
  /// In en, this message translates to:
  /// **'Error loading assignments'**
  String get errorLoadingAssignments;

  /// No description provided for @noActivePhasesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No active phases available. Configure phases in organization settings.'**
  String get noActivePhasesAvailable;

  /// No description provided for @managePhasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Phases'**
  String get managePhasesTitle;

  /// No description provided for @initializePhasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Initialize Phases'**
  String get initializePhasesTitle;

  /// No description provided for @initializePhasesConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to create default production phases? This will add standard process phases.'**
  String get initializePhasesConfirmMessage;

  /// No description provided for @initializePhasesButton.
  ///
  /// In en, this message translates to:
  /// **'Initialize Phases'**
  String get initializePhasesButton;

  /// No description provided for @phaseDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Phase deactivated'**
  String get phaseDeactivated;

  /// No description provided for @phaseActivated.
  ///
  /// In en, this message translates to:
  /// **'Phase activated'**
  String get phaseActivated;

  /// No description provided for @editPhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Phase'**
  String get editPhaseTitle;

  /// No description provided for @phaseDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get phaseDescriptionLabel;

  /// No description provided for @phaseUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phase updated successfully'**
  String get phaseUpdatedSuccess;

  /// No description provided for @noPhasesConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'No phases configured'**
  String get noPhasesConfiguredTitle;

  /// No description provided for @noPhasesConfiguredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Initialize default phases to start'**
  String get noPhasesConfiguredSubtitle;

  /// No description provided for @activePhasesSection.
  ///
  /// In en, this message translates to:
  /// **'Active Phases'**
  String get activePhasesSection;

  /// No description provided for @inactivePhasesSection.
  ///
  /// In en, this message translates to:
  /// **'Inactive Phases'**
  String get inactivePhasesSection;

  /// No description provided for @activateAction.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activateAction;

  /// No description provided for @deactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateAction;

  /// No description provided for @totalPhasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total phases'**
  String get totalPhasesLabel;

  /// No description provided for @activePhasesNote.
  ///
  /// In en, this message translates to:
  /// **'Active phases will be automatically applied to all new products.'**
  String get activePhasesNote;

  /// No description provided for @joinOrganizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Organization'**
  String get joinOrganizationTitle;

  /// No description provided for @joinOrganizationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the organization'**
  String get joinOrganizationSuccess;

  /// No description provided for @joinOrganizationError.
  ///
  /// In en, this message translates to:
  /// **'Error joining organization'**
  String get joinOrganizationError;

  /// No description provided for @inviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation Code'**
  String get inviteCodeTitle;

  /// No description provided for @inviteCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code provided by your organization'**
  String get inviteCodeSubtitle;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Format: ABCD1234 (8 characters)'**
  String get inviteCodeHelper;

  /// No description provided for @inviteCodeLengthError.
  ///
  /// In en, this message translates to:
  /// **'Code must be 8 characters long'**
  String get inviteCodeLengthError;

  /// No description provided for @enterInviteCodeError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code'**
  String get enterInviteCodeError;

  /// No description provided for @inviteCodeInfoBox.
  ///
  /// In en, this message translates to:
  /// **'The invitation code is unique for each organization and allows instant access.'**
  String get inviteCodeInfoBox;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// No description provided for @inviteMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get inviteMemberTitle;

  /// No description provided for @inviteSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully'**
  String get inviteSentSuccess;

  /// No description provided for @inviteSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending invitation'**
  String get inviteSendError;

  /// No description provided for @inviteByEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite by Email'**
  String get inviteByEmailTitle;

  /// No description provided for @inviteByEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send an invitation to join your organization'**
  String get inviteByEmailSubtitle;

  /// No description provided for @emailInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailInputLabel;

  /// No description provided for @emailInputHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter user\'s email to invite'**
  String get emailInputHelper;

  /// No description provided for @aboutInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'About invitations'**
  String get aboutInvitationsTitle;

  /// No description provided for @inviteInfoExpiration.
  ///
  /// In en, this message translates to:
  /// **'Invitation expires in 7 days'**
  String get inviteInfoExpiration;

  /// No description provided for @inviteInfoReceive.
  ///
  /// In en, this message translates to:
  /// **'User will receive the invitation upon login'**
  String get inviteInfoReceive;

  /// No description provided for @inviteInfoCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'If user has no account, they must create one first'**
  String get inviteInfoCreateAccount;

  /// No description provided for @inviteInfoExisting.
  ///
  /// In en, this message translates to:
  /// **'You can only invite users not belonging to another organization'**
  String get inviteInfoExisting;

  /// No description provided for @sendInviteButton.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInviteButton;

  /// No description provided for @newOrganizationTitle.
  ///
  /// In en, this message translates to:
  /// **'New Organization'**
  String get newOrganizationTitle;

  /// No description provided for @createOrganizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your organization to manage team and projects'**
  String get createOrganizationSubtitle;

  /// No description provided for @orgNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization Name'**
  String get orgNameLabel;

  /// No description provided for @orgNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Ex: My Company LLC'**
  String get orgNameHelper;

  /// No description provided for @orgNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the name'**
  String get orgNameError;

  /// No description provided for @orgNameLengthError.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get orgNameLengthError;

  /// No description provided for @orgDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get orgDescriptionLabel;

  /// No description provided for @orgDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe your organization'**
  String get orgDescriptionHelper;

  /// No description provided for @orgDescriptionError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get orgDescriptionError;

  /// No description provided for @orgDescriptionLengthError.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters'**
  String get orgDescriptionLengthError;

  /// No description provided for @creatorBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'As creator you will have:'**
  String get creatorBenefitsTitle;

  /// No description provided for @benefitControl.
  ///
  /// In en, this message translates to:
  /// **'Full control over the organization'**
  String get benefitControl;

  /// No description provided for @benefitInvite.
  ///
  /// In en, this message translates to:
  /// **'Ability to invite members'**
  String get benefitInvite;

  /// No description provided for @benefitRoles.
  ///
  /// In en, this message translates to:
  /// **'Role and permission management'**
  String get benefitRoles;

  /// No description provided for @benefitProjects.
  ///
  /// In en, this message translates to:
  /// **'Project administration'**
  String get benefitProjects;

  /// No description provided for @peopleLabel.
  ///
  /// In en, this message translates to:
  /// **'people'**
  String get peopleLabel;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get noMembersFound;

  /// No description provided for @ownerRole.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerRole;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRole;

  /// No description provided for @adminsLabel.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminsLabel;

  /// No description provided for @removeAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Remove Admin'**
  String get removeAdminAction;

  /// No description provided for @makeAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get makeAdminAction;

  /// No description provided for @removeMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMemberAction;

  /// No description provided for @removeMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get removeMemberTitle;

  /// No description provided for @removeMemberConfirmPart1.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove'**
  String get removeMemberConfirmPart1;

  /// No description provided for @removeMemberConfirmPart2.
  ///
  /// In en, this message translates to:
  /// **'from the organization?'**
  String get removeMemberConfirmPart2;

  /// No description provided for @updateMemberError.
  ///
  /// In en, this message translates to:
  /// **'Error updating member'**
  String get updateMemberError;

  /// No description provided for @myOrganizationTitle.
  ///
  /// In en, this message translates to:
  /// **'My Organization'**
  String get myOrganizationTitle;

  /// No description provided for @noOrganizationTitle.
  ///
  /// In en, this message translates to:
  /// **'You do not belong to any organization'**
  String get noOrganizationTitle;

  /// No description provided for @noOrganizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your own organization or join an existing one'**
  String get noOrganizationSubtitle;

  /// No description provided for @createMyOrganizationBtn.
  ///
  /// In en, this message translates to:
  /// **'Create my organization'**
  String get createMyOrganizationBtn;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orLabel;

  /// No description provided for @joinWithCodeBtn.
  ///
  /// In en, this message translates to:
  /// **'Join with code'**
  String get joinWithCodeBtn;

  /// No description provided for @tapToViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get tapToViewLabel;

  /// No description provided for @pendingInvitationPrefix.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get pendingInvitationPrefix;

  /// No description provided for @pendingInvitationSuffixSingle.
  ///
  /// In en, this message translates to:
  /// **'pending invitation'**
  String get pendingInvitationSuffixSingle;

  /// No description provided for @pendingInvitationSuffixPlural.
  ///
  /// In en, this message translates to:
  /// **'pending invitations'**
  String get pendingInvitationSuffixPlural;

  /// No description provided for @shareCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Share this code'**
  String get shareCodeLabel;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @copyCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCodeTooltip;

  /// No description provided for @regenerateCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Regenerate code'**
  String get regenerateCodeAction;

  /// No description provided for @regenerateCodeWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? The previous code will stop working.'**
  String get regenerateCodeWarning;

  /// No description provided for @regenerateBtn.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerateBtn;

  /// No description provided for @codeRegeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Code regenerated'**
  String get codeRegeneratedSuccess;

  /// No description provided for @actionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsTitle;

  /// No description provided for @managePhasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure production phases'**
  String get managePhasesSubtitle;

  /// No description provided for @viewMembersAction.
  ///
  /// In en, this message translates to:
  /// **'View members'**
  String get viewMembersAction;

  /// No description provided for @inviteMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get inviteMemberAction;

  /// No description provided for @leaveOrganizationAction.
  ///
  /// In en, this message translates to:
  /// **'Leave organization'**
  String get leaveOrganizationAction;

  /// No description provided for @leaveOrganizationWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this organization? You will lose access to all projects and data.'**
  String get leaveOrganizationWarning;

  /// No description provided for @leaveOrganizationSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have left the organization'**
  String get leaveOrganizationSuccess;

  /// No description provided for @pendingInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitations'**
  String get pendingInvitationsTitle;

  /// No description provided for @noPendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'No pending invitations'**
  String get noPendingInvitations;

  /// No description provided for @invitedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Invited by:'**
  String get invitedByLabel;

  /// No description provided for @rejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectAction;

  /// No description provided for @acceptAction.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptAction;

  /// No description provided for @invitationRejectedMsg.
  ///
  /// In en, this message translates to:
  /// **'Invitation rejected'**
  String get invitationRejectedMsg;

  /// No description provided for @selectColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColorTitle;

  /// No description provided for @currentLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Currently: Spanish, English'**
  String get currentLanguagesLabel;

  /// No description provided for @productionTitle.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get productionTitle;

  /// No description provided for @batchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Production Batches'**
  String get batchesTitle;

  /// No description provided for @activeBatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Batches'**
  String get activeBatchesTitle;

  /// No description provided for @noBatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No batches found'**
  String get noBatchesFound;

  /// No description provided for @createBatchBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Batch'**
  String get createBatchBtn;

  /// No description provided for @newBatchTitle.
  ///
  /// In en, this message translates to:
  /// **'New Batch'**
  String get newBatchTitle;

  /// No description provided for @newBatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new production batch'**
  String get newBatchSubtitle;

  /// No description provided for @batchNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch Name'**
  String get batchNameLabel;

  /// No description provided for @batchNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: January 2024 Production'**
  String get batchNameHint;

  /// No description provided for @batchNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get batchNameError;

  /// No description provided for @batchCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Batch created successfully'**
  String get batchCreatedSuccess;

  /// No description provided for @batchStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get batchStatusDraft;

  /// No description provided for @batchStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get batchStatusInProgress;

  /// No description provided for @batchStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get batchStatusCompleted;

  /// No description provided for @batchStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get batchStatusCancelled;

  /// No description provided for @batchDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch Detail'**
  String get batchDetailTitle;

  /// No description provided for @addProductBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductBtn;

  /// No description provided for @startProductionBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Production'**
  String get startProductionBtn;

  /// No description provided for @completeBatchBtn.
  ///
  /// In en, this message translates to:
  /// **'Complete Batch'**
  String get completeBatchBtn;

  /// No description provided for @deleteBatchAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Batch'**
  String get deleteBatchAction;

  /// No description provided for @deleteBatchConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete batch?'**
  String get deleteBatchConfirmTitle;

  /// No description provided for @deleteBatchConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone and will delete all associated data.'**
  String get deleteBatchConfirmMsg;

  /// No description provided for @batchDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Batch deleted successfully'**
  String get batchDeletedSuccess;

  /// No description provided for @batchStartedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Production started'**
  String get batchStartedSuccess;

  /// No description provided for @batchCompletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Batch marked as completed'**
  String get batchCompletedSuccess;

  /// No description provided for @noProductsInBatch.
  ///
  /// In en, this message translates to:
  /// **'No products in this batch'**
  String get noProductsInBatch;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @addProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Products'**
  String get addProductsTitle;

  /// No description provided for @selectProductsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Select products to add to the batch'**
  String get selectProductsInstruction;

  /// No description provided for @noAvailableProducts.
  ///
  /// In en, this message translates to:
  /// **'No available products to add'**
  String get noAvailableProducts;

  /// No description provided for @addSelectedBtn.
  ///
  /// In en, this message translates to:
  /// **'Add selected'**
  String get addSelectedBtn;

  /// No description provided for @productsAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Products added successfully'**
  String get productsAddedSuccess;

  /// No description provided for @currentPhaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Phase'**
  String get currentPhaseLabel;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @moveNextPhaseBtn.
  ///
  /// In en, this message translates to:
  /// **'Next Phase'**
  String get moveNextPhaseBtn;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessages;

  /// No description provided for @searchingMessages.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingMessages;

  /// No description provided for @writeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search'**
  String get writeToSearch;

  /// No description provided for @searchInMessages.
  ///
  /// In en, this message translates to:
  /// **'Search in messages'**
  String get searchInMessages;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search in content, names or mentions'**
  String get searchPlaceholder;

  /// No description provided for @messageFound.
  ///
  /// In en, this message translates to:
  /// **'Message found'**
  String get messageFound;

  /// No description provided for @noPinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'No pinned messages'**
  String get noPinnedMessages;

  /// No description provided for @chatOfBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch chat'**
  String get chatOfBatch;

  /// No description provided for @chatOfProject.
  ///
  /// In en, this message translates to:
  /// **'Project chat'**
  String get chatOfProject;

  /// No description provided for @chatOfProduct.
  ///
  /// In en, this message translates to:
  /// **'Product chat'**
  String get chatOfProduct;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @eventBatchCreated.
  ///
  /// In en, this message translates to:
  /// **'Batch created'**
  String get eventBatchCreated;

  /// No description provided for @eventBatchStarted.
  ///
  /// In en, this message translates to:
  /// **'Production started'**
  String get eventBatchStarted;

  /// No description provided for @eventBatchCompleted.
  ///
  /// In en, this message translates to:
  /// **'Batch completed'**
  String get eventBatchCompleted;

  /// No description provided for @eventBatchStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get eventBatchStatusChanged;

  /// No description provided for @eventPhaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Phase completed'**
  String get eventPhaseCompleted;

  /// No description provided for @eventProductMoved.
  ///
  /// In en, this message translates to:
  /// **'Product moved to phase'**
  String get eventProductMoved;

  /// No description provided for @eventProductAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added'**
  String get eventProductAdded;

  /// No description provided for @eventProductRemoved.
  ///
  /// In en, this message translates to:
  /// **'Product removed'**
  String get eventProductRemoved;

  /// No description provided for @eventProductStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Product status changed'**
  String get eventProductStatusChanged;

  /// No description provided for @eventDelayDetected.
  ///
  /// In en, this message translates to:
  /// **'Delay detected'**
  String get eventDelayDetected;

  /// No description provided for @eventMemberAssigned.
  ///
  /// In en, this message translates to:
  /// **'Member assigned'**
  String get eventMemberAssigned;

  /// No description provided for @eventMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get eventMemberRemoved;

  /// No description provided for @eventInvoiceIssued.
  ///
  /// In en, this message translates to:
  /// **'Invoice issued'**
  String get eventInvoiceIssued;

  /// No description provided for @eventPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get eventPaymentReceived;

  /// No description provided for @eventNoteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get eventNoteAdded;

  /// No description provided for @eventFileUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded'**
  String get eventFileUploaded;

  /// No description provided for @eventProjectCreated.
  ///
  /// In en, this message translates to:
  /// **'Project created'**
  String get eventProjectCreated;

  /// No description provided for @eventProjectCompleted.
  ///
  /// In en, this message translates to:
  /// **'Project completed'**
  String get eventProjectCompleted;

  /// No description provided for @eventDeadlineApproaching.
  ///
  /// In en, this message translates to:
  /// **'Deadline approaching'**
  String get eventDeadlineApproaching;

  /// No description provided for @eventQualityCheckCompleted.
  ///
  /// In en, this message translates to:
  /// **'Quality check'**
  String get eventQualityCheckCompleted;

  /// No description provided for @eventMaterialAssigned.
  ///
  /// In en, this message translates to:
  /// **'Material assigned'**
  String get eventMaterialAssigned;

  /// No description provided for @allMasculine.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allMasculine;

  /// No description provided for @allFemenine.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFemenine;

  /// No description provided for @allPluralMasculine.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allPluralMasculine;

  /// No description provided for @allPluralFeminine.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allPluralFeminine;

  /// No description provided for @allClients.
  ///
  /// In en, this message translates to:
  /// **'All clients'**
  String get allClients;

  /// No description provided for @batchesViewTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'View batches'**
  String get batchesViewTitleLabel;

  /// No description provided for @productsViewTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'View products'**
  String get productsViewTitleLabel;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @foldersView.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get foldersView;

  /// No description provided for @viewDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetailsTooltip;

  /// No description provided for @noProjectsForClient.
  ///
  /// In en, this message translates to:
  /// **'No projects for this client'**
  String get noProjectsForClient;

  /// No description provided for @clientNotFound.
  ///
  /// In en, this message translates to:
  /// **'Client not found'**
  String get clientNotFound;

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found'**
  String get projectNotFound;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get complete;

  /// No description provided for @urgentLabel.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgentLabel;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @projectsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No projects} =1 {1 Project} other {{count} Projects}}'**
  String projectsCount(num count);

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No products} =1 {1 Product} other {{count} Products}}'**
  String productsCount(num count);

  /// No description provided for @urgentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} urgent'**
  String urgentCount(Object count);

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @viewProjectDetails.
  ///
  /// In en, this message translates to:
  /// **'View project details'**
  String get viewProjectDetails;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact info'**
  String get contactInfo;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'family'**
  String get family;

  /// No description provided for @families.
  ///
  /// In en, this message translates to:
  /// **'families'**
  String get families;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @noFamiliesInProject.
  ///
  /// In en, this message translates to:
  /// **'No product families in this project'**
  String get noFamiliesInProject;

  /// No description provided for @noProductsInFamily.
  ///
  /// In en, this message translates to:
  /// **'No products in this family'**
  String get noProductsInFamily;

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get uploadingPhoto;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get photoUpdated;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @updateProfileError.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get updateProfileError;

  /// No description provided for @emailReadOnlyHelper.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be modified'**
  String get emailReadOnlyHelper;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @roleReadOnlyHelper.
  ///
  /// In en, this message translates to:
  /// **'Account type cannot be modified'**
  String get roleReadOnlyHelper;

  /// No description provided for @myProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfileTitle;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @googleAccountAlert.
  ///
  /// In en, this message translates to:
  /// **'Not available for Google accounts'**
  String get googleAccountAlert;

  /// No description provided for @updatePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get updatePasswordSubtitle;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccess;

  /// No description provided for @changePasswordError.
  ///
  /// In en, this message translates to:
  /// **'Error changing password'**
  String get changePasswordError;

  /// No description provided for @securePasswordAdvice.
  ///
  /// In en, this message translates to:
  /// **'Make sure to use a secure password'**
  String get securePasswordAdvice;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @enterCurrentPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get enterCurrentPasswordError;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @enterNewPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get enterNewPasswordError;

  /// No description provided for @passwordDiffError.
  ///
  /// In en, this message translates to:
  /// **'New password must be different'**
  String get passwordDiffError;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @passwordTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips for a secure password:'**
  String get passwordTipsTitle;

  /// No description provided for @passwordTip1.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get passwordTip1;

  /// No description provided for @passwordTip2.
  ///
  /// In en, this message translates to:
  /// **'Combine uppercase and lowercase letters'**
  String get passwordTip2;

  /// No description provided for @passwordTip3.
  ///
  /// In en, this message translates to:
  /// **'Include numbers and symbols'**
  String get passwordTip3;

  /// No description provided for @passwordTip4.
  ///
  /// In en, this message translates to:
  /// **'Do not use personal information'**
  String get passwordTip4;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @personalDataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Personal data updated'**
  String get personalDataUpdated;

  /// No description provided for @phaseCustomization.
  ///
  /// In en, this message translates to:
  /// **'Phase Customization'**
  String get phaseCustomization;

  /// No description provided for @colorPicker.
  ///
  /// In en, this message translates to:
  /// **'Color Picker'**
  String get colorPicker;

  /// No description provided for @iconPicker.
  ///
  /// In en, this message translates to:
  /// **'Icon Picker'**
  String get iconPicker;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get selectIcon;

  /// No description provided for @currentColor.
  ///
  /// In en, this message translates to:
  /// **'Current color'**
  String get currentColor;

  /// No description provided for @currentIcon.
  ///
  /// In en, this message translates to:
  /// **'Current icon'**
  String get currentIcon;

  /// No description provided for @wipSettings.
  ///
  /// In en, this message translates to:
  /// **'WIP Settings'**
  String get wipSettings;

  /// No description provided for @wipLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'WIP Limit'**
  String get wipLimitLabel;

  /// No description provided for @wipLimitHelper.
  ///
  /// In en, this message translates to:
  /// **'Maximum products allowed in this phase'**
  String get wipLimitHelper;

  /// No description provided for @wipLimitError.
  ///
  /// In en, this message translates to:
  /// **'WIP limit must be greater than 0'**
  String get wipLimitError;

  /// No description provided for @slaSettings.
  ///
  /// In en, this message translates to:
  /// **'SLA Settings'**
  String get slaSettings;

  /// No description provided for @maxDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Duration (hours)'**
  String get maxDurationLabel;

  /// No description provided for @maxDurationHelper.
  ///
  /// In en, this message translates to:
  /// **'Maximum time allowed in this phase'**
  String get maxDurationHelper;

  /// No description provided for @warningThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Warning Threshold (%)'**
  String get warningThresholdLabel;

  /// No description provided for @warningThresholdHelper.
  ///
  /// In en, this message translates to:
  /// **'Percentage for early alert (e.g. 80%)'**
  String get warningThresholdHelper;

  /// No description provided for @slaNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'SLA not configured'**
  String get slaNotConfigured;

  /// No description provided for @enableSLA.
  ///
  /// In en, this message translates to:
  /// **'Enable SLA'**
  String get enableSLA;

  /// No description provided for @disableSLA.
  ///
  /// In en, this message translates to:
  /// **'Disable SLA'**
  String get disableSLA;

  /// No description provided for @reorderPhases.
  ///
  /// In en, this message translates to:
  /// **'Reorder Phases'**
  String get reorderPhases;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// No description provided for @orderSaved.
  ///
  /// In en, this message translates to:
  /// **'Order saved successfully'**
  String get orderSaved;

  /// No description provided for @invalidColorFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid color format. Use #RRGGBB'**
  String get invalidColorFormat;

  /// No description provided for @phaseInUse.
  ///
  /// In en, this message translates to:
  /// **'This phase cannot be deleted because it has associated products'**
  String get phaseInUse;

  /// No description provided for @confirmDeletePhase.
  ///
  /// In en, this message translates to:
  /// **'Delete phase permanently?'**
  String get confirmDeletePhase;

  /// No description provided for @deletePhaseWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get deletePhaseWarning;

  /// No description provided for @createPhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Phase'**
  String get createPhaseTitle;

  /// No description provided for @phaseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Phase Name'**
  String get phaseNameLabel;

  /// No description provided for @orderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderLabel;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @basicSettings.
  ///
  /// In en, this message translates to:
  /// **'Basic Settings'**
  String get basicSettings;

  /// No description provided for @phaseCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phase created successfully'**
  String get phaseCreatedSuccess;

  /// No description provided for @phaseDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phase deleted successfully'**
  String get phaseDeletedSuccess;

  /// No description provided for @wipLimitReached.
  ///
  /// In en, this message translates to:
  /// **'WIP limit reached'**
  String get wipLimitReached;

  /// No description provided for @wipLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'WIP limit exceeded in'**
  String get wipLimitExceeded;

  /// No description provided for @slaAlerts.
  ///
  /// In en, this message translates to:
  /// **'SLA Alerts'**
  String get slaAlerts;

  /// No description provided for @activeAlerts.
  ///
  /// In en, this message translates to:
  /// **'Active Alerts'**
  String get activeAlerts;

  /// No description provided for @alertDetails.
  ///
  /// In en, this message translates to:
  /// **'Alert Details'**
  String get alertDetails;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledge;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @resolutionNotes.
  ///
  /// In en, this message translates to:
  /// **'Resolution Notes'**
  String get resolutionNotes;

  /// No description provided for @alertAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Alert acknowledged'**
  String get alertAcknowledged;

  /// No description provided for @alertResolved.
  ///
  /// In en, this message translates to:
  /// **'Alert resolved'**
  String get alertResolved;

  /// No description provided for @noAlertsActive.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get noAlertsActive;

  /// No description provided for @slaExceeded.
  ///
  /// In en, this message translates to:
  /// **'SLA Exceeded'**
  String get slaExceeded;

  /// No description provided for @slaWarning.
  ///
  /// In en, this message translates to:
  /// **'SLA Warning'**
  String get slaWarning;

  /// No description provided for @phaseBlocked.
  ///
  /// In en, this message translates to:
  /// **'Phase Blocked'**
  String get phaseBlocked;

  /// No description provided for @wipLimitExceededAlert.
  ///
  /// In en, this message translates to:
  /// **'WIP Limit Exceeded'**
  String get wipLimitExceededAlert;

  /// No description provided for @criticalSeverity.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get criticalSeverity;

  /// No description provided for @warningSeverity.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warningSeverity;

  /// No description provided for @excessHours.
  ///
  /// In en, this message translates to:
  /// **'Excess {hours}h'**
  String excessHours(Object hours);

  /// No description provided for @approachingLimit.
  ///
  /// In en, this message translates to:
  /// **'Approaching limit'**
  String get approachingLimit;

  /// No description provided for @viewAlert.
  ///
  /// In en, this message translates to:
  /// **'View alert'**
  String get viewAlert;

  /// No description provided for @dismissAlert.
  ///
  /// In en, this message translates to:
  /// **'Dismiss alert'**
  String get dismissAlert;

  /// No description provided for @alertsPanel.
  ///
  /// In en, this message translates to:
  /// **'Alerts Panel'**
  String get alertsPanel;

  /// No description provided for @filterBySeverity.
  ///
  /// In en, this message translates to:
  /// **'Filter by severity'**
  String get filterBySeverity;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// No description provided for @allSeverities.
  ///
  /// In en, this message translates to:
  /// **'All severities'**
  String get allSeverities;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @excess.
  ///
  /// In en, this message translates to:
  /// **'Excess'**
  String get excess;

  /// No description provided for @hoursLetter.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursLetter;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @metrics.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get metrics;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @kpi.
  ///
  /// In en, this message translates to:
  /// **'KPI'**
  String get kpi;

  /// No description provided for @activeProjects.
  ///
  /// In en, this message translates to:
  /// **'Active Projects'**
  String get activeProjects;

  /// No description provided for @completedProjects.
  ///
  /// In en, this message translates to:
  /// **'Completed Projects'**
  String get completedProjects;

  /// No description provided for @delayedProjects.
  ///
  /// In en, this message translates to:
  /// **'Delayed Projects'**
  String get delayedProjects;

  /// No description provided for @productsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Products Completed'**
  String get productsCompleted;

  /// No description provided for @productsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Products In Progress'**
  String get productsInProgress;

  /// No description provided for @productsPending.
  ///
  /// In en, this message translates to:
  /// **'Products Pending'**
  String get productsPending;

  /// No description provided for @slaCompliance.
  ///
  /// In en, this message translates to:
  /// **'SLA Compliance'**
  String get slaCompliance;

  /// No description provided for @efficiencyScore.
  ///
  /// In en, this message translates to:
  /// **'Efficiency Score'**
  String get efficiencyScore;

  /// No description provided for @averageTimePerPhase.
  ///
  /// In en, this message translates to:
  /// **'Average Time per Phase'**
  String get averageTimePerPhase;

  /// No description provided for @productsPerPhase.
  ///
  /// In en, this message translates to:
  /// **'Products per Phase'**
  String get productsPerPhase;

  /// No description provided for @bottlenecks.
  ///
  /// In en, this message translates to:
  /// **'Bottlenecks'**
  String get bottlenecks;

  /// No description provided for @phasePerformance.
  ///
  /// In en, this message translates to:
  /// **'Phase Performance'**
  String get phasePerformance;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @productivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get productivity;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @last3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get last3Months;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @trendUp.
  ///
  /// In en, this message translates to:
  /// **'Upward trend'**
  String get trendUp;

  /// No description provided for @trendDown.
  ///
  /// In en, this message translates to:
  /// **'Downward trend'**
  String get trendDown;

  /// No description provided for @trendStable.
  ///
  /// In en, this message translates to:
  /// **'Stable trend'**
  String get trendStable;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @loadingMetrics.
  ///
  /// In en, this message translates to:
  /// **'Loading metrics...'**
  String get loadingMetrics;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh data'**
  String get refreshData;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get exportReport;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @comparedToLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'Compared to last period'**
  String get comparedToLastPeriod;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @percentageChange.
  ///
  /// In en, this message translates to:
  /// **'Percentage change'**
  String get percentageChange;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @roleManagement.
  ///
  /// In en, this message translates to:
  /// **'Role Management'**
  String get roleManagement;

  /// No description provided for @assignRole.
  ///
  /// In en, this message translates to:
  /// **'Assign Role'**
  String get assignRole;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @roleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get roleUpdated;

  /// No description provided for @roleUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating role'**
  String get roleUpdateError;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleProductionManager.
  ///
  /// In en, this message translates to:
  /// **'Production Manager'**
  String get roleProductionManager;

  /// No description provided for @roleQualityControl.
  ///
  /// In en, this message translates to:
  /// **'Quality Control'**
  String get roleQualityControl;

  /// No description provided for @roleOwnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Full access to the entire organization'**
  String get roleOwnerDesc;

  /// No description provided for @roleAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete management except organization deletion'**
  String get roleAdminDesc;

  /// No description provided for @roleProductionManagerDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete production and batch management'**
  String get roleProductionManagerDesc;

  /// No description provided for @roleOperatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Operation of assigned phases'**
  String get roleOperatorDesc;

  /// No description provided for @roleQualityControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Product status and quality management'**
  String get roleQualityControlDesc;

  /// No description provided for @roleClientDesc.
  ///
  /// In en, this message translates to:
  /// **'View their projects and products'**
  String get roleClientDesc;

  /// No description provided for @moduleKanban.
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get moduleKanban;

  /// No description provided for @moduleBatches.
  ///
  /// In en, this message translates to:
  /// **'Batches'**
  String get moduleBatches;

  /// No description provided for @moduleProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get moduleProducts;

  /// No description provided for @moduleProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get moduleProjects;

  /// No description provided for @moduleClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get moduleClients;

  /// No description provided for @moduleCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get moduleCatalog;

  /// No description provided for @modulePhases.
  ///
  /// In en, this message translates to:
  /// **'Phases'**
  String get modulePhases;

  /// No description provided for @moduleChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get moduleChat;

  /// No description provided for @moduleOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get moduleOrganization;

  /// No description provided for @moduleReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get moduleReports;

  /// No description provided for @actionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get actionView;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get actionMove;

  /// No description provided for @actionAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get actionAssign;

  /// No description provided for @actionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get actionManage;

  /// No description provided for @actionExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExport;

  /// No description provided for @actionGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get actionGenerate;

  /// No description provided for @scopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get scopeAll;

  /// No description provided for @scopeAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned only'**
  String get scopeAssigned;

  /// No description provided for @scopeNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get scopeNone;

  /// No description provided for @scopeAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Can view/edit all resources'**
  String get scopeAllDesc;

  /// No description provided for @scopeAssignedDesc.
  ///
  /// In en, this message translates to:
  /// **'Only assigned resources'**
  String get scopeAssignedDesc;

  /// No description provided for @scopeNoneDesc.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get scopeNoneDesc;

  /// No description provided for @productStatuses.
  ///
  /// In en, this message translates to:
  /// **'Product Statuses'**
  String get productStatuses;

  /// No description provided for @statusManagement.
  ///
  /// In en, this message translates to:
  /// **'Status Management'**
  String get statusManagement;

  /// No description provided for @createStatus.
  ///
  /// In en, this message translates to:
  /// **'Create Status'**
  String get createStatus;

  /// No description provided for @editStatus.
  ///
  /// In en, this message translates to:
  /// **'Edit Status'**
  String get editStatus;

  /// No description provided for @statusCreated.
  ///
  /// In en, this message translates to:
  /// **'Status created'**
  String get statusCreated;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get statusUpdated;

  /// No description provided for @statusDeleted.
  ///
  /// In en, this message translates to:
  /// **'Status deleted'**
  String get statusDeleted;

  /// No description provided for @statusCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating status'**
  String get statusCreateError;

  /// No description provided for @statusDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting status'**
  String get statusDeleteError;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get statusHold;

  /// No description provided for @statusCAO.
  ///
  /// In en, this message translates to:
  /// **'CAO'**
  String get statusCAO;

  /// No description provided for @statusControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get statusControl;

  /// No description provided for @statusOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get statusOK;

  /// No description provided for @statusPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Product waiting to start production'**
  String get statusPendingDesc;

  /// No description provided for @statusHoldDesc.
  ///
  /// In en, this message translates to:
  /// **'Product sent to client for evaluation'**
  String get statusHoldDesc;

  /// No description provided for @statusCAODesc.
  ///
  /// In en, this message translates to:
  /// **'Product with defects reported by client'**
  String get statusCAODesc;

  /// No description provided for @statusControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Product in quality control for classification'**
  String get statusControlDesc;

  /// No description provided for @statusOKDesc.
  ///
  /// In en, this message translates to:
  /// **'Product approved and finished'**
  String get statusOKDesc;

  /// No description provided for @statusTransitions.
  ///
  /// In en, this message translates to:
  /// **'Status Transitions'**
  String get statusTransitions;

  /// No description provided for @transition.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get transition;

  /// No description provided for @fromStatus.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromStatus;

  /// No description provided for @toStatus.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toStatus;

  /// No description provided for @allowedTransitions.
  ///
  /// In en, this message translates to:
  /// **'Allowed Transitions'**
  String get allowedTransitions;

  /// No description provided for @configureTransition.
  ///
  /// In en, this message translates to:
  /// **'Configure Transition'**
  String get configureTransition;

  /// No description provided for @transitionCreated.
  ///
  /// In en, this message translates to:
  /// **'Transition created'**
  String get transitionCreated;

  /// No description provided for @transitionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transition updated'**
  String get transitionUpdated;

  /// No description provided for @transitionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transition deleted'**
  String get transitionDeleted;

  /// No description provided for @validations.
  ///
  /// In en, this message translates to:
  /// **'Validations'**
  String get validations;

  /// No description provided for @validationType.
  ///
  /// In en, this message translates to:
  /// **'Validation Type'**
  String get validationType;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Validation Required'**
  String get validationRequired;

  /// No description provided for @validationText.
  ///
  /// In en, this message translates to:
  /// **'Required text'**
  String get validationText;

  /// No description provided for @validationNumber.
  ///
  /// In en, this message translates to:
  /// **'Required number'**
  String get validationNumber;

  /// No description provided for @validationDefectiveQuantity.
  ///
  /// In en, this message translates to:
  /// **'Defective quantity'**
  String get validationDefectiveQuantity;

  /// No description provided for @validationApproval.
  ///
  /// In en, this message translates to:
  /// **'Requires approval'**
  String get validationApproval;

  /// No description provided for @validationFile.
  ///
  /// In en, this message translates to:
  /// **'Required file'**
  String get validationFile;

  /// No description provided for @conditionalLogic.
  ///
  /// In en, this message translates to:
  /// **'Conditional Logic'**
  String get conditionalLogic;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @ifCondition.
  ///
  /// In en, this message translates to:
  /// **'If'**
  String get ifCondition;

  /// No description provided for @thenAction.
  ///
  /// In en, this message translates to:
  /// **'Then'**
  String get thenAction;

  /// No description provided for @defectiveGreaterThan.
  ///
  /// In en, this message translates to:
  /// **'Defective greater than'**
  String get defectiveGreaterThan;

  /// No description provided for @requiresApprovalFrom.
  ///
  /// In en, this message translates to:
  /// **'Requires approval from'**
  String get requiresApprovalFrom;

  /// No description provided for @blockTransition.
  ///
  /// In en, this message translates to:
  /// **'Block transition'**
  String get blockTransition;

  /// No description provided for @showWarning.
  ///
  /// In en, this message translates to:
  /// **'Show warning'**
  String get showWarning;

  /// No description provided for @notifyRoles.
  ///
  /// In en, this message translates to:
  /// **'Notify roles'**
  String get notifyRoles;

  /// No description provided for @statusHistory.
  ///
  /// In en, this message translates to:
  /// **'Status History'**
  String get statusHistory;

  /// No description provided for @changedTo.
  ///
  /// In en, this message translates to:
  /// **'Changed to'**
  String get changedTo;

  /// No description provided for @changedBy.
  ///
  /// In en, this message translates to:
  /// **'Changed by'**
  String get changedBy;

  /// No description provided for @changedAt.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get changedAt;

  /// No description provided for @validationData.
  ///
  /// In en, this message translates to:
  /// **'Validation data'**
  String get validationData;

  /// No description provided for @noStatusHistory.
  ///
  /// In en, this message translates to:
  /// **'No change history'**
  String get noStatusHistory;

  /// No description provided for @specialPermissions.
  ///
  /// In en, this message translates to:
  /// **'Special Permissions'**
  String get specialPermissions;

  /// No description provided for @clientPermissions.
  ///
  /// In en, this message translates to:
  /// **'Client Permissions'**
  String get clientPermissions;

  /// No description provided for @canCreateBatches.
  ///
  /// In en, this message translates to:
  /// **'Can create batches'**
  String get canCreateBatches;

  /// No description provided for @canCreateProducts.
  ///
  /// In en, this message translates to:
  /// **'Can create products'**
  String get canCreateProducts;

  /// No description provided for @requiresApproval.
  ///
  /// In en, this message translates to:
  /// **'Requires approval'**
  String get requiresApproval;

  /// No description provided for @canViewAllProjects.
  ///
  /// In en, this message translates to:
  /// **'View all projects'**
  String get canViewAllProjects;

  /// No description provided for @standardClient.
  ///
  /// In en, this message translates to:
  /// **'Standard client'**
  String get standardClient;

  /// No description provided for @privilegedClient.
  ///
  /// In en, this message translates to:
  /// **'Privileged client'**
  String get privilegedClient;

  /// No description provided for @initializingRoles.
  ///
  /// In en, this message translates to:
  /// **'Initializing roles...'**
  String get initializingRoles;

  /// No description provided for @initializingStatuses.
  ///
  /// In en, this message translates to:
  /// **'Initializing statuses...'**
  String get initializingStatuses;

  /// No description provided for @rolesInitialized.
  ///
  /// In en, this message translates to:
  /// **'Roles initialized successfully'**
  String get rolesInitialized;

  /// No description provided for @statusesInitialized.
  ///
  /// In en, this message translates to:
  /// **'Statuses initialized successfully'**
  String get statusesInitialized;

  /// No description provided for @initializationComplete.
  ///
  /// In en, this message translates to:
  /// **'Initialization complete'**
  String get initializationComplete;

  /// No description provided for @initializationError.
  ///
  /// In en, this message translates to:
  /// **'Initialization error'**
  String get initializationError;

  /// No description provided for @insufficientPermissions.
  ///
  /// In en, this message translates to:
  /// **'Insufficient permissions'**
  String get insufficientPermissions;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @roleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Role not found'**
  String get roleNotFound;

  /// No description provided for @statusNotFound.
  ///
  /// In en, this message translates to:
  /// **'Status not found'**
  String get statusNotFound;

  /// No description provided for @invalidTransition.
  ///
  /// In en, this message translates to:
  /// **'Invalid transition'**
  String get invalidTransition;

  /// No description provided for @validationFailed.
  ///
  /// In en, this message translates to:
  /// **'Validation failed'**
  String get validationFailed;

  /// No description provided for @approvalRequired.
  ///
  /// In en, this message translates to:
  /// **'Approval required'**
  String get approvalRequired;

  /// No description provided for @contactAdminForPermissions.
  ///
  /// In en, this message translates to:
  /// **'Contact an administrator for permissions'**
  String get contactAdminForPermissions;
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
