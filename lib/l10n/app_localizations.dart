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
  /// **'Production Tracker'**
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
  /// **'Already have an account? Sign in'**
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

  /// No description provided for @statuses.
  ///
  /// In en, this message translates to:
  /// **'Statuses'**
  String get statuses;

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
  /// **'Product name'**
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

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found'**
  String get noClientsFound;

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
  /// **'Quantity label'**
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
  /// **'This action cannot be undone. Are you sure?'**
  String get deleteClientConfirm;

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
  /// **'Contact Name'**
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
  /// **'Login error'**
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
  /// **'Description label'**
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
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit? Unsaved changes will be lost.'**
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
  /// **'Error when deleting:'**
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
  /// **'Chat info'**
  String get chatInfo;

  /// No description provided for @muteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get muteNotifications;

  /// No description provided for @pinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'Pinned messages'**
  String get pinnedMessages;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @beFirstToMessage.
  ///
  /// In en, this message translates to:
  /// **'Be the first to send something'**
  String get beFirstToMessage;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get reply;

  /// No description provided for @react.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get react;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get textCopied;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @messageUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Message unpinned'**
  String get messageUnpinned;

  /// No description provided for @messagePinned.
  ///
  /// In en, this message translates to:
  /// **'Message pinned'**
  String get messagePinned;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// No description provided for @newContentHint.
  ///
  /// In en, this message translates to:
  /// **'New content...'**
  String get newContentHint;

  /// No description provided for @messageEdited.
  ///
  /// In en, this message translates to:
  /// **'Message edited'**
  String get messageEdited;

  /// No description provided for @editError.
  ///
  /// In en, this message translates to:
  /// **'Error when editing:'**
  String get editError;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessage;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get deleteMessageConfirm;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @sendMessageError.
  ///
  /// In en, this message translates to:
  /// **'Error when sending message:'**
  String get sendMessageError;

  /// No description provided for @reactionError.
  ///
  /// In en, this message translates to:
  /// **'Error when reacting:'**
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
  /// **'View orders'**
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
  /// **'Invalid color format'**
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
  /// **'Basic'**
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
  /// **'Only assigned'**
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
  /// **'Status created successfully'**
  String get statusCreated;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated successfully'**
  String get statusUpdated;

  /// No description provided for @statusDeleted.
  ///
  /// In en, this message translates to:
  /// **'Status deleted successfully'**
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
  /// **'Transition created successfully'**
  String get transitionCreated;

  /// No description provided for @transitionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transition updated successfully'**
  String get transitionUpdated;

  /// No description provided for @transitionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transition deleted successfully'**
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
  /// **'Logic'**
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

  /// No description provided for @editProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editProjectTitle;

  /// No description provided for @projectInformation.
  ///
  /// In en, this message translates to:
  /// **'Project Information'**
  String get projectInformation;

  /// No description provided for @clientInformation.
  ///
  /// In en, this message translates to:
  /// **'Client Information'**
  String get clientInformation;

  /// No description provided for @accessControl.
  ///
  /// In en, this message translates to:
  /// **'Access Control'**
  String get accessControl;

  /// No description provided for @accessControlDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage who can view and work with this project'**
  String get accessControlDescription;

  /// No description provided for @projectClient.
  ///
  /// In en, this message translates to:
  /// **'Project Client'**
  String get projectClient;

  /// No description provided for @clientCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Client cannot be changed'**
  String get clientCannotBeChanged;

  /// No description provided for @contactClient.
  ///
  /// In en, this message translates to:
  /// **'Contact Client'**
  String get contactClient;

  /// No description provided for @cannotEditProject.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to edit this project'**
  String get cannotEditProject;

  /// No description provided for @cannotEditProjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Only assigned members or administrators can edit this project'**
  String get cannotEditProjectDesc;

  /// No description provided for @projectIsCompleted.
  ///
  /// In en, this message translates to:
  /// **'This project is completed'**
  String get projectIsCompleted;

  /// No description provided for @projectIsCompletedDesc.
  ///
  /// In en, this message translates to:
  /// **'Completed projects cannot be edited'**
  String get projectIsCompletedDesc;

  /// No description provided for @projectIsCancelled.
  ///
  /// In en, this message translates to:
  /// **'This project is cancelled'**
  String get projectIsCancelled;

  /// No description provided for @projectIsCancelledDesc.
  ///
  /// In en, this message translates to:
  /// **'Cancelled projects cannot be edited'**
  String get projectIsCancelledDesc;

  /// No description provided for @automaticAccess.
  ///
  /// In en, this message translates to:
  /// **'Automatic access (no assignment needed)'**
  String get automaticAccess;

  /// No description provided for @assignAdditionalMembers.
  ///
  /// In en, this message translates to:
  /// **'Assign additional members'**
  String get assignAdditionalMembers;

  /// No description provided for @allMembersHaveAutoAccess.
  ///
  /// In en, this message translates to:
  /// **'All members have automatic access'**
  String get allMembersHaveAutoAccess;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @removeMemberFromProject.
  ///
  /// In en, this message translates to:
  /// **'Remove from project?'**
  String get removeMemberFromProject;

  /// No description provided for @removeMemberFromProjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {memberName} from this project?'**
  String removeMemberFromProjectDesc(Object memberName);

  /// No description provided for @memberHasProducts.
  ///
  /// In en, this message translates to:
  /// **'This member has assigned products'**
  String get memberHasProducts;

  /// No description provided for @memberHasProductsWarning.
  ///
  /// In en, this message translates to:
  /// **'Removing them may affect production tracking'**
  String get memberHasProductsWarning;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed from project'**
  String get memberRemoved;

  /// No description provided for @memberAdded.
  ///
  /// In en, this message translates to:
  /// **'Member added to project'**
  String get memberAdded;

  /// No description provided for @projectUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Project updated successfully'**
  String get projectUpdatedSuccess;

  /// No description provided for @projectUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating project'**
  String get projectUpdateError;

  /// No description provided for @savingChanges.
  ///
  /// In en, this message translates to:
  /// **'Saving changes...'**
  String get savingChanges;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardChanges;

  /// No description provided for @unsavedChangesDesc.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get unsavedChangesDesc;

  /// No description provided for @viewClientDetails.
  ///
  /// In en, this message translates to:
  /// **'View client details'**
  String get viewClientDetails;

  /// No description provided for @clientContact.
  ///
  /// In en, this message translates to:
  /// **'Client contact'**
  String get clientContact;

  /// No description provided for @loadingClientInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading client information...'**
  String get loadingClientInfo;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @viewByPhases.
  ///
  /// In en, this message translates to:
  /// **'View by Phases'**
  String get viewByPhases;

  /// No description provided for @viewByStatus.
  ///
  /// In en, this message translates to:
  /// **'View by Status'**
  String get viewByStatus;

  /// No description provided for @switchView.
  ///
  /// In en, this message translates to:
  /// **'Switch view'**
  String get switchView;

  /// No description provided for @phaseView.
  ///
  /// In en, this message translates to:
  /// **'Production Phases'**
  String get phaseView;

  /// No description provided for @statusView.
  ///
  /// In en, this message translates to:
  /// **'Quality States'**
  String get statusView;

  /// No description provided for @cannotMoveToPhase.
  ///
  /// In en, this message translates to:
  /// **'You cannot move products to this phase'**
  String get cannotMoveToPhase;

  /// No description provided for @cannotMoveFromPhase.
  ///
  /// In en, this message translates to:
  /// **'You cannot move products from this phase'**
  String get cannotMoveFromPhase;

  /// No description provided for @onlyAssignedPhases.
  ///
  /// In en, this message translates to:
  /// **'You can only manage your assigned phases'**
  String get onlyAssignedPhases;

  /// No description provided for @phaseReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get phaseReadOnly;

  /// No description provided for @noAccessToPhase.
  ///
  /// In en, this message translates to:
  /// **'No access to this phase'**
  String get noAccessToPhase;

  /// No description provided for @cannotChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to change status'**
  String get cannotChangeStatus;

  /// No description provided for @statusTransitionNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This status transition is not allowed'**
  String get statusTransitionNotAllowed;

  /// No description provided for @tooManyProducts.
  ///
  /// In en, this message translates to:
  /// **'Too many products to display'**
  String get tooManyProducts;

  /// No description provided for @tooManyProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Showing only the first 100 products. Apply filters to see specific results.'**
  String get tooManyProductsDesc;

  /// No description provided for @applyFiltersPrompt.
  ///
  /// In en, this message translates to:
  /// **'Apply filters to reduce results'**
  String get applyFiltersPrompt;

  /// No description provided for @showingProductsCount.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} products'**
  String showingProductsCount(Object count);

  /// No description provided for @productsInPhase.
  ///
  /// In en, this message translates to:
  /// **'{count} products in this phase'**
  String productsInPhase(Object count);

  /// No description provided for @productsInStatus.
  ///
  /// In en, this message translates to:
  /// **'{count} products in this status'**
  String productsInStatus(Object count);

  /// No description provided for @newStatus.
  ///
  /// In en, this message translates to:
  /// **'New Status'**
  String get newStatus;

  /// No description provided for @statusTransition.
  ///
  /// In en, this message translates to:
  /// **'Status Transition'**
  String get statusTransition;

  /// No description provided for @confirmStatusChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm status change'**
  String get confirmStatusChange;

  /// No description provided for @statusChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Status changed successfully'**
  String get statusChangedSuccess;

  /// No description provided for @statusChangeError.
  ///
  /// In en, this message translates to:
  /// **'Error changing status'**
  String get statusChangeError;

  /// No description provided for @fillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in the required fields to create your account'**
  String get fillRequiredFields;

  /// No description provided for @defectDescription.
  ///
  /// In en, this message translates to:
  /// **'Defect Description'**
  String get defectDescription;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get enterDescription;

  /// No description provided for @approvalRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'This change requires approval from {roles}'**
  String approvalRequiredDesc(Object roles);

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get pendingApproval;

  /// No description provided for @loadingPhases.
  ///
  /// In en, this message translates to:
  /// **'Loading phases...'**
  String get loadingPhases;

  /// No description provided for @loadingStatuses.
  ///
  /// In en, this message translates to:
  /// **'Loading statuses...'**
  String get loadingStatuses;

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @loadingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Checking permissions...'**
  String get loadingPermissions;

  /// No description provided for @timeInPhase.
  ///
  /// In en, this message translates to:
  /// **'{time} in this phase'**
  String timeInPhase(Object time);

  /// No description provided for @timeInStatus.
  ///
  /// In en, this message translates to:
  /// **'{time} in this status'**
  String timeInStatus(Object time);

  /// No description provided for @daysSingular.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get daysSingular;

  /// No description provided for @daysPlural.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysPlural;

  /// No description provided for @hoursSingular.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hoursSingular;

  /// No description provided for @hoursPlural.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hoursPlural;

  /// No description provided for @managePermissions.
  ///
  /// In en, this message translates to:
  /// **'Manage Permissions'**
  String get managePermissions;

  /// No description provided for @permissionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Permissions saved successfully'**
  String get permissionsSaved;

  /// No description provided for @baseRole.
  ///
  /// In en, this message translates to:
  /// **'Base role'**
  String get baseRole;

  /// No description provided for @customizations.
  ///
  /// In en, this message translates to:
  /// **'customizations'**
  String get customizations;

  /// No description provided for @roleAllowsButUserDenied.
  ///
  /// In en, this message translates to:
  /// **'Role allows but this user has denied'**
  String get roleAllowsButUserDenied;

  /// No description provided for @roleDeniesButUserAllowed.
  ///
  /// In en, this message translates to:
  /// **'Role denies but this user has allowed'**
  String get roleDeniesButUserAllowed;

  /// No description provided for @roleScope.
  ///
  /// In en, this message translates to:
  /// **'Role scope'**
  String get roleScope;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noProductionAccess.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to production'**
  String get noProductionAccess;

  /// No description provided for @manageMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get manageMembers;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembers;

  /// No description provided for @filterByRole.
  ///
  /// In en, this message translates to:
  /// **'Filter by Role'**
  String get filterByRole;

  /// No description provided for @filterByName.
  ///
  /// In en, this message translates to:
  /// **'Filter by name'**
  String get filterByName;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRoles;

  /// No description provided for @clientsCard.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsCard;

  /// No description provided for @totalClients.
  ///
  /// In en, this message translates to:
  /// **'Total Clients'**
  String get totalClients;

  /// No description provided for @roleDistribution.
  ///
  /// In en, this message translates to:
  /// **'Role Distribution'**
  String get roleDistribution;

  /// No description provided for @viewingOwnPermissions.
  ///
  /// In en, this message translates to:
  /// **'Viewing your permissions'**
  String get viewingOwnPermissions;

  /// No description provided for @viewingOwnPermissionsDesc.
  ///
  /// In en, this message translates to:
  /// **'You are viewing your own permissions. You cannot modify organization permissions to avoid losing access.'**
  String get viewingOwnPermissionsDesc;

  /// No description provided for @cannotModifyOrgPermissions.
  ///
  /// In en, this message translates to:
  /// **'Cannot modify own organization permissions'**
  String get cannotModifyOrgPermissions;

  /// No description provided for @readOnlyMode.
  ///
  /// In en, this message translates to:
  /// **'Read-only mode'**
  String get readOnlyMode;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @noClientsMessage.
  ///
  /// In en, this message translates to:
  /// **'No members registered as clients'**
  String get noClientsMessage;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @withoutEmail.
  ///
  /// In en, this message translates to:
  /// **'Without email'**
  String get withoutEmail;

  /// No description provided for @errorLoadingUser.
  ///
  /// In en, this message translates to:
  /// **'Error loading user'**
  String get errorLoadingUser;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @createProduct.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get createProduct;

  /// No description provided for @createProductFamily.
  ///
  /// In en, this message translates to:
  /// **'Create product family'**
  String get createProductFamily;

  /// No description provided for @selectClient.
  ///
  /// In en, this message translates to:
  /// **'Select client'**
  String get selectClient;

  /// No description provided for @selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select project'**
  String get selectProject;

  /// No description provided for @selectFamily.
  ///
  /// In en, this message translates to:
  /// **'Select family'**
  String get selectFamily;

  /// No description provided for @createFamily.
  ///
  /// In en, this message translates to:
  /// **'Create family'**
  String get createFamily;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @exitWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Exit without saving'**
  String get exitWithoutSaving;

  /// No description provided for @createNewFamily.
  ///
  /// In en, this message translates to:
  /// **'Create New Family'**
  String get createNewFamily;

  /// No description provided for @familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyNameLabel;

  /// No description provided for @familyNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g: Handbags'**
  String get familyNameHint;

  /// No description provided for @createNewFamilyDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the new product family. You must create at least one product for the family to be registered.'**
  String get createNewFamilyDescription;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @productCreatedWithFamily.
  ///
  /// In en, this message translates to:
  /// **'Family \"{family}\" and product created successfully'**
  String productCreatedWithFamily(String family);

  /// No description provided for @productCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product created successfully'**
  String get productCreatedSuccess;

  /// No description provided for @noProjectsForThisClient.
  ///
  /// In en, this message translates to:
  /// **'No projects for this client'**
  String get noProjectsForThisClient;

  /// No description provided for @selectClientFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a client first'**
  String get selectClientFirst;

  /// No description provided for @selectProjectFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a project first'**
  String get selectProjectFirst;

  /// No description provided for @noFamiliesCreateNew.
  ///
  /// In en, this message translates to:
  /// **'No families, create a new one'**
  String get noFamiliesCreateNew;

  /// No description provided for @createNewFamilyOption.
  ///
  /// In en, this message translates to:
  /// **'Create new family'**
  String get createNewFamilyOption;

  /// No description provided for @youMustCreateAProduct.
  ///
  /// In en, this message translates to:
  /// **'You must also create a product for the family to be created'**
  String get youMustCreateAProduct;

  /// No description provided for @productFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Product family'**
  String get productFamilyLabel;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @updatedBy.
  ///
  /// In en, this message translates to:
  /// **'Updated by'**
  String get updatedBy;

  /// No description provided for @timesUsed.
  ///
  /// In en, this message translates to:
  /// **'Times used'**
  String get timesUsed;

  /// No description provided for @onlyUrgent.
  ///
  /// In en, this message translates to:
  /// **'Only urgent'**
  String get onlyUrgent;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Remove filters'**
  String get clearFilters;

  /// No description provided for @searchBatches.
  ///
  /// In en, this message translates to:
  /// **'Search batches...'**
  String get searchBatches;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @searchInKanban.
  ///
  /// In en, this message translates to:
  /// **'Search in Kanban...'**
  String get searchInKanban;

  /// No description provided for @manageProductStatuses.
  ///
  /// In en, this message translates to:
  /// **'Manage Product Statuses'**
  String get manageProductStatuses;

  /// No description provided for @deleteStatus.
  ///
  /// In en, this message translates to:
  /// **'Delete Status'**
  String get deleteStatus;

  /// No description provided for @statusName.
  ///
  /// In en, this message translates to:
  /// **'Status Name'**
  String get statusName;

  /// No description provided for @statusNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Under Review'**
  String get statusNameHint;

  /// No description provided for @statusDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get statusDescription;

  /// No description provided for @statusDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what this status is used for'**
  String get statusDescriptionHint;

  /// No description provided for @statusColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get statusColor;

  /// No description provided for @statusIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get statusIcon;

  /// No description provided for @statusPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get statusPreview;

  /// No description provided for @systemStatus.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemStatus;

  /// No description provided for @systemStatuses.
  ///
  /// In en, this message translates to:
  /// **'System Statuses'**
  String get systemStatuses;

  /// No description provided for @customStatuses.
  ///
  /// In en, this message translates to:
  /// **'Custom Statuses'**
  String get customStatuses;

  /// No description provided for @customStatus.
  ///
  /// In en, this message translates to:
  /// **'Custom Status'**
  String get customStatus;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @reorderStatuses.
  ///
  /// In en, this message translates to:
  /// **'Reorder Statuses'**
  String get reorderStatuses;

  /// No description provided for @statusesReordered.
  ///
  /// In en, this message translates to:
  /// **'Statuses reordered successfully'**
  String get statusesReordered;

  /// No description provided for @errorReorderingStatuses.
  ///
  /// In en, this message translates to:
  /// **'Error reordering statuses'**
  String get errorReorderingStatuses;

  /// No description provided for @noStatusesFound.
  ///
  /// In en, this message translates to:
  /// **'No statuses configured'**
  String get noStatusesFound;

  /// No description provided for @createFirstStatus.
  ///
  /// In en, this message translates to:
  /// **'Create your first custom status to get started'**
  String get createFirstStatus;

  /// No description provided for @noCustomStatuses.
  ///
  /// In en, this message translates to:
  /// **'No custom statuses. System statuses cannot be deleted.'**
  String get noCustomStatuses;

  /// No description provided for @statusesDescription.
  ///
  /// In en, this message translates to:
  /// **'Statuses allow you to classify products during production. System statuses cannot be deleted.'**
  String get statusesDescription;

  /// No description provided for @statusNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get statusNameRequired;

  /// No description provided for @statusNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get statusNameTooShort;

  /// No description provided for @statusDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get statusDescriptionRequired;

  /// No description provided for @statusNameExists.
  ///
  /// In en, this message translates to:
  /// **'A status with this name already exists'**
  String get statusNameExists;

  /// No description provided for @statusColorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid color (use #RRGGBB format)'**
  String get statusColorInvalid;

  /// No description provided for @deleteStatusConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this status?'**
  String get deleteStatusConfirm;

  /// No description provided for @deleteStatusWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Products with this status will be left unclassified.'**
  String get deleteStatusWarning;

  /// No description provided for @statusInUseCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'This status is in use by products and cannot be deleted'**
  String get statusInUseCannotDelete;

  /// No description provided for @statusActivated.
  ///
  /// In en, this message translates to:
  /// **'Status activated'**
  String get statusActivated;

  /// No description provided for @statusDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Status deactivated'**
  String get statusDeactivated;

  /// No description provided for @errorCreatingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error creating status'**
  String get errorCreatingStatus;

  /// No description provided for @errorUpdatingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating status'**
  String get errorUpdatingStatus;

  /// No description provided for @errorDeletingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error deleting status'**
  String get errorDeletingStatus;

  /// No description provided for @tapToSelectIcon.
  ///
  /// In en, this message translates to:
  /// **'Tap to select an icon'**
  String get tapToSelectIcon;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @manageStatusTransitions.
  ///
  /// In en, this message translates to:
  /// **'Manage Transitions'**
  String get manageStatusTransitions;

  /// No description provided for @createTransition.
  ///
  /// In en, this message translates to:
  /// **'Create Transition'**
  String get createTransition;

  /// No description provided for @editTransition.
  ///
  /// In en, this message translates to:
  /// **'Edit Transition'**
  String get editTransition;

  /// No description provided for @deleteTransition.
  ///
  /// In en, this message translates to:
  /// **'Delete Transition'**
  String get deleteTransition;

  /// No description provided for @transitionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Transitions define how products can change from one status to another, with specific validations and permissions.'**
  String get transitionsDescription;

  /// No description provided for @filterByFromStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by origin status'**
  String get filterByFromStatus;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @hideInactiveTransitions.
  ///
  /// In en, this message translates to:
  /// **'Hide inactive'**
  String get hideInactiveTransitions;

  /// No description provided for @showInactiveTransitions.
  ///
  /// In en, this message translates to:
  /// **'Show inactive'**
  String get showInactiveTransitions;

  /// No description provided for @noTransitionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transitions configured'**
  String get noTransitionsFound;

  /// No description provided for @noTransitionsForStatus.
  ///
  /// In en, this message translates to:
  /// **'No transitions for this status'**
  String get noTransitionsForStatus;

  /// No description provided for @createFirstTransition.
  ///
  /// In en, this message translates to:
  /// **'Create your first transition to get started'**
  String get createFirstTransition;

  /// No description provided for @deleteTransitionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transition?'**
  String get deleteTransitionConfirm;

  /// No description provided for @deleteTransitionWarning.
  ///
  /// In en, this message translates to:
  /// **'Users will not be able to move products between these statuses.'**
  String get deleteTransitionWarning;

  /// No description provided for @transitionActivated.
  ///
  /// In en, this message translates to:
  /// **'Transition activated'**
  String get transitionActivated;

  /// No description provided for @transitionDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Transition deactivated'**
  String get transitionDeactivated;

  /// No description provided for @errorCreatingTransition.
  ///
  /// In en, this message translates to:
  /// **'Error creating transition'**
  String get errorCreatingTransition;

  /// No description provided for @errorUpdatingTransition.
  ///
  /// In en, this message translates to:
  /// **'Error updating transition'**
  String get errorUpdatingTransition;

  /// No description provided for @errorDeletingTransition.
  ///
  /// In en, this message translates to:
  /// **'Error deleting transition'**
  String get errorDeletingTransition;

  /// No description provided for @transitionWizardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure the transition between statuses step by step'**
  String get transitionWizardSubtitle;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Basic Configuration'**
  String get step1Title;

  /// No description provided for @step1Description.
  ///
  /// In en, this message translates to:
  /// **'Select the origin and destination statuses, and the roles that can execute this transition.'**
  String get step1Description;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Validation Type'**
  String get step2Title;

  /// No description provided for @step2Description.
  ///
  /// In en, this message translates to:
  /// **'Choose what type of validation is required for this transition.'**
  String get step2Description;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Configure Validation'**
  String get step3Title;

  /// No description provided for @step3Description.
  ///
  /// In en, this message translates to:
  /// **'Define the specific parameters of the selected validation.'**
  String get step3Description;

  /// No description provided for @step4Title.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Conditional Logic (Optional)'**
  String get step4Title;

  /// No description provided for @step4Description.
  ///
  /// In en, this message translates to:
  /// **'Add automatic rules that are evaluated based on the data entered.'**
  String get step4Description;

  /// No description provided for @step5Title.
  ///
  /// In en, this message translates to:
  /// **'Step 5: Summary'**
  String get step5Title;

  /// No description provided for @step5Description.
  ///
  /// In en, this message translates to:
  /// **'Review all the configuration before saving.'**
  String get step5Description;

  /// No description provided for @selectRolesDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which roles can execute this transition'**
  String get selectRolesDescription;

  /// No description provided for @selectAtLeastOneRole.
  ///
  /// In en, this message translates to:
  /// **'You must select at least one role'**
  String get selectAtLeastOneRole;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @simpleApprovalInfo.
  ///
  /// In en, this message translates to:
  /// **'This transition only requires confirmation. No additional configuration needed.'**
  String get simpleApprovalInfo;

  /// No description provided for @fieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Field label'**
  String get fieldLabel;

  /// No description provided for @fieldLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Comment'**
  String get fieldLabelHint;

  /// No description provided for @minLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum length'**
  String get minLength;

  /// No description provided for @maxLength.
  ///
  /// In en, this message translates to:
  /// **'Maximum length'**
  String get maxLength;

  /// No description provided for @quantityLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Defective quantity'**
  String get quantityLabelHint;

  /// No description provided for @quantityRange.
  ///
  /// In en, this message translates to:
  /// **'Quantity range'**
  String get quantityRange;

  /// No description provided for @minQuantity.
  ///
  /// In en, this message translates to:
  /// **'Minimum quantity'**
  String get minQuantity;

  /// No description provided for @maxQuantity.
  ///
  /// In en, this message translates to:
  /// **'Maximum quantity'**
  String get maxQuantity;

  /// No description provided for @descriptionLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Defect description'**
  String get descriptionLabelHint;

  /// No description provided for @checklistItems.
  ///
  /// In en, this message translates to:
  /// **'Checklist items'**
  String get checklistItems;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @addChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'Add checklist item'**
  String get addChecklistItem;

  /// No description provided for @itemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item label'**
  String get itemLabel;

  /// No description provided for @minPhotos.
  ///
  /// In en, this message translates to:
  /// **'Minimum photos'**
  String get minPhotos;

  /// No description provided for @minPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: 2'**
  String get minPhotosHint;

  /// No description provided for @minApprovals.
  ///
  /// In en, this message translates to:
  /// **'Minimum approvals'**
  String get minApprovals;

  /// No description provided for @minApprovalsHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: 2'**
  String get minApprovalsHint;

  /// No description provided for @validationConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Validation Configuration'**
  String get validationConfiguration;

  /// No description provided for @noConfigurationRequired.
  ///
  /// In en, this message translates to:
  /// **'No configuration required'**
  String get noConfigurationRequired;

  /// No description provided for @enableConditionalLogic.
  ///
  /// In en, this message translates to:
  /// **'Enable conditional logic'**
  String get enableConditionalLogic;

  /// No description provided for @conditionalLogicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add automatic rules based on entered data'**
  String get conditionalLogicSubtitle;

  /// No description provided for @field.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get field;

  /// No description provided for @operator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operator;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @valueHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: 5'**
  String get valueHint;

  /// No description provided for @actionType.
  ///
  /// In en, this message translates to:
  /// **'Action type'**
  String get actionType;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message to display'**
  String get messageHint;

  /// No description provided for @textLength.
  ///
  /// In en, this message translates to:
  /// **'Text length'**
  String get textLength;

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'Number of photos'**
  String get photoCount;

  /// No description provided for @approvalCount.
  ///
  /// In en, this message translates to:
  /// **'Number of approvals'**
  String get approvalCount;

  /// No description provided for @greaterThan.
  ///
  /// In en, this message translates to:
  /// **'Greater than'**
  String get greaterThan;

  /// No description provided for @greaterThanOrEqual.
  ///
  /// In en, this message translates to:
  /// **'Greater than or equal'**
  String get greaterThanOrEqual;

  /// No description provided for @lessThan.
  ///
  /// In en, this message translates to:
  /// **'Less than'**
  String get lessThan;

  /// No description provided for @lessThanOrEqual.
  ///
  /// In en, this message translates to:
  /// **'Less than or equal'**
  String get lessThanOrEqual;

  /// No description provided for @equals.
  ///
  /// In en, this message translates to:
  /// **'Equal to'**
  String get equals;

  /// No description provided for @notEquals.
  ///
  /// In en, this message translates to:
  /// **'Not equal to'**
  String get notEquals;

  /// No description provided for @contains.
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get contains;

  /// No description provided for @requireApproval.
  ///
  /// In en, this message translates to:
  /// **'Require approval'**
  String get requireApproval;

  /// No description provided for @requireAdditionalField.
  ///
  /// In en, this message translates to:
  /// **'Require additional field'**
  String get requireAdditionalField;

  /// No description provided for @selectApprovers.
  ///
  /// In en, this message translates to:
  /// **'Select approvers'**
  String get selectApprovers;

  /// No description provided for @selectRolesToNotify.
  ///
  /// In en, this message translates to:
  /// **'Select who to notify'**
  String get selectRolesToNotify;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @allowedRoles.
  ///
  /// In en, this message translates to:
  /// **'Allowed roles'**
  String get allowedRoles;

  /// No description provided for @allItemsRequired.
  ///
  /// In en, this message translates to:
  /// **'All elements required'**
  String get allItemsRequired;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Añadir'**
  String get add;

  /// No description provided for @confirmTransition.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transition'**
  String get confirmTransition;

  /// No description provided for @confirmTransitionMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to move this product to the next status?'**
  String get confirmTransitionMessage;

  /// No description provided for @totalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total quantity'**
  String get totalQuantity;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get enterText;

  /// No description provided for @enterTextHint.
  ///
  /// In en, this message translates to:
  /// **'Write here...'**
  String get enterTextHint;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @textTooShort.
  ///
  /// In en, this message translates to:
  /// **'Text is too short'**
  String get textTooShort;

  /// No description provided for @quantityAndDescription.
  ///
  /// In en, this message translates to:
  /// **'Quantity and Description'**
  String get quantityAndDescription;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get describeIssue;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @minimumValue.
  ///
  /// In en, this message translates to:
  /// **'Minimum value'**
  String get minimumValue;

  /// No description provided for @maximumValue.
  ///
  /// In en, this message translates to:
  /// **'Maximum value'**
  String get maximumValue;

  /// No description provided for @range.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get range;

  /// No description provided for @conditionalRuleTriggered.
  ///
  /// In en, this message translates to:
  /// **'A conditional rule was triggered'**
  String get conditionalRuleTriggered;

  /// No description provided for @approvalWillBeRequired.
  ///
  /// In en, this message translates to:
  /// **'This transition will require additional approval'**
  String get approvalWillBeRequired;

  /// No description provided for @verificationChecklist.
  ///
  /// In en, this message translates to:
  /// **'Verification Checklist'**
  String get verificationChecklist;

  /// No description provided for @allItemsMustBeChecked.
  ///
  /// In en, this message translates to:
  /// **'All items must be checked'**
  String get allItemsMustBeChecked;

  /// No description provided for @itemsCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get itemsCompleted;

  /// No description provided for @completeRequiredItems.
  ///
  /// In en, this message translates to:
  /// **'Complete all required items'**
  String get completeRequiredItems;

  /// No description provided for @attachPhotos.
  ///
  /// In en, this message translates to:
  /// **'Attach Photos'**
  String get attachPhotos;

  /// No description provided for @minPhotosRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum photos required'**
  String get minPhotosRequired;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @selectedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Selected photos'**
  String get selectedPhotos;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploading;

  /// No description provided for @uploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error'**
  String get uploadError;

  /// No description provided for @multiApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Multiple Approval Required'**
  String get multiApprovalRequired;

  /// No description provided for @minApprovalsRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum approvals required'**
  String get minApprovalsRequired;

  /// No description provided for @approversSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get approversSelected;

  /// No description provided for @noEligibleApprovers.
  ///
  /// In en, this message translates to:
  /// **'No eligible approvers'**
  String get noEligibleApprovers;

  /// No description provided for @unknownRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown role'**
  String get unknownRole;

  /// No description provided for @noTransitionConfigured.
  ///
  /// In en, this message translates to:
  /// **'No transition configured between these statuses'**
  String get noTransitionConfigured;

  /// No description provided for @transitionNotActive.
  ///
  /// In en, this message translates to:
  /// **'This transition is deactivated'**
  String get transitionNotActive;

  /// No description provided for @roleNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Your role is not authorized for this transition'**
  String get roleNotAuthorized;

  /// No description provided for @customParameters.
  ///
  /// In en, this message translates to:
  /// **'Custom parameters'**
  String get customParameters;

  /// No description provided for @addParameter.
  ///
  /// In en, this message translates to:
  /// **'Add parameter'**
  String get addParameter;

  /// No description provided for @removeParameter.
  ///
  /// In en, this message translates to:
  /// **'Remove parameter'**
  String get removeParameter;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @booleanType.
  ///
  /// In en, this message translates to:
  /// **'Yes/No'**
  String get booleanType;

  /// No description provided for @reorderingStatusesMessage.
  ///
  /// In en, this message translates to:
  /// **'Reordering statuses - Drag cards to change order'**
  String get reorderingStatusesMessage;

  /// No description provided for @productionDashboardTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Production Dashboard'**
  String get productionDashboardTitleLabel;

  /// No description provided for @viewAllBatches.
  ///
  /// In en, this message translates to:
  /// **'View all batches'**
  String get viewAllBatches;

  /// No description provided for @productionPhasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Production Phases'**
  String get productionPhasesLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @clientFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Client Form'**
  String get clientFormTitle;

  /// No description provided for @editingClient.
  ///
  /// In en, this message translates to:
  /// **'Editing Client'**
  String get editingClient;

  /// No description provided for @creatingClient.
  ///
  /// In en, this message translates to:
  /// **'Creating Client'**
  String get creatingClient;

  /// No description provided for @selectColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Identifying Color'**
  String get selectColorLabel;

  /// No description provided for @selectColorHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose a color to visually identify the client'**
  String get selectColorHelper;

  /// No description provided for @colorPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get colorPickerTitle;

  /// No description provided for @defaultColors.
  ///
  /// In en, this message translates to:
  /// **'Default colors'**
  String get defaultColors;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get customColor;

  /// No description provided for @clientSpecialPermissions.
  ///
  /// In en, this message translates to:
  /// **'Special Permissions'**
  String get clientSpecialPermissions;

  /// No description provided for @clientPermissionsHelper.
  ///
  /// In en, this message translates to:
  /// **'Additional permissions for this client beyond the basic role'**
  String get clientPermissionsHelper;

  /// No description provided for @clientPermissionsDescription.
  ///
  /// In en, this message translates to:
  /// **'These permissions will apply to all members associated with this client'**
  String get clientPermissionsDescription;

  /// No description provided for @noSpecialPermissions.
  ///
  /// In en, this message translates to:
  /// **'No special permissions'**
  String get noSpecialPermissions;

  /// No description provided for @permissionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No permissions} =1 {1 permission} other {{count} permissions}}'**
  String permissionsCount(num count);

  /// No description provided for @configurePermissions.
  ///
  /// In en, this message translates to:
  /// **'Configure permissions'**
  String get configurePermissions;

  /// No description provided for @permissionModule.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get permissionModule;

  /// No description provided for @permissionAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get permissionAction;

  /// No description provided for @permissionScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get permissionScope;

  /// No description provided for @requiresApprovalNote.
  ///
  /// In en, this message translates to:
  /// **'Requires administrator approval'**
  String get requiresApprovalNote;

  /// No description provided for @doesNotRequireApproval.
  ///
  /// In en, this message translates to:
  /// **'Does not require approval'**
  String get doesNotRequireApproval;

  /// No description provided for @canCreateBatchesLabel.
  ///
  /// In en, this message translates to:
  /// **'Can create batches'**
  String get canCreateBatchesLabel;

  /// No description provided for @canCreateBatchesDesc.
  ///
  /// In en, this message translates to:
  /// **'Client can create production batches'**
  String get canCreateBatchesDesc;

  /// No description provided for @canCreateProductsLabel.
  ///
  /// In en, this message translates to:
  /// **'Can create products'**
  String get canCreateProductsLabel;

  /// No description provided for @canCreateProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Client can create custom products'**
  String get canCreateProductsDesc;

  /// No description provided for @canViewAllProjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'View all projects'**
  String get canViewAllProjectsLabel;

  /// No description provided for @canViewAllProjectsDesc.
  ///
  /// In en, this message translates to:
  /// **'Can view all projects or only assigned ones'**
  String get canViewAllProjectsDesc;

  /// No description provided for @canViewAllBatchesLabel.
  ///
  /// In en, this message translates to:
  /// **'View all batches'**
  String get canViewAllBatchesLabel;

  /// No description provided for @canViewAllBatchesDesc.
  ///
  /// In en, this message translates to:
  /// **'Can view all batches or only assigned ones'**
  String get canViewAllBatchesDesc;

  /// No description provided for @canEditProductsLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit products'**
  String get canEditProductsLabel;

  /// No description provided for @canEditProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Can edit product information'**
  String get canEditProductsDesc;

  /// No description provided for @canSendMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Send messages'**
  String get canSendMessagesLabel;

  /// No description provided for @canSendMessagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Can send messages in chat'**
  String get canSendMessagesDesc;

  /// No description provided for @colorRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a color'**
  String get colorRequired;

  /// No description provided for @permissionsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Permissions updated successfully'**
  String get permissionsUpdated;

  /// No description provided for @permissionsUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating permissions'**
  String get permissionsUpdateError;

  /// No description provided for @colorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Color updated successfully'**
  String get colorUpdated;

  /// No description provided for @colorUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating color'**
  String get colorUpdateError;

  /// No description provided for @standardClientBadge.
  ///
  /// In en, this message translates to:
  /// **'Standard client'**
  String get standardClientBadge;

  /// No description provided for @privilegedClientBadge.
  ///
  /// In en, this message translates to:
  /// **'Privileged client'**
  String get privilegedClientBadge;

  /// No description provided for @enabledPermissions.
  ///
  /// In en, this message translates to:
  /// **'Enabled permissions'**
  String get enabledPermissions;

  /// No description provided for @clientColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Client color'**
  String get clientColorLabel;

  /// No description provided for @associatedMembers.
  ///
  /// In en, this message translates to:
  /// **'Associated Members'**
  String get associatedMembers;

  /// No description provided for @noAssociatedMembers.
  ///
  /// In en, this message translates to:
  /// **'No associated members'**
  String get noAssociatedMembers;

  /// No description provided for @noAssociatedMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Members with \'Client\' role will appear here when assigned from organization management'**
  String get noAssociatedMembersHint;

  /// No description provided for @errorLoadingMembers.
  ///
  /// In en, this message translates to:
  /// **'Error loading members'**
  String get errorLoadingMembers;

  /// No description provided for @clientDuplicatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Client duplicated successfully'**
  String get clientDuplicatedSuccess;

  /// No description provided for @duplicateClientError.
  ///
  /// In en, this message translates to:
  /// **'Error duplicating client'**
  String get duplicateClientError;

  /// No description provided for @deleteClientConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete client?'**
  String get deleteClientConfirmTitle;

  /// No description provided for @clientProjects.
  ///
  /// In en, this message translates to:
  /// **'Client Projects'**
  String get clientProjects;

  /// No description provided for @viewAllProjects.
  ///
  /// In en, this message translates to:
  /// **'View all projects'**
  String get viewAllProjects;

  /// No description provided for @editClientPermissions.
  ///
  /// In en, this message translates to:
  /// **'Edit Client Permissions'**
  String get editClientPermissions;

  /// No description provided for @clientPermissionsApplyToAllMembers.
  ///
  /// In en, this message translates to:
  /// **'These permissions will apply to all members associated with this client'**
  String get clientPermissionsApplyToAllMembers;

  /// No description provided for @clientPermissionsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Client permissions updated'**
  String get clientPermissionsUpdated;

  /// No description provided for @errorUpdatingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Error updating permissions'**
  String get errorUpdatingPermissions;

  /// No description provided for @clientRole.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientRole;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications'**
  String get noNotifications;

  /// No description provided for @approvalRequest.
  ///
  /// In en, this message translates to:
  /// **'Approval request'**
  String get approvalRequest;

  /// No description provided for @requestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejected;

  /// No description provided for @approveRequest.
  ///
  /// In en, this message translates to:
  /// **'Approve request'**
  String get approveRequest;

  /// No description provided for @rejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get rejectRequest;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get rejectionReason;

  /// No description provided for @enterRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Enter rejection reason'**
  String get enterRejectionReason;

  /// No description provided for @approvalSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Approval successful'**
  String get approvalSuccessful;

  /// No description provided for @rejectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Rejection successful'**
  String get rejectionSuccessful;

  /// No description provided for @objectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Object not found'**
  String get objectNotFound;

  /// No description provided for @requestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get requestedBy;

  /// No description provided for @requestedAt.
  ///
  /// In en, this message translates to:
  /// **'Requested at'**
  String get requestedAt;

  /// No description provided for @approvedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved by'**
  String get approvedBy;

  /// No description provided for @rejectedBy.
  ///
  /// In en, this message translates to:
  /// **'Rejected by'**
  String get rejectedBy;

  /// No description provided for @errorApprovingRequest.
  ///
  /// In en, this message translates to:
  /// **'Error approving request'**
  String get errorApprovingRequest;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectionReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason is required'**
  String get rejectionReasonRequired;

  /// No description provided for @errorRejectingRequest.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting request'**
  String get errorRejectingRequest;

  /// No description provided for @batchCreationPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Batch creation request sent for approval'**
  String get batchCreationPendingApproval;

  /// No description provided for @productCreationPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Product creation request sent for approval'**
  String get productCreationPendingApproval;

  /// No description provided for @projectCreationPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Project creation request sent for approval'**
  String get projectCreationPendingApproval;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your company\'s production efficiently'**
  String get welcomeSubtitle;

  /// No description provided for @joinOrganizationBtn.
  ///
  /// In en, this message translates to:
  /// **'Join an organization'**
  String get joinOrganizationBtn;

  /// No description provided for @requestActivationCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Activation Code'**
  String get requestActivationCodeTitle;

  /// No description provided for @requestCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request to create your organization'**
  String get requestCodeSubtitle;

  /// No description provided for @requestCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete the form and we\'ll send you an activation code via email within 24-48 hours'**
  String get requestCodeDescription;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyNameLabel;

  /// No description provided for @companyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: My Company LLC'**
  String get companyNameHint;

  /// No description provided for @companyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get companyNameRequired;

  /// No description provided for @companyNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get companyNameTooShort;

  /// No description provided for @contactNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Contact name is required'**
  String get contactNameRequired;

  /// No description provided for @contactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get contactEmailLabel;

  /// No description provided for @contactEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get contactEmailRequired;

  /// No description provided for @contactEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get contactEmailInvalid;

  /// No description provided for @contactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get contactPhoneLabel;

  /// No description provided for @contactPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get contactPhoneRequired;

  /// No description provided for @messageOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Message (Optional)'**
  String get messageOptionalLabel;

  /// No description provided for @messageOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your company...'**
  String get messageOptionalHint;

  /// No description provided for @activationRequestInfo.
  ///
  /// In en, this message translates to:
  /// **'We\'ll review your request and send you the activation code via email. The code will be valid for 7 days.'**
  String get activationRequestInfo;

  /// No description provided for @sendRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequestButton;

  /// No description provided for @requestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Sent!'**
  String get requestSentTitle;

  /// No description provided for @requestSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve received your request successfully.'**
  String get requestSentMessage;

  /// No description provided for @requestSentNextSteps.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive an email with the activation code within the next 24-48 hours. Check your spam folder.'**
  String get requestSentNextSteps;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @requestSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending request'**
  String get requestSendError;

  /// No description provided for @setupOrganizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Organization'**
  String get setupOrganizationTitle;

  /// No description provided for @step1BasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get step1BasicInfo;

  /// No description provided for @step2PhaseConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Phase Configuration'**
  String get step2PhaseConfiguration;

  /// No description provided for @step3Ready.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get step3Ready;

  /// No description provided for @phasesConfigurationDescription.
  ///
  /// In en, this message translates to:
  /// **'Phases help organize the production process'**
  String get phasesConfigurationDescription;

  /// No description provided for @useDefaultPhases.
  ///
  /// In en, this message translates to:
  /// **'Use default phases'**
  String get useDefaultPhases;

  /// No description provided for @useDefaultPhasesDescription.
  ///
  /// In en, this message translates to:
  /// **'Cutting, Preparation, Sewing, Finishing, Quality Control'**
  String get useDefaultPhasesDescription;

  /// No description provided for @defaultPhasesInclude.
  ///
  /// In en, this message translates to:
  /// **'Includes: Cutting, Preparation, Sewing, Finishing and Quality Control'**
  String get defaultPhasesInclude;

  /// No description provided for @organizationReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your organization is ready!'**
  String get organizationReadyMessage;

  /// No description provided for @organizationReadyDescription.
  ///
  /// In en, this message translates to:
  /// **'You can now start managing your production and invite members'**
  String get organizationReadyDescription;

  /// No description provided for @createOrganizationError.
  ///
  /// In en, this message translates to:
  /// **'Error creating organization'**
  String get createOrganizationError;

  /// No description provided for @organizationCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Organization created successfully!'**
  String get organizationCreatedSuccess;

  /// No description provided for @enterActivationCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Activation Code'**
  String get enterActivationCodeTitle;

  /// No description provided for @enterActivationCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code you received via email'**
  String get enterActivationCodeSubtitle;

  /// No description provided for @activationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Activation Code'**
  String get activationCodeLabel;

  /// No description provided for @activationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'ORG-2025-ABC123'**
  String get activationCodeHint;

  /// No description provided for @activationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get activationCodeRequired;

  /// No description provided for @validateCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Validate Code'**
  String get validateCodeButton;

  /// No description provided for @codeValidatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Valid code! Proceed to create your account'**
  String get codeValidatedSuccess;

  /// No description provided for @codeValidationError.
  ///
  /// In en, this message translates to:
  /// **'Error validating code'**
  String get codeValidationError;

  /// No description provided for @createInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Invitation'**
  String get createInvitationTitle;

  /// No description provided for @invitationCodeGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated code'**
  String get invitationCodeGenerated;

  /// No description provided for @selectRoleForInvitation.
  ///
  /// In en, this message translates to:
  /// **'Select the role for the new member'**
  String get selectRoleForInvitation;

  /// No description provided for @invitationDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get invitationDescription;

  /// No description provided for @invitationDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Invitation for John - Operator'**
  String get invitationDescriptionHint;

  /// No description provided for @maxUsesLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum uses'**
  String get maxUsesLabel;

  /// No description provided for @expirationDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days until expiration'**
  String get expirationDaysLabel;

  /// No description provided for @createInvitationButton.
  ///
  /// In en, this message translates to:
  /// **'Create Invitation'**
  String get createInvitationButton;

  /// No description provided for @invitationCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation created successfully'**
  String get invitationCreatedSuccess;

  /// No description provided for @invitationCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating invitation'**
  String get invitationCreateError;

  /// No description provided for @manageInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Invitations'**
  String get manageInvitationsTitle;

  /// No description provided for @activeInvitationsSection.
  ///
  /// In en, this message translates to:
  /// **'Active Invitations'**
  String get activeInvitationsSection;

  /// No description provided for @expiredInvitationsSection.
  ///
  /// In en, this message translates to:
  /// **'Expired Invitations'**
  String get expiredInvitationsSection;

  /// No description provided for @noActiveInvitations.
  ///
  /// In en, this message translates to:
  /// **'No active invitations'**
  String get noActiveInvitations;

  /// No description provided for @invitationCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get invitationCode;

  /// No description provided for @invitationRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get invitationRole;

  /// No description provided for @invitationCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get invitationCreator;

  /// No description provided for @invitationExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get invitationExpires;

  /// No description provided for @invitationUses.
  ///
  /// In en, this message translates to:
  /// **'Uses'**
  String get invitationUses;

  /// No description provided for @revokeInvitationAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeInvitationAction;

  /// No description provided for @deleteInvitationAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteInvitationAction;

  /// No description provided for @copyInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyInvitationCode;

  /// No description provided for @invitationCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get invitationCodeCopied;

  /// No description provided for @revokeInvitationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke this invitation?'**
  String get revokeInvitationConfirm;

  /// No description provided for @deleteInvitationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this invitation?'**
  String get deleteInvitationConfirm;

  /// No description provided for @invitationRevokedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation revoked'**
  String get invitationRevokedSuccess;

  /// No description provided for @invitationDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation deleted'**
  String get invitationDeletedSuccess;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @revoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get revoked;

  /// No description provided for @activationCodeValidated.
  ///
  /// In en, this message translates to:
  /// **'Activation code validated'**
  String get activationCodeValidated;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'You will join this organization'**
  String get invitationAccepted;

  /// No description provided for @invalidInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid invitation code'**
  String get invalidInvitationCode;

  /// No description provided for @createAndManageInvitations.
  ///
  /// In en, this message translates to:
  /// **'Create and manage invitation codes'**
  String get createAndManageInvitations;

  /// No description provided for @createInvitationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a code for new members to join'**
  String get createInvitationSubtitle;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @selectClientRequired.
  ///
  /// In en, this message translates to:
  /// **'You must select a client for this role'**
  String get selectClientRequired;

  /// No description provided for @associatedClient.
  ///
  /// In en, this message translates to:
  /// **'Associated client'**
  String get associatedClient;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @joiningOrganization.
  ///
  /// In en, this message translates to:
  /// **'You\'re joining'**
  String get joiningOrganization;

  /// No description provided for @asRole.
  ///
  /// In en, this message translates to:
  /// **'As'**
  String get asRole;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeYourProfile;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get passwordMinLength;

  /// No description provided for @createWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Create with Google'**
  String get createWithGoogle;

  /// No description provided for @createWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Create with Email'**
  String get createWithEmail;

  /// No description provided for @registrationError.
  ///
  /// In en, this message translates to:
  /// **'Error creating account'**
  String get registrationError;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @accountAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Account already exists'**
  String get accountAlreadyExists;

  /// No description provided for @accountExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get accountExistsMessage;

  /// No description provided for @signInAndJoin.
  ///
  /// In en, this message translates to:
  /// **'Sign in and join'**
  String get signInAndJoin;

  /// No description provided for @useGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Gmail accounts must use Google authentication'**
  String get useGoogleSignIn;

  /// No description provided for @messageAnsweringTo.
  ///
  /// In en, this message translates to:
  /// **'Respondiendo a'**
  String get messageAnsweringTo;

  /// No description provided for @searchMessagesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write to search message content, usernames or mentions'**
  String get searchMessagesPlaceholder;

  /// No description provided for @mondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// No description provided for @saturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// No description provided for @sundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Anwer'**
  String get answer;

  /// No description provided for @writeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeAMessage;

  /// No description provided for @internalMessageDescription.
  ///
  /// In en, this message translates to:
  /// **'Internal message (only team)'**
  String get internalMessageDescription;

  /// No description provided for @messageReactWith.
  ///
  /// In en, this message translates to:
  /// **'React with'**
  String get messageReactWith;

  /// No description provided for @originalMessage.
  ///
  /// In en, this message translates to:
  /// **'Original message'**
  String get originalMessage;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get edited;

  /// No description provided for @internal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get internal;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @answerPlural.
  ///
  /// In en, this message translates to:
  /// **'Answers'**
  String get answerPlural;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @batchChat.
  ///
  /// In en, this message translates to:
  /// **'Batch chat'**
  String get batchChat;

  /// No description provided for @projectChat.
  ///
  /// In en, this message translates to:
  /// **'Project chat'**
  String get projectChat;

  /// No description provided for @productChat.
  ///
  /// In en, this message translates to:
  /// **'Product chat'**
  String get productChat;
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
