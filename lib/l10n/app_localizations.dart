import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @applyCategoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mobiles, Smart TVs'**
  String get applyCategoryPlaceholder;

  /// No description provided for @authSplashOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline · your data is on this phone'**
  String get authSplashOffline;

  /// No description provided for @authSplashWaiting.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 change waiting to sync} other{{n} changes waiting to sync}}'**
  String authSplashWaiting(int n);

  /// No description provided for @authSplashLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {when}'**
  String authSplashLastSynced(String when);

  /// No description provided for @authSplashToday.
  ///
  /// In en, this message translates to:
  /// **'today, {time}'**
  String authSplashToday(String time);

  /// No description provided for @authSplashDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Offline time is up} =1{Offline for 1 more day} other{Offline for {n} more days}}'**
  String authSplashDaysLeft(int n);

  /// No description provided for @authPinOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Work offline'**
  String get authPinOfflineTitle;

  /// No description provided for @authPinOfflineSub.
  ///
  /// In en, this message translates to:
  /// **'Keep 30 days of your brand on this phone'**
  String get authPinOfflineSub;

  /// No description provided for @authPinOfflineOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get authPinOfflineOn;

  /// No description provided for @authOutletAllSub.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Combined figures for 1 outlet} other{Combined figures for all {count} outlets}}'**
  String authOutletAllSub(int count);

  /// No description provided for @authOutletServes.
  ///
  /// In en, this message translates to:
  /// **'{city} · serves {cities}'**
  String authOutletServes(String city, String cities);

  /// No description provided for @authOutletServesOnly.
  ///
  /// In en, this message translates to:
  /// **'Serves {cities}'**
  String authOutletServesOnly(String cities);

  /// No description provided for @authOutletPausedByYou.
  ///
  /// In en, this message translates to:
  /// **'Paused by you'**
  String get authOutletPausedByYou;

  /// No description provided for @authOutletPausedByOwner.
  ///
  /// In en, this message translates to:
  /// **'Paused by your brand owner'**
  String get authOutletPausedByOwner;

  /// No description provided for @authOutletKeepAll.
  ///
  /// In en, this message translates to:
  /// **'Keep all open outlets on this phone for offline work'**
  String get authOutletKeepAll;

  /// No description provided for @authOutletKeepOne.
  ///
  /// In en, this message translates to:
  /// **'Keep {name} on this phone for offline work'**
  String authOutletKeepOne(String name);

  /// No description provided for @authReadyOnlineWifi.
  ///
  /// In en, this message translates to:
  /// **'Online · Wi-Fi'**
  String get authReadyOnlineWifi;

  /// No description provided for @authReadySecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'About {n} seconds left'**
  String authReadySecondsLeft(int n);

  /// No description provided for @authReadyMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{About a minute left} other{About {n} minutes left}}'**
  String authReadyMinutesLeft(int n);

  /// No description provided for @homeNoticedTitle.
  ///
  /// In en, this message translates to:
  /// **'Atom noticed'**
  String get homeNoticedTitle;

  /// No description provided for @homeNoticedMorning.
  ///
  /// In en, this message translates to:
  /// **'From your data this morning'**
  String get homeNoticedMorning;

  /// No description provided for @homeNoticedAfternoon.
  ///
  /// In en, this message translates to:
  /// **'From your data this afternoon'**
  String get homeNoticedAfternoon;

  /// No description provided for @homeNoticedEvening.
  ///
  /// In en, this message translates to:
  /// **'From your data this evening'**
  String get homeNoticedEvening;

  /// No description provided for @homeNoticedSeeStock.
  ///
  /// In en, this message translates to:
  /// **'See stock'**
  String get homeNoticedSeeStock;

  /// No description provided for @homeNoticedOpenOutlet.
  ///
  /// In en, this message translates to:
  /// **'Open outlet'**
  String get homeNoticedOpenOutlet;

  /// No description provided for @homeNoticedFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow up'**
  String get homeNoticedFollowUp;

  /// No description provided for @statesKeptOnPhone.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 change is kept on this phone. It is sent as soon as you sign in again.} other{{n} changes are kept on this phone. They are sent as soon as you sign in again.}}'**
  String statesKeptOnPhone(int n);

  /// No description provided for @statesKeptOnPhoneBold.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 change is kept on this phone.} other{{n} changes are kept on this phone.}}'**
  String statesKeptOnPhoneBold(int n);

  /// No description provided for @statesPlaceSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get statesPlaceSearch;

  /// No description provided for @statesPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'the order'**
  String get statesPlaceOrder;

  /// No description provided for @statesPlaceAtompay.
  ///
  /// In en, this message translates to:
  /// **'the AtomPay order'**
  String get statesPlaceAtompay;

  /// No description provided for @statesPlaceDeal.
  ///
  /// In en, this message translates to:
  /// **'the bulk deal'**
  String get statesPlaceDeal;

  /// No description provided for @statesPlaceBulkRequest.
  ///
  /// In en, this message translates to:
  /// **'the bulk request'**
  String get statesPlaceBulkRequest;

  /// No description provided for @statesPlaceProduct.
  ///
  /// In en, this message translates to:
  /// **'the product'**
  String get statesPlaceProduct;

  /// No description provided for @statesPlaceBrandPage.
  ///
  /// In en, this message translates to:
  /// **'Brand page'**
  String get statesPlaceBrandPage;

  /// No description provided for @statesPlaceStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get statesPlaceStock;

  /// No description provided for @statesPlaceTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get statesPlaceTeam;

  /// No description provided for @statesPlaceOutlets.
  ///
  /// In en, this message translates to:
  /// **'Outlets'**
  String get statesPlaceOutlets;

  /// No description provided for @statesPlacePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan & billing'**
  String get statesPlacePlan;

  /// No description provided for @statesPlaceReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get statesPlaceReports;

  /// No description provided for @statesPlaceAskAtom.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom'**
  String get statesPlaceAskAtom;

  /// No description provided for @statesPlaceSync.
  ///
  /// In en, this message translates to:
  /// **'Sync centre'**
  String get statesPlaceSync;

  /// No description provided for @statesPlaceHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get statesPlaceHelp;

  /// No description provided for @statesPlaceSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get statesPlaceSettings;

  /// No description provided for @statesPlaceNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get statesPlaceNotifications;

  /// No description provided for @statesPlaceMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get statesPlaceMenu;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get commonChoose;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWrong;

  /// No description provided for @selectSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get selectSearchHint;

  /// No description provided for @selectClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get selectClearSearch;

  /// No description provided for @selectNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match for \"{query}\"'**
  String selectNoMatch(String query);

  /// No description provided for @selectNoMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or try part of the name.'**
  String get selectNoMatchHint;

  /// No description provided for @selectOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Offline: searching the list saved on this phone.'**
  String get selectOfflineNote;

  /// No description provided for @selectDoneChosen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Done} other{Done · {count} chosen}}'**
  String selectDoneChosen(int count);

  /// No description provided for @selectCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the list'**
  String get selectCouldNotLoad;

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get leaveTitle;

  /// No description provided for @leaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes on this screen will be lost.'**
  String get leaveBody;

  /// No description provided for @leaveDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get leaveDiscard;

  /// No description provided for @leaveKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get leaveKeepEditing;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner'**
  String get appName;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @keypadDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get keypadDelete;

  /// No description provided for @keypadFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get keypadFingerprint;

  /// No description provided for @pinDotsLabel.
  ///
  /// In en, this message translates to:
  /// **'{filled} of {length} digits entered'**
  String pinDotsLabel(int filled, int length);

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get tabOrders;

  /// No description provided for @backAgainToClose.
  ///
  /// In en, this message translates to:
  /// **'Press back again to close'**
  String get backAgainToClose;

  /// No description provided for @welcomeLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get welcomeLanguage;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @welcomeCollectedToday.
  ///
  /// In en, this message translates to:
  /// **'Cash sales today'**
  String get welcomeCollectedToday;

  /// No description provided for @welcomePaidCount.
  ///
  /// In en, this message translates to:
  /// **'7 orders'**
  String get welcomePaidCount;

  /// No description provided for @welcomeDueToday.
  ///
  /// In en, this message translates to:
  /// **'To confirm'**
  String get welcomeDueToday;

  /// No description provided for @welcomeDueCustomers.
  ///
  /// In en, this message translates to:
  /// **'4 new orders'**
  String get welcomeDueCustomers;

  /// No description provided for @welcomeNewLeads.
  ///
  /// In en, this message translates to:
  /// **'New bulk requests'**
  String get welcomeNewLeads;

  /// No description provided for @welcomeLeadsInAreas.
  ///
  /// In en, this message translates to:
  /// **'3 waiting'**
  String get welcomeLeadsInAreas;

  /// No description provided for @welcomeFromWebsite.
  ///
  /// In en, this message translates to:
  /// **'From Atomshop sellers'**
  String get welcomeFromWebsite;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your brand on Atomshop, in your pocket'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Orders, AtomPay, bulk deals, products and stock, online or with no signal at all.'**
  String get welcomeBody;

  /// No description provided for @welcomeFeaturePaymentsBold.
  ///
  /// In en, this message translates to:
  /// **'Confirm and deliver orders'**
  String get welcomeFeaturePaymentsBold;

  /// No description provided for @welcomeFeaturePaymentsRest.
  ///
  /// In en, this message translates to:
  /// **' with a proof photo'**
  String get welcomeFeaturePaymentsRest;

  /// No description provided for @welcomeFeatureOfflineBold.
  ///
  /// In en, this message translates to:
  /// **'Reply to bulk requests'**
  String get welcomeFeatureOfflineBold;

  /// No description provided for @welcomeFeatureOfflineRest.
  ///
  /// In en, this message translates to:
  /// **' with quotes on WhatsApp'**
  String get welcomeFeatureOfflineRest;

  /// No description provided for @welcomeFeatureTeamBold.
  ///
  /// In en, this message translates to:
  /// **'Stock, team and outlets'**
  String get welcomeFeatureTeamBold;

  /// No description provided for @welcomeFeatureTeamRest.
  ///
  /// In en, this message translates to:
  /// **', even offline'**
  String get welcomeFeatureTeamRest;

  /// No description provided for @welcomeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get welcomeSignIn;

  /// No description provided for @welcomeBecomeSeller.
  ///
  /// In en, this message translates to:
  /// **'Apply to list your brand'**
  String get welcomeBecomeSeller;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Brand Partner'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the same account as your Brand Partner Portal.'**
  String get signInSubtitle;

  /// No description provided for @signInOwner.
  ///
  /// In en, this message translates to:
  /// **'Brand owner'**
  String get signInOwner;

  /// No description provided for @signInAgent.
  ///
  /// In en, this message translates to:
  /// **'Team member'**
  String get signInAgent;

  /// No description provided for @signInEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signInEmail;

  /// No description provided for @signInMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get signInMobile;

  /// No description provided for @signInMobileHint.
  ///
  /// In en, this message translates to:
  /// **'The number your brand owner added you with. Owners use their email.'**
  String get signInMobileHint;

  /// No description provided for @signInPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signInPassword;

  /// No description provided for @signInForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get signInForgot;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @signInSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signInSigningIn;

  /// No description provided for @signInShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get signInShowPassword;

  /// No description provided for @signInHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get signInHidePassword;

  /// No description provided for @signInTrouble.
  ///
  /// In en, this message translates to:
  /// **'Trouble signing in?'**
  String get signInTrouble;

  /// No description provided for @signInWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Atomshop'**
  String get signInWhatsApp;

  /// No description provided for @signInEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your email, like name@example.com'**
  String get signInEmailInvalid;

  /// No description provided for @signInMobileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an 11-digit mobile number starting with 03'**
  String get signInMobileInvalid;

  /// No description provided for @signInPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get signInPasswordEmpty;

  /// No description provided for @signInOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet. Turn on mobile data or Wi-Fi and try again.'**
  String get signInOffline;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Try again in a moment.'**
  String get signInFailed;

  /// No description provided for @agentPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your own password'**
  String get agentPasswordTitle;

  /// No description provided for @agentPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Your brand owner gave you a temporary one. Pick a password only you know: you will need it on a new phone.'**
  String get agentPasswordBody;

  /// No description provided for @agentPasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get agentPasswordNew;

  /// No description provided for @agentPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get agentPasswordConfirm;

  /// No description provided for @agentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'8 or more characters'**
  String get agentPasswordHint;

  /// No description provided for @agentPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use 8 or more characters'**
  String get agentPasswordTooShort;

  /// No description provided for @agentPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords are not the same.'**
  String get agentPasswordMismatch;

  /// No description provided for @agentPasswordSave.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get agentPasswordSave;

  /// No description provided for @signedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again'**
  String get signedOutTitle;

  /// No description provided for @signedOutBody.
  ///
  /// In en, this message translates to:
  /// **'For your safety you were signed out. Your brand\'s data is safe.'**
  String get signedOutBody;

  /// No description provided for @signedOutChosenTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed out'**
  String get signedOutChosenTitle;

  /// No description provided for @signedOutChosenBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to carry on where you left off.'**
  String get signedOutChosenBody;

  /// No description provided for @signedOutReturn.
  ///
  /// In en, this message translates to:
  /// **'After you sign in, you go back to where you were.'**
  String get signedOutReturn;

  /// No description provided for @signedOutSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get signedOutSignIn;

  /// No description provided for @signedOutForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get signedOutForgot;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Atomshop is being updated'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get maintenanceData;

  /// No description provided for @maintenanceDataSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe with Atomshop'**
  String get maintenanceDataSafe;

  /// No description provided for @maintenanceCustomers.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get maintenanceCustomers;

  /// No description provided for @maintenanceCustomersOk.
  ///
  /// In en, this message translates to:
  /// **'Not affected'**
  String get maintenanceCustomersOk;

  /// No description provided for @maintenanceUsing.
  ///
  /// In en, this message translates to:
  /// **'Using the app'**
  String get maintenanceUsing;

  /// No description provided for @maintenanceUsingWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get maintenanceUsingWait;

  /// No description provided for @removedTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a package to carry on'**
  String get removedTitle;

  /// No description provided for @removedBody.
  ///
  /// In en, this message translates to:
  /// **'Your package on {business} has ended. Everything you saved is kept safe: products, orders, bulk deals and stock.'**
  String removedBody(String business);

  /// No description provided for @removedOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get removedOpenNow;

  /// No description provided for @removedOpenNowValue.
  ///
  /// In en, this message translates to:
  /// **'Plan & billing, your profile'**
  String get removedOpenNowValue;

  /// No description provided for @removedAfterPaying.
  ///
  /// In en, this message translates to:
  /// **'After paying'**
  String get removedAfterPaying;

  /// No description provided for @removedAfterPayingValue.
  ///
  /// In en, this message translates to:
  /// **'Everything, as before'**
  String get removedAfterPayingValue;

  /// No description provided for @removedSeePackages.
  ///
  /// In en, this message translates to:
  /// **'See packages & prices'**
  String get removedSeePackages;

  /// No description provided for @removedTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk to Atomshop'**
  String get removedTalk;

  /// No description provided for @removedAgentNote.
  ///
  /// In en, this message translates to:
  /// **'Only the brand owner can choose a package. Ask them to open Plan & billing.'**
  String get removedAgentNote;

  /// No description provided for @noPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'No active package'**
  String get noPlanTitle;

  /// No description provided for @noPlanBody.
  ///
  /// In en, this message translates to:
  /// **'This account has no package yet. Choose one to start using Brand Partner.'**
  String get noPlanBody;

  /// No description provided for @notInRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your role doesn\'t include this'**
  String get notInRoleTitle;

  /// No description provided for @statesAskWhyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why doesn\'t my role include this?'**
  String get statesAskWhyQuestion;

  /// No description provided for @statesCanEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything: you own the brand'**
  String get statesCanEverything;

  /// No description provided for @statesCanPayments.
  ///
  /// In en, this message translates to:
  /// **'payments'**
  String get statesCanPayments;

  /// No description provided for @statesCanAtompay.
  ///
  /// In en, this message translates to:
  /// **'AtomPay'**
  String get statesCanAtompay;

  /// No description provided for @statesCanTeam.
  ///
  /// In en, this message translates to:
  /// **'team'**
  String get statesCanTeam;

  /// No description provided for @statesCanSee.
  ///
  /// In en, this message translates to:
  /// **'see {list}'**
  String statesCanSee(String list);

  /// No description provided for @notInRoleBody.
  ///
  /// In en, this message translates to:
  /// **'The brand owner decides what each person can do. Ask them to change your role if you need it.'**
  String get notInRoleBody;

  /// No description provided for @notInRoleYourRole.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get notInRoleYourRole;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This page doesn\'t exist, or it isn\'t part of your brand.'**
  String get notFoundBody;

  /// No description provided for @notFoundHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get notFoundHome;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet'**
  String get noInternetTitle;

  /// No description provided for @noInternetBody.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner needs a connection to show and save your work. Turn on mobile data or Wi-Fi.'**
  String get noInternetBody;

  /// No description provided for @noInternetAuto.
  ///
  /// In en, this message translates to:
  /// **'It tries again by itself when the signal comes back.'**
  String get noInternetAuto;

  /// No description provided for @restrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Atomshop has paused changes on your account'**
  String get restrictedTitle;

  /// No description provided for @restrictedPayments.
  ///
  /// In en, this message translates to:
  /// **'Recording payments and deliveries'**
  String get restrictedPayments;

  /// No description provided for @restrictedWorks.
  ///
  /// In en, this message translates to:
  /// **'Works'**
  String get restrictedWorks;

  /// No description provided for @restrictedCloseDeals.
  ///
  /// In en, this message translates to:
  /// **'AtomPay hand-overs, Ask Atom'**
  String get restrictedCloseDeals;

  /// No description provided for @restrictedNewThings.
  ///
  /// In en, this message translates to:
  /// **'Products, quotes, stock'**
  String get restrictedNewThings;

  /// No description provided for @restrictedPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get restrictedPaused;

  /// No description provided for @restrictedWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Message Atomshop on WhatsApp'**
  String get restrictedWhatsApp;

  /// No description provided for @restrictedCall.
  ///
  /// In en, this message translates to:
  /// **'Call {phone}'**
  String restrictedCall(String phone);

  /// No description provided for @restrictedNote.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t about a bill, so there is nothing to pay. Orders already placed carry on.'**
  String get restrictedNote;

  /// No description provided for @bannerPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get bannerPay;

  /// No description provided for @menuOwner.
  ///
  /// In en, this message translates to:
  /// **'Brand owner'**
  String get menuOwner;

  /// No description provided for @menuSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get menuSignOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Brand Partner?'**
  String get signOutConfirmTitle;

  /// Sign out, when this person has unsent offline work.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change you made hasn\'t reached Atomshop yet.} other{{count} changes you made haven\'t reached Atomshop yet.}} It stays on this phone and goes up when you sign in here again. Nobody else who signs in can send it.'**
  String signOutUnsentBody(int count);

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need your password to sign in on this phone again. Your brand\'s data stays safe with Atomshop.'**
  String get signOutConfirmBody;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak password'**
  String get passwordWeak;

  /// No description provided for @passwordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair password'**
  String get passwordFair;

  /// No description provided for @passwordGood.
  ///
  /// In en, this message translates to:
  /// **'Good password'**
  String get passwordGood;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong password'**
  String get passwordStrong;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotTitle;

  /// No description provided for @forgotBody.
  ///
  /// In en, this message translates to:
  /// **'We will send a 6-digit code to the WhatsApp number or email on your account.'**
  String get forgotBody;

  /// No description provided for @forgotLogin.
  ///
  /// In en, this message translates to:
  /// **'Email or mobile number'**
  String get forgotLogin;

  /// No description provided for @forgotLoginInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your email, or a mobile number starting with 03'**
  String get forgotLoginInvalid;

  /// No description provided for @forgotSendBy.
  ///
  /// In en, this message translates to:
  /// **'Send the code by'**
  String get forgotSendBy;

  /// No description provided for @forgotWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get forgotWhatsApp;

  /// No description provided for @forgotWhatsAppSub.
  ///
  /// In en, this message translates to:
  /// **'Fastest · to the number on your account'**
  String get forgotWhatsAppSub;

  /// No description provided for @forgotEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get forgotEmail;

  /// No description provided for @forgotEmailSub.
  ///
  /// In en, this message translates to:
  /// **'Check spam if it does not arrive'**
  String get forgotEmailSub;

  /// No description provided for @forgotSend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotSend;

  /// No description provided for @forgotNote.
  ///
  /// In en, this message translates to:
  /// **'Needs internet. Team members can also ask their brand owner to reset it.'**
  String get forgotNote;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get codeTitle;

  /// No description provided for @codeSentWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'We sent it on WhatsApp to the number on your account.'**
  String get codeSentWhatsApp;

  /// No description provided for @codeSentEmail.
  ///
  /// In en, this message translates to:
  /// **'We sent it by email to the address on your account.'**
  String get codeSentEmail;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @codeDidntGet.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it?'**
  String get codeDidntGet;

  /// No description provided for @codeResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String codeResendIn(String time);

  /// No description provided for @codeResend.
  ///
  /// In en, this message translates to:
  /// **'Send it again'**
  String get codeResend;

  /// No description provided for @codeNote.
  ///
  /// In en, this message translates to:
  /// **'The code works for {minutes} minutes. Atomshop will never ask you for it on a call.'**
  String codeNote(int minutes);

  /// No description provided for @codeVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get codeVerify;

  /// No description provided for @codeByEmail.
  ///
  /// In en, this message translates to:
  /// **'Send by email instead'**
  String get codeByEmail;

  /// No description provided for @codeByWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Send on WhatsApp instead'**
  String get codeByWhatsApp;

  /// No description provided for @codeIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Type all 6 digits'**
  String get codeIncomplete;

  /// No description provided for @codeSentAgain.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get codeSentAgain;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordFor.
  ///
  /// In en, this message translates to:
  /// **'For {login}. You will be signed out on every other phone.'**
  String newPasswordFor(String login);

  /// No description provided for @newPasswordSave.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get newPasswordSave;

  /// No description provided for @passwordDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordDoneTitle;

  /// No description provided for @passwordDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your new password.'**
  String get passwordDoneBody;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & conditions'**
  String get termsTitle;

  /// No description provided for @termsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String termsVersion(String version);

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'The agreement between your brand and Atomshop.pk for using Brand Partner.'**
  String get termsBody;

  /// No description provided for @termsRead.
  ///
  /// In en, this message translates to:
  /// **'Read the terms'**
  String get termsRead;

  /// No description provided for @termsNotPublished.
  ///
  /// In en, this message translates to:
  /// **'The full text isn\'t on the app yet. Ask Atomshop for it before you accept.'**
  String get termsNotPublished;

  /// No description provided for @termsAskAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Ask Atomshop on WhatsApp'**
  String get termsAskAtomshop;

  /// No description provided for @termsAcceptBox.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the terms for {business}'**
  String termsAcceptBox(String business);

  /// No description provided for @termsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get termsAccept;

  /// No description provided for @termsTickFirst.
  ///
  /// In en, this message translates to:
  /// **'Tick the box to continue'**
  String get termsTickFirst;

  /// No description provided for @termsChanged.
  ///
  /// In en, this message translates to:
  /// **'These terms have changed. They are shown again below.'**
  String get termsChanged;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Know the moment an order comes in'**
  String get notifTitle;

  /// No description provided for @notifWhyPayments.
  ///
  /// In en, this message translates to:
  /// **'New orders to confirm, and AtomPay units to hand over'**
  String get notifWhyPayments;

  /// No description provided for @notifWhyLeads.
  ///
  /// In en, this message translates to:
  /// **'New bulk requests, so you reply before other brands'**
  String get notifWhyLeads;

  /// No description provided for @notifWhyAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Product review decisions, messages and bills from Atomshop'**
  String get notifWhyAtomshop;

  /// No description provided for @notifAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notifAllow;

  /// No description provided for @notifNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notifNotNow;

  /// No description provided for @notifFootnote.
  ///
  /// In en, this message translates to:
  /// **'Shown once after sign-in, before the phone asks. Change it any time in Settings.'**
  String get notifFootnote;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateTwoDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'2 days ago'**
  String get dateTwoDaysAgo;

  /// No description provided for @datePreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get datePreviousMonth;

  /// No description provided for @dateNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get dateNextMonth;

  /// No description provided for @dateUse.
  ///
  /// In en, this message translates to:
  /// **'Use {day}'**
  String dateUse(String day);

  /// No description provided for @payOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet, so it isn\'t saved yet. Everything you typed is still here; save it when you are back online.'**
  String get payOffline;

  /// No description provided for @customerMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get customerMobile;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customerName;

  /// No description provided for @customerOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get customerOptional;

  /// No description provided for @customerPhoneMissing.
  ///
  /// In en, this message translates to:
  /// **'Type an 11-digit mobile, 03…'**
  String get customerPhoneMissing;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @acctCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the account'**
  String get acctCloseTitle;

  /// No description provided for @acctCloseSub.
  ///
  /// In en, this message translates to:
  /// **'Ask Atomshop to close {shop}'**
  String acctCloseSub(String shop);

  /// No description provided for @acctCloseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in for you and your team'**
  String get acctCloseSignIn;

  /// No description provided for @acctCloseShopPage.
  ///
  /// In en, this message translates to:
  /// **'Brand page and new orders'**
  String get acctCloseShopPage;

  /// No description provided for @acctCloseRecords.
  ///
  /// In en, this message translates to:
  /// **'Orders, deals, payments'**
  String get acctCloseRecords;

  /// No description provided for @acctCloseBills.
  ///
  /// In en, this message translates to:
  /// **'Unpaid bills'**
  String get acctCloseBills;

  /// No description provided for @acctCloseStops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get acctCloseStops;

  /// No description provided for @acctCloseKept.
  ///
  /// In en, this message translates to:
  /// **'Kept by Atomshop'**
  String get acctCloseKept;

  /// No description provided for @acctCloseStillDue.
  ///
  /// In en, this message translates to:
  /// **'Still due'**
  String get acctCloseStillDue;

  /// No description provided for @acctCloseWhyKept.
  ///
  /// In en, this message translates to:
  /// **'Records are kept because your orders, deals and the law need them. Atomshop calls you before anything is closed. Export your data first if you want a copy.'**
  String get acctCloseWhyKept;

  /// No description provided for @acctCloseExportFirst.
  ///
  /// In en, this message translates to:
  /// **'Export my data first'**
  String get acctCloseExportFirst;

  /// No description provided for @acctCloseReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you leaving?'**
  String get acctCloseReason;

  /// No description provided for @acctCloseReasonHint.
  ///
  /// In en, this message translates to:
  /// **'It helps us improve'**
  String get acctCloseReasonHint;

  /// No description provided for @acctClosePassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get acctClosePassword;

  /// No description provided for @acctCloseTypePassword.
  ///
  /// In en, this message translates to:
  /// **'Type your password'**
  String get acctCloseTypePassword;

  /// No description provided for @acctCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Ask Atomshop to close the account'**
  String get acctCloseButton;

  /// No description provided for @acctCloseSent.
  ///
  /// In en, this message translates to:
  /// **'Your request went to Atomshop. They will call you before anything is closed.'**
  String get acctCloseSent;

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get dataTitle;

  /// No description provided for @dataSub.
  ///
  /// In en, this message translates to:
  /// **'What is kept, where, and for how long'**
  String get dataSub;

  /// No description provided for @dataKept.
  ///
  /// In en, this message translates to:
  /// **'What Brand Partner keeps'**
  String get dataKept;

  /// No description provided for @dataShop.
  ///
  /// In en, this message translates to:
  /// **'Your brand'**
  String get dataShop;

  /// No description provided for @dataShopBody.
  ///
  /// In en, this message translates to:
  /// **'Products, orders, payments, bulk deals and stock, on Atomshop\'s servers.'**
  String get dataShopBody;

  /// No description provided for @dataPhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get dataPhone;

  /// No description provided for @dataPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Only what is on screen; nothing stays after you sign out.'**
  String get dataPhoneBody;

  /// No description provided for @dataPhoneOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'An encrypted copy for offline work, deleted when you sign out or the phone is signed out.'**
  String get dataPhoneOfflineBody;

  /// No description provided for @dataCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera and photos'**
  String get dataCamera;

  /// No description provided for @dataUsage.
  ///
  /// In en, this message translates to:
  /// **'App usage'**
  String get dataUsage;

  /// No description provided for @dataUsageBody.
  ///
  /// In en, this message translates to:
  /// **'Crash reports and which screens are used, without buyer details.'**
  String get dataUsageBody;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get dataExport;

  /// No description provided for @dataExportButton.
  ///
  /// In en, this message translates to:
  /// **'Request the export'**
  String get dataExportButton;

  /// No description provided for @exportStarted.
  ///
  /// In en, this message translates to:
  /// **'Atomshop is making your file. A download link will reach {email} shortly.'**
  String exportStarted(String email);

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices & sessions'**
  String get devicesTitle;

  /// No description provided for @devicesSub.
  ///
  /// In en, this message translates to:
  /// **'Where you are signed in'**
  String get devicesSub;

  /// No description provided for @devicesSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in now'**
  String get devicesSignedIn;

  /// No description provided for @devicesThisPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone · {name}'**
  String devicesThisPhone(String name);

  /// No description provided for @devicesThisOne.
  ///
  /// In en, this message translates to:
  /// **'This one'**
  String get devicesThisOne;

  /// No description provided for @devicesNow.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner app · now'**
  String get devicesNow;

  /// No description provided for @devicesSignOutOthers.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices'**
  String get devicesSignOutOthers;

  /// No description provided for @devicesSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get devicesSignedOut;

  /// No description provided for @devicesNone.
  ///
  /// In en, this message translates to:
  /// **'Not signed in anywhere.'**
  String get devicesNone;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackSub.
  ///
  /// In en, this message translates to:
  /// **'An idea, a problem, or praise'**
  String get feedbackSub;

  /// No description provided for @feedbackIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get feedbackIdea;

  /// No description provided for @feedbackProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get feedbackProblem;

  /// No description provided for @feedbackPraise.
  ///
  /// In en, this message translates to:
  /// **'Praise'**
  String get feedbackPraise;

  /// No description provided for @feedbackIdeaLabel.
  ///
  /// In en, this message translates to:
  /// **'Your idea'**
  String get feedbackIdeaLabel;

  /// No description provided for @feedbackIdeaHint.
  ///
  /// In en, this message translates to:
  /// **'What would make Brand Partner better for your brand?'**
  String get feedbackIdeaHint;

  /// No description provided for @feedbackProblemLabel.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get feedbackProblemLabel;

  /// No description provided for @feedbackProblemHint.
  ///
  /// In en, this message translates to:
  /// **'What were you doing, and what happened?'**
  String get feedbackProblemHint;

  /// No description provided for @feedbackPraiseLabel.
  ///
  /// In en, this message translates to:
  /// **'What do you like?'**
  String get feedbackPraiseLabel;

  /// No description provided for @feedbackPraiseHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what works well'**
  String get feedbackPraiseHint;

  /// No description provided for @feedbackScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Add a screenshot'**
  String get feedbackScreenshot;

  /// No description provided for @feedbackScreenshotAdded.
  ///
  /// In en, this message translates to:
  /// **'Screenshot added · change'**
  String get feedbackScreenshotAdded;

  /// No description provided for @feedbackWithDevice.
  ///
  /// In en, this message translates to:
  /// **'Include phone model and app version'**
  String get feedbackWithDevice;

  /// No description provided for @feedbackWriteFirst.
  ///
  /// In en, this message translates to:
  /// **'Write a few words first'**
  String get feedbackWriteFirst;

  /// No description provided for @feedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Send to Atomshop'**
  String get feedbackSend;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your feedback went to Atomshop.'**
  String get feedbackSent;

  /// No description provided for @languageApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get languageApp;

  /// No description provided for @languageSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get languageSoon;

  /// No description provided for @menuWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get menuWork;

  /// No description provided for @menuAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get menuAccount;

  /// No description provided for @menuVersion.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner {version} · a partner app of Atomshop.pk'**
  String menuVersion(String version);

  /// No description provided for @passwordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get passwordTitle;

  /// No description provided for @passwordSub.
  ///
  /// In en, this message translates to:
  /// **'Signs out other devices'**
  String get passwordSub;

  /// No description provided for @passwordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get passwordCurrent;

  /// No description provided for @passwordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get passwordNew;

  /// No description provided for @passwordAgain.
  ///
  /// In en, this message translates to:
  /// **'New password again'**
  String get passwordAgain;

  /// No description provided for @passwordTypeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Type your current password'**
  String get passwordTypeCurrent;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Make the new password stronger'**
  String get passwordTooWeak;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords don\'t match'**
  String get passwordMismatch;

  /// No description provided for @passwordSave.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get passwordSave;

  /// No description provided for @passwordSignOutOthers.
  ///
  /// In en, this message translates to:
  /// **'Sign out my other phones'**
  String get passwordSignOutOthers;

  /// No description provided for @passwordSignOutOthersSub.
  ///
  /// In en, this message translates to:
  /// **'Anyone signed in elsewhere with the old password is signed out'**
  String get passwordSignOutOthersSub;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Letters and spaces only'**
  String get profileNameHint;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profilePhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved'**
  String get profilePhotoSaved;

  /// No description provided for @rateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Brand Partner'**
  String get rateTitle;

  /// No description provided for @rateSub.
  ///
  /// In en, this message translates to:
  /// **'On Google Play'**
  String get rateSub;

  /// No description provided for @rateQuestion.
  ///
  /// In en, this message translates to:
  /// **'How is Brand Partner for your brand?'**
  String get rateQuestion;

  /// No description provided for @rateStars.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String rateStars(int count);

  /// No description provided for @rateHigh.
  ///
  /// In en, this message translates to:
  /// **'Thank you! A rating on Google Play helps other brands find us.'**
  String get rateHigh;

  /// No description provided for @rateLow.
  ///
  /// In en, this message translates to:
  /// **'Sorry to hear that. Tell us what to fix; it goes straight to Atomshop.'**
  String get rateLow;

  /// No description provided for @rateOnPlay.
  ///
  /// In en, this message translates to:
  /// **'Rate on Google Play'**
  String get rateOnPlay;

  /// No description provided for @rateNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get rateNotNow;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsProfileCard.
  ///
  /// In en, this message translates to:
  /// **'{name}, your profile'**
  String settingsProfileCard(String name);

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Name, photo, mobile number'**
  String get settingsProfileSub;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacy;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get settingsHelp;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsSignOutGroup.
  ///
  /// In en, this message translates to:
  /// **'Sign out & account'**
  String get settingsSignOutGroup;

  /// No description provided for @settingsSignOutSub.
  ///
  /// In en, this message translates to:
  /// **'Of Brand Partner on this phone · asks first'**
  String get settingsSignOutSub;

  /// No description provided for @bannerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get bannerOpen;

  /// No description provided for @bannerLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get bannerLater;

  /// No description provided for @noticeAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get noticeAlwaysOn;

  /// No description provided for @noticeHow.
  ///
  /// In en, this message translates to:
  /// **'How they arrive'**
  String get noticeHow;

  /// No description provided for @noticeOpenFromList.
  ///
  /// In en, this message translates to:
  /// **'Open this message from Notifications.'**
  String get noticeOpenFromList;

  /// No description provided for @noticeSettingsFoot.
  ///
  /// In en, this message translates to:
  /// **'These are for you on this phone. The brand portal has its own bell; the morning message is in Settings › Daily summary.'**
  String get noticeSettingsFoot;

  /// No description provided for @notifMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning summary'**
  String get notifMorningTitle;

  /// No description provided for @notifMorningSub.
  ///
  /// In en, this message translates to:
  /// **'One message with today\'s work'**
  String get notifMorningSub;

  /// No description provided for @notifMorningAt.
  ///
  /// In en, this message translates to:
  /// **'8:30 am'**
  String get notifMorningAt;

  /// No description provided for @notifActFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow up'**
  String get notifActFollowUp;

  /// No description provided for @noticeSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'What you get, quiet hours'**
  String get noticeSettingsSub;

  /// No description provided for @noticeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get noticeSettingsTitle;

  /// No description provided for @noticesAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get noticesAccount;

  /// No description provided for @noticesAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get noticesAll;

  /// No description provided for @noticesEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get noticesEarlier;

  /// Button at the end of Notifications: the next 20, older ones.
  ///
  /// In en, this message translates to:
  /// **'Show older'**
  String get noticesShowOlder;

  /// No description provided for @noticesEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Go to orders'**
  String get noticesEmptyAction;

  /// No description provided for @notifEmptyHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get notifEmptyHome;

  /// No description provided for @noticesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New orders, bulk requests, AtomPay hand-overs and product reviews show here. Older ones are kept for 90 days.'**
  String get noticesEmptyBody;

  /// No description provided for @noticesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get noticesEmptyTitle;

  /// No description provided for @noticesFromAtomshop.
  ///
  /// In en, this message translates to:
  /// **'From Atomshop'**
  String get noticesFromAtomshop;

  /// No description provided for @noticesFromAtomshopNew.
  ///
  /// In en, this message translates to:
  /// **'From Atomshop · new'**
  String get noticesFromAtomshopNew;

  /// No description provided for @noticesOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get noticesOrders;

  /// No description provided for @noticesReadAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get noticesReadAll;

  /// No description provided for @notifActConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get notifActConfirm;

  /// No description provided for @notifActHandOver.
  ///
  /// In en, this message translates to:
  /// **'Hand over'**
  String get notifActHandOver;

  /// No description provided for @notifActSendQuote.
  ///
  /// In en, this message translates to:
  /// **'Send quote'**
  String get notifActSendQuote;

  /// No description provided for @notifActReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get notifActReply;

  /// No description provided for @notifActAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get notifActAnswer;

  /// No description provided for @notifActOpenDeal.
  ///
  /// In en, this message translates to:
  /// **'Open deal'**
  String get notifActOpenDeal;

  /// No description provided for @notifActStockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get notifActStockIn;

  /// No description provided for @notifActFix.
  ///
  /// In en, this message translates to:
  /// **'Fix and resend'**
  String get notifActFix;

  /// No description provided for @noticesStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get noticesStock;

  /// No description provided for @noticesTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get noticesTeam;

  /// No description provided for @noticesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get noticesTitle;

  /// No description provided for @noticesToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get noticesToday;

  /// No description provided for @noticesYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get noticesYesterday;

  /// No description provided for @quietFrom.
  ///
  /// In en, this message translates to:
  /// **'Quiet from'**
  String get quietFrom;

  /// No description provided for @quietTo.
  ///
  /// In en, this message translates to:
  /// **'Quiet until'**
  String get quietTo;

  /// No description provided for @quietTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietTitle;

  /// No description provided for @bioTitle.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint or face'**
  String get bioTitle;

  /// No description provided for @lockAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock the app after'**
  String get lockAfterTitle;

  /// No description provided for @lockAfterSub.
  ///
  /// In en, this message translates to:
  /// **'When it is in the background'**
  String get lockAfterSub;

  /// No description provided for @lockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get lockImmediately;

  /// No description provided for @lockAfterSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String lockAfterSeconds(int seconds);

  /// No description provided for @lockAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String lockAfterMinutes(int minutes);

  /// No description provided for @lockBioReason.
  ///
  /// In en, this message translates to:
  /// **'Open Brand Partner'**
  String get lockBioReason;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String lockTitle(String name);

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsTitle;

  /// No description provided for @permissionsSub.
  ///
  /// In en, this message translates to:
  /// **'What the app may use on this phone'**
  String get permissionsSub;

  /// No description provided for @permissionsBody.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner asks only when you first use a feature.'**
  String get permissionsBody;

  /// No description provided for @permissionsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionsNotifications;

  /// No description provided for @permissionsNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'New orders, bulk requests, AtomPay, product reviews'**
  String get permissionsNotificationsSub;

  /// No description provided for @permissionsTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get permissionsTurnOn;

  /// No description provided for @permissionsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get permissionsAllowed;

  /// No description provided for @permissionsCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionsCamera;

  /// No description provided for @permissionsPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get permissionsPhotos;

  /// No description provided for @permissionsPhotosSub.
  ///
  /// In en, this message translates to:
  /// **'Only the ones you pick'**
  String get permissionsPhotosSub;

  /// No description provided for @permissionsWhenUsed.
  ///
  /// In en, this message translates to:
  /// **'Asked when used'**
  String get permissionsWhenUsed;

  /// No description provided for @pinSet.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get pinSet;

  /// No description provided for @pinChange.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get pinChange;

  /// No description provided for @pinSub.
  ///
  /// In en, this message translates to:
  /// **'4 digits, for quick unlock'**
  String get pinSub;

  /// No description provided for @pinStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 2'**
  String pinStepOf(int step);

  /// No description provided for @pinCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit PIN'**
  String get pinCreateTitle;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Type your PIN again'**
  String get pinConfirmTitle;

  /// No description provided for @pinCreateBody.
  ///
  /// In en, this message translates to:
  /// **'You will use it to open the app, even offline. Avoid 1234 or your birth year.'**
  String get pinCreateBody;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs did not match. Start again.'**
  String get pinMismatch;

  /// No description provided for @pinDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You are all set'**
  String get pinDoneTitle;

  /// No description provided for @pinDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Next time, open Brand Partner with your PIN or fingerprint, with or without internet.'**
  String get pinDoneBody;

  /// No description provided for @pinSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now, set it later in Settings'**
  String get pinSkip;

  /// No description provided for @pinRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get pinRemove;

  /// No description provided for @pinRemoveSub.
  ///
  /// In en, this message translates to:
  /// **'This phone opens without a PIN or fingerprint'**
  String get pinRemoveSub;

  /// No description provided for @pinRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the PIN?'**
  String get pinRemoveTitle;

  /// No description provided for @pinRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner will open without asking for a PIN or fingerprint on this phone. Any sign-in saved behind the fingerprint is erased. You can set a PIN again any time.'**
  String get pinRemoveBody;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp reminders'**
  String get remindersTitle;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Account security'**
  String get securityTitle;

  /// No description provided for @securitySub.
  ///
  /// In en, this message translates to:
  /// **'Password, PIN, fingerprint, auto-lock'**
  String get securitySub;

  /// No description provided for @securitySignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get securitySignIn;

  /// No description provided for @securityThisPhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get securityThisPhone;

  /// No description provided for @securityEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Everywhere'**
  String get securityEverywhere;

  /// No description provided for @securitySignOutOthersSub.
  ///
  /// In en, this message translates to:
  /// **'Keeps you signed in on this phone'**
  String get securitySignOutOthersSub;

  /// No description provided for @securityNote.
  ///
  /// In en, this message translates to:
  /// **'Biometrics never leave the phone; Atomshop only learns that the unlock succeeded.'**
  String get securityNote;

  /// No description provided for @settingsShop.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get settingsShop;

  /// No description provided for @settingsShopNote.
  ///
  /// In en, this message translates to:
  /// **'Only you see these. They apply to all your outlets.'**
  String get settingsShopNote;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// No description provided for @storageCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get storageCache;

  /// No description provided for @storageClear.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get storageClear;

  /// No description provided for @storageClearBody.
  ///
  /// In en, this message translates to:
  /// **'Pictures and PDFs download again when you open them. Orders, products and stock are not touched.'**
  String get storageClearBody;

  /// No description provided for @storageClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get storageClearButton;

  /// No description provided for @menuPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan & billing'**
  String get menuPlan;

  /// No description provided for @syncActionOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order status changed'**
  String get syncActionOrderStatus;

  /// No description provided for @syncActionStockAdjust.
  ///
  /// In en, this message translates to:
  /// **'Stock adjusted'**
  String get syncActionStockAdjust;

  /// No description provided for @syncActionStockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get syncActionStockIn;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncOnline.
  ///
  /// In en, this message translates to:
  /// **'Online · synced {time}'**
  String syncOnline(String time);

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline · working from this phone'**
  String get syncOffline;

  /// No description provided for @syncNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncNeverSynced;

  /// No description provided for @syncAllSent.
  ///
  /// In en, this message translates to:
  /// **'Everything is sent.'**
  String get syncAllSent;

  /// No description provided for @syncSomeWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change is waiting to send.} other{{count} changes are waiting to send.}}'**
  String syncSomeWaiting(int count);

  /// No description provided for @syncSomeAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 needs you.} other{{count} need you.}}'**
  String syncSomeAttention(int count);

  /// No description provided for @syncWorksUntil.
  ///
  /// In en, this message translates to:
  /// **'Works offline until {day}'**
  String syncWorksUntil(String day);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Needs internet'**
  String get syncNeedsInternet;

  /// No description provided for @syncAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get syncAttentionTitle;

  /// No description provided for @syncAttentionSub.
  ///
  /// In en, this message translates to:
  /// **'Saved here, but the server couldn\'t apply them'**
  String get syncAttentionSub;

  /// No description provided for @syncAttentionLead.
  ///
  /// In en, this message translates to:
  /// **'These were saved on your phone, but the server found something had changed meanwhile. Nothing was applied, so nothing happened twice.'**
  String get syncAttentionLead;

  /// Needs attention: under a payment the server refused because the instalment was already paid.
  ///
  /// In en, this message translates to:
  /// **'If it was a second payment, record it on the plan, then discard this one.'**
  String get syncAttentionSecondPay;

  /// No description provided for @syncAttentionOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Open the plan'**
  String get syncAttentionOpenPlan;

  /// No description provided for @syncAttentionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs you'**
  String get syncAttentionEmpty;

  /// No description provided for @syncAttentionEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved on this phone is waiting for you to sort out.'**
  String get syncAttentionEmptyBody;

  /// No description provided for @syncWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get syncWaitingTitle;

  /// No description provided for @syncWaitingSub.
  ///
  /// In en, this message translates to:
  /// **'Deliveries, payments, stock in, notes made on this phone'**
  String get syncWaitingSub;

  /// No description provided for @syncWaitingNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting'**
  String get syncWaitingNone;

  /// No description provided for @syncWaitingNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Everything made on this phone has been sent.'**
  String get syncWaitingNoneBody;

  /// No description provided for @syncWaitingOrder.
  ///
  /// In en, this message translates to:
  /// **'No signal. These go in this order as soon as there is.'**
  String get syncWaitingOrder;

  /// No description provided for @syncChangesCount.
  ///
  /// In en, this message translates to:
  /// **'Changes · {count}'**
  String syncChangesCount(int count);

  /// No description provided for @syncUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get syncUndo;

  /// No description provided for @syncUndoNote.
  ///
  /// In en, this message translates to:
  /// **'Undo works only before it is sent.'**
  String get syncUndoNote;

  /// No description provided for @syncUndone.
  ///
  /// In en, this message translates to:
  /// **'Taken out of the queue'**
  String get syncUndone;

  /// No description provided for @syncTooLate.
  ///
  /// In en, this message translates to:
  /// **'It has gone to the server already'**
  String get syncTooLate;

  /// No description provided for @syncDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get syncDiscard;

  /// No description provided for @syncDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this change?'**
  String get syncDiscardTitle;

  /// No description provided for @syncDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'It was never applied on the server, and it will not be. This cannot be undone.'**
  String get syncDiscardBody;

  /// Toast after Try again on a Needs attention row.
  ///
  /// In en, this message translates to:
  /// **'Sent again. If it is still refused, it comes back here.'**
  String get syncRetried;

  /// Toast when Try again finds the row is no longer waiting on the seller (sent or discarded meanwhile).
  ///
  /// In en, this message translates to:
  /// **'This one is already sorted'**
  String get syncRetryGone;

  /// Needs attention: the line above Sign out at the bottom of the list.
  ///
  /// In en, this message translates to:
  /// **'Not your work, or need to sign in again? Sign out here. Nothing on this list is lost: it waits on this phone for you.'**
  String get syncAttentionNotYou;

  /// No description provided for @syncOnThisPhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get syncOnThisPhone;

  /// No description provided for @syncCopyLine.
  ///
  /// In en, this message translates to:
  /// **'{customers} orders · {orders} products · encrypted'**
  String syncCopyLine(int customers, int orders);

  /// No description provided for @syncNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing downloaded yet'**
  String get syncNothingYet;

  /// No description provided for @syncSentOf.
  ///
  /// In en, this message translates to:
  /// **'{sent} of {total} sent'**
  String syncSentOf(int sent, int total);

  /// No description provided for @syncKeepWorking.
  ///
  /// In en, this message translates to:
  /// **'You can keep working; new changes join the queue.'**
  String get syncKeepWorking;

  /// No description provided for @syncDownloading.
  ///
  /// In en, this message translates to:
  /// **'Getting others\' changes'**
  String get syncDownloading;

  /// No description provided for @syncFootnote.
  ///
  /// In en, this message translates to:
  /// **'The app sends changes by itself when there is signal, in the order you made them. Nothing is ever paid or added twice.'**
  String get syncFootnote;

  /// No description provided for @syncStopNote.
  ///
  /// In en, this message translates to:
  /// **'If the signal drops, it stops and carries on later from the same place.'**
  String get syncStopNote;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync'**
  String get syncFailed;

  /// No description provided for @syncOffBar.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncOffBar;

  /// No description provided for @syncOffBarChanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to send} other{{count} changes waiting to send}}'**
  String syncOffBarChanges(int count);

  /// No description provided for @syncOffBarDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get syncOffBarDetails;

  /// No description provided for @syncUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Brand Partner to send your changes'**
  String get syncUpdateTitle;

  /// No description provided for @syncEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'This phone now works online only'**
  String get syncEndedTitle;

  /// No description provided for @syncEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Offline working is no longer on this account. Your phone is sending what it saved, then it will work online only.'**
  String get syncEndedBody;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan & billing'**
  String get planTitle;

  /// No description provided for @ecosystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Our ecosystem'**
  String get ecosystemTitle;

  /// No description provided for @faqsNone.
  ///
  /// In en, this message translates to:
  /// **'No answer matches. Try other words, or ask Atomshop on WhatsApp.'**
  String get faqsNone;

  /// No description provided for @helpFaqsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No answers here yet'**
  String get helpFaqsEmpty;

  /// No description provided for @helpFaqsEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Atomshop is still writing answers for this topic. Ask Atomshop on WhatsApp meanwhile.'**
  String get helpFaqsEmptySub;

  /// No description provided for @faqsTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqsTitle;

  /// No description provided for @helpAllFaqs.
  ///
  /// In en, this message translates to:
  /// **'All FAQs'**
  String get helpAllFaqs;

  /// No description provided for @helpCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get helpCall;

  /// No description provided for @helpEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get helpEmail;

  /// No description provided for @helpPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get helpPopular;

  /// No description provided for @helpSearch.
  ///
  /// In en, this message translates to:
  /// **'Search help: \"hand over\", \"quote\"…'**
  String get helpSearch;

  /// No description provided for @helpTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk to Atomshop'**
  String get helpTalk;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get helpTitle;

  /// No description provided for @helpTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get helpTopics;

  /// No description provided for @helpVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get helpVersion;

  /// No description provided for @menuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQs'**
  String get menuHelp;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyTitle;

  /// No description provided for @supportAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get supportAnswered;

  /// No description provided for @supportAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Atomshop support'**
  String get supportAtomshop;

  /// No description provided for @supportEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Questions Ask Atom sends to Atomshop for you show here with the answer.'**
  String get supportEmptyBody;

  /// No description provided for @supportOpenFromList.
  ///
  /// In en, this message translates to:
  /// **'Open this request from Your support requests.'**
  String get supportOpenFromList;

  /// No description provided for @supportSub.
  ///
  /// In en, this message translates to:
  /// **'Questions sent to Atomshop, and the answers'**
  String get supportSub;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Your support requests'**
  String get supportTitle;

  /// No description provided for @supportWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get supportWaiting;

  /// No description provided for @supportWaitingNote.
  ///
  /// In en, this message translates to:
  /// **'Atomshop hasn\'t answered yet. The answer comes as a notification.'**
  String get supportWaitingNote;

  /// No description provided for @supportWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Message Atomshop on WhatsApp'**
  String get supportWhatsApp;

  /// No description provided for @supportYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportYou;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// No description provided for @tourStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get tourStart;

  /// No description provided for @tourOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm orders in a tap'**
  String get tourOrdersTitle;

  /// No description provided for @tourOrdersText.
  ///
  /// In en, this message translates to:
  /// **'New orders are on Home. Call the customer, confirm, and mark it delivered with a proof photo.'**
  String get tourOrdersText;

  /// No description provided for @tourOrdersChip1.
  ///
  /// In en, this message translates to:
  /// **'#48213 · AC 1.5 ton'**
  String get tourOrdersChip1;

  /// No description provided for @tourOrdersChip2.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get tourOrdersChip2;

  /// No description provided for @tourBulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Win bulk deals first'**
  String get tourBulkTitle;

  /// No description provided for @tourBulkText.
  ///
  /// In en, this message translates to:
  /// **'Reply to bulk requests with a quote on WhatsApp, then deliver and take payments on the deal.'**
  String get tourBulkText;

  /// No description provided for @tourBulkChip1.
  ///
  /// In en, this message translates to:
  /// **'40 × 55\" TV'**
  String get tourBulkChip1;

  /// No description provided for @tourBulkChip2.
  ///
  /// In en, this message translates to:
  /// **'Quote sent'**
  String get tourBulkChip2;

  /// No description provided for @tourOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Works without signal'**
  String get tourOfflineTitle;

  /// No description provided for @tourOfflineText.
  ///
  /// In en, this message translates to:
  /// **'Orders, stock and deals are on this phone. What you do offline is sent when the signal comes back.'**
  String get tourOfflineText;

  /// No description provided for @tourOfflineChip1.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get tourOfflineChip1;

  /// No description provided for @tourOfflineChip2.
  ///
  /// In en, this message translates to:
  /// **'3 waiting to send'**
  String get tourOfflineChip2;

  /// No description provided for @tourAtomTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom anything'**
  String get tourAtomTitle;

  /// No description provided for @tourAtomText.
  ///
  /// In en, this message translates to:
  /// **'Orders to confirm, quotes running out, what is low. In English, Roman Urdu or اردو.'**
  String get tourAtomText;

  /// No description provided for @tourAtomChip1.
  ///
  /// In en, this message translates to:
  /// **'What is running low?'**
  String get tourAtomChip1;

  /// No description provided for @tourAtomChip2.
  ///
  /// In en, this message translates to:
  /// **'4 products'**
  String get tourAtomChip2;

  /// No description provided for @tourWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'One ecosystem, built in Lahore'**
  String get tourWhoTitle;

  /// No description provided for @tourWhoBody.
  ///
  /// In en, this message translates to:
  /// **'Buyers find products on Atomshop and pay in steps. Verified sellers run the deals. Brands like yours supply them.'**
  String get tourWhoBody;

  /// No description provided for @tourPayInSteps.
  ///
  /// In en, this message translates to:
  /// **'Pay in Steps'**
  String get tourPayInSteps;

  /// No description provided for @tourSellerSub.
  ///
  /// In en, this message translates to:
  /// **'The app for brands'**
  String get tourSellerSub;

  /// No description provided for @tourEcoTitle.
  ///
  /// In en, this message translates to:
  /// **'Four apps, one business'**
  String get tourEcoTitle;

  /// No description provided for @tourEcoBody.
  ///
  /// In en, this message translates to:
  /// **'You sit at the source: orders and bulk requests for your products come to you.'**
  String get tourEcoBody;

  /// No description provided for @tourEcoSupply.
  ///
  /// In en, this message translates to:
  /// **'supply stock'**
  String get tourEcoSupply;

  /// No description provided for @tourFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything your brand runs on'**
  String get tourFeaturesTitle;

  /// No description provided for @tourFeaturesBody.
  ///
  /// In en, this message translates to:
  /// **'Online, or with no signal at all.'**
  String get tourFeaturesBody;

  /// No description provided for @tourFeatureOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get tourFeatureOrders;

  /// No description provided for @tourFeatureOrdersSub.
  ///
  /// In en, this message translates to:
  /// **'Cash and AtomPay orders: confirm, deliver, get paid'**
  String get tourFeatureOrdersSub;

  /// No description provided for @tourFeatureCollections.
  ///
  /// In en, this message translates to:
  /// **'Bulk deals'**
  String get tourFeatureCollections;

  /// No description provided for @tourFeatureCollectionsSub.
  ///
  /// In en, this message translates to:
  /// **'Seller and website requests, quotes and deals'**
  String get tourFeatureCollectionsSub;

  /// No description provided for @tourFeatureCustomers.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get tourFeatureCustomers;

  /// No description provided for @tourFeatureCustomersSub.
  ///
  /// In en, this message translates to:
  /// **'Your catalogue and brand page on atomshop.pk'**
  String get tourFeatureCustomersSub;

  /// No description provided for @tourFeatureStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get tourFeatureStock;

  /// No description provided for @tourFeatureStockSub.
  ///
  /// In en, this message translates to:
  /// **'Purchases, stock on hand and what it is worth'**
  String get tourFeatureStockSub;

  /// No description provided for @tourFeatureTeam.
  ///
  /// In en, this message translates to:
  /// **'Team and outlets'**
  String get tourFeatureTeam;

  /// No description provided for @tourFeatureTeamSub.
  ///
  /// In en, this message translates to:
  /// **'Each with their own sign-in and what they may do'**
  String get tourFeatureTeamSub;

  /// No description provided for @tourFeatureReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get tourFeatureReports;

  /// No description provided for @tourFeatureReportsSub.
  ///
  /// In en, this message translates to:
  /// **'Sales, payments received and what is still due'**
  String get tourFeatureReportsSub;

  /// No description provided for @tourOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Works with no signal. It syncs when you are back.'**
  String get tourOfflineNote;

  /// No description provided for @tourAddonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on only what you need'**
  String get tourAddonsTitle;

  /// No description provided for @tourAddonsPath.
  ///
  /// In en, this message translates to:
  /// **'Menu › Plan & billing › Add-ons'**
  String get tourAddonsPath;

  /// No description provided for @tourAddonsOnLead.
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get tourAddonsOnLead;

  /// No description provided for @tourAddonsOnRest.
  ///
  /// In en, this message translates to:
  /// **' starts a free trial where there is one, or pays for the rest of the period.'**
  String get tourAddonsOnRest;

  /// No description provided for @tourAddonsOffLead.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get tourAddonsOffLead;

  /// No description provided for @tourAddonsOffRest.
  ///
  /// In en, this message translates to:
  /// **' keeps it working until the period ends, then it stops renewing.'**
  String get tourAddonsOffRest;

  /// No description provided for @tourAddonInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get tourAddonInventory;

  /// No description provided for @tourAddonInventorySub.
  ///
  /// In en, this message translates to:
  /// **'Purchases, stock and its value'**
  String get tourAddonInventorySub;

  /// No description provided for @tourAddonAskAtom.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom'**
  String get tourAddonAskAtom;

  /// No description provided for @tourAddonAskAtomSub.
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get tourAddonAskAtomSub;

  /// No description provided for @tourAddonRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles management'**
  String get tourAddonRoles;

  /// No description provided for @tourAddonRolesSub.
  ///
  /// In en, this message translates to:
  /// **'Team members and what each may do'**
  String get tourAddonRolesSub;

  /// No description provided for @tourAddonAlerts.
  ///
  /// In en, this message translates to:
  /// **'Live alerts'**
  String get tourAddonAlerts;

  /// No description provided for @tourAddonAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'A push the moment something changes'**
  String get tourAddonAlertsSub;

  /// No description provided for @tourStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {count}'**
  String tourStep(int step, int count);

  /// No description provided for @atomLangAuto.
  ///
  /// In en, this message translates to:
  /// **'The way I write'**
  String get atomLangAuto;

  /// No description provided for @atomLangAutoSub.
  ///
  /// In en, this message translates to:
  /// **'Matches English, Roman Urdu or Urdu'**
  String get atomLangAutoSub;

  /// No description provided for @atomLangTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom answers in'**
  String get atomLangTitle;

  /// No description provided for @atomTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom'**
  String get atomTitle;

  /// No description provided for @scanSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get scanSerial;

  /// No description provided for @menuBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get menuBusiness;

  /// No description provided for @liveBPdfGetting.
  ///
  /// In en, this message translates to:
  /// **'Getting the PDF…'**
  String get liveBPdfGetting;

  /// Toast when a PDF from seller admin (report, receipt, statement) cannot be fetched because the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'No internet. Turn on mobile data or Wi-Fi to get the PDF.'**
  String get pdfOffline;

  /// Toast when seller admin could not make a PDF (HTTP 500). message is the server's sentence; ref is the code the seller quotes to Atomshop support.
  ///
  /// In en, this message translates to:
  /// **'{message} Ref: {ref}'**
  String pdfFailedRef(String message, String ref);

  /// No description provided for @askAPasswordSignedOut.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Password changed} =1{Password changed. 1 other phone was signed out} other{Password changed. {count} other phones were signed out}}'**
  String askAPasswordSignedOut(int count);

  /// No description provided for @auth2Tagline.
  ///
  /// In en, this message translates to:
  /// **'Connect. Sell. Grow.'**
  String get auth2Tagline;

  /// No description provided for @auth2SplashBy.
  ///
  /// In en, this message translates to:
  /// **'by {brand} · Pay in Steps'**
  String auth2SplashBy(String brand);

  /// No description provided for @auth2MainShop.
  ///
  /// In en, this message translates to:
  /// **'All outlets'**
  String get auth2MainShop;

  /// No description provided for @auth2Online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get auth2Online;

  /// No description provided for @auth2NoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet'**
  String get auth2NoInternet;

  /// No description provided for @auth2Or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get auth2Or;

  /// No description provided for @auth2SignInFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Sign in with fingerprint'**
  String get auth2SignInFingerprint;

  /// No description provided for @auth2PasswordOnce.
  ///
  /// In en, this message translates to:
  /// **'Sign in once with your password on a new phone (needs internet). After that, use your {quick}, even with no signal.'**
  String auth2PasswordOnce(String quick);

  /// No description provided for @auth2PasswordOnceBold.
  ///
  /// In en, this message translates to:
  /// **'fingerprint or PIN'**
  String get auth2PasswordOnceBold;

  /// No description provided for @auth2WrongOwner.
  ///
  /// In en, this message translates to:
  /// **'Email or password is wrong. Check both and try again.'**
  String get auth2WrongOwner;

  /// No description provided for @auth2WrongAgent.
  ///
  /// In en, this message translates to:
  /// **'Mobile number or password is wrong. Check both and try again.'**
  String get auth2WrongAgent;

  /// No description provided for @auth2OfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet.'**
  String get auth2OfflineTitle;

  /// No description provided for @auth2OfflineBody.
  ///
  /// In en, this message translates to:
  /// **'The first sign-in on this phone needs internet, so we can check your account. Connect to Wi-Fi or mobile data.'**
  String get auth2OfflineBody;

  /// No description provided for @auth2WaitingForInternet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for internet…'**
  String get auth2WaitingForInternet;

  /// No description provided for @auth2PendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your application is being checked.'**
  String get auth2PendingTitle;

  /// No description provided for @auth2PendingBody.
  ///
  /// In en, this message translates to:
  /// **'Atomshop reviews every brand before it can sign in, then creates your login. We will message you on WhatsApp when it is ready, usually within two working days.'**
  String get auth2PendingBody;

  /// No description provided for @auth2AskOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Ask Atomshop on WhatsApp'**
  String get auth2AskOnWhatsApp;

  /// No description provided for @auth2RuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get auth2RuleLength;

  /// No description provided for @auth2RuleMix.
  ///
  /// In en, this message translates to:
  /// **'Letters and numbers'**
  String get auth2RuleMix;

  /// No description provided for @auth2RuleNotTemp.
  ///
  /// In en, this message translates to:
  /// **'Not the temporary password'**
  String get auth2RuleNotTemp;

  /// No description provided for @auth2PinSavedBold.
  ///
  /// In en, this message translates to:
  /// **'PIN saved on this phone.'**
  String get auth2PinSavedBold;

  /// No description provided for @auth2PinSavedRest.
  ///
  /// In en, this message translates to:
  /// **'It never leaves the phone.'**
  String get auth2PinSavedRest;

  /// No description provided for @auth2BioRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Open with fingerprint'**
  String get auth2BioRowTitle;

  /// No description provided for @auth2BioRowSub.
  ///
  /// In en, this message translates to:
  /// **'Faster than typing your PIN'**
  String get auth2BioRowSub;

  /// No description provided for @auth2PinSmallPrint.
  ///
  /// In en, this message translates to:
  /// **'Anyone who knows your PIN can open the app on this phone. Lost the phone? Sign out all phones from the dashboard: Settings › Security.'**
  String get auth2PinSmallPrint;

  /// No description provided for @auth2Continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get auth2Continue;

  /// No description provided for @auth2FpBody.
  ///
  /// In en, this message translates to:
  /// **'Touch the fingerprint sensor on your phone. Works with or without internet.'**
  String get auth2FpBody;

  /// No description provided for @auth2FpOkTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get auth2FpOkTitle;

  /// No description provided for @auth2FpOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening {shop}…'**
  String auth2FpOpening(String shop);

  /// No description provided for @auth2FpTap.
  ///
  /// In en, this message translates to:
  /// **'Tap the circle to try it'**
  String get auth2FpTap;

  /// No description provided for @auth2FpFailed.
  ///
  /// In en, this message translates to:
  /// **'Not recognised. Try again, or use your PIN.'**
  String get auth2FpFailed;

  /// No description provided for @auth2FpOk.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get auth2FpOk;

  /// No description provided for @auth2FpButton.
  ///
  /// In en, this message translates to:
  /// **'Touch to sign in with fingerprint'**
  String get auth2FpButton;

  /// No description provided for @auth2UsePin.
  ///
  /// In en, this message translates to:
  /// **'Use PIN instead'**
  String get auth2UsePin;

  /// No description provided for @auth2SignInPassword.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get auth2SignInPassword;

  /// No description provided for @auth2EnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get auth2EnterPin;

  /// No description provided for @auth2WrongPinWait.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =1{Wrong PIN. 1 try left before a 5-minute wait.} other{Wrong PIN. {left} tries left before a 5-minute wait.}}'**
  String auth2WrongPinWait(int left);

  /// No description provided for @auth2WrongPinPassword.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =1{Wrong PIN. 1 try left before you need your password.} other{Wrong PIN. {left} tries left before you need your password.}}'**
  String auth2WrongPinPassword(int left);

  /// No description provided for @auth2ForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get auth2ForgotPin;

  /// No description provided for @auth2SwitchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get auth2SwitchAccount;

  /// No description provided for @auth2TooManyTitle.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs'**
  String get auth2TooManyTitle;

  /// No description provided for @auth2TooManyBody.
  ///
  /// In en, this message translates to:
  /// **'To keep your brand\'s orders and customer details safe, the app is paused for a few minutes.'**
  String get auth2TooManyBody;

  /// No description provided for @auth2TryAgainIn.
  ///
  /// In en, this message translates to:
  /// **'Try again in'**
  String get auth2TryAgainIn;

  /// No description provided for @auth2TenPins.
  ///
  /// In en, this message translates to:
  /// **'After {count} you will need your password and internet to open the app.'**
  String auth2TenPins(String count);

  /// No description provided for @auth2TenPinsBold.
  ///
  /// In en, this message translates to:
  /// **'10 wrong PINs'**
  String get auth2TenPinsBold;

  /// No description provided for @auth2PasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password instead'**
  String get auth2PasswordInstead;

  /// No description provided for @auth2DonePinKept.
  ///
  /// In en, this message translates to:
  /// **'Your PIN on this phone stays as it was.'**
  String get auth2DonePinKept;

  /// No description provided for @auth2DoneOthersTitle.
  ///
  /// In en, this message translates to:
  /// **'Your other phones are signed out'**
  String get auth2DoneOthersTitle;

  /// No description provided for @auth2DoneOthersSub.
  ///
  /// In en, this message translates to:
  /// **'They need the new password to sign in again'**
  String get auth2DoneOthersSub;

  /// No description provided for @auth2SignedOutPlace.
  ///
  /// In en, this message translates to:
  /// **'After you sign in you go back to {place}'**
  String auth2SignedOutPlace(String place);

  /// No description provided for @auth3PromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner'**
  String get auth3PromptTitle;

  /// No description provided for @auth3PromptRead.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your fingerprint'**
  String get auth3PromptRead;

  /// No description provided for @auth3PromptSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your fingerprint to save your sign-in on this phone'**
  String get auth3PromptSave;

  /// Fingerprint prompt when the fingerprint is given the key to the phone's offline copy (RULES 5).
  ///
  /// In en, this message translates to:
  /// **'Confirm your fingerprint to open the app, and what is saved on this phone, with it'**
  String get copyBioPromptSub;

  /// Unlock: the phone has a PIN but the offline copy's key was never wrapped by it (set up before RULES 5 was enforced); one PIN entry wraps it.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN once to lock what is saved on this phone behind it. Your fingerprint opens it after that.'**
  String get lockPinOnceToProtect;

  /// Unlock: the fingerprint's copy of the offline key is unreadable (new fingerprints, or the Keystore lost it); the PIN opens it instead.
  ///
  /// In en, this message translates to:
  /// **'Your fingerprint can\'t open what is saved on this phone any more. Enter your PIN this once.'**
  String get lockBioUsePin;

  /// No description provided for @auth3FpFailed.
  ///
  /// In en, this message translates to:
  /// **'Not recognised. Try again, or sign in with your password.'**
  String get auth3FpFailed;

  /// No description provided for @auth3FingerprintsChanged.
  ///
  /// In en, this message translates to:
  /// **'Your fingerprints changed on this phone. Sign in with your password.'**
  String get auth3FingerprintsChanged;

  /// No description provided for @auth3PasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password has changed. Sign in with your password.'**
  String get auth3PasswordChanged;

  /// No description provided for @auth3NotSaved.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint sign-in is off. You can turn it on in Settings › Account security.'**
  String get auth3NotSaved;

  /// No description provided for @auth3SheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Type your password to sign in with your fingerprint'**
  String get auth3SheetTitle;

  /// No description provided for @auth3SheetBody.
  ///
  /// In en, this message translates to:
  /// **'It is kept on this phone, behind your fingerprint, and sent only to sign you in.'**
  String get auth3SheetBody;

  /// No description provided for @auth3SheetSave.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get auth3SheetSave;

  /// No description provided for @auth3BioSub.
  ///
  /// In en, this message translates to:
  /// **'Unlock with this phone\'s biometrics'**
  String get auth3BioSub;

  /// No description provided for @auth3SignOutBodyQuick.
  ///
  /// In en, this message translates to:
  /// **'Next time, sign in on this phone with your fingerprint or your password. Your brand\'s data stays safe with Atomshop.'**
  String get auth3SignOutBodyQuick;

  /// No description provided for @dpETNoInternetKept.
  ///
  /// In en, this message translates to:
  /// **'The payment you were typing ({what}) is kept on this screen. Nothing was saved yet; save it when you are back online.'**
  String dpETNoInternetKept(String what);

  /// No description provided for @dpDbRoleOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your role doesn\'t include making orders'**
  String get dpDbRoleOrderTitle;

  /// No description provided for @dpDbRoleOrderBody.
  ///
  /// In en, this message translates to:
  /// **'The owner decides what each person can do. Ask them to change your role if you need it.'**
  String get dpDbRoleOrderBody;

  /// No description provided for @dpDbRoleStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Your role doesn\'t include stock'**
  String get dpDbRoleStockTitle;

  /// No description provided for @dpDbRoleStockBody.
  ///
  /// In en, this message translates to:
  /// **'You can still sell items the owner gives you. Ask the owner if you need to see stock.'**
  String get dpDbRoleStockBody;

  /// No description provided for @dpDbRoleDiscountTitle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t give discounts'**
  String get dpDbRoleDiscountTitle;

  /// No description provided for @dpDbRoleDiscountBody.
  ///
  /// In en, this message translates to:
  /// **'Only the owner, or roles with \"Give discounts\", can lower a price. The full price is kept.'**
  String get dpDbRoleDiscountBody;

  /// No description provided for @dpDbRoleYouCan.
  ///
  /// In en, this message translates to:
  /// **'You can'**
  String get dpDbRoleYouCan;

  /// No description provided for @dpDbRoleAskAtom.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom why'**
  String get dpDbRoleAskAtom;

  /// No description provided for @dpDbCanCollections.
  ///
  /// In en, this message translates to:
  /// **'deals'**
  String get dpDbCanCollections;

  /// No description provided for @dpDbCanCustomers.
  ///
  /// In en, this message translates to:
  /// **'products'**
  String get dpDbCanCustomers;

  /// No description provided for @dpDbCanOrders.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get dpDbCanOrders;

  /// No description provided for @dpDbCanStock.
  ///
  /// In en, this message translates to:
  /// **'stock'**
  String get dpDbCanStock;

  /// No description provided for @dpDbCanLeads.
  ///
  /// In en, this message translates to:
  /// **'bulk requests'**
  String get dpDbCanLeads;

  /// No description provided for @dpDbCanReports.
  ///
  /// In en, this message translates to:
  /// **'reports'**
  String get dpDbCanReports;

  /// No description provided for @dpDbCanList.
  ///
  /// In en, this message translates to:
  /// **'{first} and {last}'**
  String dpDbCanList(String first, String last);

  /// No description provided for @dpDbSeeBill.
  ///
  /// In en, this message translates to:
  /// **'See bill'**
  String get dpDbSeeBill;

  /// No description provided for @dpDbErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save'**
  String get dpDbErrorTitle;

  /// No description provided for @dpDbErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Atomshop couldn\'t save the {what} just now. Nothing was changed, and what you typed is still here.'**
  String dpDbErrorBody(String what);

  /// No description provided for @dpDbErrorRef.
  ///
  /// In en, this message translates to:
  /// **'Ref {ref} · {when}'**
  String dpDbErrorRef(String ref, String when);

  /// No description provided for @dpDbErrorRefNote.
  ///
  /// In en, this message translates to:
  /// **'The reference helps Atomshop find it if you contact them.'**
  String get dpDbErrorRefNote;

  /// No description provided for @dpDbLoadingToday.
  ///
  /// In en, this message translates to:
  /// **'Getting today\'s work…'**
  String get dpDbLoadingToday;

  /// No description provided for @dpDbMaintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll let you know when it’s ready.'**
  String get dpDbMaintenanceBody;

  /// No description provided for @dpDbUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Please update Brand Partner'**
  String get dpDbUpdateTitle;

  /// No description provided for @dpDbUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'This version is too old to talk to Atomshop. The update takes about a minute.'**
  String get dpDbUpdateBody;

  /// No description provided for @dpDbUpdateUsing.
  ///
  /// In en, this message translates to:
  /// **'After the update'**
  String get dpDbUpdateUsing;

  /// No description provided for @dpDbUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update on Google Play'**
  String get dpDbUpdateButton;

  /// No description provided for @dpDcMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get dpDcMessages;

  /// No description provided for @dpDcUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get dpDcUnread;

  /// No description provided for @dpDcAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Atomshop'**
  String get dpDcAtomshop;

  /// No description provided for @dpDcAskAtomAbout.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom about this'**
  String get dpDcAskAtomAbout;

  /// No description provided for @dpDcReplyAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Reply to Atomshop'**
  String get dpDcReplyAtomshop;

  /// No description provided for @dpDcReplyText.
  ///
  /// In en, this message translates to:
  /// **'About your message \"{title}\": '**
  String dpDcReplyText(String title);

  /// No description provided for @dpDcQuietSub.
  ///
  /// In en, this message translates to:
  /// **'No sound or popups; they wait in Notifications'**
  String get dpDcQuietSub;

  /// No description provided for @dpDcQuietChange.
  ///
  /// In en, this message translates to:
  /// **'Change the hours'**
  String get dpDcQuietChange;

  /// No description provided for @dpDcQuietOff.
  ///
  /// In en, this message translates to:
  /// **'Turn quiet hours off'**
  String get dpDcQuietOff;

  /// No description provided for @dpDcOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get dpDcOff;

  /// No description provided for @dpDcSound.
  ///
  /// In en, this message translates to:
  /// **'Sound & vibration'**
  String get dpDcSound;

  /// No description provided for @dpDcPhoneSettings.
  ///
  /// In en, this message translates to:
  /// **'Phone settings'**
  String get dpDcPhoneSettings;

  /// No description provided for @dpDcOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get dpDcOpen;

  /// No description provided for @dpDcRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get dpDcRead;

  /// No description provided for @dpDdDevicesLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking your devices…'**
  String get dpDdDevicesLoading;

  /// No description provided for @dpDdDevicesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your devices · tap to try again'**
  String get dpDdDevicesError;

  /// No description provided for @dpDdRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Due day, then 1 and 3 days late'**
  String get dpDdRemindersSub;

  /// No description provided for @dpDdLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'App and Ask Atom'**
  String get dpDdLanguageSub;

  /// No description provided for @dpDdPermissionsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get dpDdPermissionsOff;

  /// No description provided for @dpDdStorageSub.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get dpDdStorageSub;

  /// No description provided for @dpDdDataUse.
  ///
  /// In en, this message translates to:
  /// **'How we use your data'**
  String get dpDdDataUse;

  /// No description provided for @dpDdExport.
  ///
  /// In en, this message translates to:
  /// **'Export your data'**
  String get dpDdExport;

  /// No description provided for @dpDdExportSub.
  ///
  /// In en, this message translates to:
  /// **'Orders, deals and payments as Excel'**
  String get dpDdExportSub;

  /// No description provided for @dpDdPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get dpDdPrivacy;

  /// No description provided for @dpDdPrivacySub.
  ///
  /// In en, this message translates to:
  /// **'Saved on the phone, opens offline'**
  String get dpDdPrivacySub;

  /// No description provided for @dpDdTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & conditions'**
  String get dpDdTerms;

  /// No description provided for @dpDdTermsSub.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String dpDdTermsSub(String version);

  /// No description provided for @dpDdHelpSub.
  ///
  /// In en, this message translates to:
  /// **'Answers, Ask Atom, contact Atomshop'**
  String get dpDdHelpSub;

  /// No description provided for @dpDdVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · up to date'**
  String dpDdVersion(String version);

  /// No description provided for @dpDdEcosystem.
  ///
  /// In en, this message translates to:
  /// **'Our ecosystem'**
  String get dpDdEcosystem;

  /// No description provided for @dpDdByline.
  ///
  /// In en, this message translates to:
  /// **'by Atomshop.pk'**
  String get dpDdByline;

  /// No description provided for @dpDdNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Needs internet'**
  String get dpDdNeedsInternet;

  /// No description provided for @dpDdOfflineFoot.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Rows marked Needs internet open again when you are back online.'**
  String get dpDdOfflineFoot;

  /// No description provided for @dpDdCacheFreed.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared · {size} freed'**
  String dpDdCacheFreed(String size);

  /// No description provided for @dpDdSignInWithIt.
  ///
  /// In en, this message translates to:
  /// **'you sign in with it'**
  String get dpDdSignInWithIt;

  /// No description provided for @dpDdOwnerChangesPhone.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can change it.'**
  String get dpDdOwnerChangesPhone;

  /// No description provided for @dpDdPasswordSub.
  ///
  /// In en, this message translates to:
  /// **'Signs you out on other phones'**
  String get dpDdPasswordSub;

  /// No description provided for @dpDdDeviceApp.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner app'**
  String get dpDdDeviceApp;

  /// No description provided for @dpDdDeviceLastUsed.
  ///
  /// In en, this message translates to:
  /// **'{app} · last used {day}'**
  String dpDdDeviceLastUsed(String app, String day);

  /// No description provided for @dpDdTeamPhones.
  ///
  /// In en, this message translates to:
  /// **'Your team\'s phones'**
  String get dpDdTeamPhones;

  /// No description provided for @dpDdDevicesNote.
  ///
  /// In en, this message translates to:
  /// **'A device you sign out is signed out at once. Needs internet.'**
  String get dpDdDevicesNote;

  /// No description provided for @dpDdStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get dpDdStop;

  /// No description provided for @dpDdCloseLead.
  ///
  /// In en, this message translates to:
  /// **'This asks Atomshop to close {shop}.'**
  String dpDdCloseLead(String shop);

  /// No description provided for @dpDdCloseRest.
  ///
  /// In en, this message translates to:
  /// **'It can\'t be undone from the app.'**
  String get dpDdCloseRest;

  /// No description provided for @dpDdDataCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Only when you scan a serial or take a delivery or product photo. Scanning runs on the phone; nothing goes to Google.'**
  String get dpDdDataCameraBody;

  /// No description provided for @dpDdDataAtom.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom'**
  String get dpDdDataAtom;

  /// No description provided for @dpDdDataAtomBody.
  ///
  /// In en, this message translates to:
  /// **'Questions are kept 90 days with phone numbers removed.'**
  String get dpDdDataAtomBody;

  /// No description provided for @dpDdDownloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download everything as Excel'**
  String get dpDdDownloadAll;

  /// No description provided for @dpDdDownloadAllSub.
  ///
  /// In en, this message translates to:
  /// **'Orders, payments, products, bulk deals, stock'**
  String get dpDdDownloadAllSub;

  /// No description provided for @dpDdExportNote.
  ///
  /// In en, this message translates to:
  /// **'Atomshop makes the file and emails a link valid for 24 hours. Delivery photos are not included.'**
  String get dpDdExportNote;

  /// No description provided for @dpDdMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get dpDdMore;

  /// No description provided for @dpDdOnThisPhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get dpDdOnThisPhone;

  /// No description provided for @dpDdCameraSub.
  ///
  /// In en, this message translates to:
  /// **'Scan serials and IMEIs, delivery and product photos'**
  String get dpDdCameraSub;

  /// No description provided for @dpDdSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get dpDdSelected;

  /// No description provided for @dpDdBioSub.
  ///
  /// In en, this message translates to:
  /// **'Quick unlock'**
  String get dpDdBioSub;

  /// No description provided for @dpDdNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Not asked'**
  String get dpDdNotAsked;

  /// No description provided for @dpDdOpenPhoneSettings.
  ///
  /// In en, this message translates to:
  /// **'Open phone settings'**
  String get dpDdOpenPhoneSettings;

  /// No description provided for @dpDdPermissionsNever.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner never asks for your contacts, location or call log.'**
  String get dpDdPermissionsNever;

  /// No description provided for @dpDdUsed.
  ///
  /// In en, this message translates to:
  /// **'Used by Brand Partner'**
  String get dpDdUsed;

  /// No description provided for @dpDdCacheKey.
  ///
  /// In en, this message translates to:
  /// **'Amber: cache'**
  String get dpDdCacheKey;

  /// No description provided for @dpDdStorageNote.
  ///
  /// In en, this message translates to:
  /// **'Nothing else is stored on this phone.'**
  String get dpDdStorageNote;

  /// No description provided for @dpDdClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear {size} of cache?'**
  String dpDdClearTitle(String size);

  /// No description provided for @dpDdDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get dpDdDetails;

  /// No description provided for @dpDaMenuTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get dpDaMenuTeam;

  /// No description provided for @dpDaLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Atomshop.pk'**
  String get dpDaLogoLabel;

  /// No description provided for @dpDdToday.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String dpDdToday(String time);

  /// No description provided for @dpDdCacheSub.
  ///
  /// In en, this message translates to:
  /// **'Product pictures and PDFs you opened'**
  String get dpDdCacheSub;

  /// No description provided for @dpAMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get dpAMore;

  /// No description provided for @dpDcTopicStart.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get dpDcTopicStart;

  /// No description provided for @dpDcTopicInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get dpDcTopicInventory;

  /// No description provided for @helpTopicAtompay.
  ///
  /// In en, this message translates to:
  /// **'AtomPay'**
  String get helpTopicAtompay;

  /// No description provided for @helpTopicPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get helpTopicPayments;

  /// No description provided for @helpTopicBrandPage.
  ///
  /// In en, this message translates to:
  /// **'Brand page'**
  String get helpTopicBrandPage;

  /// No description provided for @dpDcTopicPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan & billing'**
  String get dpDcTopicPlan;

  /// No description provided for @dpDcTopicReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get dpDcTopicReports;

  /// No description provided for @dpDcTopicGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get dpDcTopicGeneral;

  /// No description provided for @dpDcSupportCounts.
  ///
  /// In en, this message translates to:
  /// **'{answered} answered, {waiting} waiting'**
  String dpDcSupportCounts(int answered, int waiting);

  /// No description provided for @dpDcEcosystemSub.
  ///
  /// In en, this message translates to:
  /// **'Atomshop, AtomPay, Atom Seller, Brand Partner'**
  String get dpDcEcosystemSub;

  /// No description provided for @dpDcVersionOk.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner {version} · up to date'**
  String dpDcVersionOk(String version);

  /// No description provided for @dpDcVersionOld.
  ///
  /// In en, this message translates to:
  /// **'Brand Partner {version} · an update is needed'**
  String dpDcVersionOld(String version);

  /// No description provided for @dpDcAskAtomFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest: it knows your brand and answers in seconds'**
  String get dpDcAskAtomFastest;

  /// No description provided for @dpDcAnswers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 answer} other{{count} answers}}'**
  String dpDcAnswers(int count);

  /// No description provided for @dpDcFaqSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in English or Roman Urdu'**
  String get dpDcFaqSearchHint;

  /// No description provided for @dpDcFaqSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search FAQs'**
  String get dpDcFaqSearchLabel;

  /// No description provided for @dpDcFaqFoot.
  ///
  /// In en, this message translates to:
  /// **'Answers are kept up to date by Atomshop. Saved on your phone for offline.'**
  String get dpDcFaqFoot;

  /// No description provided for @dpDcReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get dpDcReadMore;

  /// No description provided for @dpDcFaqOpenFromList.
  ///
  /// In en, this message translates to:
  /// **'Open this answer from FAQs.'**
  String get dpDcFaqOpenFromList;

  /// No description provided for @dpDcDidThisHelp.
  ///
  /// In en, this message translates to:
  /// **'Did this help?'**
  String get dpDcDidThisHelp;

  /// No description provided for @dpDcAskAtomCase.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom about your case'**
  String get dpDcAskAtomCase;

  /// No description provided for @dpDcThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you. It helps Atomshop improve the answers.'**
  String get dpDcThanks;

  /// No description provided for @dpDcTodayAt.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String dpDcTodayAt(String time);

  /// No description provided for @dpDcClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get dpDcClosed;

  /// No description provided for @dpDcWaitingAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Atomshop'**
  String get dpDcWaitingAtomshop;

  /// No description provided for @dpDcSince.
  ///
  /// In en, this message translates to:
  /// **'since {when}'**
  String dpDcSince(String when);

  /// No description provided for @dpDcHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get dpDcHelpSupport;

  /// No description provided for @dpDcAskAtomFirst.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom first'**
  String get dpDcAskAtomFirst;

  /// No description provided for @dpDcAskAtomFirstSub.
  ///
  /// In en, this message translates to:
  /// **'Most answers come in seconds. Atom passes it to Atomshop if it can\'t help.'**
  String get dpDcAskAtomFirstSub;

  /// No description provided for @dpDcNoOpen.
  ///
  /// In en, this message translates to:
  /// **'No open requests'**
  String get dpDcNoOpen;

  /// No description provided for @dpDcNoClosed.
  ///
  /// In en, this message translates to:
  /// **'No closed requests'**
  String get dpDcNoClosed;

  /// No description provided for @dpDcWhatsAppAtomshop.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Atomshop · {phone}'**
  String dpDcWhatsAppAtomshop(String phone);

  /// No description provided for @dpDcLastAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Atomshop: \"{text}\"'**
  String dpDcLastAtomshop(String text);

  /// No description provided for @dpDcLastYou.
  ///
  /// In en, this message translates to:
  /// **'You: \"{text}\"'**
  String dpDcLastYou(String text);

  /// No description provided for @dpDcClosedToast.
  ///
  /// In en, this message translates to:
  /// **'Request closed'**
  String get dpDcClosedToast;

  /// No description provided for @dpDcFromAskAtom.
  ///
  /// In en, this message translates to:
  /// **'From Ask Atom'**
  String get dpDcFromAskAtom;

  /// No description provided for @dpDcFromAskAtomAbout.
  ///
  /// In en, this message translates to:
  /// **'From Ask Atom · about {about}'**
  String dpDcFromAskAtomAbout(String about);

  /// No description provided for @dpDcSolved.
  ///
  /// In en, this message translates to:
  /// **'Did this solve it?'**
  String get dpDcSolved;

  /// No description provided for @dpDcYesClose.
  ///
  /// In en, this message translates to:
  /// **'Yes, close it'**
  String get dpDcYesClose;

  /// No description provided for @dpDcOrReply.
  ///
  /// In en, this message translates to:
  /// **'· or reply below.'**
  String get dpDcOrReply;

  /// No description provided for @dpDcSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get dpDcSend;

  /// No description provided for @dpDcOpenOnSite.
  ///
  /// In en, this message translates to:
  /// **'Open on atomshop.pk'**
  String get dpDcOpenOnSite;

  /// No description provided for @dpDcLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String dpDcLastUpdated(String date);

  /// No description provided for @dpDcPrivacyLead.
  ///
  /// In en, this message translates to:
  /// **'How Atomshop.pk and Brand Partner keep your brand\'s information and the details of buyers who order from you.'**
  String get dpDcPrivacyLead;

  /// No description provided for @dpDcPrivacyFoot.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone, so it opens offline. Questions? {email}'**
  String dpDcPrivacyFoot(String email);

  /// No description provided for @dpDcEcoTitle.
  ///
  /// In en, this message translates to:
  /// **'One ecosystem, built in Lahore'**
  String get dpDcEcoTitle;

  /// No description provided for @dpDcEcoLead.
  ///
  /// In en, this message translates to:
  /// **'Customers find products on Atomshop. Brands like yours list them and deliver. Verified local sellers handle AtomPay orders and buy in bulk. AtomPay gives verified customers a 0% markup limit.'**
  String get dpDcEcoLead;

  /// No description provided for @dpDcEcoFlowLabel.
  ///
  /// In en, this message translates to:
  /// **'Customers order on Atomshop, you deliver, sellers buy in bulk and handle AtomPay'**
  String get dpDcEcoFlowLabel;

  /// No description provided for @dpDcEcoCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get dpDcEcoCustomers;

  /// No description provided for @dpDcEcoCustomersSub.
  ///
  /// In en, this message translates to:
  /// **'order on Atomshop'**
  String get dpDcEcoCustomersSub;

  /// No description provided for @dpDcEcoYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get dpDcEcoYou;

  /// No description provided for @dpDcEcoYouSub.
  ///
  /// In en, this message translates to:
  /// **'confirm and deliver in Brand Partner'**
  String get dpDcEcoYouSub;

  /// No description provided for @dpDcEcoBrands.
  ///
  /// In en, this message translates to:
  /// **'Sellers'**
  String get dpDcEcoBrands;

  /// No description provided for @dpDcEcoBrandsSub.
  ///
  /// In en, this message translates to:
  /// **'buy in bulk and take AtomPay units'**
  String get dpDcEcoBrandsSub;

  /// No description provided for @dpDcYouAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get dpDcYouAreHere;

  /// No description provided for @dpDcEcoSeller.
  ///
  /// In en, this message translates to:
  /// **'Run your brand on Atomshop: orders, AtomPay hand-overs, bulk deals, products, stock and your team.'**
  String get dpDcEcoSeller;

  /// No description provided for @dpDcShareSeller.
  ///
  /// In en, this message translates to:
  /// **'Share with your team'**
  String get dpDcShareSeller;

  /// No description provided for @dpDcShareSellerText.
  ///
  /// In en, this message translates to:
  /// **'Get Brand Partner to work on our Atomshop orders with me: {link}'**
  String dpDcShareSellerText(String link);

  /// No description provided for @dpDcEcoAtomshop.
  ///
  /// In en, this message translates to:
  /// **'For customers: browse your brand page, order cash or with AtomPay. Their orders come to you.'**
  String get dpDcEcoAtomshop;

  /// No description provided for @dpDcSendCustomer.
  ///
  /// In en, this message translates to:
  /// **'Send to a buyer'**
  String get dpDcSendCustomer;

  /// No description provided for @dpDcSendCustomerText.
  ///
  /// In en, this message translates to:
  /// **'Shop on Atomshop and pay in steps: {link}'**
  String dpDcSendCustomerText(String link);

  /// No description provided for @dpDcEcoPay.
  ///
  /// In en, this message translates to:
  /// **'Verified customers get a 0% markup limit for eligible products: 3 months, no advance.'**
  String get dpDcEcoPay;

  /// No description provided for @dpDcEcoBrand.
  ///
  /// In en, this message translates to:
  /// **'For verified local sellers: they take AtomPay units from you and send bulk requests.'**
  String get dpDcEcoBrand;

  /// No description provided for @dpDcEcoSiteShop.
  ///
  /// In en, this message translates to:
  /// **'Where customers find you. Your brand page shows your story, slides and live products.'**
  String get dpDcEcoSiteShop;

  /// No description provided for @dpDcEcoSite.
  ///
  /// In en, this message translates to:
  /// **'Where customers find you and order your products.'**
  String get dpDcEcoSite;

  /// No description provided for @dpDcOpenSite.
  ///
  /// In en, this message translates to:
  /// **'Open atomshop.pk'**
  String get dpDcOpenSite;

  /// No description provided for @dpDcYourShopPage.
  ///
  /// In en, this message translates to:
  /// **'Your brand page'**
  String get dpDcYourShopPage;

  /// No description provided for @dpDcFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow Atomshop'**
  String get dpDcFollow;

  /// No description provided for @dpDcTermsPill.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · {date}'**
  String dpDcTermsPill(String version, String date);

  /// No description provided for @dpDcTermsAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted by {name} on {date} · version {version}'**
  String dpDcTermsAccepted(String name, String date, String version);

  /// No description provided for @qa3PinCurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get qa3PinCurrentTitle;

  /// No description provided for @qa3PinCurrentBody.
  ///
  /// In en, this message translates to:
  /// **'To change your PIN, first type the one you use now.'**
  String get qa3PinCurrentBody;

  /// No description provided for @qa3PinCurrentWrong.
  ///
  /// In en, this message translates to:
  /// **'{left, plural, =1{Wrong PIN. 1 try left.} other{Wrong PIN. {left} tries left.}}'**
  String qa3PinCurrentWrong(int left);

  /// No description provided for @qa3PinCurrentTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. Your PIN was not changed.'**
  String get qa3PinCurrentTooMany;

  /// Change PIN: the current PIN can't be checked during the 5-minute wait after 5 wrong PINs (the same wait as the lock screen).
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Too many wrong PINs. Try again in 1 minute. Your PIN was not changed.} other{Too many wrong PINs. Try again in {minutes} minutes. Your PIN was not changed.}}'**
  String qa3PinCurrentWait(int minutes);

  /// No description provided for @qa3PinTooEasy.
  ///
  /// In en, this message translates to:
  /// **'Too easy to guess. Pick another PIN.'**
  String get qa3PinTooEasy;

  /// No description provided for @secHideAmounts.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts on the lock screen'**
  String get secHideAmounts;

  /// No description provided for @secHideAmountsSub.
  ///
  /// In en, this message translates to:
  /// **'Notifications say \"tap to see\"'**
  String get secHideAmountsSub;

  /// No description provided for @secBlockShots.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots'**
  String get secBlockShots;

  /// No description provided for @secBlockShotsSub.
  ///
  /// In en, this message translates to:
  /// **'Of orders, buyer phone numbers and invoices'**
  String get secBlockShotsSub;

  /// No description provided for @recoTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recoTitle;

  /// No description provided for @recoEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get recoEmptyTitle;

  /// No description provided for @recoEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Atomshop sends news and tips for your brand. It shows here.'**
  String get recoEmptyBody;

  /// No description provided for @emuP4DevicesSummary.
  ///
  /// In en, this message translates to:
  /// **'{others, plural, =0{This phone only} =1{This phone, 1 more device} other{This phone, {others} more devices}}'**
  String emuP4DevicesSummary(int others);

  /// No description provided for @emuP4TryItNow.
  ///
  /// In en, this message translates to:
  /// **'Try it now'**
  String get emuP4TryItNow;

  /// No description provided for @savedHereTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get savedHereTitle;

  /// No description provided for @savedHereBody.
  ///
  /// In en, this message translates to:
  /// **'There is no signal, so this is waiting on your phone. It goes to Atomshop by itself as soon as you are back online.'**
  String get savedHereBody;

  /// No description provided for @savedHereSee.
  ///
  /// In en, this message translates to:
  /// **'See what is waiting'**
  String get savedHereSee;

  /// No description provided for @savedHereDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get savedHereDone;

  /// No description provided for @savedHereToast.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. It goes when you are back online.'**
  String get savedHereToast;

  /// No description provided for @syncLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to keep working'**
  String get syncLimitTitle;

  /// No description provided for @syncLimitBody.
  ///
  /// In en, this message translates to:
  /// **'This phone has worked on its own for as long as Atomshop allows. Find a signal for a minute and everything you saved goes up.'**
  String get syncLimitBody;

  /// No description provided for @syncLimitWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change is waiting on this phone.} other{{count} changes are waiting on this phone.}}'**
  String syncLimitWaiting(int count);

  /// No description provided for @syncLimitSafe.
  ///
  /// In en, this message translates to:
  /// **'Nothing is lost. It stays here until it is sent.'**
  String get syncLimitSafe;

  /// No description provided for @syncLimitTry.
  ///
  /// In en, this message translates to:
  /// **'Try now'**
  String get syncLimitTry;

  /// No description provided for @syncEndedSending.
  ///
  /// In en, this message translates to:
  /// **'Sending what is left…'**
  String get syncEndedSending;

  /// No description provided for @syncEndedDone.
  ///
  /// In en, this message translates to:
  /// **'Everything is sent.'**
  String get syncEndedDone;

  /// No description provided for @syncEndedContinue.
  ///
  /// In en, this message translates to:
  /// **'Carry on'**
  String get syncEndedContinue;

  /// Update screen (iPhone): opens the App Store page.
  ///
  /// In en, this message translates to:
  /// **'Update on the App Store'**
  String get updateButtonIos;

  /// No description provided for @updatePulledTitle.
  ///
  /// In en, this message translates to:
  /// **'This version needs an update'**
  String get updatePulledTitle;

  /// No description provided for @updatePulledBody.
  ///
  /// In en, this message translates to:
  /// **'We found a problem in this version and fixed it. Update to keep working: it takes about a minute.'**
  String get updatePulledBody;

  /// No description provided for @updateWaitingLabel.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get updateWaitingLabel;

  /// Update screen: unsent offline work survives the update and goes up after it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change, safe on this phone} other{{count} changes, safe on this phone}}'**
  String updateWaitingValue(int count);

  /// No description provided for @updateNewVersion.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get updateNewVersion;

  /// Shown once after the app was updated.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in {version}'**
  String updateWhatsNewTitle(String version);

  /// No description provided for @updateWhatsNewTitleNoVersion.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updateWhatsNewTitleNoVersion;

  /// No description provided for @updateWhatsNewDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get updateWhatsNewDone;

  /// No description provided for @signInNewBrand.
  ///
  /// In en, this message translates to:
  /// **'New brand?'**
  String get signInNewBrand;

  /// No description provided for @noticesBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk deals'**
  String get noticesBulk;

  /// No description provided for @noticesProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get noticesProducts;

  /// No description provided for @tabBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk deals'**
  String get tabBulk;

  /// No description provided for @tabAtompay.
  ///
  /// In en, this message translates to:
  /// **'AtomPay'**
  String get tabAtompay;

  /// No description provided for @tabProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get tabProducts;

  /// No description provided for @tabBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get tabBusiness;

  /// No description provided for @tabInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get tabInsights;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @businessSub.
  ///
  /// In en, this message translates to:
  /// **'Orders, bulk deals, products and stock'**
  String get businessSub;

  /// No description provided for @insightsSub.
  ///
  /// In en, this message translates to:
  /// **'Reports and answers about your brand'**
  String get insightsSub;

  /// No description provided for @bizOrdersSub.
  ///
  /// In en, this message translates to:
  /// **'Confirm, deliver and track orders'**
  String get bizOrdersSub;

  /// No description provided for @bizAtompaySub.
  ///
  /// In en, this message translates to:
  /// **'AtomPay orders to hand over'**
  String get bizAtompaySub;

  /// No description provided for @bizBulkSub.
  ///
  /// In en, this message translates to:
  /// **'Requests from Atomshop sellers, quotes and deals'**
  String get bizBulkSub;

  /// No description provided for @bizProductsSub.
  ///
  /// In en, this message translates to:
  /// **'Your catalogue on Atomshop'**
  String get bizProductsSub;

  /// No description provided for @bizStockSub.
  ///
  /// In en, this message translates to:
  /// **'What you have, by product and warehouse'**
  String get bizStockSub;

  /// No description provided for @bizWarehousesSub.
  ///
  /// In en, this message translates to:
  /// **'Where your stock is kept'**
  String get bizWarehousesSub;

  /// No description provided for @insReportsSub.
  ///
  /// In en, this message translates to:
  /// **'Sales, orders and stock, to view or download'**
  String get insReportsSub;

  /// No description provided for @insAskAtomSub.
  ///
  /// In en, this message translates to:
  /// **'Ask about your sales, orders and stock'**
  String get insAskAtomSub;

  /// No description provided for @tabQuickActions.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get tabQuickActions;

  /// No description provided for @applyRequired.
  ///
  /// In en, this message translates to:
  /// **'Fill this in.'**
  String get applyRequired;

  /// No description provided for @applyStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String applyStep(int step, int total);

  /// No description provided for @applyTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a brand partner'**
  String get applyTitle;

  /// No description provided for @applyBody.
  ///
  /// In en, this message translates to:
  /// **'Sell your catalogue to buyers across Pakistan on atomshop.pk. It takes about two minutes, and we reply within two working days.'**
  String get applyBody;

  /// No description provided for @applyAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get applyAboutYou;

  /// No description provided for @applyName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get applyName;

  /// No description provided for @applyMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile (WhatsApp)'**
  String get applyMobile;

  /// No description provided for @applyEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Your login is sent here once approved'**
  String get applyEmailHint;

  /// No description provided for @applyBusiness.
  ///
  /// In en, this message translates to:
  /// **'Your business'**
  String get applyBusiness;

  /// No description provided for @applyCompany.
  ///
  /// In en, this message translates to:
  /// **'Company / brand name'**
  String get applyCompany;

  /// No description provided for @applyBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Business type'**
  String get applyBusinessType;

  /// No description provided for @applyCategory.
  ///
  /// In en, this message translates to:
  /// **'Main category'**
  String get applyCategory;

  /// No description provided for @applyOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get applyOptional;

  /// No description provided for @applyWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get applyWebsite;

  /// No description provided for @applyProducts.
  ///
  /// In en, this message translates to:
  /// **'Number of products'**
  String get applyProducts;

  /// No description provided for @applyProductsHint.
  ///
  /// In en, this message translates to:
  /// **'At least 3 to get listed'**
  String get applyProductsHint;

  /// No description provided for @applyPartnership.
  ///
  /// In en, this message translates to:
  /// **'Partnership'**
  String get applyPartnership;

  /// No description provided for @applyShare.
  ///
  /// In en, this message translates to:
  /// **'AtomShop share per sale'**
  String get applyShare;

  /// No description provided for @applyMessage.
  ///
  /// In en, this message translates to:
  /// **'Anything else?'**
  String get applyMessage;

  /// No description provided for @applyWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can apply:'**
  String get applyWhoTitle;

  /// No description provided for @applyWhoBody.
  ///
  /// In en, this message translates to:
  /// **'manufacturers, official distributors and authorised importers with genuine, warrantied products.'**
  String get applyWhoBody;

  /// No description provided for @applyVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify phone & continue'**
  String get applyVerify;

  /// No description provided for @applyAlreadyPartner.
  ///
  /// In en, this message translates to:
  /// **'Already a partner?'**
  String get applyAlreadyPartner;

  /// No description provided for @applyCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get applyCodeTitle;

  /// No description provided for @applyCodeBody.
  ///
  /// In en, this message translates to:
  /// **'We sent it on WhatsApp to {phone}, so we know the number is yours.'**
  String applyCodeBody(String phone);

  /// No description provided for @applyResend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? Send again'**
  String get applyResend;

  /// No description provided for @applySend.
  ///
  /// In en, this message translates to:
  /// **'Send application'**
  String get applySend;

  /// No description provided for @applyChange.
  ///
  /// In en, this message translates to:
  /// **'Change my details'**
  String get applyChange;

  /// No description provided for @applyDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Application received'**
  String get applyDoneTitle;

  /// No description provided for @applyDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you, {name}. {company} is in the queue for review.'**
  String applyDoneBody(String name, String company);

  /// No description provided for @applyNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get applyNext;

  /// No description provided for @applyNextSent.
  ///
  /// In en, this message translates to:
  /// **'Application sent'**
  String get applyNextSent;

  /// No description provided for @applyNextSentBody.
  ///
  /// In en, this message translates to:
  /// **'Your details and phone number are verified.'**
  String get applyNextSentBody;

  /// No description provided for @applyNextReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get applyNextReview;

  /// No description provided for @applyNextReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Our team checks your brand and agrees pricing and margins with you.'**
  String get applyNextReviewBody;

  /// No description provided for @applyNextLogin.
  ///
  /// In en, this message translates to:
  /// **'Your login arrives'**
  String get applyNextLogin;

  /// No description provided for @applyNextLoginBody.
  ///
  /// In en, this message translates to:
  /// **'We email {email} and message you on WhatsApp.'**
  String applyNextLoginBody(String email);

  /// No description provided for @applyBackToStart.
  ///
  /// In en, this message translates to:
  /// **'Back to start'**
  String get applyBackToStart;

  /// No description provided for @outletTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you working today?'**
  String get outletTitle;

  /// No description provided for @outletBody.
  ///
  /// In en, this message translates to:
  /// **'You can switch outlet any time from the top of the app.'**
  String get outletBody;

  /// No description provided for @outletAll.
  ///
  /// In en, this message translates to:
  /// **'All outlets'**
  String get outletAll;

  /// No description provided for @outletAllSub.
  ///
  /// In en, this message translates to:
  /// **'See every outlet together'**
  String get outletAllSub;

  /// No description provided for @outletMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get outletMain;

  /// No description provided for @outletContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to {name}'**
  String outletContinue(String name);

  /// No description provided for @outletNone.
  ///
  /// In en, this message translates to:
  /// **'No outlets yet'**
  String get outletNone;

  /// No description provided for @menuOutlets.
  ///
  /// In en, this message translates to:
  /// **'Outlets'**
  String get menuOutlets;

  /// No description provided for @menuStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get menuStock;

  /// No description provided for @menuBrandPage.
  ///
  /// In en, this message translates to:
  /// **'Brand page'**
  String get menuBrandPage;

  /// No description provided for @menuBrandPageSub.
  ///
  /// In en, this message translates to:
  /// **'Your page on atomshop.pk'**
  String get menuBrandPageSub;

  /// No description provided for @menuShopSettings.
  ///
  /// In en, this message translates to:
  /// **'Shop settings'**
  String get menuShopSettings;

  /// No description provided for @menuShopSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Brand details, receipts and defaults'**
  String get menuShopSettingsSub;

  /// No description provided for @menuSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get menuSell;

  /// No description provided for @menuAtompay.
  ///
  /// In en, this message translates to:
  /// **'AtomPay orders'**
  String get menuAtompay;

  /// No description provided for @menuInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get menuInventory;

  /// No description provided for @menuStockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get menuStockIn;

  /// No description provided for @menuWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Warehouses'**
  String get menuWarehouses;

  /// No description provided for @menuStockHistory.
  ///
  /// In en, this message translates to:
  /// **'Stock history'**
  String get menuStockHistory;

  /// No description provided for @menuCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get menuCatalogue;

  /// No description provided for @menuReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get menuReports;

  /// No description provided for @menuLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get menuLogOut;

  /// No description provided for @menuRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get menuRoleOwner;

  /// No description provided for @menuTeamRoles.
  ///
  /// In en, this message translates to:
  /// **'Team & roles'**
  String get menuTeamRoles;

  /// No description provided for @menuProfileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & settings'**
  String get menuProfileSettings;

  /// No description provided for @menuHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get menuHelpSupport;

  /// No description provided for @menuGroupHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuGroupHelp;

  /// No description provided for @menuBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String menuBadgeNew(int count);

  /// No description provided for @menuBadgeOut.
  ///
  /// In en, this message translates to:
  /// **'{count} out'**
  String menuBadgeOut(int count);

  /// No description provided for @menuPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until {date}'**
  String menuPaidUntil(String date);

  /// No description provided for @menuPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String menuPeople(int count);

  /// No description provided for @menuOutletsOpen.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String menuOutletsOpen(int count);

  /// No description provided for @menuSyncedAt.
  ///
  /// In en, this message translates to:
  /// **'Synced {time}'**
  String menuSyncedAt(String time);

  /// No description provided for @menuMyPassword.
  ///
  /// In en, this message translates to:
  /// **'My password'**
  String get menuMyPassword;

  /// No description provided for @syncActionOrderDeliver.
  ///
  /// In en, this message translates to:
  /// **'Order delivered'**
  String get syncActionOrderDeliver;

  /// No description provided for @syncActionOrderPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get syncActionOrderPayment;

  /// No description provided for @syncActionAtompayHandover.
  ///
  /// In en, this message translates to:
  /// **'AtomPay unit handed over'**
  String get syncActionAtompayHandover;

  /// No description provided for @syncActionDealDeliver.
  ///
  /// In en, this message translates to:
  /// **'Deal units delivered'**
  String get syncActionDealDeliver;

  /// No description provided for @syncActionDealPayment.
  ///
  /// In en, this message translates to:
  /// **'Deal payment recorded'**
  String get syncActionDealPayment;

  /// No description provided for @syncActionOrderCancel.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get syncActionOrderCancel;

  /// No description provided for @syncActionBulkStatus.
  ///
  /// In en, this message translates to:
  /// **'Bulk request status changed'**
  String get syncActionBulkStatus;

  /// No description provided for @syncActionStockTransfer.
  ///
  /// In en, this message translates to:
  /// **'Stock moved'**
  String get syncActionStockTransfer;

  /// No description provided for @catProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get catProductsTitle;

  /// No description provided for @catAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get catAddProduct;

  /// No description provided for @catAskAtom.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom'**
  String get catAskAtom;

  /// No description provided for @catFilterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get catFilterByStatus;

  /// No description provided for @catSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get catSearchLabel;

  /// No description provided for @catSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Product name or PR number'**
  String get catSearchHint;

  /// No description provided for @catAllProducts.
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get catAllProducts;

  /// No description provided for @catShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get catShowAll;

  /// No description provided for @catNoProductsHere.
  ///
  /// In en, this message translates to:
  /// **'No products here.'**
  String get catNoProductsHere;

  /// No description provided for @catNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get catNoProductsFound;

  /// No description provided for @catFirstProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first product'**
  String get catFirstProductTitle;

  /// No description provided for @catFirstProductBody.
  ///
  /// In en, this message translates to:
  /// **'Atomshop reviews it and puts it live on atomshop.pk, usually within one working day.'**
  String get catFirstProductBody;

  /// No description provided for @catReviewFoot.
  ///
  /// In en, this message translates to:
  /// **'New products and edits to live ones go to Atomshop for review, usually within one working day.'**
  String get catReviewFoot;

  /// No description provided for @catShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get catShowMore;

  /// No description provided for @catOfflineList.
  ///
  /// In en, this message translates to:
  /// **'No signal: this is the list your phone keeps. Changes wait until you are back online.'**
  String get catOfflineList;

  /// No description provided for @catOnHoldManyBody.
  ///
  /// In en, this message translates to:
  /// **'Atomshop asked for changes before publishing'**
  String get catOnHoldManyBody;

  /// No description provided for @catFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get catFix;

  /// No description provided for @catSee.
  ///
  /// In en, this message translates to:
  /// **'See'**
  String get catSee;

  /// No description provided for @catNewCode.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get catNewCode;

  /// No description provided for @catFeaturedTag.
  ///
  /// In en, this message translates to:
  /// **'★ Featured'**
  String get catFeaturedTag;

  /// No description provided for @catAtompayOnTag.
  ///
  /// In en, this message translates to:
  /// **'AtomPay on'**
  String get catAtompayOnTag;

  /// No description provided for @catNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'None available'**
  String get catNoneAvailable;

  /// No description provided for @catNotInStockYet.
  ///
  /// In en, this message translates to:
  /// **'Not in stock yet'**
  String get catNotInStockYet;

  /// No description provided for @catSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort products'**
  String get catSortTitle;

  /// No description provided for @catSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get catSortNewest;

  /// No description provided for @catSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get catSortOldest;

  /// No description provided for @catSortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get catSortPriceLow;

  /// No description provided for @catSortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get catSortPriceHigh;

  /// No description provided for @catSortName.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get catSortName;

  /// No description provided for @catSortStock.
  ///
  /// In en, this message translates to:
  /// **'Fewest in stock'**
  String get catSortStock;

  /// No description provided for @catEditProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get catEditProduct;

  /// No description provided for @catEditProductNote.
  ///
  /// In en, this message translates to:
  /// **'Changes to a live product go for review'**
  String get catEditProductNote;

  /// No description provided for @catViewProduct.
  ///
  /// In en, this message translates to:
  /// **'View product'**
  String get catViewProduct;

  /// No description provided for @catStockAndSerials.
  ///
  /// In en, this message translates to:
  /// **'Stock and serials'**
  String get catStockAndSerials;

  /// No description provided for @catFeatureOnPage.
  ///
  /// In en, this message translates to:
  /// **'Feature on your brand page'**
  String get catFeatureOnPage;

  /// No description provided for @catFeatureNote.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 products · live products only'**
  String get catFeatureNote;

  /// No description provided for @catAtompay.
  ///
  /// In en, this message translates to:
  /// **'AtomPay'**
  String get catAtompay;

  /// No description provided for @catAtompayNote.
  ///
  /// In en, this message translates to:
  /// **'3 monthly payments, no advance, 0% markup'**
  String get catAtompayNote;

  /// No description provided for @catAtompayBrandWideNote.
  ///
  /// In en, this message translates to:
  /// **'Atomshop turned AtomPay on for every product of this brand'**
  String get catAtompayBrandWideNote;

  /// No description provided for @catMarkOut.
  ///
  /// In en, this message translates to:
  /// **'Mark out of stock'**
  String get catMarkOut;

  /// No description provided for @catMarkOutNote.
  ///
  /// In en, this message translates to:
  /// **'Customers can\'t order it until you mark it back'**
  String get catMarkOutNote;

  /// No description provided for @catBackIn.
  ///
  /// In en, this message translates to:
  /// **'Back in stock'**
  String get catBackIn;

  /// No description provided for @catBackInNote.
  ///
  /// In en, this message translates to:
  /// **'Customers can order it again'**
  String get catBackInNote;

  /// No description provided for @catDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get catDeleteProduct;

  /// No description provided for @catDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Not possible once it has been ordered'**
  String get catDeleteNote;

  /// No description provided for @catDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It is removed from your catalogue and from atomshop.pk. This can’t be undone.'**
  String get catDeleteConfirmBody;

  /// No description provided for @catDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get catDelete;

  /// No description provided for @catDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get catDeleted;

  /// No description provided for @catFeaturedOn.
  ///
  /// In en, this message translates to:
  /// **'Featured on your brand page'**
  String get catFeaturedOn;

  /// No description provided for @catFeaturedOff.
  ///
  /// In en, this message translates to:
  /// **'Removed from your featured products'**
  String get catFeaturedOff;

  /// No description provided for @catAtompayOn.
  ///
  /// In en, this message translates to:
  /// **'AtomPay turned on'**
  String get catAtompayOn;

  /// No description provided for @catAtompayOff.
  ///
  /// In en, this message translates to:
  /// **'AtomPay turned off'**
  String get catAtompayOff;

  /// No description provided for @catMarkedOut.
  ///
  /// In en, this message translates to:
  /// **'Marked out of stock'**
  String get catMarkedOut;

  /// No description provided for @catMarkedIn.
  ///
  /// In en, this message translates to:
  /// **'Back in stock'**
  String get catMarkedIn;

  /// No description provided for @catBackInTitle.
  ///
  /// In en, this message translates to:
  /// **'Back in stock'**
  String get catBackInTitle;

  /// No description provided for @catBackInBody.
  ///
  /// In en, this message translates to:
  /// **'How many units can customers order?'**
  String get catBackInBody;

  /// No description provided for @catUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units in stock'**
  String get catUnitsLabel;

  /// No description provided for @catUnitsError.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 1 unit'**
  String get catUnitsError;

  /// No description provided for @catEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get catEditTitle;

  /// No description provided for @catNotSentYet.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get catNotSentYet;

  /// No description provided for @catSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get catSections;

  /// No description provided for @catJumpPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get catJumpPhotos;

  /// No description provided for @catJumpDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get catJumpDetails;

  /// No description provided for @catJumpPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get catJumpPrice;

  /// No description provided for @catJumpVariants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get catJumpVariants;

  /// No description provided for @catJumpDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get catJumpDescription;

  /// No description provided for @catNoteNew.
  ///
  /// In en, this message translates to:
  /// **'Atomshop reviews every new product before it goes live on atomshop.pk, usually within one working day.'**
  String get catNoteNew;

  /// No description provided for @catNoteLive.
  ///
  /// In en, this message translates to:
  /// **'This product is live. Your changes go to Atomshop for review; customers keep seeing the current version until they\'re approved.'**
  String get catNoteLive;

  /// No description provided for @catNoteHoldLead.
  ///
  /// In en, this message translates to:
  /// **'Atomshop put this on hold:'**
  String get catNoteHoldLead;

  /// No description provided for @catNoteReview.
  ///
  /// In en, this message translates to:
  /// **'Atomshop is reviewing this product. Saving sends them your latest version.'**
  String get catNoteReview;

  /// No description provided for @catNoteOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'This product is out of stock. Saving keeps it out of stock.'**
  String get catNoteOutOfStock;

  /// No description provided for @catNoteClosed.
  ///
  /// In en, this message translates to:
  /// **'Atomshop closed this product. Contact Atomshop to list it again.'**
  String get catNoteClosed;

  /// No description provided for @catNoteReadOnly.
  ///
  /// In en, this message translates to:
  /// **'You can see this product. Your role can\'t change it.'**
  String get catNoteReadOnly;

  /// No description provided for @catSectionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get catSectionPhotos;

  /// No description provided for @catFeatureImage.
  ///
  /// In en, this message translates to:
  /// **'Feature image'**
  String get catFeatureImage;

  /// No description provided for @catFeatureImageNote.
  ///
  /// In en, this message translates to:
  /// **'Required · up to 4 MB'**
  String get catFeatureImageNote;

  /// No description provided for @catFeatureImageMissing.
  ///
  /// In en, this message translates to:
  /// **'Add a feature image'**
  String get catFeatureImageMissing;

  /// No description provided for @catChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get catChange;

  /// No description provided for @catAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get catAddPhoto;

  /// No description provided for @catMorePhotos.
  ///
  /// In en, this message translates to:
  /// **'More photos'**
  String get catMorePhotos;

  /// No description provided for @catAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get catAdd;

  /// No description provided for @catPhotosTip.
  ///
  /// In en, this message translates to:
  /// **'Front, back, side, box and remote. Plain background works best.'**
  String get catPhotosTip;

  /// No description provided for @catRemovePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo?'**
  String get catRemovePhotoTitle;

  /// No description provided for @catRemovePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'It is taken off the product straight away, also on atomshop.pk.'**
  String get catRemovePhotoBody;

  /// No description provided for @catRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get catRemove;

  /// No description provided for @catPhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get catPhotoRemoved;

  /// No description provided for @catPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large. Use one under 4 MB.'**
  String get catPhotoTooLarge;

  /// No description provided for @catLogoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That logo is too large. Use one under 2 MB.'**
  String get catLogoTooLarge;

  /// No description provided for @catPickCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get catPickCamera;

  /// No description provided for @catPickGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get catPickGallery;

  /// No description provided for @catSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get catSectionDetails;

  /// No description provided for @catTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Product title'**
  String get catTitleLabel;

  /// No description provided for @catTitleHint.
  ///
  /// In en, this message translates to:
  /// **'As customers search for it: brand, size, model.'**
  String get catTitleHint;

  /// No description provided for @catCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get catCategory;

  /// No description provided for @catCategorySearch.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get catCategorySearch;

  /// No description provided for @catBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get catBrand;

  /// No description provided for @catBrandSearch.
  ///
  /// In en, this message translates to:
  /// **'Search brands'**
  String get catBrandSearch;

  /// No description provided for @catBrandsInCategory.
  ///
  /// In en, this message translates to:
  /// **'Sell in this category'**
  String get catBrandsInCategory;

  /// No description provided for @catOtherBrands.
  ///
  /// In en, this message translates to:
  /// **'Other brands'**
  String get catOtherBrands;

  /// No description provided for @catDetailHeading.
  ///
  /// In en, this message translates to:
  /// **'Detail page heading'**
  String get catDetailHeading;

  /// No description provided for @catOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get catOptional;

  /// No description provided for @catOptionalTag.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get catOptionalTag;

  /// No description provided for @catDetailHeadingHint.
  ///
  /// In en, this message translates to:
  /// **'Shown at the top of the product page'**
  String get catDetailHeadingHint;

  /// No description provided for @catSectionPrice.
  ///
  /// In en, this message translates to:
  /// **'Price and AtomPay'**
  String get catSectionPrice;

  /// No description provided for @catCashPrice.
  ///
  /// In en, this message translates to:
  /// **'Cash price'**
  String get catCashPrice;

  /// No description provided for @catMinAdvance.
  ///
  /// In en, this message translates to:
  /// **'Minimum advance'**
  String get catMinAdvance;

  /// No description provided for @catAdvanceHint.
  ///
  /// In en, this message translates to:
  /// **'The advance can\'t be more than the cash price.'**
  String get catAdvanceHint;

  /// No description provided for @catAdvanceTooHigh.
  ///
  /// In en, this message translates to:
  /// **'The advance can\'t be more than the cash price'**
  String get catAdvanceTooHigh;

  /// No description provided for @catSellWithAtompay.
  ///
  /// In en, this message translates to:
  /// **'Sell with AtomPay'**
  String get catSellWithAtompay;

  /// No description provided for @catSellWithAtompayBody.
  ///
  /// In en, this message translates to:
  /// **'Customer pays in 3 months, no advance, 0% markup. Atomshop gives the order to a seller; for you it is a cash sale.'**
  String get catSellWithAtompayBody;

  /// No description provided for @catSectionVariants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get catSectionVariants;

  /// No description provided for @catColours.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get catColours;

  /// No description provided for @catChooseColours.
  ///
  /// In en, this message translates to:
  /// **'Choose colours'**
  String get catChooseColours;

  /// No description provided for @catSearchColours.
  ///
  /// In en, this message translates to:
  /// **'Search colours'**
  String get catSearchColours;

  /// No description provided for @catStorageLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage, each with its own price'**
  String get catStorageLabel;

  /// No description provided for @catSizesLabel.
  ///
  /// In en, this message translates to:
  /// **'Screen sizes, each with its own price'**
  String get catSizesLabel;

  /// No description provided for @catAddStorage.
  ///
  /// In en, this message translates to:
  /// **'Add a storage'**
  String get catAddStorage;

  /// No description provided for @catAddSize.
  ///
  /// In en, this message translates to:
  /// **'Add a size'**
  String get catAddSize;

  /// No description provided for @catStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get catStorage;

  /// No description provided for @catSize.
  ///
  /// In en, this message translates to:
  /// **'Screen size'**
  String get catSize;

  /// No description provided for @catPriceForThis.
  ///
  /// In en, this message translates to:
  /// **'Price for this option'**
  String get catPriceForThis;

  /// No description provided for @catVariantsTip.
  ///
  /// In en, this message translates to:
  /// **'The options follow the category: storage for phones, screen size for TVs.'**
  String get catVariantsTip;

  /// No description provided for @catVariantIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Choose the option and its price'**
  String get catVariantIncomplete;

  /// No description provided for @catSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get catSectionDescription;

  /// No description provided for @catShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get catShortDescription;

  /// No description provided for @catShortTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it under 500 characters'**
  String get catShortTooLong;

  /// No description provided for @catFullDescription.
  ///
  /// In en, this message translates to:
  /// **'Full description'**
  String get catFullDescription;

  /// No description provided for @catFullHint.
  ///
  /// In en, this message translates to:
  /// **'One feature per line. Start a line with • or - for a bullet.'**
  String get catFullHint;

  /// No description provided for @catSendForReview.
  ///
  /// In en, this message translates to:
  /// **'Send for review'**
  String get catSendForReview;

  /// No description provided for @catFixAndSend.
  ///
  /// In en, this message translates to:
  /// **'Fix and send again'**
  String get catFixAndSend;

  /// No description provided for @catSaveAndSend.
  ///
  /// In en, this message translates to:
  /// **'Save and send for review'**
  String get catSaveAndSend;

  /// No description provided for @catSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get catSaveChanges;

  /// No description provided for @catReviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by Atomshop, usually within one working day'**
  String get catReviewedBy;

  /// No description provided for @catSentForReview.
  ///
  /// In en, this message translates to:
  /// **'Sent to Atomshop for review'**
  String get catSentForReview;

  /// No description provided for @catChangesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get catChangesSaved;

  /// No description provided for @catSendLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Send your changes for review?'**
  String get catSendLiveTitle;

  /// No description provided for @catSendLiveBody.
  ///
  /// In en, this message translates to:
  /// **'Customers keep seeing the current version until Atomshop approves the new one.'**
  String get catSendLiveBody;

  /// No description provided for @catSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get catSend;

  /// No description provided for @catGapPicture.
  ///
  /// In en, this message translates to:
  /// **'a feature image'**
  String get catGapPicture;

  /// No description provided for @catGapTitle.
  ///
  /// In en, this message translates to:
  /// **'a title'**
  String get catGapTitle;

  /// No description provided for @catGapCategory.
  ///
  /// In en, this message translates to:
  /// **'a category'**
  String get catGapCategory;

  /// No description provided for @catGapBrand.
  ///
  /// In en, this message translates to:
  /// **'a brand'**
  String get catGapBrand;

  /// No description provided for @catGapPrice.
  ///
  /// In en, this message translates to:
  /// **'a price'**
  String get catGapPrice;

  /// No description provided for @catGapAdvance.
  ///
  /// In en, this message translates to:
  /// **'the minimum advance'**
  String get catGapAdvance;

  /// No description provided for @catGapAdvanceHigh.
  ///
  /// In en, this message translates to:
  /// **'a lower advance'**
  String get catGapAdvanceHigh;

  /// No description provided for @catGapShort.
  ///
  /// In en, this message translates to:
  /// **'a short description'**
  String get catGapShort;

  /// No description provided for @catGapShortLong.
  ///
  /// In en, this message translates to:
  /// **'a shorter description'**
  String get catGapShortLong;

  /// No description provided for @catGapVariants.
  ///
  /// In en, this message translates to:
  /// **'a price for each option'**
  String get catGapVariants;

  /// No description provided for @catProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'This product is no longer in your catalogue.'**
  String get catProductNotFound;

  /// No description provided for @catBrandPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Brand page'**
  String get catBrandPageTitle;

  /// No description provided for @catViewOnAtomshop.
  ///
  /// In en, this message translates to:
  /// **'View on atomshop.pk'**
  String get catViewOnAtomshop;

  /// No description provided for @catPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get catPage;

  /// No description provided for @catAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get catAddress;

  /// No description provided for @catLiveProducts.
  ///
  /// In en, this message translates to:
  /// **'Live products'**
  String get catLiveProducts;

  /// No description provided for @catFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get catFeatured;

  /// No description provided for @catAddressFixed.
  ///
  /// In en, this message translates to:
  /// **'The address is fixed. Ask Atomshop to change it.'**
  String get catAddressFixed;

  /// No description provided for @catLogoAndBanner.
  ///
  /// In en, this message translates to:
  /// **'Logo and banner'**
  String get catLogoAndBanner;

  /// No description provided for @catChangeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change logo'**
  String get catChangeLogo;

  /// No description provided for @catChangeBanner.
  ///
  /// In en, this message translates to:
  /// **'Change banner'**
  String get catChangeBanner;

  /// No description provided for @catLogoBannerHint.
  ///
  /// In en, this message translates to:
  /// **'Logo up to 2 MB, banner up to 4 MB.'**
  String get catLogoBannerHint;

  /// No description provided for @catNewLogo.
  ///
  /// In en, this message translates to:
  /// **'New logo, not saved yet'**
  String get catNewLogo;

  /// No description provided for @catNewBanner.
  ///
  /// In en, this message translates to:
  /// **'New banner, not saved yet'**
  String get catNewBanner;

  /// No description provided for @catNoBanner.
  ///
  /// In en, this message translates to:
  /// **'No banner yet'**
  String get catNoBanner;

  /// No description provided for @catYourStory.
  ///
  /// In en, this message translates to:
  /// **'Your story'**
  String get catYourStory;

  /// No description provided for @catDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get catDisplayName;

  /// No description provided for @catDisplayNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter the name customers see'**
  String get catDisplayNameError;

  /// No description provided for @catTagline.
  ///
  /// In en, this message translates to:
  /// **'Tagline'**
  String get catTagline;

  /// No description provided for @catIntro.
  ///
  /// In en, this message translates to:
  /// **'Intro'**
  String get catIntro;

  /// No description provided for @catIntroHint.
  ///
  /// In en, this message translates to:
  /// **'Up to 300 characters, under your name.'**
  String get catIntroHint;

  /// No description provided for @catIntroTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the intro under 300 characters'**
  String get catIntroTooLong;

  /// No description provided for @catAbout.
  ///
  /// In en, this message translates to:
  /// **'About the brand'**
  String get catAbout;

  /// No description provided for @catPromoBanner.
  ///
  /// In en, this message translates to:
  /// **'Promo banner'**
  String get catPromoBanner;

  /// No description provided for @catSmallLabel.
  ///
  /// In en, this message translates to:
  /// **'Small label'**
  String get catSmallLabel;

  /// No description provided for @catHeadline.
  ///
  /// In en, this message translates to:
  /// **'Headline'**
  String get catHeadline;

  /// No description provided for @catSupportingLine.
  ///
  /// In en, this message translates to:
  /// **'Supporting line'**
  String get catSupportingLine;

  /// No description provided for @catAddSlide.
  ///
  /// In en, this message translates to:
  /// **'Add a slide'**
  String get catAddSlide;

  /// No description provided for @catSlideNoHeadline.
  ///
  /// In en, this message translates to:
  /// **'A slide without a headline is not shown.'**
  String get catSlideNoHeadline;

  /// No description provided for @catContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get catContact;

  /// No description provided for @catWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get catWebsite;

  /// No description provided for @catWebsiteError.
  ///
  /// In en, this message translates to:
  /// **'Enter a web address, like zenvo.pk'**
  String get catWebsiteError;

  /// No description provided for @catSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support email'**
  String get catSupportEmail;

  /// No description provided for @catSupportEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address, like care@zenvo.pk'**
  String get catSupportEmailError;

  /// No description provided for @catSupportPhone.
  ///
  /// In en, this message translates to:
  /// **'Support phone'**
  String get catSupportPhone;

  /// No description provided for @catFeaturedOnPage.
  ///
  /// In en, this message translates to:
  /// **'Featured on your page'**
  String get catFeaturedOnPage;

  /// No description provided for @catFeaturedHint.
  ///
  /// In en, this message translates to:
  /// **'Feature live products with the star on Products. Up to 5 show.'**
  String get catFeaturedHint;

  /// No description provided for @catNoFeatured.
  ///
  /// In en, this message translates to:
  /// **'No featured products yet.'**
  String get catNoFeatured;

  /// No description provided for @catSavePage.
  ///
  /// In en, this message translates to:
  /// **'Save brand page'**
  String get catSavePage;

  /// No description provided for @catDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get catDiscardChanges;

  /// No description provided for @catPageSaved.
  ///
  /// In en, this message translates to:
  /// **'Brand page saved'**
  String get catPageSaved;

  /// No description provided for @catFixFields.
  ///
  /// In en, this message translates to:
  /// **'Check the fields marked in red'**
  String get catFixFields;

  /// No description provided for @catProductsSummary.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{1 product · {live} live on atomshop.pk} other{{total} products · {live} live on atomshop.pk}}'**
  String catProductsSummary(int total, int live);

  /// No description provided for @catOnHoldOne.
  ///
  /// In en, this message translates to:
  /// **'{title} is on hold'**
  String catOnHoldOne(String title);

  /// No description provided for @catOnHoldMany.
  ///
  /// In en, this message translates to:
  /// **'{n} products are on hold'**
  String catOnHoldMany(int n);

  /// No description provided for @catMoreActionsFor.
  ///
  /// In en, this message translates to:
  /// **'More actions for {title}'**
  String catMoreActionsFor(String title);

  /// No description provided for @catAvailableUnits.
  ///
  /// In en, this message translates to:
  /// **'{n} available'**
  String catAvailableUnits(int n);

  /// No description provided for @catOnlyLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {n} left'**
  String catOnlyLeft(int n);

  /// No description provided for @catDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {title}?'**
  String catDeleteConfirmTitle(String title);

  /// No description provided for @catNoteHold.
  ///
  /// In en, this message translates to:
  /// **'Atomshop put this on hold: “{reason}” Fix it and send it again.'**
  String catNoteHold(String reason);

  /// No description provided for @catPhotosOf.
  ///
  /// In en, this message translates to:
  /// **'{n} of {max}'**
  String catPhotosOf(int n, int max);

  /// No description provided for @catPhotoN.
  ///
  /// In en, this message translates to:
  /// **'Photo {n}'**
  String catPhotoN(int n);

  /// No description provided for @catRemovePhotoN.
  ///
  /// In en, this message translates to:
  /// **'Remove photo {n}'**
  String catRemovePhotoN(int n);

  /// No description provided for @catCustomerPays.
  ///
  /// In en, this message translates to:
  /// **'Customer pays 3 × {monthly}'**
  String catCustomerPays(String monthly);

  /// No description provided for @catColoursPicked.
  ///
  /// In en, this message translates to:
  /// **'{n} picked'**
  String catColoursPicked(int n);

  /// No description provided for @catRemoveVariant.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String catRemoveVariant(String name);

  /// No description provided for @catShortCount.
  ///
  /// In en, this message translates to:
  /// **'{n} / {max} · shown next to the price'**
  String catShortCount(int n, int max);

  /// No description provided for @catAddToSend.
  ///
  /// In en, this message translates to:
  /// **'Add {list} to send'**
  String catAddToSend(String list);

  /// No description provided for @catFeaturedOf.
  ///
  /// In en, this message translates to:
  /// **'{n} of {max}'**
  String catFeaturedOf(int n, int max);

  /// No description provided for @catUpToSlides.
  ///
  /// In en, this message translates to:
  /// **'Up to {n} slides'**
  String catUpToSlides(int n);

  /// No description provided for @catSlideN.
  ///
  /// In en, this message translates to:
  /// **'Slide {n}'**
  String catSlideN(int n);

  /// No description provided for @catAndMore.
  ///
  /// In en, this message translates to:
  /// **'And {n} more'**
  String catAndMore(int n);

  /// No description provided for @homeAllOutlets.
  ///
  /// In en, this message translates to:
  /// **'All outlets'**
  String get homeAllOutlets;

  /// No description provided for @homeBrandPartner.
  ///
  /// In en, this message translates to:
  /// **'Brand partner'**
  String get homeBrandPartner;

  /// No description provided for @homeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearch;

  /// No description provided for @homeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotifications;

  /// No description provided for @homeMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu and profile'**
  String get homeMenu;

  /// No description provided for @homeSwitchOutlet.
  ///
  /// In en, this message translates to:
  /// **'Switch outlet'**
  String get homeSwitchOutlet;

  /// No description provided for @homeAskBar.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom: what sold best this week…'**
  String get homeAskBar;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get homeDashboard;

  /// No description provided for @homeOrdersToConfirm.
  ///
  /// In en, this message translates to:
  /// **'New orders to confirm'**
  String get homeOrdersToConfirm;

  /// No description provided for @homeUnitsToHandOver.
  ///
  /// In en, this message translates to:
  /// **'AtomPay units to hand over'**
  String get homeUnitsToHandOver;

  /// No description provided for @homeRequestsToQuote.
  ///
  /// In en, this message translates to:
  /// **'Seller & bulk requests to quote'**
  String get homeRequestsToQuote;

  /// No description provided for @homeConfirmOrders.
  ///
  /// In en, this message translates to:
  /// **'Confirm orders'**
  String get homeConfirmOrders;

  /// No description provided for @homeReplyToBulk.
  ///
  /// In en, this message translates to:
  /// **'Reply to bulk'**
  String get homeReplyToBulk;

  /// No description provided for @homeOfflineLegend.
  ///
  /// In en, this message translates to:
  /// **'New orders arrive when you are back online'**
  String get homeOfflineLegend;

  /// No description provided for @homeNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get homeNeedsAttention;

  /// No description provided for @homeNothingToDo.
  ///
  /// In en, this message translates to:
  /// **'All done. New tasks show here as they come in.'**
  String get homeNothingToDo;

  /// No description provided for @homeFromCopy.
  ///
  /// In en, this message translates to:
  /// **'From this phone\'s copy'**
  String get homeFromCopy;

  /// No description provided for @homeYourSales.
  ///
  /// In en, this message translates to:
  /// **'Your sales on Atomshop'**
  String get homeYourSales;

  /// No description provided for @homeReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get homeReport;

  /// No description provided for @homeCashSales.
  ///
  /// In en, this message translates to:
  /// **'Cash sales'**
  String get homeCashSales;

  /// No description provided for @homePaymentsReceived.
  ///
  /// In en, this message translates to:
  /// **'Payments received'**
  String get homePaymentsReceived;

  /// No description provided for @homeUnitsSold.
  ///
  /// In en, this message translates to:
  /// **'Units sold'**
  String get homeUnitsSold;

  /// No description provided for @homeUnitsNote.
  ///
  /// In en, this message translates to:
  /// **'Cash and AtomPay orders'**
  String get homeUnitsNote;

  /// No description provided for @homeLiveOnAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Live on atomshop.pk'**
  String get homeLiveOnAtomshop;

  /// No description provided for @homeNothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing still due'**
  String get homeNothingDue;

  /// No description provided for @homeSalesAndPayments.
  ///
  /// In en, this message translates to:
  /// **'Cash sales and payments'**
  String get homeSalesAndPayments;

  /// No description provided for @homeAllOrders.
  ///
  /// In en, this message translates to:
  /// **'All orders'**
  String get homeAllOrders;

  /// No description provided for @homeOrderPipeline.
  ///
  /// In en, this message translates to:
  /// **'Order pipeline'**
  String get homeOrderPipeline;

  /// No description provided for @homeBulkDeals.
  ///
  /// In en, this message translates to:
  /// **'Bulk deals'**
  String get homeBulkDeals;

  /// No description provided for @homeAllRequests.
  ///
  /// In en, this message translates to:
  /// **'All requests'**
  String get homeAllRequests;

  /// No description provided for @homeOutletsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Your outlets this month'**
  String get homeOutletsThisMonth;

  /// No description provided for @homeOutlets.
  ///
  /// In en, this message translates to:
  /// **'Outlets'**
  String get homeOutlets;

  /// No description provided for @homeOpenPill.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeOpenPill;

  /// No description provided for @homePausedPill.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get homePausedPill;

  /// No description provided for @homeTopProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get homeTopProducts;

  /// No description provided for @homeCashPriceLine.
  ///
  /// In en, this message translates to:
  /// **'{price} cash price'**
  String homeCashPriceLine(String price);

  /// No description provided for @homeCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get homeCatalogue;

  /// No description provided for @homeLatestOrders.
  ///
  /// In en, this message translates to:
  /// **'Latest orders'**
  String get homeLatestOrders;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @homeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get homeCash;

  /// No description provided for @homeAtompay.
  ///
  /// In en, this message translates to:
  /// **'AtomPay'**
  String get homeAtompay;

  /// No description provided for @homeNoOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet. They show here the moment a customer orders.'**
  String get homeNoOrdersYet;

  /// No description provided for @homeRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get homeRecentActivity;

  /// No description provided for @homeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeAll;

  /// No description provided for @homePlanAndBilling.
  ///
  /// In en, this message translates to:
  /// **'Plan & billing'**
  String get homePlanAndBilling;

  /// No description provided for @homeNoAddons.
  ///
  /// In en, this message translates to:
  /// **'no add-ons'**
  String get homeNoAddons;

  /// No description provided for @homeWithProof.
  ///
  /// In en, this message translates to:
  /// **'With the proof photo · sent when online'**
  String get homeWithProof;

  /// No description provided for @homeDeliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get homeDeliver;

  /// No description provided for @homeWorksOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline · sent when online'**
  String get homeWorksOffline;

  /// No description provided for @homeRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get homeRecord;

  /// No description provided for @homeQuoteNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Sending a quote needs internet'**
  String get homeQuoteNeedsInternet;

  /// No description provided for @homeOnlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Online only'**
  String get homeOnlineOnly;

  /// No description provided for @homeNothingOffline.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting on this phone.'**
  String get homeNothingOffline;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Brand Partner'**
  String get homeWelcome;

  /// No description provided for @homeLetsSell.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get your brand selling'**
  String get homeLetsSell;

  /// No description provided for @homeFirstSteps.
  ///
  /// In en, this message translates to:
  /// **'Your first steps'**
  String get homeFirstSteps;

  /// No description provided for @homeAboutTen.
  ///
  /// In en, this message translates to:
  /// **'About 10 minutes'**
  String get homeAboutTen;

  /// No description provided for @homeStuck.
  ///
  /// In en, this message translates to:
  /// **'Stuck? Ask Atom'**
  String get homeStuck;

  /// No description provided for @homeStuckQ.
  ///
  /// In en, this message translates to:
  /// **'\"How do I add a product with colours and storage options?\"'**
  String get homeStuckQ;

  /// No description provided for @homeHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get homeHide;

  /// No description provided for @homeKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get homeKeepIt;

  /// No description provided for @homeSwitchOff.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get homeSwitchOff;

  /// No description provided for @homePay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get homePay;

  /// No description provided for @homeSeeBill.
  ///
  /// In en, this message translates to:
  /// **'See bill'**
  String get homeSeeBill;

  /// No description provided for @homeRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get homeRead;

  /// No description provided for @homeReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get homeReadMore;

  /// No description provided for @homeWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get homeWhatToDo;

  /// No description provided for @homeOnlyYourRole.
  ///
  /// In en, this message translates to:
  /// **'Only what your role allows is shown.'**
  String get homeOnlyYourRole;

  /// No description provided for @homeAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get homeAddProduct;

  /// No description provided for @homeAddProductSub.
  ///
  /// In en, this message translates to:
  /// **'Atomshop reviews it before it goes live'**
  String get homeAddProductSub;

  /// No description provided for @homeStockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get homeStockIn;

  /// No description provided for @homeStockInSub.
  ///
  /// In en, this message translates to:
  /// **'Units that arrived from the factory, with serials'**
  String get homeStockInSub;

  /// No description provided for @homeRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get homeRecordPayment;

  /// No description provided for @homeRecordPaymentSub.
  ///
  /// In en, this message translates to:
  /// **'On a delivered cash order, with a receipt photo'**
  String get homeRecordPaymentSub;

  /// No description provided for @homeSendQuote.
  ///
  /// In en, this message translates to:
  /// **'Send a quote'**
  String get homeSendQuote;

  /// No description provided for @homeSendQuoteSub.
  ///
  /// In en, this message translates to:
  /// **'Reply to a bulk request on WhatsApp'**
  String get homeSendQuoteSub;

  /// No description provided for @homeHandOver.
  ///
  /// In en, this message translates to:
  /// **'Hand over AtomPay unit'**
  String get homeHandOver;

  /// No description provided for @homeHandOverSub.
  ///
  /// In en, this message translates to:
  /// **'To the seller Atomshop gave the order to'**
  String get homeHandOverSub;

  /// No description provided for @homeAskAtom.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom'**
  String get homeAskAtom;

  /// No description provided for @homeAskAtomSub.
  ///
  /// In en, this message translates to:
  /// **'Answers from your own records'**
  String get homeAskAtomSub;

  /// No description provided for @homeNothingForRole.
  ///
  /// In en, this message translates to:
  /// **'Your role has nothing to add here. Ask your brand owner if you need more.'**
  String get homeNothingForRole;

  /// No description provided for @homeSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get homeSales;

  /// No description provided for @homeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'To confirm'**
  String get homeToConfirm;

  /// No description provided for @homeMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get homeMain;

  /// No description provided for @homeAddOutlet.
  ///
  /// In en, this message translates to:
  /// **'Add an outlet'**
  String get homeAddOutlet;

  /// No description provided for @homeManageOutlets.
  ///
  /// In en, this message translates to:
  /// **'Manage outlets'**
  String get homeManageOutlets;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Order number, product or PR number'**
  String get homeSearchHint;

  /// No description provided for @homeScan.
  ///
  /// In en, this message translates to:
  /// **'Scan a serial or IMEI'**
  String get homeScan;

  /// No description provided for @homeTypeMore.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 letters or digits.'**
  String get homeTypeMore;

  /// No description provided for @homeFirstFive.
  ///
  /// In en, this message translates to:
  /// **'Showing the first 5. Open the list to see all.'**
  String get homeFirstFive;

  /// No description provided for @homeSearchTip.
  ///
  /// In en, this message translates to:
  /// **'Search by order number, product, PR number, serial or business.'**
  String get homeSearchTip;

  /// No description provided for @homeSearchTipOffline.
  ///
  /// In en, this message translates to:
  /// **'Search by order number, product, PR number, serial or business. Works offline.'**
  String get homeSearchTipOffline;

  /// No description provided for @homeFromCopyNote.
  ///
  /// In en, this message translates to:
  /// **'No signal: these come from this phone\'s copy.'**
  String get homeFromCopyNote;

  /// No description provided for @homeSalam.
  ///
  /// In en, this message translates to:
  /// **'Salam, {name}'**
  String homeSalam(String name);

  /// No description provided for @homeSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced {time}'**
  String homeSynced(String time);

  /// No description provided for @homeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String homeUpdated(String time);

  /// No description provided for @homeAsOf.
  ///
  /// In en, this message translates to:
  /// **'As of {time}'**
  String homeAsOf(String time);

  /// No description provided for @homeThingsNeedYou.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Nothing needs you right now} =1{1 thing needs you today} other{{n} things need you today}}'**
  String homeThingsNeedYou(int n);

  /// No description provided for @homeOrdersToConfirmLine.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{new order to confirm} other{new orders to confirm}}'**
  String homeOrdersToConfirmLine(int n);

  /// No description provided for @homeUnitsToHandOverLine.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{AtomPay unit to hand over} other{AtomPay units to hand over}}'**
  String homeUnitsToHandOverLine(int n);

  /// No description provided for @homeRequestsLine.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{bulk request to quote} other{bulk requests to quote}}'**
  String homeRequestsLine(int n);

  /// No description provided for @homeOpen.
  ///
  /// In en, this message translates to:
  /// **'{n} open'**
  String homeOpen(int n);

  /// No description provided for @homeLiveOf.
  ///
  /// In en, this message translates to:
  /// **'{live} of {total}'**
  String homeLiveOf(int live, int total);

  /// No description provided for @homeStillDue.
  ///
  /// In en, this message translates to:
  /// **'{amount} still due'**
  String homeStillDue(String amount);

  /// No description provided for @homeReceived.
  ///
  /// In en, this message translates to:
  /// **'Received {amount}'**
  String homeReceived(String amount);

  /// No description provided for @homeOutletLine.
  ///
  /// In en, this message translates to:
  /// **'{orders, plural, =1{1 order · {toConfirm} to confirm} other{{orders} orders · {toConfirm} to confirm}}'**
  String homeOutletLine(int orders, int toConfirm);

  /// No description provided for @homeSold.
  ///
  /// In en, this message translates to:
  /// **'{n} sold'**
  String homeSold(int n);

  /// No description provided for @homePaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until {day}'**
  String homePaidUntil(String day);

  /// No description provided for @homeAgentNote.
  ///
  /// In en, this message translates to:
  /// **'Business totals and reports are for your brand owner. Your role: {role}.'**
  String homeAgentNote(String role);

  /// No description provided for @homeMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Mark 1 order delivered} other{Mark {n} orders delivered}}'**
  String homeMarkDelivered(int n);

  /// No description provided for @homeToRecord.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{{amount} to record from 1 delivered order} other{{amount} to record from {n} delivered orders}}'**
  String homeToRecord(String amount, int n);

  /// No description provided for @homeReplyRequests.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Reply to 1 new bulk request} other{Reply to {n} new bulk requests}}'**
  String homeReplyRequests(int n);

  /// No description provided for @homeDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String homeDoneOf(int done, int total);

  /// No description provided for @homePayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} now'**
  String homePayNow(String amount);

  /// No description provided for @homeOutletsSub.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{{brand} · 1 outlet · this month} other{{brand} · {n} outlets · this month}}'**
  String homeOutletsSub(String brand, int n);

  /// No description provided for @homeUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} used'**
  String homeUsed(int used, int limit);

  /// No description provided for @homeSwitched.
  ///
  /// In en, this message translates to:
  /// **'Now showing {name}'**
  String homeSwitched(String name);

  /// No description provided for @homeAllCount.
  ///
  /// In en, this message translates to:
  /// **'All · {n}'**
  String homeAllCount(int n);

  /// No description provided for @homeOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'Orders · {n}'**
  String homeOrdersCount(String n);

  /// No description provided for @homeProductsCount.
  ///
  /// In en, this message translates to:
  /// **'Products · {n}'**
  String homeProductsCount(String n);

  /// No description provided for @homeBulkCount.
  ///
  /// In en, this message translates to:
  /// **'Bulk · {n}'**
  String homeBulkCount(String n);

  /// No description provided for @homeRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'Bulk requests · {n}'**
  String homeRequestsCount(String n);

  /// No description provided for @homeNoneFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for \"{q}\".'**
  String homeNoneFound(String q);

  /// No description provided for @homeAvailable.
  ///
  /// In en, this message translates to:
  /// **'{n} available'**
  String homeAvailable(int n);

  /// No description provided for @catNewProduct.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get catNewProduct;

  /// No description provided for @catNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{brand} · new'**
  String catNewSubtitle(String brand);

  /// No description provided for @catStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get catStatusLive;

  /// No description provided for @catStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get catStatusInReview;

  /// No description provided for @catStatusOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get catStatusOutOfStock;

  /// No description provided for @catStatusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get catStatusOnHold;

  /// No description provided for @catStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get catStatusClosed;

  /// No description provided for @catListAnd.
  ///
  /// In en, this message translates to:
  /// **'{head} and {last}'**
  String catListAnd(String head, String last);

  /// No description provided for @settingsMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get settingsMyProfile;

  /// No description provided for @settingsProfileSubOwner.
  ///
  /// In en, this message translates to:
  /// **'Contact name, email for sign-in, mobile number'**
  String get settingsProfileSubOwner;

  /// No description provided for @settingsProfileSubAgent.
  ///
  /// In en, this message translates to:
  /// **'Your name and the mobile you sign in with'**
  String get settingsProfileSubAgent;

  /// No description provided for @settingsPasswordSubOwner.
  ///
  /// In en, this message translates to:
  /// **'Changing it signs out your other devices'**
  String get settingsPasswordSubOwner;

  /// No description provided for @settingsPasswordSubAgent.
  ///
  /// In en, this message translates to:
  /// **'The password you sign in with'**
  String get settingsPasswordSubAgent;

  /// No description provided for @settingsSecuritySub.
  ///
  /// In en, this message translates to:
  /// **'PIN, fingerprint, auto-lock'**
  String get settingsSecuritySub;

  /// No description provided for @settingsShopNoteEvery.
  ///
  /// In en, this message translates to:
  /// **'Only you see these. They apply to every outlet.'**
  String get settingsShopNoteEvery;

  /// No description provided for @settingsPayTitle.
  ///
  /// In en, this message translates to:
  /// **'How customers pay you'**
  String get settingsPayTitle;

  /// No description provided for @settingsPaySub.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery, bank transfer, JazzCash or Easypaisa'**
  String get settingsPaySub;

  /// No description provided for @settingsPayCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get settingsPayCod;

  /// No description provided for @settingsPayBank.
  ///
  /// In en, this message translates to:
  /// **'bank transfer'**
  String get settingsPayBank;

  /// No description provided for @settingsPayWallet.
  ///
  /// In en, this message translates to:
  /// **'JazzCash or Easypaisa'**
  String get settingsPayWallet;

  /// No description provided for @settingsOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders and the portal'**
  String get settingsOrdersTitle;

  /// No description provided for @settingsOrdersSub.
  ///
  /// In en, this message translates to:
  /// **'Confirm time and idle sign-out'**
  String get settingsOrdersSub;

  /// No description provided for @settingsOrdersSubSet.
  ///
  /// In en, this message translates to:
  /// **'Confirm within {hours} hours · sign out after {minutes} minutes idle'**
  String settingsOrdersSubSet(int hours, int minutes);

  /// No description provided for @settingsReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get settingsReceipts;

  /// No description provided for @settingsReceiptsSub.
  ///
  /// In en, this message translates to:
  /// **'Note printed on every receipt'**
  String get settingsReceiptsSub;

  /// No description provided for @settingsDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily summary'**
  String get settingsDaily;

  /// No description provided for @settingsDailySub.
  ///
  /// In en, this message translates to:
  /// **'Orders to confirm and quotes running out'**
  String get settingsDailySub;

  /// No description provided for @settingsBrandAccount.
  ///
  /// In en, this message translates to:
  /// **'Brand account'**
  String get settingsBrandAccount;

  /// No description provided for @settingsBrandAccountNote.
  ///
  /// In en, this message translates to:
  /// **'Set by Atomshop. Ask them to change any of it.'**
  String get settingsBrandAccountNote;

  /// No description provided for @settingsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get settingsStatus;

  /// No description provided for @settingsPartnerSince.
  ///
  /// In en, this message translates to:
  /// **'partner since {date}'**
  String settingsPartnerSince(String date);

  /// No description provided for @settingsAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get settingsAccountType;

  /// No description provided for @settingsMultiOutlet.
  ///
  /// In en, this message translates to:
  /// **'Multi-outlet · outlets {used} of {limit}'**
  String settingsMultiOutlet(int used, int limit);

  /// No description provided for @settingsSingleOutlet.
  ///
  /// In en, this message translates to:
  /// **'Single outlet'**
  String get settingsSingleOutlet;

  /// No description provided for @settingsAtompayWhole.
  ///
  /// In en, this message translates to:
  /// **'AtomPay for the whole brand'**
  String get settingsAtompayWhole;

  /// No description provided for @settingsAtompayWholeOn.
  ///
  /// In en, this message translates to:
  /// **'Every product can be sold on AtomPay'**
  String get settingsAtompayWholeOn;

  /// No description provided for @settingsAtompayWholeOff.
  ///
  /// In en, this message translates to:
  /// **'Product by product, as Atomshop sets'**
  String get settingsAtompayWholeOff;

  /// No description provided for @settingsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsOn;

  /// No description provided for @settingsDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left} other{{days} days left}}'**
  String settingsDaysLeft(int days);

  /// No description provided for @settingsTalkSub.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp the partner team'**
  String get settingsTalkSub;

  /// No description provided for @settingsPasswordRow.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsPasswordRow;

  /// No description provided for @settingsPageLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get settingsPageLive;

  /// No description provided for @settingsPageNotLive.
  ///
  /// In en, this message translates to:
  /// **'Not live'**
  String get settingsPageNotLive;

  /// No description provided for @settingsDeleteRowSub.
  ///
  /// In en, this message translates to:
  /// **'Delete your account · password-confirmed'**
  String get settingsDeleteRowSub;

  /// No description provided for @settingsStatusActivePartner.
  ///
  /// In en, this message translates to:
  /// **'Active partner'**
  String get settingsStatusActivePartner;

  /// No description provided for @settingsBioNoneSub.
  ///
  /// In en, this message translates to:
  /// **'Set up a fingerprint or face in the phone\'s settings first'**
  String get settingsBioNoneSub;

  /// No description provided for @settingsBioPinFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN first, then switch this on'**
  String get settingsBioPinFirst;

  /// No description provided for @settingsOfflineCopy.
  ///
  /// In en, this message translates to:
  /// **'Offline copy'**
  String get settingsOfflineCopy;

  /// No description provided for @settingsOfflineCopySub.
  ///
  /// In en, this message translates to:
  /// **'Orders, products, stock, bulk deals · encrypted'**
  String get settingsOfflineCopySub;

  /// No description provided for @settingsBlueKey.
  ///
  /// In en, this message translates to:
  /// **'Blue: offline copy'**
  String get settingsBlueKey;

  /// No description provided for @settingsOfflineCopyNote.
  ///
  /// In en, this message translates to:
  /// **'The offline copy is removed only when you sign out, so nothing waiting is lost.'**
  String get settingsOfflineCopyNote;

  /// No description provided for @settingsMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get settingsMic;

  /// No description provided for @settingsMicSub.
  ///
  /// In en, this message translates to:
  /// **'Only for speaking to Ask Atom'**
  String get settingsMicSub;

  /// No description provided for @settingsSignOutOthersDone.
  ///
  /// In en, this message translates to:
  /// **'Your other devices are signed out'**
  String get settingsSignOutOthersDone;

  /// No description provided for @settingsSignOutOthersNone.
  ///
  /// In en, this message translates to:
  /// **'You weren\'t signed in anywhere else'**
  String get settingsSignOutOthersNone;

  /// No description provided for @settingsSignOutOthersTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices?'**
  String get settingsSignOutOthersTitle;

  /// No description provided for @settingsSignOutOthersBody.
  ///
  /// In en, this message translates to:
  /// **'Every other phone, tablet and the brand portal signs out at once. This phone stays signed in.'**
  String get settingsSignOutOthersBody;

  /// No description provided for @settingsSessionsNote.
  ///
  /// In en, this message translates to:
  /// **'A device you sign out is signed out at once. With Offline working, its saved copy is deleted the next time it goes online. Needs internet.'**
  String get settingsSessionsNote;

  /// No description provided for @settingsSessionsNow.
  ///
  /// In en, this message translates to:
  /// **'Signed in now'**
  String get settingsSessionsNow;

  /// No description provided for @settingsDailyPreviewNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to report today, so no message would go out.'**
  String get settingsDailyPreviewNone;

  /// No description provided for @settingsNoticesSub.
  ///
  /// In en, this message translates to:
  /// **'What you get, quiet hours'**
  String get settingsNoticesSub;

  /// No description provided for @settingsLanguageSubAtom.
  ///
  /// In en, this message translates to:
  /// **'App and Ask Atom'**
  String get settingsLanguageSubAtom;

  /// No description provided for @settingsStorageSubOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline copy and cache'**
  String get settingsStorageSubOffline;

  /// No description provided for @settingsDataSub.
  ///
  /// In en, this message translates to:
  /// **'What is kept, where, and for how long'**
  String get settingsDataSub;

  /// No description provided for @settingsExportSub.
  ///
  /// In en, this message translates to:
  /// **'Orders, payments, products and stock as Excel'**
  String get settingsExportSub;

  /// No description provided for @settingsPrivacySub.
  ///
  /// In en, this message translates to:
  /// **'Saved on the phone, opens offline'**
  String get settingsPrivacySub;

  /// No description provided for @settingsHelpSubAtom.
  ///
  /// In en, this message translates to:
  /// **'Answers, Ask Atom, contact Atomshop'**
  String get settingsHelpSubAtom;

  /// No description provided for @settingsHelpSub.
  ///
  /// In en, this message translates to:
  /// **'Answers, contact Atomshop'**
  String get settingsHelpSub;

  /// No description provided for @settingsBrandPartner.
  ///
  /// In en, this message translates to:
  /// **'Brand partner'**
  String get settingsBrandPartner;

  /// No description provided for @settingsOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can change it.'**
  String get settingsOwnerOnly;

  /// No description provided for @settingsPasswordChangedOwner.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Your other phones are signed out.'**
  String get settingsPasswordChangedOwner;

  /// No description provided for @settingsPasswordSaved.
  ///
  /// In en, this message translates to:
  /// **'Your password is saved.'**
  String get settingsPasswordSaved;

  /// No description provided for @settingsPasswordNoteOwner.
  ///
  /// In en, this message translates to:
  /// **'Changing it signs you out on your other phones. This one stays signed in.'**
  String get settingsPasswordNoteOwner;

  /// No description provided for @settingsPasswordNoteAgent.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters. You sign in with your mobile number and this password.'**
  String get settingsPasswordNoteAgent;

  /// No description provided for @settingsFeedbackOff.
  ///
  /// In en, this message translates to:
  /// **'Feedback from the app isn’t switched on yet. Send it from Help, Talk to Atomshop.'**
  String get settingsFeedbackOff;

  /// No description provided for @settingsExportOff.
  ///
  /// In en, this message translates to:
  /// **'Export from the app isn’t switched on yet. Download your data on the brand portal.'**
  String get settingsExportOff;

  /// No description provided for @settingsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get settingsDeleteConfirmTitle;

  /// No description provided for @settingsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your brand page and live products come off atomshop.pk, and everyone on your team is signed out. It can’t be undone.'**
  String get settingsDeleteConfirmBody;

  /// No description provided for @settingsDeleteMine.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get settingsDeleteMine;

  /// No description provided for @settingsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get settingsDeleted;

  /// No description provided for @settingsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteTitle;

  /// No description provided for @settingsDeleteWarn.
  ///
  /// In en, this message translates to:
  /// **'This deletes your Brand Partner login. It can’t be undone.'**
  String get settingsDeleteWarn;

  /// No description provided for @settingsDeleteWarnBold.
  ///
  /// In en, this message translates to:
  /// **'This deletes your Brand Partner login.'**
  String get settingsDeleteWarnBold;

  /// No description provided for @settingsDeleteSignIn.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in on every phone and the portal'**
  String get settingsDeleteSignIn;

  /// No description provided for @settingsDeletePage.
  ///
  /// In en, this message translates to:
  /// **'Brand page and live products'**
  String get settingsDeletePage;

  /// No description provided for @settingsDeleteTakenOff.
  ///
  /// In en, this message translates to:
  /// **'Taken off atomshop.pk'**
  String get settingsDeleteTakenOff;

  /// No description provided for @settingsDeleteRecords.
  ///
  /// In en, this message translates to:
  /// **'Orders, payments and invoices'**
  String get settingsDeleteRecords;

  /// No description provided for @settingsDeleteWhyKept.
  ///
  /// In en, this message translates to:
  /// **'Order and payment records are kept because the law needs them. Open orders must be delivered or cancelled first. Export your data first if you want a copy.'**
  String get settingsDeleteWhyKept;

  /// No description provided for @settingsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get settingsStatusActive;

  /// No description provided for @settingsStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get settingsStatusInactive;

  /// No description provided for @settingsTypeName.
  ///
  /// In en, this message translates to:
  /// **'Type your name'**
  String get settingsTypeName;

  /// No description provided for @settingsTypeMobile.
  ///
  /// In en, this message translates to:
  /// **'Type a mobile number like 0300 1234567'**
  String get settingsTypeMobile;

  /// No description provided for @settingsMax100.
  ///
  /// In en, this message translates to:
  /// **'At most 100 characters'**
  String get settingsMax100;

  /// No description provided for @settingsPasswordsDiffer.
  ///
  /// In en, this message translates to:
  /// **'The two passwords don’t match'**
  String get settingsPasswordsDiffer;

  /// No description provided for @settingsPasswordReused.
  ///
  /// In en, this message translates to:
  /// **'Choose a password you haven’t used here'**
  String get settingsPasswordReused;

  /// No description provided for @notifKindReviews.
  ///
  /// In en, this message translates to:
  /// **'Product reviews'**
  String get notifKindReviews;

  /// No description provided for @notifLiveOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Live alerts is off.'**
  String get notifLiveOffTitle;

  /// No description provided for @notifLiveOffOwner.
  ///
  /// In en, this message translates to:
  /// **'Nothing pops up on your phone; everything still reaches the inbox. Switch it on in Plan & billing.'**
  String get notifLiveOffOwner;

  /// No description provided for @notifLiveOffAgent.
  ///
  /// In en, this message translates to:
  /// **'Nothing pops up on your phone; everything still reaches the inbox.'**
  String get notifLiveOffAgent;

  /// No description provided for @helpRepliesOff.
  ///
  /// In en, this message translates to:
  /// **'Replies from the app aren’t switched on yet. WhatsApp Atomshop instead.'**
  String get helpRepliesOff;

  /// No description provided for @helpAtomshopLogo.
  ///
  /// In en, this message translates to:
  /// **'Atomshop.pk, Pay in Steps'**
  String get helpAtomshopLogo;

  /// No description provided for @syncLastSyncWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last sync {when}. 1 change is waiting to send.} other{Last sync {when}. {count} changes are waiting to send.}}'**
  String syncLastSyncWaiting(String when, int count);

  /// No description provided for @syncAllSentExcept.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Everything is sent, except 1 that needs you.} other{Everything is sent, except {count} that need you.}}'**
  String syncAllSentExcept(int count);

  /// No description provided for @syncWorksUntilLead.
  ///
  /// In en, this message translates to:
  /// **'Works offline until'**
  String get syncWorksUntilLead;

  /// No description provided for @syncUntilWhy.
  ///
  /// In en, this message translates to:
  /// **'paid-until date'**
  String get syncUntilWhy;

  /// No description provided for @syncPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get syncPhotos;

  /// No description provided for @syncPhotosWaiting.
  ///
  /// In en, this message translates to:
  /// **'{n} waiting to upload'**
  String syncPhotosWaiting(int n);

  /// No description provided for @syncPhotosNone.
  ///
  /// In en, this message translates to:
  /// **'Proof and receipt photos go with their change'**
  String get syncPhotosNone;

  /// No description provided for @syncPhones.
  ///
  /// In en, this message translates to:
  /// **'Phones signed in'**
  String get syncPhones;

  /// No description provided for @syncPhonesTeam.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You and 1 team phone} other{You and {count} team phones}}'**
  String syncPhonesTeam(int count);

  /// No description provided for @syncPhonesThis.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get syncPhonesThis;

  /// No description provided for @syncPhonesMore.
  ///
  /// In en, this message translates to:
  /// **'This phone and {count} more'**
  String syncPhonesMore(int count);

  /// No description provided for @syncPhonesLoading.
  ///
  /// In en, this message translates to:
  /// **'Your phones and your team’s'**
  String get syncPhonesLoading;

  /// No description provided for @syncEncrypted.
  ///
  /// In en, this message translates to:
  /// **'encrypted'**
  String get syncEncrypted;

  /// No description provided for @syncCopyLocked.
  ///
  /// In en, this message translates to:
  /// **'Unlock with your PIN to see what is kept here'**
  String get syncCopyLocked;

  /// No description provided for @syncCopyNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. The first sync copies your work.'**
  String get syncCopyNothing;

  /// No description provided for @syncReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Your account is read-only: changes wait here, payments still go.'**
  String get syncReadOnly;

  /// No description provided for @syncChanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change} other{{count} changes}}'**
  String syncChanges(int count);

  /// No description provided for @syncUndoNoteFull.
  ///
  /// In en, this message translates to:
  /// **'Undo works only before it is sent. Undoing a stock in also undoes anything later that used its units.'**
  String get syncUndoNoteFull;

  /// No description provided for @syncPhotosLine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo goes with these changes} other{{count} photos go with these changes}}'**
  String syncPhotosLine(int count);

  /// No description provided for @syncPhotoWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get syncPhotoWaiting;

  /// No description provided for @syncCheckIt.
  ///
  /// In en, this message translates to:
  /// **'Check it'**
  String get syncCheckIt;

  /// No description provided for @syncFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get syncFix;

  /// No description provided for @syncAlreadyMoved.
  ///
  /// In en, this message translates to:
  /// **'It is {now} on the server now.'**
  String syncAlreadyMoved(String now);

  /// No description provided for @syncReasonOrderChanged.
  ///
  /// In en, this message translates to:
  /// **'Order changed meanwhile'**
  String get syncReasonOrderChanged;

  /// No description provided for @syncReasonDealChanged.
  ///
  /// In en, this message translates to:
  /// **'Deal changed meanwhile'**
  String get syncReasonDealChanged;

  /// No description provided for @syncReasonRequestChanged.
  ///
  /// In en, this message translates to:
  /// **'Request changed meanwhile'**
  String get syncReasonRequestChanged;

  /// No description provided for @syncReasonChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed meanwhile'**
  String get syncReasonChanged;

  /// No description provided for @syncReasonSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial already taken'**
  String get syncReasonSerial;

  /// No description provided for @syncReasonNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found any more'**
  String get syncReasonNotFound;

  /// No description provided for @syncReasonNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Your role doesn’t allow this'**
  String get syncReasonNotAllowed;

  /// No description provided for @syncReasonReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Account is read-only'**
  String get syncReasonReadOnly;

  /// No description provided for @syncReasonAddon.
  ///
  /// In en, this message translates to:
  /// **'Add-on is off'**
  String get syncReasonAddon;

  /// No description provided for @syncReasonRefused.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get syncReasonRefused;

  /// No description provided for @syncReasonCantSend.
  ///
  /// In en, this message translates to:
  /// **'This app can’t send it'**
  String get syncReasonCantSend;

  /// No description provided for @syncReasonNotApplied.
  ///
  /// In en, this message translates to:
  /// **'Not applied'**
  String get syncReasonNotApplied;

  /// No description provided for @syncClashTitle.
  ///
  /// In en, this message translates to:
  /// **'Serial already in stock'**
  String get syncClashTitle;

  /// No description provided for @syncClashOther.
  ///
  /// In en, this message translates to:
  /// **'Already on the server'**
  String get syncClashOther;

  /// No description provided for @syncClashMine.
  ///
  /// In en, this message translates to:
  /// **'You added it'**
  String get syncClashMine;

  /// No description provided for @syncClashWhat.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get syncClashWhat;

  /// No description provided for @syncClashTwice.
  ///
  /// In en, this message translates to:
  /// **'Same box, counted twice'**
  String get syncClashTwice;

  /// No description provided for @syncClashTwiceSub.
  ///
  /// In en, this message translates to:
  /// **'Keep the one already in stock. Yours is dropped; stock stays right.'**
  String get syncClashTwiceSub;

  /// No description provided for @syncClashTwiceDo.
  ///
  /// In en, this message translates to:
  /// **'Drop mine'**
  String get syncClashTwiceDo;

  /// No description provided for @syncClashMove.
  ///
  /// In en, this message translates to:
  /// **'It is now at {where}'**
  String syncClashMove(String where);

  /// No description provided for @syncClashMoveSub.
  ///
  /// In en, this message translates to:
  /// **'Keep the unit and move it to {where}.'**
  String syncClashMoveSub(String where);

  /// No description provided for @syncClashMoveDo.
  ///
  /// In en, this message translates to:
  /// **'Move it to {where}'**
  String syncClashMoveDo(String where);

  /// No description provided for @syncClashWrong.
  ///
  /// In en, this message translates to:
  /// **'I scanned the wrong box'**
  String get syncClashWrong;

  /// No description provided for @syncClashWrongSub.
  ///
  /// In en, this message translates to:
  /// **'Scan the box you meant to add.'**
  String get syncClashWrongSub;

  /// No description provided for @syncClashWrongDo.
  ///
  /// In en, this message translates to:
  /// **'Scan the right box'**
  String get syncClashWrongDo;

  /// No description provided for @syncClashDiscard.
  ///
  /// In en, this message translates to:
  /// **'Drop this change'**
  String get syncClashDiscard;

  /// No description provided for @syncClashDiscardSub.
  ///
  /// In en, this message translates to:
  /// **'The server keeps what it has. Nothing of yours is applied.'**
  String get syncClashDiscardSub;

  /// No description provided for @syncClashRest.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The other 1 unit of this stock in are sent again on their own.} other{The other {count} units of this stock in are sent again on their own.}}'**
  String syncClashRest(int count);

  /// No description provided for @syncClashFixed.
  ///
  /// In en, this message translates to:
  /// **'Sorted. The rest goes with the next sync.'**
  String get syncClashFixed;

  /// No description provided for @syncClashGone.
  ///
  /// In en, this message translates to:
  /// **'This change has already been sorted.'**
  String get syncClashGone;

  /// No description provided for @syncClashSentFirst.
  ///
  /// In en, this message translates to:
  /// **'Sent first'**
  String get syncClashSentFirst;

  /// No description provided for @syncSendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sending your changes'**
  String get syncSendingTitle;

  /// No description provided for @syncStepOrders.
  ///
  /// In en, this message translates to:
  /// **'Deliveries & payments'**
  String get syncStepOrders;

  /// No description provided for @syncStepBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk deals'**
  String get syncStepBulk;

  /// No description provided for @syncStepStock.
  ///
  /// In en, this message translates to:
  /// **'Stock in & moves'**
  String get syncStepStock;

  /// No description provided for @syncStepDown.
  ///
  /// In en, this message translates to:
  /// **'Getting others’ changes'**
  String get syncStepDown;

  /// No description provided for @syncStepSent.
  ///
  /// In en, this message translates to:
  /// **'{n} sent'**
  String syncStepSent(int n);

  /// No description provided for @syncStepSending.
  ///
  /// In en, this message translates to:
  /// **'sending {n} of {total}'**
  String syncStepSending(int n, int total);

  /// No description provided for @syncStepWaiting.
  ///
  /// In en, this message translates to:
  /// **'{n} waiting'**
  String syncStepWaiting(int n);

  /// No description provided for @syncStepNext.
  ///
  /// In en, this message translates to:
  /// **'next'**
  String get syncStepNext;

  /// No description provided for @syncStepDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get syncStepDone;

  /// No description provided for @syncStepNothing.
  ///
  /// In en, this message translates to:
  /// **'nothing to send'**
  String get syncStepNothing;

  /// No description provided for @syncSignalNote.
  ///
  /// In en, this message translates to:
  /// **'If the signal drops, it stops and carries on later from the same place. A change is never sent twice.'**
  String get syncSignalNote;

  /// No description provided for @syncAllDone.
  ///
  /// In en, this message translates to:
  /// **'All sent. This phone is up to date.'**
  String get syncAllDone;

  /// No description provided for @syncUpdateAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Atombrand to send your changes'**
  String get syncUpdateAppTitle;

  /// No description provided for @syncUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This version{version} can’t send to Atomshop any more. Your 1 change is safe on this phone and go out right after the update.} other{This version{version} can’t send to Atomshop any more. Your {count} changes are safe on this phone and go out right after the update.}}'**
  String syncUpdateBody(String version, int count);

  /// No description provided for @syncUpdateOnPlay.
  ///
  /// In en, this message translates to:
  /// **'Update on Google Play'**
  String get syncUpdateOnPlay;

  /// No description provided for @syncUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Keep working, update later'**
  String get syncUpdateLater;

  /// No description provided for @syncUpdateSafe.
  ///
  /// In en, this message translates to:
  /// **'Updating never deletes what is saved on the phone.'**
  String get syncUpdateSafe;

  /// No description provided for @syncYours.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get syncYours;

  /// No description provided for @syncYourTeam.
  ///
  /// In en, this message translates to:
  /// **'Your team'**
  String get syncYourTeam;

  /// No description provided for @syncNowTag.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get syncNowTag;

  /// No description provided for @syncSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get syncSignOut;

  /// No description provided for @syncSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced {when}'**
  String syncSynced(String when);

  /// No description provided for @syncLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync {when}'**
  String syncLastSync(String when);

  /// No description provided for @syncOfflineUntil.
  ///
  /// In en, this message translates to:
  /// **'works offline until {day}'**
  String syncOfflineUntil(String day);

  /// No description provided for @syncNotSent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change not sent} other{{count} changes not sent}}'**
  String syncNotSent(int count);

  /// No description provided for @syncNothingWaiting.
  ///
  /// In en, this message translates to:
  /// **'nothing waiting'**
  String get syncNothingWaiting;

  /// No description provided for @syncAllOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other phones'**
  String get syncAllOut;

  /// No description provided for @syncAllOutTeam.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other phones, team too'**
  String get syncAllOutTeam;

  /// No description provided for @syncPhonesNote.
  ///
  /// In en, this message translates to:
  /// **'A phone that is signed out deletes its saved copy the next time it goes online. Lost a phone? Sign it out here.'**
  String get syncPhonesNote;

  /// No description provided for @syncPhonesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Only this phone is signed in.'**
  String get syncPhonesEmpty;

  /// No description provided for @syncUnknownPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get syncUnknownPhone;

  /// No description provided for @syncDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{yesterday} other{{count} days ago}}'**
  String syncDaysAgo(int count);

  /// No description provided for @syncSignOutThisTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out this phone?'**
  String get syncSignOutThisTitle;

  /// No description provided for @syncSignOutOwnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out {owner}’s phone?'**
  String syncSignOutOwnerTitle(String owner);

  /// No description provided for @syncUnsentWarn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change on that phone was never sent. If you sign it out, they are lost.} other{{count} changes on that phone were never sent. If you sign it out, they are lost.}}'**
  String syncUnsentWarn(int count);

  /// No description provided for @syncUnsentAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask {owner} to open the app with internet first, if you can.'**
  String syncUnsentAsk(String owner);

  /// No description provided for @syncNextOnline.
  ///
  /// In en, this message translates to:
  /// **'Next time it goes online'**
  String get syncNextOnline;

  /// No description provided for @syncCopyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Its saved copy is deleted'**
  String get syncCopyDeleted;

  /// No description provided for @syncLoginYours.
  ///
  /// In en, this message translates to:
  /// **'Your login'**
  String get syncLoginYours;

  /// No description provided for @syncLoginOwner.
  ///
  /// In en, this message translates to:
  /// **'{owner}’s login'**
  String syncLoginOwner(String owner);

  /// No description provided for @syncLoginStays.
  ///
  /// In en, this message translates to:
  /// **'Stays; can sign in again'**
  String get syncLoginStays;

  /// No description provided for @syncStopCompletely.
  ///
  /// In en, this message translates to:
  /// **'To stop someone completely, switch them off in Team & roles instead.'**
  String get syncStopCompletely;

  /// No description provided for @syncKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get syncKeepIt;

  /// No description provided for @syncSignItOut.
  ///
  /// In en, this message translates to:
  /// **'Sign it out'**
  String get syncSignItOut;

  /// No description provided for @syncSignedOutOk.
  ///
  /// In en, this message translates to:
  /// **'That phone is signed out. Its copy is deleted the next time it connects.'**
  String get syncSignedOutOk;

  /// No description provided for @syncAllOutOk.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No other phone was signed in.} =1{1 phone is signed out.} other{{count} phones are signed out.}}'**
  String syncAllOutOk(int count);

  /// No description provided for @syncAllOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out the other phones?'**
  String get syncAllOutTitle;

  /// No description provided for @syncAllOutBody.
  ///
  /// In en, this message translates to:
  /// **'Each one deletes its saved copy the next time it goes online. Changes not sent from those phones are lost.'**
  String get syncAllOutBody;

  /// No description provided for @syncNoInternetBody.
  ///
  /// In en, this message translates to:
  /// **'Atombrand needs a connection to show and save your work. Turn on mobile data or Wi-Fi.'**
  String get syncNoInternetBody;

  /// No description provided for @syncNoInternetDraft.
  ///
  /// In en, this message translates to:
  /// **'What you were typing is kept on this screen. Nothing was saved yet; save it when you are back online.'**
  String get syncNoInternetDraft;

  /// No description provided for @syncEndedBodyFull.
  ///
  /// In en, this message translates to:
  /// **'Offline working has ended on your account. First, everything saved on this phone is sent, so nothing is lost.'**
  String get syncEndedBodyFull;

  /// No description provided for @syncEndedSend.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Send 1 waiting change} other{Send {count} waiting changes}}'**
  String syncEndedSend(int count);

  /// No description provided for @syncEndedPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Send 1 photo} other{Send {count} photos}}'**
  String syncEndedPhotos(int count);

  /// No description provided for @syncEndedDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete the copy on this phone'**
  String get syncEndedDelete;

  /// No description provided for @syncEndedSendingTag.
  ///
  /// In en, this message translates to:
  /// **'sending'**
  String get syncEndedSendingTag;

  /// No description provided for @syncEndedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change needs you before the copy can be deleted.} other{{count} changes need you before the copy can be deleted.}}'**
  String syncEndedAttention(int count);

  /// No description provided for @syncContinueOnline.
  ///
  /// In en, this message translates to:
  /// **'Continue online'**
  String get syncContinueOnline;

  /// No description provided for @syncLimitDays.
  ///
  /// In en, this message translates to:
  /// **'You have worked offline for {days} days. Connect once so we can send your work and check your account.'**
  String syncLimitDays(int days);

  /// No description provided for @syncPlanEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan ended on {day}'**
  String syncPlanEndedTitle(String day);

  /// No description provided for @syncPlanEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Offline use stops when your plan ends. Connect to the internet so we can sync your work and you can renew on Plan & billing.'**
  String get syncPlanEndedBody;

  /// No description provided for @syncSafeHere.
  ///
  /// In en, this message translates to:
  /// **'Safe on this phone'**
  String get syncSafeHere;

  /// No description provided for @syncSafeHereSub.
  ///
  /// In en, this message translates to:
  /// **'Nothing is lost. It all syncs when you connect.'**
  String get syncSafeHereSub;

  /// No description provided for @syncLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {when}'**
  String syncLastSynced(String when);

  /// No description provided for @syncNotSyncedYet.
  ///
  /// In en, this message translates to:
  /// **'Not synced on this phone yet'**
  String get syncNotSyncedYet;

  /// No description provided for @syncLimitWhy.
  ///
  /// In en, this message translates to:
  /// **'the offline limit'**
  String get syncLimitWhy;

  /// No description provided for @syncOpenWifi.
  ///
  /// In en, this message translates to:
  /// **'Open Wi-Fi settings'**
  String get syncOpenWifi;

  /// No description provided for @syncLookUpOnly.
  ///
  /// In en, this message translates to:
  /// **'You can still look up orders, deals and stock, but not change them.'**
  String get syncLookUpOnly;

  /// No description provided for @syncHoldTag.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get syncHoldTag;

  /// No description provided for @syncHoldTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is on hold'**
  String get syncHoldTitle;

  /// No description provided for @syncHoldBody.
  ///
  /// In en, this message translates to:
  /// **'This phone was signed out and its offline copy deleted. Ask your brand owner, or message Atomshop.'**
  String get syncHoldBody;

  /// No description provided for @syncHoldSafe.
  ///
  /// In en, this message translates to:
  /// **'Work you recorded before was sent to the brand. This phone no longer keeps its offline copy.'**
  String get syncHoldSafe;

  /// No description provided for @syncHoldWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Message Atomshop on WhatsApp'**
  String get syncHoldWhatsApp;

  /// No description provided for @syncHoldSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with another account'**
  String get syncHoldSignIn;

  /// No description provided for @syncOnlineTag.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syncOnlineTag;

  /// No description provided for @syncReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting {where} ready for offline'**
  String syncReadyTitle(String where);

  /// No description provided for @syncReadyBody.
  ///
  /// In en, this message translates to:
  /// **'We are copying your brand’s orders, deals and stock to this phone, encrypted. Keep the app open: on Wi-Fi this takes about a minute.'**
  String get syncReadyBody;

  /// No description provided for @syncReadyOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders and payments'**
  String get syncReadyOrders;

  /// No description provided for @syncReadyBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk requests and deals'**
  String get syncReadyBulk;

  /// No description provided for @syncReadyProducts.
  ///
  /// In en, this message translates to:
  /// **'Products and prices'**
  String get syncReadyProducts;

  /// No description provided for @syncReadyStock.
  ///
  /// In en, this message translates to:
  /// **'Stock and serial numbers'**
  String get syncReadyStock;

  /// No description provided for @syncReadyAtompay.
  ///
  /// In en, this message translates to:
  /// **'AtomPay orders'**
  String get syncReadyAtompay;

  /// No description provided for @syncReadyPhotos.
  ///
  /// In en, this message translates to:
  /// **'Delivery and receipt photos'**
  String get syncReadyPhotos;

  /// No description provided for @syncStartNow.
  ///
  /// In en, this message translates to:
  /// **'Start working now'**
  String get syncStartNow;

  /// No description provided for @syncReadyNote.
  ///
  /// In en, this message translates to:
  /// **'Photos finish in the background. Sending quotes and new bulk requests need internet.'**
  String get syncReadyNote;

  /// No description provided for @syncReadyFailed.
  ///
  /// In en, this message translates to:
  /// **'The copy stopped part-way. It carries on by itself when there is signal.'**
  String get syncReadyFailed;

  /// No description provided for @syncReadyDone.
  ///
  /// In en, this message translates to:
  /// **'Ready. This phone works without signal now.'**
  String get syncReadyDone;

  /// No description provided for @stockTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockTitle;

  /// No description provided for @stockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in'**
  String get stockIn;

  /// No description provided for @stockMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get stockMove;

  /// No description provided for @stockAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get stockAdjust;

  /// No description provided for @stockHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get stockHistory;

  /// No description provided for @stockHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock history'**
  String get stockHistoryTitle;

  /// No description provided for @stockListTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock list'**
  String get stockListTitle;

  /// No description provided for @stockMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move stock'**
  String get stockMoveTitle;

  /// No description provided for @stockAdjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get stockAdjustTitle;

  /// No description provided for @stockWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Warehouses'**
  String get stockWarehouses;

  /// No description provided for @stockWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get stockWarehouse;

  /// No description provided for @stockOutlet.
  ///
  /// In en, this message translates to:
  /// **'Outlet'**
  String get stockOutlet;

  /// No description provided for @stockAllOutlets.
  ///
  /// In en, this message translates to:
  /// **'All outlets'**
  String get stockAllOutlets;

  /// No description provided for @stockAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get stockAll;

  /// No description provided for @stockAllProducts.
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get stockAllProducts;

  /// No description provided for @stockProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get stockProduct;

  /// No description provided for @stockProductVariant.
  ///
  /// In en, this message translates to:
  /// **'Product and variant'**
  String get stockProductVariant;

  /// No description provided for @stockProductOrSku.
  ///
  /// In en, this message translates to:
  /// **'Product or SKU'**
  String get stockProductOrSku;

  /// No description provided for @stockSerialOrImei.
  ///
  /// In en, this message translates to:
  /// **'Serial or IMEI'**
  String get stockSerialOrImei;

  /// No description provided for @stockSerialOrProduct.
  ///
  /// In en, this message translates to:
  /// **'Serial or product'**
  String get stockSerialOrProduct;

  /// No description provided for @stockTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Type the number'**
  String get stockTypeNumber;

  /// No description provided for @stockScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get stockScan;

  /// No description provided for @stockLookUp.
  ///
  /// In en, this message translates to:
  /// **'Look it up'**
  String get stockLookUp;

  /// No description provided for @stockAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get stockAdd;

  /// No description provided for @stockEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get stockEdit;

  /// No description provided for @stockOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get stockOpen;

  /// No description provided for @stockDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stockDone;

  /// No description provided for @stockChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get stockChange;

  /// No description provided for @stockRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get stockRemove;

  /// No description provided for @stockNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get stockNote;

  /// No description provided for @stockOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get stockOptional;

  /// No description provided for @stockRequired.
  ///
  /// In en, this message translates to:
  /// **'(required)'**
  String get stockRequired;

  /// No description provided for @stockDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get stockDate;

  /// No description provided for @stockReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get stockReason;

  /// No description provided for @stockPrefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get stockPrefix;

  /// No description provided for @stockStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get stockStandard;

  /// No description provided for @stockOutletFilter.
  ///
  /// In en, this message translates to:
  /// **'Outlet: {name}'**
  String stockOutletFilter(String name);

  /// No description provided for @stockCategoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Category: {name}'**
  String stockCategoryFilter(String name);

  /// No description provided for @stockCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get stockCategory;

  /// No description provided for @stockNoRecentIn.
  ///
  /// In en, this message translates to:
  /// **'Nothing received in the last 30 days.'**
  String get stockNoRecentIn;

  /// No description provided for @stockCameraOffTitle.
  ///
  /// In en, this message translates to:
  /// **'The camera is off for Brand Partner'**
  String get stockCameraOffTitle;

  /// No description provided for @stockCameraOffBody.
  ///
  /// In en, this message translates to:
  /// **'To scan serials and IMEIs, allow the camera in your phone\'s settings. You can also type the number.'**
  String get stockCameraOffBody;

  /// No description provided for @stockCameraFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'The camera didn\'t start'**
  String get stockCameraFailedTitle;

  /// No description provided for @stockCameraFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Close other apps using the camera and try again, or type the number.'**
  String get stockCameraFailedBody;

  /// No description provided for @stockOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get stockOpenSettings;

  /// No description provided for @catVarPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category first. The options follow it: storage for phones, screen size for TVs.'**
  String get catVarPickCategory;

  /// No description provided for @catVarOneVersion.
  ///
  /// In en, this message translates to:
  /// **'Products in this category come in one version.'**
  String get catVarOneVersion;

  /// No description provided for @catVarNoColours.
  ///
  /// In en, this message translates to:
  /// **'Atomshop hasn\'t added colours yet. Ask support for the ones you need.'**
  String get catVarNoColours;

  /// No description provided for @catVarNoSizes.
  ///
  /// In en, this message translates to:
  /// **'Atomshop hasn\'t added screen sizes yet. Ask support for the ones you need.'**
  String get catVarNoSizes;

  /// No description provided for @catVarNoStorage.
  ///
  /// In en, this message translates to:
  /// **'Atomshop hasn\'t added storage options yet. Ask support for the ones you need.'**
  String get catVarNoStorage;

  /// No description provided for @syncNoTeamPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone signed in yet'**
  String get syncNoTeamPhone;

  /// No description provided for @teamKpiOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders handled this month'**
  String get teamKpiOrders;

  /// No description provided for @teamKpiOrdersNote.
  ///
  /// In en, this message translates to:
  /// **'Confirmed or delivered'**
  String get teamKpiOrdersNote;

  /// No description provided for @teamOrdersMonthN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 order this month} other{{n} orders this month}}'**
  String teamOrdersMonthN(int n);

  /// No description provided for @teamKpiHandled.
  ///
  /// In en, this message translates to:
  /// **'Orders handled · {month}'**
  String teamKpiHandled(String month);

  /// No description provided for @teamKpiHandledNote.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} confirmed, {delivered} delivered'**
  String teamKpiHandledNote(int confirmed, int delivered);

  /// No description provided for @teamKpiPaid.
  ///
  /// In en, this message translates to:
  /// **'Payments recorded · {month}'**
  String teamKpiPaid(String month);

  /// No description provided for @teamKpiPaidNote.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 payment} other{{n} payments}}'**
  String teamKpiPaidNote(int n);

  /// No description provided for @teamPhonesRow.
  ///
  /// In en, this message translates to:
  /// **'Sign out their phones'**
  String get teamPhonesRow;

  /// No description provided for @teamPhonesSub.
  ///
  /// In en, this message translates to:
  /// **'They can sign in again'**
  String get teamPhonesSub;

  /// No description provided for @teamPhonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out {name}\'s phones?'**
  String teamPhonesTitle(String name);

  /// No description provided for @teamPhonesBody.
  ///
  /// In en, this message translates to:
  /// **'Every phone they use is signed out. A phone with an offline copy deletes it the next time it goes online, with anything it never sent. Their login stays.'**
  String get teamPhonesBody;

  /// No description provided for @teamPhonesButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out phones'**
  String get teamPhonesButton;

  /// No description provided for @teamPhonesDone.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s phones are signed out.'**
  String teamPhonesDone(String name);

  /// No description provided for @teamPhonesNone.
  ///
  /// In en, this message translates to:
  /// **'No phone was signed in.'**
  String get teamPhonesNone;

  /// No description provided for @teamBlurbManager.
  ///
  /// In en, this message translates to:
  /// **'Everything except outlets, settings and billing'**
  String get teamBlurbManager;

  /// No description provided for @teamBlurbOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders, payments, AtomPay; sees products and stock'**
  String get teamBlurbOrders;

  /// No description provided for @teamBlurbBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk requests, quotes and deals'**
  String get teamBlurbBulk;

  /// No description provided for @teamBlurbStock.
  ///
  /// In en, this message translates to:
  /// **'Stock in, adjust, move; warehouses'**
  String get teamBlurbStock;

  /// No description provided for @teamBlurbMarketing.
  ///
  /// In en, this message translates to:
  /// **'Products and the brand page'**
  String get teamBlurbMarketing;

  /// No description provided for @teamBlurbAccountant.
  ///
  /// In en, this message translates to:
  /// **'Totals, payments, reports and exports'**
  String get teamBlurbAccountant;

  /// No description provided for @stockProductFilter.
  ///
  /// In en, this message translates to:
  /// **'Product: {name}'**
  String stockProductFilter(String name);

  /// No description provided for @stockWhenFilter.
  ///
  /// In en, this message translates to:
  /// **'When: {period}'**
  String stockWhenFilter(String period);

  /// No description provided for @stockWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get stockWhen;

  /// No description provided for @stockNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match for \"{query}\"'**
  String stockNoMatch(String query);

  /// No description provided for @stockNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get stockNothingHere;

  /// No description provided for @stockNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet.'**
  String get stockNothingYet;

  /// No description provided for @stockOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get stockOther;

  /// No description provided for @stockTrackingImei.
  ///
  /// In en, this message translates to:
  /// **'IMEI'**
  String get stockTrackingImei;

  /// No description provided for @stockTrackingSerial.
  ///
  /// In en, this message translates to:
  /// **'serial number'**
  String get stockTrackingSerial;

  /// No description provided for @stockTrackingAuto.
  ///
  /// In en, this message translates to:
  /// **'auto number'**
  String get stockTrackingAuto;

  /// No description provided for @stockNumberedBy.
  ///
  /// In en, this message translates to:
  /// **'numbered by {what}'**
  String stockNumberedBy(String what);

  /// No description provided for @stockWhTypeFactory.
  ///
  /// In en, this message translates to:
  /// **'Factory store'**
  String get stockWhTypeFactory;

  /// No description provided for @stockWhTypeGodown.
  ///
  /// In en, this message translates to:
  /// **'Godown'**
  String get stockWhTypeGodown;

  /// No description provided for @stockWhTypeStore.
  ///
  /// In en, this message translates to:
  /// **'Outlet store'**
  String get stockWhTypeStore;

  /// No description provided for @stockSerialTwice.
  ///
  /// In en, this message translates to:
  /// **'Entered twice'**
  String get stockSerialTwice;

  /// No description provided for @stockSerialImei15.
  ///
  /// In en, this message translates to:
  /// **'IMEI should be 15 digits'**
  String get stockSerialImei15;

  /// No description provided for @stockSerialCheckDigit.
  ///
  /// In en, this message translates to:
  /// **'Last digit doesn’t match'**
  String get stockSerialCheckDigit;

  /// No description provided for @stockSerialLength.
  ///
  /// In en, this message translates to:
  /// **'Should be 3 to 60 characters'**
  String get stockSerialLength;

  /// No description provided for @stockSerialInStock.
  ///
  /// In en, this message translates to:
  /// **'Already in stock'**
  String get stockSerialInStock;

  /// No description provided for @stockChooseWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Choose the warehouse'**
  String get stockChooseWarehouse;

  /// No description provided for @stockChooseProduct.
  ///
  /// In en, this message translates to:
  /// **'Choose the product'**
  String get stockChooseProduct;

  /// No description provided for @stockInEnterQty.
  ///
  /// In en, this message translates to:
  /// **'Enter how many units arrived'**
  String get stockInEnterQty;

  /// No description provided for @stockInMax.
  ///
  /// In en, this message translates to:
  /// **'Add up to {max} units at a time'**
  String stockInMax(int max);

  /// No description provided for @stockInScanEach.
  ///
  /// In en, this message translates to:
  /// **'Scan or type each unit’s {what}'**
  String stockInScanEach(String what);

  /// No description provided for @stockAutoRange.
  ///
  /// In en, this message translates to:
  /// **'{first} to {last}'**
  String stockAutoRange(String first, String last);

  /// No description provided for @stockWhereNone.
  ///
  /// In en, this message translates to:
  /// **'None in stock'**
  String get stockWhereNone;

  /// No description provided for @stockStateOut.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get stockStateOut;

  /// No description provided for @stockStateLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get stockStateLow;

  /// No description provided for @stockStateIn.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get stockStateIn;

  /// No description provided for @stockMoveDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stockMoveDelivered;

  /// No description provided for @stockMoveMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get stockMoveMoved;

  /// No description provided for @stockMoveAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted'**
  String get stockMoveAdjusted;

  /// No description provided for @stockDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get stockDayToday;

  /// No description provided for @stockDayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday · {date}'**
  String stockDayYesterday(String date);

  /// No description provided for @stockDayEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get stockDayEarlier;

  /// No description provided for @stockAdjustChooseUnit.
  ///
  /// In en, this message translates to:
  /// **'Choose the unit to remove'**
  String get stockAdjustChooseUnit;

  /// No description provided for @stockAdjustEnterImei.
  ///
  /// In en, this message translates to:
  /// **'Enter the IMEI'**
  String get stockAdjustEnterImei;

  /// No description provided for @stockAdjustEnterSerial.
  ///
  /// In en, this message translates to:
  /// **'Enter the serial number'**
  String get stockAdjustEnterSerial;

  /// No description provided for @stockAdjustCheckImei.
  ///
  /// In en, this message translates to:
  /// **'Check the IMEI: 15 digits'**
  String get stockAdjustCheckImei;

  /// No description provided for @stockAdjustChooseReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason'**
  String get stockAdjustChooseReason;

  /// No description provided for @stockAdjustWriteNote.
  ///
  /// In en, this message translates to:
  /// **'Write a note: what happened?'**
  String get stockAdjustWriteNote;

  /// No description provided for @stockMoveChooseFrom.
  ///
  /// In en, this message translates to:
  /// **'Choose where it moves from'**
  String get stockMoveChooseFrom;

  /// No description provided for @stockMoveChooseTo.
  ///
  /// In en, this message translates to:
  /// **'Choose where it goes'**
  String get stockMoveChooseTo;

  /// No description provided for @stockMoveDifferent.
  ///
  /// In en, this message translates to:
  /// **'Choose a different warehouse'**
  String get stockMoveDifferent;

  /// No description provided for @stockMoveTickUnits.
  ///
  /// In en, this message translates to:
  /// **'Tick the units to move'**
  String get stockMoveTickUnits;

  /// No description provided for @stockMoveMax.
  ///
  /// In en, this message translates to:
  /// **'Move up to 200 units at a time'**
  String get stockMoveMax;

  /// No description provided for @stockWhNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Give the warehouse a name'**
  String get stockWhNameMissing;

  /// No description provided for @stockWhNameLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the name to 60 characters'**
  String get stockWhNameLong;

  /// No description provided for @stockWhChooseOutlet.
  ///
  /// In en, this message translates to:
  /// **'Choose the outlet'**
  String get stockWhChooseOutlet;

  /// No description provided for @stockPrefixRule.
  ///
  /// In en, this message translates to:
  /// **'Use 2 to 6 letters or digits'**
  String get stockPrefixRule;

  /// No description provided for @stockOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Inventory isn’t switched on for your brand.'**
  String get stockOffMessage;

  /// No description provided for @stockReadOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Inventory has ended, so stock can’t be changed. Switch it back on in Plan & billing.'**
  String get stockReadOnlyMessage;

  /// No description provided for @stockOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory isn’t on'**
  String get stockOffTitle;

  /// No description provided for @stockOffBody.
  ///
  /// In en, this message translates to:
  /// **'Ask Atomshop to switch on the Inventory add-on for your brand.'**
  String get stockOffBody;

  /// No description provided for @stockNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get stockNotFoundTitle;

  /// No description provided for @stockNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It isn’t in your stock, or it’s in an outlet you don’t work in.'**
  String get stockNotFoundBody;

  /// No description provided for @stockTodayDay.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String stockTodayDay(String date);

  /// No description provided for @stockWarehousesN.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 warehouse} other{{count} warehouses}}'**
  String stockWarehousesN(int count);

  /// No description provided for @stockScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All outlets · {warehouses}'**
  String stockScopeAll(String warehouses);

  /// No description provided for @stockScopeNamed.
  ///
  /// In en, this message translates to:
  /// **'{name} · {warehouses}'**
  String stockScopeNamed(String name, String warehouses);

  /// No description provided for @stockTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory free trial.'**
  String get stockTrialTitle;

  /// No description provided for @stockTrialDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Inventory free trial: {days, plural, =1{1 day} other{{days} days}} left.'**
  String stockTrialDaysLeft(int days);

  /// No description provided for @stockTrialOwner.
  ///
  /// In en, this message translates to:
  /// **'Keep it on from Plan & billing.'**
  String get stockTrialOwner;

  /// No description provided for @stockTrialStaff.
  ///
  /// In en, this message translates to:
  /// **'Your brand’s owner can keep it on.'**
  String get stockTrialStaff;

  /// No description provided for @stockPlanBilling.
  ///
  /// In en, this message translates to:
  /// **'Plan & billing'**
  String get stockPlanBilling;

  /// No description provided for @stockReadOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory has ended, so stock is read-only.'**
  String get stockReadOnlyTitle;

  /// No description provided for @stockReadOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'You can still see it.'**
  String get stockReadOnlyBody;

  /// No description provided for @stockSwitchBackOn.
  ///
  /// In en, this message translates to:
  /// **'Switch it back on'**
  String get stockSwitchBackOn;

  /// No description provided for @stockViewByProduct.
  ///
  /// In en, this message translates to:
  /// **'By product'**
  String get stockViewByProduct;

  /// No description provided for @stockHeld.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get stockHeld;

  /// No description provided for @stockViewHeldN.
  ///
  /// In en, this message translates to:
  /// **'Held · {count}'**
  String stockViewHeldN(int count);

  /// No description provided for @stockViewSerial.
  ///
  /// In en, this message translates to:
  /// **'Find a serial'**
  String get stockViewSerial;

  /// No description provided for @stockChipAll.
  ///
  /// In en, this message translates to:
  /// **'All {n}'**
  String stockChipAll(int n);

  /// No description provided for @stockChipLow.
  ///
  /// In en, this message translates to:
  /// **'Low {n}'**
  String stockChipLow(int n);

  /// No description provided for @stockChipOut.
  ///
  /// In en, this message translates to:
  /// **'Out {n}'**
  String stockChipOut(int n);

  /// No description provided for @stockEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stock yet'**
  String get stockEmptyTitle;

  /// No description provided for @stockEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Stock in what arrives from the factory and it shows here.'**
  String get stockEmptyBody;

  /// No description provided for @stockEmptyLow.
  ///
  /// In en, this message translates to:
  /// **'No variant is running low.'**
  String get stockEmptyLow;

  /// No description provided for @stockEmptyOut.
  ///
  /// In en, this message translates to:
  /// **'No variant is out of stock.'**
  String get stockEmptyOut;

  /// No description provided for @stockSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all {total} products'**
  String stockSeeAll(int total);

  /// No description provided for @stockAvailableNote.
  ///
  /// In en, this message translates to:
  /// **'Available = in stock minus units held for confirmed orders and bulk deals. When it reaches 0 the product shows \"Out of stock\" on atomshop.pk.'**
  String get stockAvailableNote;

  /// No description provided for @stockScanSerial.
  ///
  /// In en, this message translates to:
  /// **'Scan a serial'**
  String get stockScanSerial;

  /// No description provided for @stockAvailableToSell.
  ///
  /// In en, this message translates to:
  /// **'Available to sell'**
  String get stockAvailableToSell;

  /// No description provided for @stockOfUnits.
  ///
  /// In en, this message translates to:
  /// **'of {units} units in stock · {products, plural, =1{1 product} other{{products} products}}'**
  String stockOfUnits(int units, int products);

  /// No description provided for @stockFullList.
  ///
  /// In en, this message translates to:
  /// **'Full list'**
  String get stockFullList;

  /// No description provided for @stockHeldForOrders.
  ///
  /// In en, this message translates to:
  /// **'Held for orders'**
  String get stockHeldForOrders;

  /// No description provided for @stockLiveOn.
  ///
  /// In en, this message translates to:
  /// **'Live on atomshop.pk'**
  String get stockLiveOn;

  /// No description provided for @stockLiveOf.
  ///
  /// In en, this message translates to:
  /// **'{live} of {listed}'**
  String stockLiveOf(int live, int listed);

  /// No description provided for @stockLowOrOut.
  ///
  /// In en, this message translates to:
  /// **'Low or out'**
  String get stockLowOrOut;

  /// No description provided for @stockLowOutValue.
  ///
  /// In en, this message translates to:
  /// **'{total} · {out} out'**
  String stockLowOutValue(int total, int out);

  /// No description provided for @stockOutAlert.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 variant is out of stock} other{{count} variants are out of stock}}'**
  String stockOutAlert(int count);

  /// No description provided for @stockOutAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Customers can’t order them on atomshop.pk'**
  String get stockOutAlertBody;

  /// No description provided for @stockVariantSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, {count} available'**
  String stockVariantSemantics(String title, int count);

  /// No description provided for @stockLevelSemantics.
  ///
  /// In en, this message translates to:
  /// **'{available} available, {held} held, {onHand} in stock'**
  String stockLevelSemantics(int available, int held, int onHand);

  /// No description provided for @stockAvailableWord.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get stockAvailableWord;

  /// No description provided for @stockHeldN.
  ///
  /// In en, this message translates to:
  /// **'{count} held'**
  String stockHeldN(int count);

  /// No description provided for @stockHeldEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing is held'**
  String get stockHeldEmptyTitle;

  /// No description provided for @stockHeldEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Units held for confirmed orders and bulk deals show here.'**
  String get stockHeldEmptyBody;

  /// No description provided for @stockBulkDealN.
  ///
  /// In en, this message translates to:
  /// **'Bulk deal #{id}'**
  String stockBulkDealN(String id);

  /// No description provided for @stockCashOrderN.
  ///
  /// In en, this message translates to:
  /// **'Cash order #{id}'**
  String stockCashOrderN(String id);

  /// No description provided for @stockFromWh.
  ///
  /// In en, this message translates to:
  /// **'from {warehouse}'**
  String stockFromWh(String warehouse);

  /// No description provided for @stockSince.
  ///
  /// In en, this message translates to:
  /// **'since {when}'**
  String stockSince(String when);

  /// No description provided for @stockSinceToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get stockSinceToday;

  /// No description provided for @stockSinceYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get stockSinceYesterday;

  /// No description provided for @stockRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get stockRemoved;

  /// No description provided for @stockNotInYourStock.
  ///
  /// In en, this message translates to:
  /// **'This number isn’t in your stock.'**
  String get stockNotInYourStock;

  /// No description provided for @stockWhere.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get stockWhere;

  /// No description provided for @stockCameIn.
  ///
  /// In en, this message translates to:
  /// **'Came in'**
  String get stockCameIn;

  /// No description provided for @stockHeldFor.
  ///
  /// In en, this message translates to:
  /// **'Held for'**
  String get stockHeldFor;

  /// No description provided for @stockWhy.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get stockWhy;

  /// No description provided for @stockOpenOrder.
  ///
  /// In en, this message translates to:
  /// **'Open the order'**
  String get stockOpenOrder;

  /// No description provided for @stockOpenDeal.
  ///
  /// In en, this message translates to:
  /// **'Open the deal'**
  String get stockOpenDeal;

  /// No description provided for @stockOpenProduct.
  ///
  /// In en, this message translates to:
  /// **'Open product'**
  String get stockOpenProduct;

  /// No description provided for @stockFoundAddBack.
  ///
  /// In en, this message translates to:
  /// **'Found it: add it back'**
  String get stockFoundAddBack;

  /// No description provided for @stockStockItIn.
  ///
  /// In en, this message translates to:
  /// **'Stock it in'**
  String get stockStockItIn;

  /// No description provided for @stockFoundUnit.
  ///
  /// In en, this message translates to:
  /// **'Found a unit'**
  String get stockFoundUnit;

  /// No description provided for @stockEditProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get stockEditProduct;

  /// No description provided for @stockLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get stockLive;

  /// No description provided for @stockOrdersAndDeals.
  ///
  /// In en, this message translates to:
  /// **'Orders and bulk deals'**
  String get stockOrdersAndDeals;

  /// No description provided for @stockAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get stockAvailable;

  /// No description provided for @stockCanSellNow.
  ///
  /// In en, this message translates to:
  /// **'Can be sold now'**
  String get stockCanSellNow;

  /// No description provided for @stockDelivered90.
  ///
  /// In en, this message translates to:
  /// **'Delivered in 90 days'**
  String get stockDelivered90;

  /// No description provided for @stockVariants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get stockVariants;

  /// No description provided for @stockColVariant.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get stockColVariant;

  /// No description provided for @stockColAvail.
  ///
  /// In en, this message translates to:
  /// **'Avail.'**
  String get stockColAvail;

  /// No description provided for @stockByWarehouse.
  ///
  /// In en, this message translates to:
  /// **'By outlet and warehouse'**
  String get stockByWarehouse;

  /// No description provided for @stockSellsOnline.
  ///
  /// In en, this message translates to:
  /// **'sells online'**
  String get stockSellsOnline;

  /// No description provided for @stockNotOnline.
  ///
  /// In en, this message translates to:
  /// **'not online'**
  String get stockNotOnline;

  /// No description provided for @stockSegInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock · {count}'**
  String stockSegInStock(int count);

  /// No description provided for @stockSegDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered · {count}'**
  String stockSegDelivered(int count);

  /// No description provided for @stockNothingDelivered.
  ///
  /// In en, this message translates to:
  /// **'Nothing delivered yet.'**
  String get stockNothingDelivered;

  /// No description provided for @stockNoUnits.
  ///
  /// In en, this message translates to:
  /// **'No units in stock.'**
  String get stockNoUnits;

  /// No description provided for @stockRecentChanges.
  ///
  /// In en, this message translates to:
  /// **'Recent stock changes'**
  String get stockRecentChanges;

  /// No description provided for @stockNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes yet.'**
  String get stockNoChanges;

  /// No description provided for @stockOnAtomshop.
  ///
  /// In en, this message translates to:
  /// **'On atomshop.pk'**
  String get stockOnAtomshop;

  /// No description provided for @stockShowsAs.
  ///
  /// In en, this message translates to:
  /// **'Shows as'**
  String get stockShowsAs;

  /// No description provided for @stockNotListed.
  ///
  /// In en, this message translates to:
  /// **'Not listed'**
  String get stockNotListed;

  /// No description provided for @stockCountsFrom.
  ///
  /// In en, this message translates to:
  /// **'Counts from'**
  String get stockCountsFrom;

  /// No description provided for @stockOnlineWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Warehouses that sell online'**
  String get stockOnlineWarehouses;

  /// No description provided for @stockAvailableOnline.
  ///
  /// In en, this message translates to:
  /// **'Available online'**
  String get stockAvailableOnline;

  /// No description provided for @stockDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get stockDetails;

  /// No description provided for @stockPrNumber.
  ///
  /// In en, this message translates to:
  /// **'PR number'**
  String get stockPrNumber;

  /// No description provided for @stockUnitsNumberedBy.
  ///
  /// In en, this message translates to:
  /// **'Units numbered by'**
  String get stockUnitsNumberedBy;

  /// No description provided for @stockOnWebsite.
  ///
  /// In en, this message translates to:
  /// **'On the website'**
  String get stockOnWebsite;

  /// No description provided for @stockUnitBulkDeal.
  ///
  /// In en, this message translates to:
  /// **'bulk deal #{id}'**
  String stockUnitBulkDeal(String id);

  /// No description provided for @stockUnitOrder.
  ///
  /// In en, this message translates to:
  /// **'order #{id}'**
  String stockUnitOrder(String id);

  /// No description provided for @stockUnitCameIn.
  ///
  /// In en, this message translates to:
  /// **'came in {date}'**
  String stockUnitCameIn(String date);

  /// No description provided for @stockNumberingSaved.
  ///
  /// In en, this message translates to:
  /// **'Numbering saved.'**
  String get stockNumberingSaved;

  /// No description provided for @stockNumImeiHint.
  ///
  /// In en, this message translates to:
  /// **'Phones and tablets: the 15-digit number'**
  String get stockNumImeiHint;

  /// No description provided for @stockNumSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get stockNumSerial;

  /// No description provided for @stockNumSerialHint.
  ///
  /// In en, this message translates to:
  /// **'The number on the box or the back label'**
  String get stockNumSerialHint;

  /// No description provided for @stockNumAuto.
  ///
  /// In en, this message translates to:
  /// **'Numbered for me'**
  String get stockNumAuto;

  /// No description provided for @stockNumAutoHint.
  ///
  /// In en, this message translates to:
  /// **'We give each unit a number with your prefix'**
  String get stockNumAutoHint;

  /// No description provided for @stockNumTitle.
  ///
  /// In en, this message translates to:
  /// **'How units are numbered'**
  String get stockNumTitle;

  /// No description provided for @stockPrefixNote.
  ///
  /// In en, this message translates to:
  /// **'up to 6 letters'**
  String get stockPrefixNote;

  /// No description provided for @stockPrefixHint.
  ///
  /// In en, this message translates to:
  /// **'Units become {prefix}-0001, {prefix}-0002…'**
  String stockPrefixHint(String prefix);

  /// No description provided for @stockSaveNumbering.
  ///
  /// In en, this message translates to:
  /// **'Save numbering'**
  String get stockSaveNumbering;

  /// No description provided for @stockScanNotImei.
  ///
  /// In en, this message translates to:
  /// **'That isn’t an IMEI: 15 digits (dial *#06#).'**
  String get stockScanNotImei;

  /// No description provided for @stockScanLength.
  ///
  /// In en, this message translates to:
  /// **'Should be 3 to 60 characters.'**
  String get stockScanLength;

  /// No description provided for @stockScanHintImei.
  ///
  /// In en, this message translates to:
  /// **'Point at the IMEI barcode on the box.'**
  String get stockScanHintImei;

  /// No description provided for @stockScanHintSerial.
  ///
  /// In en, this message translates to:
  /// **'Point at the serial number’s barcode.'**
  String get stockScanHintSerial;

  /// No description provided for @stockScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a serial or IMEI'**
  String get stockScanTitle;

  /// No description provided for @stockTypeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type it instead'**
  String get stockTypeInstead;

  /// No description provided for @stockScannedN.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scanned} other{{count} scanned}}'**
  String stockScannedN(int count);

  /// No description provided for @stockScanPoint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the serial or IMEI barcode.'**
  String get stockScanPoint;

  /// No description provided for @stockScanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan another'**
  String get stockScanAnother;

  /// No description provided for @stockUnitToRemove.
  ///
  /// In en, this message translates to:
  /// **'Unit to remove'**
  String get stockUnitToRemove;

  /// No description provided for @stockScanTheUnit.
  ///
  /// In en, this message translates to:
  /// **'Scan the unit'**
  String get stockScanTheUnit;

  /// No description provided for @stockNotInStockHere.
  ///
  /// In en, this message translates to:
  /// **'{serial} isn’t in stock in your warehouses.'**
  String stockNotInStockHere(String serial);

  /// No description provided for @stockTakenOut.
  ///
  /// In en, this message translates to:
  /// **'{serial} taken out of stock.'**
  String stockTakenOut(String serial);

  /// No description provided for @stockUnitAddedBack.
  ///
  /// In en, this message translates to:
  /// **'Unit added back to stock.'**
  String get stockUnitAddedBack;

  /// No description provided for @stockAddedBack.
  ///
  /// In en, this message translates to:
  /// **'{serial} added back to stock.'**
  String stockAddedBack(String serial);

  /// No description provided for @stockRemoveUnit.
  ///
  /// In en, this message translates to:
  /// **'Remove a unit'**
  String get stockRemoveUnit;

  /// No description provided for @stockChooseUnit.
  ///
  /// In en, this message translates to:
  /// **'Choose the unit'**
  String get stockChooseUnit;

  /// No description provided for @stockAutoNote.
  ///
  /// In en, this message translates to:
  /// **'This product is numbered for you: the unit gets the next number.'**
  String get stockAutoNote;

  /// No description provided for @stockWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get stockWhatHappened;

  /// No description provided for @stockRemoveOne.
  ///
  /// In en, this message translates to:
  /// **'Remove 1 unit'**
  String get stockRemoveOne;

  /// No description provided for @stockAddUnit.
  ///
  /// In en, this message translates to:
  /// **'Add the unit'**
  String get stockAddUnit;

  /// No description provided for @stockPeriod30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get stockPeriod30;

  /// No description provided for @stockPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get stockPeriodMonth;

  /// No description provided for @stockPeriod90.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get stockPeriod90;

  /// No description provided for @stockPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get stockPeriodAll;

  /// No description provided for @stockSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get stockSearchHistory;

  /// No description provided for @stockHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Product, serial or reference'**
  String get stockHistoryHint;

  /// No description provided for @stockNothingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this period'**
  String get stockNothingPeriod;

  /// No description provided for @stockRunningLow.
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get stockRunningLow;

  /// No description provided for @stockFindStock.
  ///
  /// In en, this message translates to:
  /// **'Find stock'**
  String get stockFindStock;

  /// No description provided for @stockFindHint.
  ///
  /// In en, this message translates to:
  /// **'Product, PR number or SKU'**
  String get stockFindHint;

  /// No description provided for @stockNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try the product’s name, PR number or SKU.'**
  String get stockNoMatchBody;

  /// No description provided for @stockNoVariant.
  ///
  /// In en, this message translates to:
  /// **'No variant in this list.'**
  String get stockNoVariant;

  /// No description provided for @stockListNote.
  ///
  /// In en, this message translates to:
  /// **'Numbers are what you can sell now: in stock minus units held for orders and bulk deals.'**
  String get stockListNote;

  /// No description provided for @stockNotLive.
  ///
  /// In en, this message translates to:
  /// **'Not live'**
  String get stockNotLive;

  /// No description provided for @stockScanEachBox.
  ///
  /// In en, this message translates to:
  /// **'Scan each box’s serial'**
  String get stockScanEachBox;

  /// No description provided for @stockAddedUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 unit to stock.} other{Added {count} units to stock.}}'**
  String stockAddedUnits(int count);

  /// No description provided for @stockImeis.
  ///
  /// In en, this message translates to:
  /// **'IMEIs'**
  String get stockImeis;

  /// No description provided for @stockSerials.
  ///
  /// In en, this message translates to:
  /// **'Serials'**
  String get stockSerials;

  /// No description provided for @stockWhereArrived.
  ///
  /// In en, this message translates to:
  /// **'Where it arrived'**
  String get stockWhereArrived;

  /// No description provided for @stockSellsOnAtomshop.
  ///
  /// In en, this message translates to:
  /// **'sells on atomshop.pk'**
  String get stockSellsOnAtomshop;

  /// No description provided for @stockNotOnAtomshop.
  ///
  /// In en, this message translates to:
  /// **'not on atomshop.pk'**
  String get stockNotOnAtomshop;

  /// No description provided for @stockReceivedOn.
  ///
  /// In en, this message translates to:
  /// **'Received on'**
  String get stockReceivedOn;

  /// No description provided for @stockReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get stockReference;

  /// No description provided for @stockRefPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. FDN-2304'**
  String get stockRefPlaceholder;

  /// No description provided for @stockRefHint.
  ///
  /// In en, this message translates to:
  /// **'Factory delivery note or reference.'**
  String get stockRefHint;

  /// No description provided for @stockWhatArrived.
  ///
  /// In en, this message translates to:
  /// **'What arrived'**
  String get stockWhatArrived;

  /// No description provided for @stockHowMany.
  ///
  /// In en, this message translates to:
  /// **'How many arrived'**
  String get stockHowMany;

  /// No description provided for @stockNumberedAs.
  ///
  /// In en, this message translates to:
  /// **'They’ll be numbered {numbers}.'**
  String stockNumberedAs(String numbers);

  /// No description provided for @stockNextNumber.
  ///
  /// In en, this message translates to:
  /// **'Each unit gets the next number with your prefix.'**
  String get stockNextNumber;

  /// No description provided for @stockLinesN.
  ///
  /// In en, this message translates to:
  /// **'{what} · {count}'**
  String stockLinesN(String what, int count);

  /// No description provided for @stockTypeMore.
  ///
  /// In en, this message translates to:
  /// **'Or type or paste more'**
  String get stockTypeMore;

  /// No description provided for @stockOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'One per line'**
  String get stockOnePerLine;

  /// No description provided for @stockPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Type or paste them, one per line. Duplicates are left out.'**
  String get stockPasteHint;

  /// No description provided for @stockNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Second truck from the factory'**
  String get stockNotePlaceholder;

  /// No description provided for @stockSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get stockSummary;

  /// No description provided for @stockInto.
  ///
  /// In en, this message translates to:
  /// **'Into'**
  String get stockInto;

  /// No description provided for @stockUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get stockUnits;

  /// No description provided for @stockAddToStock.
  ///
  /// In en, this message translates to:
  /// **'Add to stock'**
  String get stockAddToStock;

  /// No description provided for @stockAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add and receive another'**
  String get stockAddAnother;

  /// No description provided for @stockScanNext.
  ///
  /// In en, this message translates to:
  /// **'Scan the next serial'**
  String get stockScanNext;

  /// No description provided for @stockScanStrip.
  ///
  /// In en, this message translates to:
  /// **'Point at each box’s serial.\nIt adds them one by one.'**
  String get stockScanStrip;

  /// No description provided for @stockRecentIn.
  ///
  /// In en, this message translates to:
  /// **'Recent stock in'**
  String get stockRecentIn;

  /// No description provided for @stockScanToMove.
  ///
  /// In en, this message translates to:
  /// **'Scan the units to move'**
  String get stockScanToMove;

  /// No description provided for @stockNotInStockN.
  ///
  /// In en, this message translates to:
  /// **'{count} not in stock'**
  String stockNotInStockN(int count);

  /// No description provided for @stockElsewhereN.
  ///
  /// In en, this message translates to:
  /// **'{count} in another warehouse'**
  String stockElsewhereN(int count);

  /// No description provided for @stockMovedUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 unit to {to}.} other{Moved {count} units to {to}.}}'**
  String stockMovedUnits(int count, String to);

  /// No description provided for @stockFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get stockFrom;

  /// No description provided for @stockTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get stockTo;

  /// No description provided for @stockUnitsN.
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String stockUnitsN(int count);

  /// No description provided for @stockMoveFrom.
  ///
  /// In en, this message translates to:
  /// **'Move from'**
  String get stockMoveFrom;

  /// No description provided for @stockMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get stockMoveTo;

  /// No description provided for @stockSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get stockSwap;

  /// No description provided for @stockTickedN.
  ///
  /// In en, this message translates to:
  /// **'{count} ticked'**
  String stockTickedN(int count);

  /// No description provided for @stockNoUnitsHere.
  ///
  /// In en, this message translates to:
  /// **'No units in stock here.'**
  String get stockNoUnitsHere;

  /// No description provided for @stockScanInstead.
  ///
  /// In en, this message translates to:
  /// **'Scan units instead'**
  String get stockScanInstead;

  /// No description provided for @stockMovedOn.
  ///
  /// In en, this message translates to:
  /// **'Moved on'**
  String get stockMovedOn;

  /// No description provided for @stockMovePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Truck, driver…'**
  String get stockMovePlaceholder;

  /// No description provided for @stockMoveN.
  ///
  /// In en, this message translates to:
  /// **'Move {count} units'**
  String stockMoveN(int count);

  /// No description provided for @stockMoveNTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Move 1 unit to {to}} other{Move {count} units to {to}}}'**
  String stockMoveNTo(int count, String to);

  /// No description provided for @stockHeldCantMove.
  ///
  /// In en, this message translates to:
  /// **'Held units can’t move. They stay with their order.'**
  String get stockHeldCantMove;

  /// No description provided for @stockWhReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Inventory has ended, so warehouses can’t be changed.'**
  String get stockWhReadOnly;

  /// No description provided for @stockNoWarehouses.
  ///
  /// In en, this message translates to:
  /// **'No warehouses yet'**
  String get stockNoWarehouses;

  /// No description provided for @stockNoWarehousesBody.
  ///
  /// In en, this message translates to:
  /// **'Each outlet gets a store warehouse made for it.'**
  String get stockNoWarehousesBody;

  /// No description provided for @stockArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get stockArchived;

  /// No description provided for @stockArchivedUnits.
  ///
  /// In en, this message translates to:
  /// **'Archived · {count} units'**
  String stockArchivedUnits(int count);

  /// No description provided for @stockBringBack.
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get stockBringBack;

  /// No description provided for @stockDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get stockDefault;

  /// No description provided for @stockSellsOnAtomshopTag.
  ///
  /// In en, this message translates to:
  /// **'Sells on atomshop.pk'**
  String get stockSellsOnAtomshopTag;

  /// No description provided for @stockNotOnAtomshopTag.
  ///
  /// In en, this message translates to:
  /// **'Not on atomshop.pk'**
  String get stockNotOnAtomshopTag;

  /// No description provided for @stockInChargeOf.
  ///
  /// In en, this message translates to:
  /// **'in charge: {name}'**
  String stockInChargeOf(String name);

  /// No description provided for @stockNobodyYet.
  ///
  /// In en, this message translates to:
  /// **'nobody yet'**
  String get stockNobodyYet;

  /// No description provided for @stockArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String stockArchiveTitle(String name);

  /// No description provided for @stockArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves the lists. Move its stock out first.'**
  String get stockArchiveBody;

  /// No description provided for @stockArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get stockArchive;

  /// No description provided for @stockWhArchived.
  ///
  /// In en, this message translates to:
  /// **'{name} archived.'**
  String stockWhArchived(String name);

  /// No description provided for @stockWhSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved.'**
  String stockWhSaved(String name);

  /// No description provided for @stockAddWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Add a warehouse'**
  String get stockAddWarehouse;

  /// No description provided for @stockEditWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Edit warehouse'**
  String get stockEditWarehouse;

  /// No description provided for @stockName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get stockName;

  /// No description provided for @stockType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get stockType;

  /// No description provided for @stockInCharge.
  ///
  /// In en, this message translates to:
  /// **'In charge'**
  String get stockInCharge;

  /// No description provided for @stockNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get stockNobody;

  /// No description provided for @stockOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get stockOwner;

  /// No description provided for @stockAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get stockAddress;

  /// No description provided for @stockSellsOnlineSub.
  ///
  /// In en, this message translates to:
  /// **'Its units count as available online'**
  String get stockSellsOnlineSub;

  /// No description provided for @stockDefaultOutlet.
  ///
  /// In en, this message translates to:
  /// **'Default for this outlet'**
  String get stockDefaultOutlet;

  /// No description provided for @stockDefaultSub.
  ///
  /// In en, this message translates to:
  /// **'Stock in and orders use it first'**
  String get stockDefaultSub;

  /// No description provided for @syncCopyOrders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order} other{{count} orders}}'**
  String syncCopyOrders(int count);

  /// No description provided for @syncCopyProducts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product} other{{count} products}}'**
  String syncCopyProducts(int count);

  /// No description provided for @syncCopyUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit} other{{count} units}}'**
  String syncCopyUnits(int count);

  /// No description provided for @syncCopyBulk.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bulk request} other{{count} bulk requests}}'**
  String syncCopyBulk(int count);

  /// No description provided for @syncCopyMb.
  ///
  /// In en, this message translates to:
  /// **'{count} MB'**
  String syncCopyMb(int count);

  /// No description provided for @syncUpdateBold.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change is safe on this phone} other{{count} changes are safe on this phone}}'**
  String syncUpdateBold(int count);

  /// No description provided for @syncUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit} other{{count} units}}'**
  String syncUnits(int count);

  /// No description provided for @syncEntryVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get syncEntryVerification;

  /// No description provided for @syncEntryOrder.
  ///
  /// In en, this message translates to:
  /// **'order'**
  String get syncEntryOrder;

  /// No description provided for @syncEntryOrderNo.
  ///
  /// In en, this message translates to:
  /// **'order #{id}'**
  String syncEntryOrderNo(String id);

  /// No description provided for @syncEntryReceivedBy.
  ///
  /// In en, this message translates to:
  /// **'received by {name}'**
  String syncEntryReceivedBy(String name);

  /// No description provided for @syncEntryCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get syncEntryCancelled;

  /// No description provided for @syncEntryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment {amount}'**
  String syncEntryPayment(String amount);

  /// No description provided for @syncEntryHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get syncEntryHandedOver;

  /// No description provided for @syncEntryAtompay.
  ///
  /// In en, this message translates to:
  /// **'AtomPay {order}'**
  String syncEntryAtompay(String order);

  /// No description provided for @syncEntryDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get syncEntryDelivery;

  /// No description provided for @syncEntryDeal.
  ///
  /// In en, this message translates to:
  /// **'deal {number}'**
  String syncEntryDeal(String number);

  /// No description provided for @syncEntryRequest.
  ///
  /// In en, this message translates to:
  /// **'request #{id}'**
  String syncEntryRequest(String id);

  /// No description provided for @syncEntryStockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock in · {qty}'**
  String syncEntryStockIn(String qty);

  /// No description provided for @syncEntrySerials.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 serial} other{{count} serials}}'**
  String syncEntrySerials(int count);

  /// No description provided for @syncEntryStockOut.
  ///
  /// In en, this message translates to:
  /// **'Stock out'**
  String get syncEntryStockOut;

  /// No description provided for @syncEntryBackIn.
  ///
  /// In en, this message translates to:
  /// **'Back into stock'**
  String get syncEntryBackIn;

  /// No description provided for @syncEntryUnit.
  ///
  /// In en, this message translates to:
  /// **'unit #{id}'**
  String syncEntryUnit(String id);

  /// No description provided for @syncEntryMoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 unit} other{Moved {count} units}}'**
  String syncEntryMoved(int count);

  /// No description provided for @syncEntryTo.
  ///
  /// In en, this message translates to:
  /// **'to {name}'**
  String syncEntryTo(String name);

  /// No description provided for @syncLimitAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago, {why}'**
  String syncLimitAgo(int days, String why);

  /// No description provided for @syncYourBrand.
  ///
  /// In en, this message translates to:
  /// **'your brand'**
  String get syncYourBrand;

  /// No description provided for @ordersStagePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ordersStagePending;

  /// No description provided for @ordersStageConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get ordersStageConfirming;

  /// No description provided for @ordersStageProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get ordersStageProcessing;

  /// No description provided for @ordersStageDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get ordersStageDelivered;

  /// No description provided for @ordersStageCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ordersStageCompleted;

  /// No description provided for @ordersStageCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ordersStageCancelled;

  /// No description provided for @ordersPayUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get ordersPayUnpaid;

  /// No description provided for @ordersPayPart.
  ///
  /// In en, this message translates to:
  /// **'Part paid'**
  String get ordersPayPart;

  /// No description provided for @ordersPayPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get ordersPayPaid;

  /// No description provided for @ordersPayNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'Not needed'**
  String get ordersPayNotNeeded;

  /// No description provided for @ordersCancelUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Customer can’t be reached'**
  String get ordersCancelUnreachable;

  /// No description provided for @ordersCancelChangedMind.
  ///
  /// In en, this message translates to:
  /// **'Customer changed their mind'**
  String get ordersCancelChangedMind;

  /// No description provided for @ordersCancelOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get ordersCancelOutOfStock;

  /// No description provided for @ordersCancelNoDelivery.
  ///
  /// In en, this message translates to:
  /// **'We don’t deliver there'**
  String get ordersCancelNoDelivery;

  /// No description provided for @ordersMethodCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get ordersMethodCod;

  /// No description provided for @ordersMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get ordersMethodBank;

  /// No description provided for @ordersMethodJazzcash.
  ///
  /// In en, this message translates to:
  /// **'JazzCash'**
  String get ordersMethodJazzcash;

  /// No description provided for @ordersMethodEasypaisa.
  ///
  /// In en, this message translates to:
  /// **'Easypaisa'**
  String get ordersMethodEasypaisa;

  /// No description provided for @ordersMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get ordersMethodCash;

  /// No description provided for @ordersMethodCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get ordersMethodCheque;

  /// No description provided for @ordersPayNothingLeft.
  ///
  /// In en, this message translates to:
  /// **'Nothing is left to pay.'**
  String get ordersPayNothingLeft;

  /// No description provided for @ordersPayEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get ordersPayEnterAmount;

  /// No description provided for @ordersPayTooMuch.
  ///
  /// In en, this message translates to:
  /// **'More than what is left to pay.'**
  String get ordersPayTooMuch;

  /// No description provided for @ordersDeliverScanFirst.
  ///
  /// In en, this message translates to:
  /// **'Scan the serial first'**
  String get ordersDeliverScanFirst;

  /// No description provided for @ordersSayWhoReceived.
  ///
  /// In en, this message translates to:
  /// **'Say who received it'**
  String get ordersSayWhoReceived;

  /// No description provided for @ordersDeliverEnterCash.
  ///
  /// In en, this message translates to:
  /// **'Enter the cash collected'**
  String get ordersDeliverEnterCash;

  /// No description provided for @ordersDeliverTooMuch.
  ///
  /// In en, this message translates to:
  /// **'More than what is left to pay'**
  String get ordersDeliverTooMuch;

  /// No description provided for @ordersPickHowPaid.
  ///
  /// In en, this message translates to:
  /// **'Pick how they paid'**
  String get ordersPickHowPaid;

  /// No description provided for @ordersTheCustomer.
  ///
  /// In en, this message translates to:
  /// **'the customer'**
  String get ordersTheCustomer;

  /// No description provided for @ordersCallCustomer.
  ///
  /// In en, this message translates to:
  /// **'Call the customer'**
  String get ordersCallCustomer;

  /// No description provided for @ordersNextCallBody.
  ///
  /// In en, this message translates to:
  /// **'Call {name} to confirm the order, the colour and the address. Start confirming so the team knows you are on it.'**
  String ordersNextCallBody(String name);

  /// No description provided for @ordersStartConfirming.
  ///
  /// In en, this message translates to:
  /// **'Start confirming'**
  String get ordersStartConfirming;

  /// No description provided for @ordersConfirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get ordersConfirmOrder;

  /// No description provided for @ordersNextConfirmBodyHeld.
  ///
  /// In en, this message translates to:
  /// **'Spoke to the customer? Confirm the order and one unit is held for it.'**
  String get ordersNextConfirmBodyHeld;

  /// No description provided for @ordersNextConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Spoke to the customer? Confirm the order so it can go out.'**
  String get ordersNextConfirmBody;

  /// No description provided for @ordersMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark delivered'**
  String get ordersMarkDelivered;

  /// No description provided for @ordersNextDeliverBody.
  ///
  /// In en, this message translates to:
  /// **'Note who received it, the serial and a proof photo. Cash collected on delivery is recorded too.'**
  String get ordersNextDeliverBody;

  /// No description provided for @ordersRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get ordersRecordPayment;

  /// No description provided for @ordersNextPayBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} is still to collect. Complete the order once it is paid in full.'**
  String ordersNextPayBody(String amount);

  /// No description provided for @ordersComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get ordersComplete;

  /// No description provided for @ordersNextCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delivered and paid in full. Complete the order to close it.'**
  String get ordersNextCompleteBody;

  /// No description provided for @ordersStepNew.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get ordersStepNew;

  /// No description provided for @ordersDayTime.
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String ordersDayTime(String day, String time);

  /// No description provided for @ordersYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get ordersYou;

  /// No description provided for @ordersSubHeldOnWay.
  ///
  /// In en, this message translates to:
  /// **'Unit held, on its way'**
  String get ordersSubHeldOnWay;

  /// No description provided for @ordersSubOnWay.
  ///
  /// In en, this message translates to:
  /// **'On its way'**
  String get ordersSubOnWay;

  /// No description provided for @ordersSubSerialProof.
  ///
  /// In en, this message translates to:
  /// **'Serial and proof'**
  String get ordersSubSerialProof;

  /// No description provided for @ordersPaidInFull.
  ///
  /// In en, this message translates to:
  /// **'Paid in full'**
  String get ordersPaidInFull;

  /// No description provided for @ordersSubPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed {when}'**
  String ordersSubPlaced(String when);

  /// No description provided for @ordersSubCalled.
  ///
  /// In en, this message translates to:
  /// **'Called {when}'**
  String ordersSubCalled(String when);

  /// No description provided for @ordersSubUnitHeld.
  ///
  /// In en, this message translates to:
  /// **'Unit held · {day}'**
  String ordersSubUnitHeld(String day);

  /// No description provided for @ordersSubConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed {when}'**
  String ordersSubConfirmed(String when);

  /// No description provided for @ordersSubReceivedBy.
  ///
  /// In en, this message translates to:
  /// **'Received by {name}'**
  String ordersSubReceivedBy(String name);

  /// No description provided for @ordersSubDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered {day}'**
  String ordersSubDelivered(String day);

  /// No description provided for @ordersSubCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed {day}'**
  String ordersSubCompleted(String day);

  /// No description provided for @ordersEvMovedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved to {to}'**
  String ordersEvMovedTo(String to);

  /// No description provided for @ordersEvMovedFromTo.
  ///
  /// In en, this message translates to:
  /// **'Moved from {from} to {to}'**
  String ordersEvMovedFromTo(String from, String to);

  /// No description provided for @ordersPlacedOnline.
  ///
  /// In en, this message translates to:
  /// **'Order placed on atomshop.pk'**
  String get ordersPlacedOnline;

  /// No description provided for @ordersEvPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get ordersEvPlaced;

  /// No description provided for @ordersEvStarted.
  ///
  /// In en, this message translates to:
  /// **'Started confirming'**
  String get ordersEvStarted;

  /// No description provided for @ordersEvConfirmedHeld.
  ///
  /// In en, this message translates to:
  /// **'Confirmed, moved to Processing, 1 unit held'**
  String get ordersEvConfirmedHeld;

  /// No description provided for @ordersEvConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed, moved to Processing'**
  String get ordersEvConfirmed;

  /// No description provided for @ordersEvDeliveredTo.
  ///
  /// In en, this message translates to:
  /// **'Delivered to {name}'**
  String ordersEvDeliveredTo(String name);

  /// No description provided for @ordersEvCollected.
  ///
  /// In en, this message translates to:
  /// **'{amount} collected'**
  String ordersEvCollected(String amount);

  /// No description provided for @ordersEvCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed, paid in full'**
  String get ordersEvCompleted;

  /// No description provided for @ordersEvCancelledWhy.
  ///
  /// In en, this message translates to:
  /// **'Cancelled: {why}'**
  String ordersEvCancelledWhy(String why);

  /// No description provided for @ordersEvPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment {amount} by {method}'**
  String ordersEvPayment(String amount, String method);

  /// No description provided for @ordersRef.
  ///
  /// In en, this message translates to:
  /// **'ref {ref}'**
  String ordersRef(String ref);

  /// No description provided for @ordersRecordedBy.
  ///
  /// In en, this message translates to:
  /// **'recorded by {name}'**
  String ordersRecordedBy(String name);

  /// No description provided for @ordersReceiptPaidFull.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Paid in full · 1 payment} other{Paid in full · {count} payments}}'**
  String ordersReceiptPaidFull(int count);

  /// No description provided for @ordersReceiptNotPaid.
  ///
  /// In en, this message translates to:
  /// **'Not paid yet'**
  String get ordersReceiptNotPaid;

  /// No description provided for @ordersReceiptPartLeft.
  ///
  /// In en, this message translates to:
  /// **'Part paid · {amount} left'**
  String ordersReceiptPartLeft(String amount);

  /// No description provided for @ordersCashReceipt.
  ///
  /// In en, this message translates to:
  /// **'Cash receipt'**
  String get ordersCashReceipt;

  /// No description provided for @ordersOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String ordersOrderNumber(String number);

  /// No description provided for @ordersCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get ordersCustomer;

  /// No description provided for @ordersItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get ordersItem;

  /// No description provided for @ordersSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get ordersSerial;

  /// No description provided for @ordersLeftToPay.
  ///
  /// In en, this message translates to:
  /// **'Left to pay'**
  String get ordersLeftToPay;

  /// No description provided for @ordersSoldOn.
  ///
  /// In en, this message translates to:
  /// **'Sold on atomshop.pk'**
  String get ordersSoldOn;

  /// No description provided for @ordersReceiptMsgHead.
  ///
  /// In en, this message translates to:
  /// **'{brand}: cash receipt {number}'**
  String ordersReceiptMsgHead(String brand, String number);

  /// No description provided for @ordersSerialValue.
  ///
  /// In en, this message translates to:
  /// **'Serial {serial}'**
  String ordersSerialValue(String serial);

  /// No description provided for @ordersTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String ordersTotalValue(String amount);

  /// No description provided for @ordersQty.
  ///
  /// In en, this message translates to:
  /// **'Qty {qty}'**
  String ordersQty(int qty);

  /// No description provided for @atompayStepApproving.
  ///
  /// In en, this message translates to:
  /// **'Atomshop approving'**
  String get atompayStepApproving;

  /// No description provided for @atompayStepSeller.
  ///
  /// In en, this message translates to:
  /// **'Finding a seller'**
  String get atompayStepSeller;

  /// No description provided for @atompayHandOver.
  ///
  /// In en, this message translates to:
  /// **'Hand over'**
  String get atompayHandOver;

  /// No description provided for @atompayHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get atompayHandedOver;

  /// No description provided for @atompayStepPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid to you'**
  String get atompayStepPaid;

  /// No description provided for @atompayStepCancelled.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get atompayStepCancelled;

  /// No description provided for @bulkStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get bulkStatusNew;

  /// No description provided for @bulkStatusChangeAsked.
  ///
  /// In en, this message translates to:
  /// **'Change asked'**
  String get bulkStatusChangeAsked;

  /// No description provided for @bulkStatusQuoted.
  ///
  /// In en, this message translates to:
  /// **'Quoted'**
  String get bulkStatusQuoted;

  /// No description provided for @bulkStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get bulkStatusDeclined;

  /// No description provided for @bulkStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get bulkStatusAccepted;

  /// No description provided for @bulkStatusContacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get bulkStatusContacted;

  /// No description provided for @bulkStatusWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get bulkStatusWon;

  /// No description provided for @bulkStatusLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get bulkStatusLost;

  /// No description provided for @bulkStatusBackToNew.
  ///
  /// In en, this message translates to:
  /// **'Back to new'**
  String get bulkStatusBackToNew;

  /// No description provided for @bulkDaysToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get bulkDaysToday;

  /// No description provided for @bulkDaysTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get bulkDaysTomorrow;

  /// No description provided for @bulkDaysLate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day late} other{{count} days late}}'**
  String bulkDaysLate(int count);

  /// No description provided for @bulkDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String bulkDaysCount(int days);

  /// No description provided for @bulkActReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get bulkActReply;

  /// No description provided for @bulkActSendQuote.
  ///
  /// In en, this message translates to:
  /// **'Send quote'**
  String get bulkActSendQuote;

  /// No description provided for @bulkActFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow up'**
  String get bulkActFollowUp;

  /// No description provided for @bulkActOpenDeal.
  ///
  /// In en, this message translates to:
  /// **'Open deal'**
  String get bulkActOpenDeal;

  /// No description provided for @bulkActView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get bulkActView;

  /// No description provided for @bulkLostReasonNeeded.
  ///
  /// In en, this message translates to:
  /// **'Choose why it was lost.'**
  String get bulkLostReasonNeeded;

  /// No description provided for @bulkQpNoLines.
  ///
  /// In en, this message translates to:
  /// **'Add at least one line.'**
  String get bulkQpNoLines;

  /// No description provided for @bulkQpMaxLines.
  ///
  /// In en, this message translates to:
  /// **'A quote can have up to {max} lines.'**
  String bulkQpMaxLines(String max);

  /// No description provided for @bulkQpLineProduct.
  ///
  /// In en, this message translates to:
  /// **'Line {n}: choose a product.'**
  String bulkQpLineProduct(int n);

  /// No description provided for @bulkQpLineQty.
  ///
  /// In en, this message translates to:
  /// **'Line {n}: enter a quantity from 1 to {max}.'**
  String bulkQpLineQty(int n, String max);

  /// No description provided for @bulkQpLinePrice.
  ///
  /// In en, this message translates to:
  /// **'Line {n}: enter the unit price.'**
  String bulkQpLinePrice(int n);

  /// No description provided for @bulkQpLinePriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Line {n}: the unit price is too high.'**
  String bulkQpLinePriceHigh(int n);

  /// No description provided for @bulkQpLineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Line {n}: the discount is 0 to 100%.'**
  String bulkQpLineDiscount(int n);

  /// No description provided for @bulkQpDelivery.
  ///
  /// In en, this message translates to:
  /// **'Enter a delivery charge up to Rs 5,000,000.'**
  String get bulkQpDelivery;

  /// No description provided for @bulkQpValidNeeded.
  ///
  /// In en, this message translates to:
  /// **'Choose until when the quote is valid.'**
  String get bulkQpValidNeeded;

  /// No description provided for @bulkQpValidPast.
  ///
  /// In en, this message translates to:
  /// **'Valid until is today or later.'**
  String get bulkQpValidPast;

  /// No description provided for @bulkQpAdvance.
  ///
  /// In en, this message translates to:
  /// **'The advance is 0 to 100%.'**
  String get bulkQpAdvance;

  /// No description provided for @bulkQpNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes are up to 500 letters.'**
  String get bulkQpNotes;

  /// No description provided for @bulkQpTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This quote is too large. Split it into smaller deals.'**
  String get bulkQpTooLarge;

  /// No description provided for @bulkSerialCount.
  ///
  /// In en, this message translates to:
  /// **'{title}: {serials} serials for {qty} units. Enter one per unit, or none.'**
  String bulkSerialCount(String title, String serials, int qty);

  /// No description provided for @bulkSerialTwice.
  ///
  /// In en, this message translates to:
  /// **'{title}: a serial is listed twice.'**
  String bulkSerialTwice(String title);

  /// No description provided for @bulkDeliverWhoNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enter who received the units.'**
  String get bulkDeliverWhoNeeded;

  /// No description provided for @bulkDeliverWhoLong.
  ///
  /// In en, this message translates to:
  /// **'Received by is up to 100 letters.'**
  String get bulkDeliverWhoLong;

  /// No description provided for @bulkDeliverNoteLong.
  ///
  /// In en, this message translates to:
  /// **'The note is up to 500 letters.'**
  String get bulkDeliverNoteLong;

  /// No description provided for @bulkPayAmountNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount received.'**
  String get bulkPayAmountNeeded;

  /// No description provided for @bulkPayOverBalance.
  ///
  /// In en, this message translates to:
  /// **'More than the balance of {amount}'**
  String bulkPayOverBalance(String amount);

  /// No description provided for @bulkPayAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get bulkPayAdvance;

  /// No description provided for @bulkPayHalf.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get bulkPayHalf;

  /// No description provided for @bulkPayFull.
  ///
  /// In en, this message translates to:
  /// **'Full balance'**
  String get bulkPayFull;

  /// No description provided for @bulkMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get bulkMethodBank;

  /// No description provided for @bulkMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get bulkMethodCash;

  /// No description provided for @bulkMethodCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get bulkMethodCheque;

  /// No description provided for @bulkTermsEach.
  ///
  /// In en, this message translates to:
  /// **'Before each delivery'**
  String get bulkTermsEach;

  /// No description provided for @bulkTermsLast.
  ///
  /// In en, this message translates to:
  /// **'Before the last delivery'**
  String get bulkTermsLast;

  /// No description provided for @bulkDealOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get bulkDealOpen;

  /// No description provided for @bulkDealDelivering.
  ///
  /// In en, this message translates to:
  /// **'Delivering'**
  String get bulkDealDelivering;

  /// No description provided for @bulkDealDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get bulkDealDelivered;

  /// No description provided for @bulkDealPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get bulkDealPaid;

  /// No description provided for @bulkDealClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get bulkDealClosed;

  /// No description provided for @bulkQuoteDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get bulkQuoteDraft;

  /// No description provided for @bulkQuoteSuperseded.
  ///
  /// In en, this message translates to:
  /// **'Superseded'**
  String get bulkQuoteSuperseded;

  /// No description provided for @bulkQuoteExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get bulkQuoteExpired;

  /// No description provided for @bulkQuoteSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get bulkQuoteSent;

  /// No description provided for @bulkWhenToday.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String bulkWhenToday(String time);

  /// No description provided for @bulkWhenYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String bulkWhenYesterday(String time);

  /// No description provided for @bulkAgoNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get bulkAgoNow;

  /// No description provided for @bulkAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String bulkAgoMinutes(int minutes);

  /// No description provided for @bulkAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String bulkAgoHours(int hours);

  /// No description provided for @bulkAgoYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get bulkAgoYesterday;

  /// No description provided for @bulkStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {reached} of {total}: {label}'**
  String bulkStepOf(int reached, int total, String label);

  /// No description provided for @bulkVerifiedSeller.
  ///
  /// In en, this message translates to:
  /// **'Verified seller'**
  String get bulkVerifiedSeller;

  /// No description provided for @bulkNeededBy.
  ///
  /// In en, this message translates to:
  /// **'Needed by'**
  String get bulkNeededBy;

  /// No description provided for @bulkNeedByDate.
  ///
  /// In en, this message translates to:
  /// **'{lead} {date}'**
  String bulkNeedByDate(String lead, String date);

  /// No description provided for @bulkCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get bulkCall;

  /// No description provided for @bulkWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get bulkWhatsApp;

  /// No description provided for @bulkNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed, or it belongs to another outlet.'**
  String get bulkNotFoundBody;

  /// No description provided for @bulkFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get bulkFree;

  /// No description provided for @bulkPickHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a request or deal to see it here'**
  String get bulkPickHint;

  /// No description provided for @bulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk deals'**
  String get bulkTitle;

  /// No description provided for @bulkAskAtom.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom'**
  String get bulkAskAtom;

  /// No description provided for @bulkSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get bulkSearch;

  /// No description provided for @bulkTabBadge.
  ///
  /// In en, this message translates to:
  /// **'{label}, {badge} new'**
  String bulkTabBadge(String label, int badge);

  /// No description provided for @bulkTabSellers.
  ///
  /// In en, this message translates to:
  /// **'Seller requests'**
  String get bulkTabSellers;

  /// No description provided for @bulkTabWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get bulkTabWebsite;

  /// No description provided for @bulkTabDeals.
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get bulkTabDeals;

  /// No description provided for @bulkKpiNew.
  ///
  /// In en, this message translates to:
  /// **'New requests'**
  String get bulkKpiNew;

  /// No description provided for @bulkKpiNewNote.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your reply'**
  String get bulkKpiNewNote;

  /// No description provided for @bulkKpiQuotesOut.
  ///
  /// In en, this message translates to:
  /// **'Quotes out'**
  String get bulkKpiQuotesOut;

  /// No description provided for @bulkKpiQuotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 quote} other{{count} quotes}}'**
  String bulkKpiQuotes(int count);

  /// No description provided for @bulkKpiExpireSoon.
  ///
  /// In en, this message translates to:
  /// **'{count} expire this week'**
  String bulkKpiExpireSoon(int count);

  /// No description provided for @bulkKpiWon.
  ///
  /// In en, this message translates to:
  /// **'Won this month'**
  String get bulkKpiWon;

  /// No description provided for @bulkKpiDeals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 deal} other{{count} deals}}'**
  String bulkKpiDeals(int count);

  /// No description provided for @bulkKpiWinRate.
  ///
  /// In en, this message translates to:
  /// **'win rate {rate}%'**
  String bulkKpiWinRate(String rate);

  /// No description provided for @bulkKpiCollect.
  ///
  /// In en, this message translates to:
  /// **'Still to collect'**
  String get bulkKpiCollect;

  /// No description provided for @bulkKpiOpenDeals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{On 1 open deal} other{On {count} open deals}}'**
  String bulkKpiOpenDeals(int count);

  /// No description provided for @bulkKpiChangeAsked.
  ///
  /// In en, this message translates to:
  /// **'{count} asked for a change'**
  String bulkKpiChangeAsked(int count);

  /// No description provided for @bulkKpiOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get bulkKpiOpenNow;

  /// No description provided for @bulkSellersNote.
  ///
  /// In en, this message translates to:
  /// **'Verified Atomshop sellers asking you for stock for their shops. They answer your quote in their app; the seller pays you directly. Quote before their \"needed by\" date.'**
  String get bulkSellersNote;

  /// No description provided for @bulkSellersNoteBold.
  ///
  /// In en, this message translates to:
  /// **'Verified Atomshop sellers asking you for stock'**
  String get bulkSellersNoteBold;

  /// No description provided for @bulkChangeAskedNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A seller asked for a change to your quote. See Quoted.} other{{count} sellers asked for a change to your quote. See Quoted.}}'**
  String bulkChangeAskedNote(int count);

  /// No description provided for @bulkEmptySellersNew.
  ///
  /// In en, this message translates to:
  /// **'No new seller requests'**
  String get bulkEmptySellersNew;

  /// No description provided for @bulkEmptyAccepted.
  ///
  /// In en, this message translates to:
  /// **'No accepted quotes yet'**
  String get bulkEmptyAccepted;

  /// No description provided for @bulkEmptyDeclined.
  ///
  /// In en, this message translates to:
  /// **'Nothing declined'**
  String get bulkEmptyDeclined;

  /// No description provided for @bulkEmptyHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get bulkEmptyHere;

  /// No description provided for @bulkEmptySellersBody.
  ///
  /// In en, this message translates to:
  /// **'When an Atomshop seller asks you for stock, it shows here.'**
  String get bulkEmptySellersBody;

  /// No description provided for @bulkSellersFooter.
  ///
  /// In en, this message translates to:
  /// **'A seller can have up to 10 open requests. Atomshop\'s commission on seller deals is shown on the request before you send a quote.'**
  String get bulkSellersFooter;

  /// No description provided for @bulkValidUntil.
  ///
  /// In en, this message translates to:
  /// **'valid until {date}'**
  String bulkValidUntil(String date);

  /// No description provided for @bulkHopingFor.
  ///
  /// In en, this message translates to:
  /// **'Hoping for {price} a unit'**
  String bulkHopingFor(String price);

  /// No description provided for @bulkYourPrice.
  ///
  /// In en, this message translates to:
  /// **'your price {price}'**
  String bulkYourPrice(String price);

  /// No description provided for @bulkSellerSaid.
  ///
  /// In en, this message translates to:
  /// **'Seller said: {reason}'**
  String bulkSellerSaid(String reason);

  /// No description provided for @bulkActSendNewQuote.
  ///
  /// In en, this message translates to:
  /// **'Send new quote'**
  String get bulkActSendNewQuote;

  /// No description provided for @bulkOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get bulkOpen;

  /// No description provided for @bulkTypedTag.
  ///
  /// In en, this message translates to:
  /// **'Not in your catalogue · typed by the seller'**
  String get bulkTypedTag;

  /// No description provided for @bulkEmptyWebNew.
  ///
  /// In en, this message translates to:
  /// **'No new enquiries'**
  String get bulkEmptyWebNew;

  /// No description provided for @bulkEmptyWebBody.
  ///
  /// In en, this message translates to:
  /// **'They appear here the moment a buyer asks for a quote.'**
  String get bulkEmptyWebBody;

  /// No description provided for @bulkWebFooter.
  ///
  /// In en, this message translates to:
  /// **'Website buyers asking atomshop.pk for a bulk price. Reply fast: the first brand to call usually wins.'**
  String get bulkWebFooter;

  /// No description provided for @bulkDealStatus.
  ///
  /// In en, this message translates to:
  /// **'Deal status'**
  String get bulkDealStatus;

  /// No description provided for @bulkAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get bulkAny;

  /// No description provided for @bulkStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String bulkStatusFilter(String status);

  /// No description provided for @bulkEmptyDeals.
  ///
  /// In en, this message translates to:
  /// **'No deals yet'**
  String get bulkEmptyDeals;

  /// No description provided for @bulkEmptyDealsHere.
  ///
  /// In en, this message translates to:
  /// **'No deals here'**
  String get bulkEmptyDealsHere;

  /// No description provided for @bulkEmptyDealsBody.
  ///
  /// In en, this message translates to:
  /// **'A deal opens when a buyer or a seller says yes to your quote.'**
  String get bulkEmptyDealsBody;

  /// No description provided for @bulkWonOn.
  ///
  /// In en, this message translates to:
  /// **'Won {date}'**
  String bulkWonOn(String date);

  /// No description provided for @bulkSellerTag.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get bulkSellerTag;

  /// No description provided for @bulkUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit} other{{count} units}}'**
  String bulkUnits(int count);

  /// No description provided for @bulkDeliveredOf.
  ///
  /// In en, this message translates to:
  /// **'Delivered {done} of {units}'**
  String bulkDeliveredOf(int done, int units);

  /// No description provided for @bulkPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount}'**
  String bulkPaidAmount(String amount);

  /// No description provided for @bulkPercentPaid.
  ///
  /// In en, this message translates to:
  /// **'{pct} percent paid'**
  String bulkPercentPaid(int pct);

  /// No description provided for @bulkAmountDue.
  ///
  /// In en, this message translates to:
  /// **'{amount} due'**
  String bulkAmountDue(String amount);

  /// No description provided for @bulkPaidInFull.
  ///
  /// In en, this message translates to:
  /// **'Paid in full'**
  String get bulkPaidInFull;

  /// No description provided for @bulkDeliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get bulkDeliver;

  /// No description provided for @bulkRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get bulkRecordPayment;

  /// No description provided for @acctBeingChecked.
  ///
  /// In en, this message translates to:
  /// **'Being checked'**
  String get acctBeingChecked;

  /// No description provided for @acctReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get acctReadOnly;

  /// No description provided for @acctLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get acctLate;

  /// No description provided for @acctBillWaiting.
  ///
  /// In en, this message translates to:
  /// **'Bill waiting'**
  String get acctBillWaiting;

  /// No description provided for @acctNoPlanYet.
  ///
  /// In en, this message translates to:
  /// **'No plan yet'**
  String get acctNoPlanYet;

  /// No description provided for @acctFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get acctFreeTrial;

  /// No description provided for @acctPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get acctPaid;

  /// No description provided for @acctFreeUntil.
  ///
  /// In en, this message translates to:
  /// **'Free until {day}'**
  String acctFreeUntil(String day);

  /// No description provided for @acctFreeTrialUntil.
  ///
  /// In en, this message translates to:
  /// **'Free trial until {day}'**
  String acctFreeTrialUntil(String day);

  /// No description provided for @acctPaidUntilDay.
  ///
  /// In en, this message translates to:
  /// **'Paid until {day}'**
  String acctPaidUntilDay(String day);

  /// No description provided for @acctBasicPackage.
  ///
  /// In en, this message translates to:
  /// **'Basic package'**
  String get acctBasicPackage;

  /// No description provided for @acctMultiOutlet.
  ///
  /// In en, this message translates to:
  /// **'Multi-outlet'**
  String get acctMultiOutlet;

  /// No description provided for @acctSingleOutlet.
  ///
  /// In en, this message translates to:
  /// **'Single outlet'**
  String get acctSingleOutlet;

  /// No description provided for @acctOutletCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 outlet} other{{count} outlets}}'**
  String acctOutletCount(int count);

  /// No description provided for @acctEndsToday.
  ///
  /// In en, this message translates to:
  /// **'Ends today'**
  String get acctEndsToday;

  /// No description provided for @acctDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String acctDaysLeft(int count);

  /// No description provided for @acctFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get acctFree;

  /// No description provided for @acctFreeTrialLeft.
  ///
  /// In en, this message translates to:
  /// **'Free trial · {left}'**
  String acctFreeTrialLeft(String left);

  /// No description provided for @acctTrialStops.
  ///
  /// In en, this message translates to:
  /// **'Trial stops {day}'**
  String acctTrialStops(String day);

  /// No description provided for @acctOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get acctOn;

  /// No description provided for @acctOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get acctOff;

  /// No description provided for @acctEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get acctEnded;

  /// No description provided for @acctSwitchedOffUntil.
  ///
  /// In en, this message translates to:
  /// **'Switched off · works until {day}'**
  String acctSwitchedOffUntil(String day);

  /// No description provided for @acctBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get acctBill;

  /// No description provided for @acctRenewal.
  ///
  /// In en, this message translates to:
  /// **'{month} renewal'**
  String acctRenewal(String month);

  /// No description provided for @acctCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get acctCancelled;

  /// No description provided for @acctPartPaid.
  ///
  /// In en, this message translates to:
  /// **'Part paid'**
  String get acctPartPaid;

  /// No description provided for @acctToPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get acctToPay;

  /// No description provided for @acctReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get acctReceived;

  /// No description provided for @acctNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get acctNotFound;

  /// No description provided for @acctReversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get acctReversed;

  /// No description provided for @acctBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get acctBank;

  /// No description provided for @acctJazzCash.
  ///
  /// In en, this message translates to:
  /// **'JazzCash'**
  String get acctJazzCash;

  /// No description provided for @acctEasypaisa.
  ///
  /// In en, this message translates to:
  /// **'Easypaisa'**
  String get acctEasypaisa;

  /// No description provided for @acctCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get acctCash;

  /// No description provided for @acctCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get acctCheque;

  /// No description provided for @acctPayNoMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose how you paid'**
  String get acctPayNoMethod;

  /// No description provided for @acctPayNoAmount.
  ///
  /// In en, this message translates to:
  /// **'Type the amount you paid'**
  String get acctPayNoAmount;

  /// No description provided for @acctPayTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That amount is too large'**
  String get acctPayTooLarge;

  /// No description provided for @acctPayNoDay.
  ///
  /// In en, this message translates to:
  /// **'Choose the day you paid'**
  String get acctPayNoDay;

  /// No description provided for @acctPayFutureDay.
  ///
  /// In en, this message translates to:
  /// **'The day you paid can\'t be in the future'**
  String get acctPayFutureDay;

  /// No description provided for @acctPayRefTooLong.
  ///
  /// In en, this message translates to:
  /// **'The transaction ID is too long (100 characters at most)'**
  String get acctPayRefTooLong;

  /// No description provided for @acctPayNoScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Add the payment screenshot'**
  String get acctPayNoScreenshot;

  /// No description provided for @acctOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get acctOneYear;

  /// No description provided for @acctMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String acctMonths(int count);

  /// No description provided for @acctMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get acctMonthly;

  /// No description provided for @acctYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get acctYearly;

  /// No description provided for @acctEveryMonths.
  ///
  /// In en, this message translates to:
  /// **'Every {count} months'**
  String acctEveryMonths(int count);

  /// No description provided for @acctShopNeedOnePay.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one way for customers to pay'**
  String get acctShopNeedOnePay;

  /// No description provided for @acctShopNeedBankName.
  ///
  /// In en, this message translates to:
  /// **'Enter the bank name, or switch bank transfer off'**
  String get acctShopNeedBankName;

  /// No description provided for @acctShopNeedBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the account title, or switch bank transfer off'**
  String get acctShopNeedBankTitle;

  /// No description provided for @acctShopNeedIban.
  ///
  /// In en, this message translates to:
  /// **'Enter the IBAN, or switch bank transfer off'**
  String get acctShopNeedIban;

  /// No description provided for @acctShopBadIban.
  ///
  /// In en, this message translates to:
  /// **'An IBAN looks like PK36 MEZN 0002 4501 0123 4567'**
  String get acctShopBadIban;

  /// No description provided for @acctShopNeedWallet.
  ///
  /// In en, this message translates to:
  /// **'Enter a JazzCash or Easypaisa number'**
  String get acctShopNeedWallet;

  /// No description provided for @acctShopBadMobile.
  ///
  /// In en, this message translates to:
  /// **'A mobile number looks like 0300 1234567'**
  String get acctShopBadMobile;

  /// No description provided for @acctShopPickHours.
  ///
  /// In en, this message translates to:
  /// **'Pick 2, 4, 8 or 24 hours'**
  String get acctShopPickHours;

  /// No description provided for @acctShopLowStockRange.
  ///
  /// In en, this message translates to:
  /// **'Between 0 and 100 units'**
  String get acctShopLowStockRange;

  /// No description provided for @acctShopNoteTooLong.
  ///
  /// In en, this message translates to:
  /// **'Up to 200 characters'**
  String get acctShopNoteTooLong;

  /// No description provided for @acctShopPickMinutes.
  ///
  /// In en, this message translates to:
  /// **'Pick 15 or 30 minutes'**
  String get acctShopPickMinutes;

  /// No description provided for @acctPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get acctPeriodToday;

  /// No description provided for @acctPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get acctPeriodMonth;

  /// No description provided for @acctPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get acctPeriodYear;

  /// No description provided for @acctPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get acctPeriodAll;

  /// No description provided for @acctPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get acctPeriodCustom;

  /// No description provided for @acctTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get acctTotal;

  /// No description provided for @acctPdfFooterMade.
  ///
  /// In en, this message translates to:
  /// **'Atombrand · Made {when}'**
  String acctPdfFooterMade(String when);

  /// No description provided for @acctFeatInventory1.
  ///
  /// In en, this message translates to:
  /// **'Stock in, adjust and move units between warehouses'**
  String get acctFeatInventory1;

  /// No description provided for @acctFeatInventory2.
  ///
  /// In en, this message translates to:
  /// **'Orders hold a unit while you confirm them'**
  String get acctFeatInventory2;

  /// No description provided for @acctFeatInventory3.
  ///
  /// In en, this message translates to:
  /// **'Out-of-stock products show as such on atomshop.pk'**
  String get acctFeatInventory3;

  /// No description provided for @acctFeatTeam1.
  ///
  /// In en, this message translates to:
  /// **'Order handler, Bulk sales, Stock keeper, Marketing, Accountant'**
  String get acctFeatTeam1;

  /// No description provided for @acctFeatTeam2.
  ///
  /// In en, this message translates to:
  /// **'Each person sees only their outlets'**
  String get acctFeatTeam2;

  /// No description provided for @acctFeatTeam3.
  ///
  /// In en, this message translates to:
  /// **'Switch anyone off in a tap'**
  String get acctFeatTeam3;

  /// No description provided for @acctFeatAskAtom1.
  ///
  /// In en, this message translates to:
  /// **'Which orders wait to be confirmed'**
  String get acctFeatAskAtom1;

  /// No description provided for @acctFeatAskAtom2.
  ///
  /// In en, this message translates to:
  /// **'Which quotes run out this week'**
  String get acctFeatAskAtom2;

  /// No description provided for @acctFeatAskAtom3.
  ///
  /// In en, this message translates to:
  /// **'What is running low'**
  String get acctFeatAskAtom3;

  /// No description provided for @acctFeatAlerts1.
  ///
  /// In en, this message translates to:
  /// **'A new order or bulk request the moment it arrives'**
  String get acctFeatAlerts1;

  /// No description provided for @acctFeatAlerts2.
  ///
  /// In en, this message translates to:
  /// **'AtomPay units to hand over'**
  String get acctFeatAlerts2;

  /// No description provided for @acctFeatAlerts3.
  ///
  /// In en, this message translates to:
  /// **'Quiet 10 PM to 8 AM'**
  String get acctFeatAlerts3;

  /// No description provided for @acctFeatOffline1.
  ///
  /// In en, this message translates to:
  /// **'Orders, stock and payments work with no signal'**
  String get acctFeatOffline1;

  /// No description provided for @acctFeatOffline2.
  ///
  /// In en, this message translates to:
  /// **'Changes wait on the phone and send when you are back'**
  String get acctFeatOffline2;

  /// No description provided for @acctFeatOffline3.
  ///
  /// In en, this message translates to:
  /// **'A copy of your records, locked with your PIN'**
  String get acctFeatOffline3;

  /// No description provided for @acctAddonTrialStarted.
  ///
  /// In en, this message translates to:
  /// **'{name} is on: free trial started'**
  String acctAddonTrialStarted(String name);

  /// No description provided for @acctAddonIsOff.
  ///
  /// In en, this message translates to:
  /// **'{name} is off'**
  String acctAddonIsOff(String name);

  /// No description provided for @acctAddonStopsAtEnd.
  ///
  /// In en, this message translates to:
  /// **'{name} stops at the end of the period'**
  String acctAddonStopsAtEnd(String name);

  /// No description provided for @acctBillReady.
  ///
  /// In en, this message translates to:
  /// **'Bill {number} is ready'**
  String acctBillReady(String number);

  /// No description provided for @acctAddonIsOn.
  ///
  /// In en, this message translates to:
  /// **'{name} is on'**
  String acctAddonIsOn(String name);

  /// No description provided for @acctAddonNotSold.
  ///
  /// In en, this message translates to:
  /// **'This add-on isn\'t sold to brands'**
  String get acctAddonNotSold;

  /// No description provided for @acctAddonTryTitle.
  ///
  /// In en, this message translates to:
  /// **'Try it free for {count} days'**
  String acctAddonTryTitle(int count);

  /// No description provided for @acctAddonTrySub.
  ///
  /// In en, this message translates to:
  /// **'Then it is added to your bill, unless you switch it off during the trial.'**
  String get acctAddonTrySub;

  /// No description provided for @acctAddonTryCta.
  ///
  /// In en, this message translates to:
  /// **'Try free'**
  String get acctAddonTryCta;

  /// No description provided for @acctAddonPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch on and pay now'**
  String get acctAddonPayTitle;

  /// No description provided for @acctAddonPaySub.
  ///
  /// In en, this message translates to:
  /// **'A bill for the rest of this period, then it renews with your plan.'**
  String get acctAddonPaySub;

  /// No description provided for @acctSwitchOn.
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get acctSwitchOn;

  /// No description provided for @acctAddonKeepOn.
  ///
  /// In en, this message translates to:
  /// **'Keep it on'**
  String get acctAddonKeepOn;

  /// No description provided for @acctAddonCarriesOn.
  ///
  /// In en, this message translates to:
  /// **'It carries on with your plan.'**
  String get acctAddonCarriesOn;

  /// No description provided for @acctAddonWasStopping.
  ///
  /// In en, this message translates to:
  /// **'It was going to stop on {day}. Keep it and it renews with your plan.'**
  String acctAddonWasStopping(String day);

  /// No description provided for @acctAddonOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch it off'**
  String get acctAddonOffTitle;

  /// No description provided for @acctAddonOffTrial.
  ///
  /// In en, this message translates to:
  /// **'The free trial stops now.'**
  String get acctAddonOffTrial;

  /// No description provided for @acctAddonOffLegacy.
  ///
  /// In en, this message translates to:
  /// **'It stops now; switching it on again later starts a bill.'**
  String get acctAddonOffLegacy;

  /// No description provided for @acctAddonOffPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'It works until the period ends, then it isn\'t renewed.'**
  String get acctAddonOffPeriodEnd;

  /// No description provided for @acctAddonOffUntil.
  ///
  /// In en, this message translates to:
  /// **'It works until {day}, then it isn\'t renewed.'**
  String acctAddonOffUntil(String day);

  /// No description provided for @acctSwitchOff.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get acctSwitchOff;

  /// No description provided for @acctAddonFreeUntilDot.
  ///
  /// In en, this message translates to:
  /// **'Free until {day}.'**
  String acctAddonFreeUntilDot(String day);

  /// No description provided for @acctAddonAfterLegacy.
  ///
  /// In en, this message translates to:
  /// **'After that it joins your bill, or you can switch it off.'**
  String get acctAddonAfterLegacy;

  /// No description provided for @acctAddonEnded.
  ///
  /// In en, this message translates to:
  /// **'It ended: you can still see what is there, but not change it.'**
  String get acctAddonEnded;

  /// No description provided for @acctPlanOn.
  ///
  /// In en, this message translates to:
  /// **'Your plan is on.'**
  String get acctPlanOn;

  /// No description provided for @acctBillReadyDot.
  ///
  /// In en, this message translates to:
  /// **'Bill {number} is ready.'**
  String acctBillReadyDot(String number);

  /// No description provided for @acctRenewTitle.
  ///
  /// In en, this message translates to:
  /// **'Renew or change your plan'**
  String get acctRenewTitle;

  /// No description provided for @acctHowLong.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get acctHowLong;

  /// No description provided for @acctAddons.
  ///
  /// In en, this message translates to:
  /// **'Add-ons'**
  String get acctAddons;

  /// No description provided for @acctYourBill.
  ///
  /// In en, this message translates to:
  /// **'Your bill'**
  String get acctYourBill;

  /// No description provided for @acctChangePeriod.
  ///
  /// In en, this message translates to:
  /// **'Change the period or add-ons'**
  String get acctChangePeriod;

  /// No description provided for @acctGetBill.
  ///
  /// In en, this message translates to:
  /// **'Get my bill'**
  String get acctGetBill;

  /// No description provided for @acctGetBillTotal.
  ///
  /// In en, this message translates to:
  /// **'Get my bill · {total}'**
  String acctGetBillTotal(String total);

  /// No description provided for @acctNotSoldFor.
  ///
  /// In en, this message translates to:
  /// **'Not sold for {period}'**
  String acctNotSoldFor(String period);

  /// No description provided for @acctPriceFor.
  ///
  /// In en, this message translates to:
  /// **'{price} for {period}'**
  String acctPriceFor(String price, String period);

  /// No description provided for @acctSpecialPrice.
  ///
  /// In en, this message translates to:
  /// **'Special price'**
  String get acctSpecialPrice;

  /// No description provided for @acctYourCredit.
  ///
  /// In en, this message translates to:
  /// **'Your credit'**
  String get acctYourCredit;

  /// No description provided for @acctDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily summary'**
  String get acctDailyTitle;

  /// No description provided for @acctDailySend.
  ///
  /// In en, this message translates to:
  /// **'Send me a daily summary'**
  String get acctDailySend;

  /// No description provided for @acctDailySendSub.
  ///
  /// In en, this message translates to:
  /// **'On WhatsApp and in the app, at 9:00 am'**
  String get acctDailySendSub;

  /// No description provided for @acctDailyTellsAbout.
  ///
  /// In en, this message translates to:
  /// **'It tells you about'**
  String get acctDailyTellsAbout;

  /// No description provided for @acctDailyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Orders to confirm'**
  String get acctDailyConfirm;

  /// No description provided for @acctDailyConfirmSub.
  ///
  /// In en, this message translates to:
  /// **'New orders still waiting, oldest first'**
  String get acctDailyConfirmSub;

  /// No description provided for @acctDailyQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes running out'**
  String get acctDailyQuotes;

  /// No description provided for @acctDailyQuotesSub.
  ///
  /// In en, this message translates to:
  /// **'Sent quotes that end within 2 days'**
  String get acctDailyQuotesSub;

  /// No description provided for @acctDailyHandOverSub.
  ///
  /// In en, this message translates to:
  /// **'Units Atomshop gave to a seller'**
  String get acctDailyHandOverSub;

  /// No description provided for @acctDailyLow.
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get acctDailyLow;

  /// No description provided for @acctDailyLowSub.
  ///
  /// In en, this message translates to:
  /// **'Products at or under your low-stock number'**
  String get acctDailyLowSub;

  /// No description provided for @acctDailyYouSee.
  ///
  /// In en, this message translates to:
  /// **'You see'**
  String get acctDailyYouSee;

  /// No description provided for @acctDailySample.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}. {brand} today: 3 orders to confirm (oldest 6 hours), 1 quote runs out tomorrow, 1 AtomPay unit to hand over.'**
  String acctDailySample(String name, String brand);

  /// No description provided for @acctDailyThere.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get acctDailyThere;

  /// No description provided for @acctDailyYourBrand.
  ///
  /// In en, this message translates to:
  /// **'Your brand'**
  String get acctDailyYourBrand;

  /// No description provided for @acctDailyNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to report? No message that day.'**
  String get acctDailyNothing;

  /// No description provided for @acctDailySoon.
  ///
  /// In en, this message translates to:
  /// **'Daily summary is coming soon'**
  String get acctDailySoon;

  /// No description provided for @acctDailySoonBody.
  ///
  /// In en, this message translates to:
  /// **'One message each morning with the orders to confirm, quotes running out and units to hand over.'**
  String get acctDailySoonBody;

  /// No description provided for @acctPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get acctPaidOn;

  /// No description provided for @acctPaymentSent.
  ///
  /// In en, this message translates to:
  /// **'Payment sent. It shows as Being checked until Atomshop finds it.'**
  String get acctPaymentSent;

  /// No description provided for @acctIvePaid.
  ///
  /// In en, this message translates to:
  /// **'I\'ve paid'**
  String get acctIvePaid;

  /// No description provided for @acctSendPayment.
  ///
  /// In en, this message translates to:
  /// **'Send payment'**
  String get acctSendPayment;

  /// No description provided for @acctWalletNumber.
  ///
  /// In en, this message translates to:
  /// **'{wallet} number'**
  String acctWalletNumber(String wallet);

  /// No description provided for @acctAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account title'**
  String get acctAccountTitle;

  /// No description provided for @acctIban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get acctIban;

  /// No description provided for @acctHowToPay.
  ///
  /// In en, this message translates to:
  /// **'How to pay Atomshop'**
  String get acctHowToPay;

  /// No description provided for @acctAskForAccount.
  ///
  /// In en, this message translates to:
  /// **'Ask Atomshop for the account to pay into.'**
  String get acctAskForAccount;

  /// No description provided for @acctAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get acctAmount;

  /// No description provided for @acctNotForOneBill.
  ///
  /// In en, this message translates to:
  /// **'Not for one bill'**
  String get acctNotForOneBill;

  /// No description provided for @acctWhichBill.
  ///
  /// In en, this message translates to:
  /// **'Which bill?'**
  String get acctWhichBill;

  /// No description provided for @acctTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get acctTransactionId;

  /// No description provided for @acctOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get acctOptional;

  /// No description provided for @acctTransactionIdHint.
  ///
  /// In en, this message translates to:
  /// **'From your bank or wallet message'**
  String get acctTransactionIdHint;

  /// No description provided for @acctPayCheckedNote.
  ///
  /// In en, this message translates to:
  /// **'Your payment shows as Being checked until Atomshop finds it. You keep using everything meanwhile.'**
  String get acctPayCheckedNote;

  /// No description provided for @acctScreenshotAdded.
  ///
  /// In en, this message translates to:
  /// **'Screenshot added · change'**
  String get acctScreenshotAdded;

  /// No description provided for @acctAddonsFollow.
  ///
  /// In en, this message translates to:
  /// **'add-ons follow the same period'**
  String get acctAddonsFollow;

  /// No description provided for @acctPayAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String acctPayAmount(String amount);

  /// No description provided for @acctPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get acctPlan;

  /// No description provided for @acctNoneYet.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get acctNoneYet;

  /// No description provided for @acctPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until'**
  String get acctPaidUntil;

  /// No description provided for @acctAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get acctAmountDue;

  /// No description provided for @acctNothingToPay.
  ///
  /// In en, this message translates to:
  /// **'Nothing to pay'**
  String get acctNothingToPay;

  /// No description provided for @acctOpenBills.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open bill} other{{count} open bills}}'**
  String acctOpenBills(int count);

  /// No description provided for @acctCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get acctCredit;

  /// No description provided for @acctSpecialPricePct.
  ///
  /// In en, this message translates to:
  /// **'{pct} special price'**
  String acctSpecialPricePct(String pct);

  /// No description provided for @acctNoSpecialPrice.
  ///
  /// In en, this message translates to:
  /// **'No special price'**
  String get acctNoSpecialPrice;

  /// No description provided for @acctDueOn.
  ///
  /// In en, this message translates to:
  /// **'due {day}'**
  String acctDueOn(String day);

  /// No description provided for @acctPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get acctPay;

  /// No description provided for @acctHowLongLine.
  ///
  /// In en, this message translates to:
  /// **'How long: {periods}'**
  String acctHowLongLine(String periods);

  /// No description provided for @acctRenewSub.
  ///
  /// In en, this message translates to:
  /// **'Pick add-ons, see the total, get my bill'**
  String get acctRenewSub;

  /// No description provided for @acctYourPayments.
  ///
  /// In en, this message translates to:
  /// **'Your payments'**
  String get acctYourPayments;

  /// No description provided for @acctReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get acctReceipt;

  /// No description provided for @acctBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get acctBills;

  /// No description provided for @acctPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get acctPdf;

  /// No description provided for @acctPricesNote.
  ///
  /// In en, this message translates to:
  /// **'Prices come from Atomshop\'s price list. Switching an add-on off keeps it until the period ends.'**
  String get acctPricesNote;

  /// No description provided for @acctPeriodsOr.
  ///
  /// In en, this message translates to:
  /// **'{list} or {last} months'**
  String acctPeriodsOr(String list, String last);

  /// No description provided for @acctCopyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy {label}'**
  String acctCopyLabel(String label);

  /// No description provided for @acctCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String acctCopied(String label);

  /// No description provided for @acctPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make the PDF on this phone. Try again.'**
  String get acctPdfFailed;

  /// No description provided for @acctDownloadsOnPortal.
  ///
  /// In en, this message translates to:
  /// **'Downloads are on the brand portal for now.'**
  String get acctDownloadsOnPortal;

  /// No description provided for @acctReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get acctReport;

  /// No description provided for @acctReportMissing.
  ///
  /// In en, this message translates to:
  /// **'This report isn\'t there for your brand'**
  String get acctReportMissing;

  /// No description provided for @acctExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get acctExcel;

  /// No description provided for @acctExcelOnline.
  ///
  /// In en, this message translates to:
  /// **'Excel · online'**
  String get acctExcelOnline;

  /// No description provided for @accountReportOrders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No orders} =1{1 order} other{{count} orders}}'**
  String accountReportOrders(int count);

  /// No description provided for @accountReportStillDue.
  ///
  /// In en, this message translates to:
  /// **'{amount} still due'**
  String accountReportStillDue(String amount);

  /// No description provided for @accountReportUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No units} =1{1 unit} other{{count} units}}'**
  String accountReportUnits(int count);

  /// No description provided for @accountReportDeals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No deals} =1{1 deal} other{{count} deals}}'**
  String accountReportDeals(int count);

  /// No description provided for @accountReportNoneToday.
  ///
  /// In en, this message translates to:
  /// **'None today'**
  String get accountReportNoneToday;

  /// No description provided for @accountReportMethodIs.
  ///
  /// In en, this message translates to:
  /// **'Method: {method}'**
  String accountReportMethodIs(String method);

  /// No description provided for @accountReportMethodAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get accountReportMethodAny;

  /// No description provided for @accountReportWhichMethod.
  ///
  /// In en, this message translates to:
  /// **'Which method?'**
  String get accountReportWhichMethod;

  /// No description provided for @accountNoPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get accountNoPaymentsYet;

  /// No description provided for @accountNoBillsYet.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get accountNoBillsYet;

  /// No description provided for @acctOutletIs.
  ///
  /// In en, this message translates to:
  /// **'Outlet: {outlet}'**
  String acctOutletIs(String outlet);

  /// No description provided for @acctNothingThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Nothing for this period'**
  String get acctNothingThisPeriod;

  /// No description provided for @acctTryAnotherPeriod.
  ///
  /// In en, this message translates to:
  /// **'Try another period.'**
  String get acctTryAnotherPeriod;

  /// No description provided for @acctMadeAt.
  ///
  /// In en, this message translates to:
  /// **'Made {when}'**
  String acctMadeAt(String when);

  /// No description provided for @acctDateRange.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String acctDateRange(String from, String to);

  /// No description provided for @acctSalesPeriod.
  ///
  /// In en, this message translates to:
  /// **'Sales · {period}'**
  String acctSalesPeriod(String period);

  /// No description provided for @acctCashOrders.
  ///
  /// In en, this message translates to:
  /// **'Cash orders'**
  String get acctCashOrders;

  /// No description provided for @acctPaymentsReceived.
  ///
  /// In en, this message translates to:
  /// **'Payments received'**
  String get acctPaymentsReceived;

  /// No description provided for @acctAtompayPaid.
  ///
  /// In en, this message translates to:
  /// **'AtomPay, paid to you'**
  String get acctAtompayPaid;

  /// No description provided for @acctBulkWon.
  ///
  /// In en, this message translates to:
  /// **'Bulk deals won'**
  String get acctBulkWon;

  /// No description provided for @acctLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get acctLast6Months;

  /// No description provided for @acctNoReports.
  ///
  /// In en, this message translates to:
  /// **'No reports for your role'**
  String get acctNoReports;

  /// No description provided for @acctNoReportsBody.
  ///
  /// In en, this message translates to:
  /// **'Ask the owner if you need one.'**
  String get acctNoReportsBody;

  /// No description provided for @acctReportsOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline: reports need internet. Pull down to try again when you are back.'**
  String get acctReportsOffline;

  /// No description provided for @acctReportsCanExport.
  ///
  /// In en, this message translates to:
  /// **'Open any report, then share it as a PDF on WhatsApp or download Excel.'**
  String get acctReportsCanExport;

  /// No description provided for @acctReportsNoExport.
  ///
  /// In en, this message translates to:
  /// **'Your role can open reports but not download them.'**
  String get acctReportsNoExport;

  /// No description provided for @acctOutlet.
  ///
  /// In en, this message translates to:
  /// **'Outlet'**
  String get acctOutlet;

  /// No description provided for @acctWhichOutlet.
  ///
  /// In en, this message translates to:
  /// **'Which outlet?'**
  String get acctWhichOutlet;

  /// No description provided for @acctMonthSemantics.
  ///
  /// In en, this message translates to:
  /// **'{month}: cash orders {cash}, received {received}'**
  String acctMonthSemantics(String month, String cash, String received);

  /// No description provided for @acctShopSaved.
  ///
  /// In en, this message translates to:
  /// **'Shop settings saved'**
  String get acctShopSaved;

  /// No description provided for @acctShopHowPaid.
  ///
  /// In en, this message translates to:
  /// **'How customers pay you'**
  String get acctShopHowPaid;

  /// No description provided for @acctShopCod.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get acctShopCod;

  /// No description provided for @acctShopCodSub.
  ///
  /// In en, this message translates to:
  /// **'Collected when the unit is handed over'**
  String get acctShopCodSub;

  /// No description provided for @acctShopBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer before dispatch'**
  String get acctShopBank;

  /// No description provided for @acctShopBankSub.
  ///
  /// In en, this message translates to:
  /// **'Shown to customers at checkout'**
  String get acctShopBankSub;

  /// No description provided for @acctShopWallet.
  ///
  /// In en, this message translates to:
  /// **'JazzCash or Easypaisa'**
  String get acctShopWallet;

  /// No description provided for @acctShopWalletSub.
  ///
  /// In en, this message translates to:
  /// **'Paid to your number before dispatch'**
  String get acctShopWalletSub;

  /// No description provided for @acctBankName.
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get acctBankName;

  /// No description provided for @acctShopCashAlways.
  ///
  /// In en, this message translates to:
  /// **'Cash is always allowed when you record a payment.'**
  String get acctShopCashAlways;

  /// No description provided for @acctShopOrdersPortal.
  ///
  /// In en, this message translates to:
  /// **'Orders and the portal'**
  String get acctShopOrdersPortal;

  /// No description provided for @acctShopConfirmWithin.
  ///
  /// In en, this message translates to:
  /// **'Confirm new orders within'**
  String get acctShopConfirmWithin;

  /// No description provided for @acctHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String acctHours(int count);

  /// No description provided for @acctShopConfirmNote.
  ///
  /// In en, this message translates to:
  /// **'Later than this, the task on Home turns red.'**
  String get acctShopConfirmNote;

  /// No description provided for @acctShopIdle.
  ///
  /// In en, this message translates to:
  /// **'Sign out when idle for'**
  String get acctShopIdle;

  /// No description provided for @acctMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String acctMinutes(int count);

  /// No description provided for @acctShopIdleNote.
  ///
  /// In en, this message translates to:
  /// **'For the brand portal on the web.'**
  String get acctShopIdleNote;

  /// No description provided for @acctShopLowAt.
  ///
  /// In en, this message translates to:
  /// **'Running low at'**
  String get acctShopLowAt;

  /// No description provided for @acctShopLowAtNote.
  ///
  /// In en, this message translates to:
  /// **'0–100 units'**
  String get acctShopLowAtNote;

  /// No description provided for @acctShopAtomLanguage.
  ///
  /// In en, this message translates to:
  /// **'Atom language'**
  String get acctShopAtomLanguage;

  /// No description provided for @acctShopAtomAnswersIn.
  ///
  /// In en, this message translates to:
  /// **'Atom answers in'**
  String get acctShopAtomAnswersIn;

  /// No description provided for @acctShopReceiptNote.
  ///
  /// In en, this message translates to:
  /// **'Receipt note'**
  String get acctShopReceiptNote;

  /// No description provided for @acctShopReceiptNoteLimit.
  ///
  /// In en, this message translates to:
  /// **'up to 200 characters'**
  String get acctShopReceiptNoteLimit;

  /// No description provided for @acctShopReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'7-day replacement on factory faults. Keep this receipt.'**
  String get acctShopReceiptHint;

  /// No description provided for @acctLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get acctLangEnglish;

  /// No description provided for @acctLangRomanUrdu.
  ///
  /// In en, this message translates to:
  /// **'Roman Urdu'**
  String get acctLangRomanUrdu;

  /// No description provided for @acctLangAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get acctLangAuto;

  /// No description provided for @askAtomName.
  ///
  /// In en, this message translates to:
  /// **'Atom'**
  String get askAtomName;

  /// No description provided for @askAtomStatus.
  ///
  /// In en, this message translates to:
  /// **'Knows your brand · answers in seconds'**
  String get askAtomStatus;

  /// No description provided for @askAtomStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Needs internet to answer'**
  String get askAtomStatusOffline;

  /// No description provided for @askAtomNoticed.
  ///
  /// In en, this message translates to:
  /// **'Atom noticed'**
  String get askAtomNoticed;

  /// No description provided for @askAtomAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get askAtomAsk;

  /// No description provided for @askAtomRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get askAtomRecent;

  /// No description provided for @askAtomHowFix.
  ///
  /// In en, this message translates to:
  /// **'How to fix it'**
  String get askAtomHowFix;

  /// No description provided for @askAtomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get askAtomConfirm;

  /// No description provided for @askAtomAskAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Ask Atomshop'**
  String get askAtomAskAtomshop;

  /// No description provided for @askAtomHelpfulQ.
  ///
  /// In en, this message translates to:
  /// **'Helpful?'**
  String get askAtomHelpfulQ;

  /// No description provided for @askAtomHelpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get askAtomHelpful;

  /// No description provided for @askAtomNotHelpful.
  ///
  /// In en, this message translates to:
  /// **'Not helpful'**
  String get askAtomNotHelpful;

  /// No description provided for @askAtomThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for telling us.'**
  String get askAtomThanks;

  /// No description provided for @askAtomLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'Atom answers the way you write: English, Roman Urdu or اردو.'**
  String get askAtomLanguageNote;

  /// No description provided for @askAtomHint.
  ///
  /// In en, this message translates to:
  /// **'Ask, or tap the mic'**
  String get askAtomHint;

  /// No description provided for @askAtomHintOffline.
  ///
  /// In en, this message translates to:
  /// **'Atom needs internet'**
  String get askAtomHintOffline;

  /// No description provided for @askAtomSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get askAtomSend;

  /// No description provided for @askAtomWhatsAppUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent? WhatsApp Atomshop'**
  String get askAtomWhatsAppUrgent;

  /// No description provided for @askAtomSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to Atomshop support as {code}. Their reply comes to your notifications.'**
  String askAtomSentTo(String code);

  /// No description provided for @askAtomMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get askAtomMorning;

  /// No description provided for @askAtomAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get askAtomAfternoon;

  /// No description provided for @askAtomEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get askAtomEvening;

  /// No description provided for @askAtomHello.
  ///
  /// In en, this message translates to:
  /// **'{part}. What do you need?'**
  String askAtomHello(String part);

  /// No description provided for @askAtomHelloName.
  ///
  /// In en, this message translates to:
  /// **'{part}, {name}. What do you need?'**
  String askAtomHelloName(String part, String name);

  /// No description provided for @askAtomQOrders.
  ///
  /// In en, this message translates to:
  /// **'Which orders are waiting to be confirmed?'**
  String get askAtomQOrders;

  /// No description provided for @askAtomQQuotes.
  ///
  /// In en, this message translates to:
  /// **'Which quotes run out this week?'**
  String get askAtomQQuotes;

  /// No description provided for @askAtomQLow.
  ///
  /// In en, this message translates to:
  /// **'What is running low?'**
  String get askAtomQLow;

  /// No description provided for @askAtomQSales.
  ///
  /// In en, this message translates to:
  /// **'Sales this month'**
  String get askAtomQSales;

  /// No description provided for @askAtomQRequests.
  ///
  /// In en, this message translates to:
  /// **'Which seller requests are new?'**
  String get askAtomQRequests;

  /// No description provided for @askAtomQAtompay.
  ///
  /// In en, this message translates to:
  /// **'Is mahine kitni AtomPay sales hui?'**
  String get askAtomQAtompay;

  /// No description provided for @askAtomShowThem.
  ///
  /// In en, this message translates to:
  /// **'Show them'**
  String get askAtomShowThem;

  /// No description provided for @askAtomMic.
  ///
  /// In en, this message translates to:
  /// **'Speak your question'**
  String get askAtomMic;

  /// No description provided for @askAtomMicStop.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get askAtomMicStop;

  /// No description provided for @askAtomListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get askAtomListening;

  /// No description provided for @askAtomMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Atom can\'t hear you: the microphone is off for Brand Partner. Allow it in your phone\'s settings, or type your question.'**
  String get askAtomMicDenied;

  /// No description provided for @askAtomMicUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice isn\'t available on this phone. Type your question instead.'**
  String get askAtomMicUnavailable;

  /// No description provided for @applyTypeManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get applyTypeManufacturer;

  /// No description provided for @applyTypeDistributor.
  ///
  /// In en, this message translates to:
  /// **'Official distributor'**
  String get applyTypeDistributor;

  /// No description provided for @applyTypeImporter.
  ///
  /// In en, this message translates to:
  /// **'Authorised importer'**
  String get applyTypeImporter;

  /// No description provided for @applyTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get applyTypeOther;

  /// No description provided for @commonBeingBuilt.
  ///
  /// In en, this message translates to:
  /// **'This screen is being built.'**
  String get commonBeingBuilt;

  /// No description provided for @syncPaidNow.
  ///
  /// In en, this message translates to:
  /// **'Paid on the server now: {amount}.'**
  String syncPaidNow(String amount);

  /// No description provided for @syncWhenToday.
  ///
  /// In en, this message translates to:
  /// **'{time} today'**
  String syncWhenToday(String time);

  /// No description provided for @bulkQuoteLine.
  ///
  /// In en, this message translates to:
  /// **'Quote {name} · {amount}'**
  String bulkQuoteLine(String name, String amount);

  /// No description provided for @bulkQuoteLineColon.
  ///
  /// In en, this message translates to:
  /// **'Quote: {name} · {amount}'**
  String bulkQuoteLineColon(String name, String amount);

  /// No description provided for @bulkNeedBySoon.
  ///
  /// In en, this message translates to:
  /// **'{lead} {day} · {rest}'**
  String bulkNeedBySoon(String lead, String day, String rest);

  /// No description provided for @syncPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String syncPhotoCount(int count);

  /// No description provided for @syncThisWarehouse.
  ///
  /// In en, this message translates to:
  /// **'this warehouse'**
  String get syncThisWarehouse;

  /// No description provided for @teamKpiMembersNote.
  ///
  /// In en, this message translates to:
  /// **'{n} active'**
  String teamKpiMembersNote(int n);

  /// No description provided for @teamKpiRolesNote.
  ///
  /// In en, this message translates to:
  /// **'{ready} ready-made, {own} yours'**
  String teamKpiRolesNote(int ready, int own);

  /// No description provided for @teamAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} is on your team'**
  String teamAddedTitle(String name);

  /// No description provided for @teamPasswordHow.
  ///
  /// In en, this message translates to:
  /// **'{first} signs in with their mobile number and this password, then chooses their own. If it gets lost, reset it from their page.'**
  String teamPasswordHow(String first);

  /// No description provided for @teamAddedNote.
  ///
  /// In en, this message translates to:
  /// **'The app link goes with the WhatsApp message. Their phone gets only what {aRole} may see.'**
  String teamAddedNote(String aRole);

  /// No description provided for @teamAddedNoteOffline.
  ///
  /// In en, this message translates to:
  /// **'The app link goes with the WhatsApp message. Their phone gets only what {aRole} may see, and can work offline on it.'**
  String teamAddedNoteOffline(String aRole);

  /// No description provided for @teamArticleA.
  ///
  /// In en, this message translates to:
  /// **'a {role}'**
  String teamArticleA(String role);

  /// No description provided for @teamArticleAn.
  ///
  /// In en, this message translates to:
  /// **'an {role}'**
  String teamArticleAn(String role);

  /// No description provided for @teamWhatsAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Assalam o Alaikum {first}, you are on the {brand} team on Atombrand. Sign in with your mobile number {username} and this temporary password: {password}\nYou will choose your own password after signing in.\nApp: {appLink}'**
  String teamWhatsAppMessage(
    String first,
    String brand,
    String username,
    String password,
    String appLink,
  );

  /// No description provided for @teamWhatsAppWeb.
  ///
  /// In en, this message translates to:
  /// **'Web: {webLink}'**
  String teamWhatsAppWeb(String webLink);

  /// No description provided for @teamResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset {first}’s password?'**
  String teamResetTitle(String first);

  /// No description provided for @teamOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch {first} off?'**
  String teamOffTitle(String first);

  /// No description provided for @teamOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch {first} on?'**
  String teamOnTitle(String first);

  /// No description provided for @teamOffDone.
  ///
  /// In en, this message translates to:
  /// **'{first} is switched off'**
  String teamOffDone(String first);

  /// No description provided for @teamPeopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String teamPeopleCount(int count);

  /// No description provided for @teamPeopleAllOff.
  ///
  /// In en, this message translates to:
  /// **'{people} (switched off)'**
  String teamPeopleAllOff(String people);

  /// No description provided for @teamPeopleSomeOff.
  ///
  /// In en, this message translates to:
  /// **'{people}, {off} switched off'**
  String teamPeopleSomeOff(String people, int off);

  /// No description provided for @teamRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Role · {name}'**
  String teamRoleTitle(String name);

  /// No description provided for @teamDeleteRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String teamDeleteRoleTitle(String name);

  /// No description provided for @teamTitle.
  ///
  /// In en, this message translates to:
  /// **'Team & roles'**
  String get teamTitle;

  /// No description provided for @teamAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add team member'**
  String get teamAddMember;

  /// No description provided for @teamAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get teamAdd;

  /// No description provided for @teamPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get teamPeople;

  /// No description provided for @teamRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get teamRoles;

  /// No description provided for @teamRolesAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles and permissions'**
  String get teamRolesAndPermissions;

  /// No description provided for @teamKpiMembers.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get teamKpiMembers;

  /// No description provided for @teamKpiToday.
  ///
  /// In en, this message translates to:
  /// **'Signed in today'**
  String get teamKpiToday;

  /// No description provided for @teamKpiTodayNote.
  ///
  /// In en, this message translates to:
  /// **'App and portal'**
  String get teamKpiTodayNote;

  /// No description provided for @teamKpiWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sign in'**
  String get teamKpiWaiting;

  /// No description provided for @teamKpiWaitingNote.
  ///
  /// In en, this message translates to:
  /// **'Still on the temporary password'**
  String get teamKpiWaitingNote;

  /// No description provided for @teamKpiRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get teamKpiRoles;

  /// No description provided for @teamFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get teamFilterActive;

  /// No description provided for @teamFilterOff.
  ///
  /// In en, this message translates to:
  /// **'Switched off'**
  String get teamFilterOff;

  /// No description provided for @teamFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teamFilterAll;

  /// No description provided for @teamOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get teamOwner;

  /// No description provided for @teamActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get teamActiveNow;

  /// No description provided for @teamEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No team members yet'**
  String get teamEmptyTitle;

  /// No description provided for @teamEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the people who help you: each signs in with their own mobile number and sees only what their role allows.'**
  String get teamEmptyBody;

  /// No description provided for @teamEmptyOff.
  ///
  /// In en, this message translates to:
  /// **'Nobody is switched off'**
  String get teamEmptyOff;

  /// No description provided for @teamFootOnline.
  ///
  /// In en, this message translates to:
  /// **'Team members sign in with their mobile number and see only their outlets.'**
  String get teamFootOnline;

  /// No description provided for @teamFootOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline: you can see your team, but adding or changing people needs internet.'**
  String get teamFootOffline;

  /// No description provided for @teamNoRole.
  ///
  /// In en, this message translates to:
  /// **'No role'**
  String get teamNoRole;

  /// No description provided for @teamEditMember.
  ///
  /// In en, this message translates to:
  /// **'Change team member'**
  String get teamEditMember;

  /// No description provided for @teamFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get teamFullName;

  /// No description provided for @teamMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get teamMobile;

  /// No description provided for @teamEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get teamEmailOptional;

  /// No description provided for @teamMobileHint.
  ///
  /// In en, this message translates to:
  /// **'They sign in with this mobile number.'**
  String get teamMobileHint;

  /// No description provided for @teamMobileFixed.
  ///
  /// In en, this message translates to:
  /// **'The mobile number is their username: it can’t change.'**
  String get teamMobileFixed;

  /// No description provided for @teamRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get teamRole;

  /// No description provided for @teamWorksIn.
  ///
  /// In en, this message translates to:
  /// **'Works in'**
  String get teamWorksIn;

  /// No description provided for @teamEveryOutlet.
  ///
  /// In en, this message translates to:
  /// **'Every outlet'**
  String get teamEveryOutlet;

  /// No description provided for @teamSomeOutlets.
  ///
  /// In en, this message translates to:
  /// **'Only some outlets'**
  String get teamSomeOutlets;

  /// No description provided for @teamEveryOutletHint.
  ///
  /// In en, this message translates to:
  /// **'Orders, stock and deals of every outlet.'**
  String get teamEveryOutletHint;

  /// No description provided for @teamSomeOutletsHint.
  ///
  /// In en, this message translates to:
  /// **'Only the outlets you tick.'**
  String get teamSomeOutletsHint;

  /// No description provided for @teamAllOutlets.
  ///
  /// In en, this message translates to:
  /// **'All outlets'**
  String get teamAllOutlets;

  /// No description provided for @teamPickOutlets.
  ///
  /// In en, this message translates to:
  /// **'Outlets they work in'**
  String get teamPickOutlets;

  /// No description provided for @teamSearchOutlets.
  ///
  /// In en, this message translates to:
  /// **'Search outlets'**
  String get teamSearchOutlets;

  /// No description provided for @teamSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get teamSave;

  /// No description provided for @teamNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes yet'**
  String get teamNoChanges;

  /// No description provided for @teamNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Needs internet'**
  String get teamNeedsInternet;

  /// No description provided for @teamSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get teamSaved;

  /// No description provided for @teamLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login for Brand Partner'**
  String get teamLoginTitle;

  /// No description provided for @teamShownOnce.
  ///
  /// In en, this message translates to:
  /// **'Shown once'**
  String get teamShownOnce;

  /// No description provided for @teamUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get teamUsername;

  /// No description provided for @teamCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get teamCopy;

  /// No description provided for @teamCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get teamCopied;

  /// No description provided for @teamPasswordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password copied'**
  String get teamPasswordCopied;

  /// No description provided for @teamSendWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Send on WhatsApp'**
  String get teamSendWhatsApp;

  /// No description provided for @teamDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get teamDone;

  /// No description provided for @teamAddedGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'The password was shown once'**
  String get teamAddedGoneTitle;

  /// No description provided for @teamAddedGoneBody.
  ///
  /// In en, this message translates to:
  /// **'If they didn’t get it, open their page and reset the password: that makes a new one.'**
  String get teamAddedGoneBody;

  /// No description provided for @teamMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Team member'**
  String get teamMemberTitle;

  /// No description provided for @teamEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get teamEdit;

  /// No description provided for @teamLoginAndAccess.
  ///
  /// In en, this message translates to:
  /// **'Login and access'**
  String get teamLoginAndAccess;

  /// No description provided for @teamLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active'**
  String get teamLastActive;

  /// No description provided for @teamPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get teamPassword;

  /// No description provided for @teamTheirOwn.
  ///
  /// In en, this message translates to:
  /// **'Their own'**
  String get teamTheirOwn;

  /// No description provided for @teamTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary: not changed yet'**
  String get teamTemporary;

  /// No description provided for @teamEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get teamEmail;

  /// No description provided for @teamAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get teamAdded;

  /// No description provided for @teamResetRow.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get teamResetRow;

  /// No description provided for @teamResetSub.
  ///
  /// In en, this message translates to:
  /// **'Gives a new temporary one and signs them out'**
  String get teamResetSub;

  /// No description provided for @teamOffRow.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get teamOffRow;

  /// No description provided for @teamOffSub.
  ///
  /// In en, this message translates to:
  /// **'Can’t sign in; their work stays'**
  String get teamOffSub;

  /// No description provided for @teamOnRow.
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get teamOnRow;

  /// No description provided for @teamOnSub.
  ///
  /// In en, this message translates to:
  /// **'Can sign in again with a new temporary password'**
  String get teamOnSub;

  /// No description provided for @teamResetBody.
  ///
  /// In en, this message translates to:
  /// **'They are signed out on every phone and get a new temporary password to sign in with.'**
  String get teamResetBody;

  /// No description provided for @teamResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get teamResetButton;

  /// No description provided for @teamOffBody.
  ///
  /// In en, this message translates to:
  /// **'They are signed out everywhere and can’t sign in. Orders and payments they handled stay.'**
  String get teamOffBody;

  /// No description provided for @teamOnBody.
  ///
  /// In en, this message translates to:
  /// **'They get a new temporary password to sign in with.'**
  String get teamOnBody;

  /// No description provided for @teamNeedInternetFoot.
  ///
  /// In en, this message translates to:
  /// **'These need internet.'**
  String get teamNeedInternetFoot;

  /// No description provided for @teamNotYoursToChange.
  ///
  /// In en, this message translates to:
  /// **'You can see this person, but only the owner can change them.'**
  String get teamNotYoursToChange;

  /// No description provided for @teamMemberGone.
  ///
  /// In en, this message translates to:
  /// **'This person isn’t on your team any more'**
  String get teamMemberGone;

  /// No description provided for @teamNewRole.
  ///
  /// In en, this message translates to:
  /// **'New role'**
  String get teamNewRole;

  /// No description provided for @teamYours.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get teamYours;

  /// No description provided for @teamReadyMade.
  ///
  /// In en, this message translates to:
  /// **'Ready-made'**
  String get teamReadyMade;

  /// No description provided for @teamOwnerRole.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get teamOwnerRole;

  /// No description provided for @teamOwnerRoleSum.
  ///
  /// In en, this message translates to:
  /// **'Everything, including outlets, shop settings, roles and the team.'**
  String get teamOwnerRoleSum;

  /// No description provided for @teamReadyNote.
  ///
  /// In en, this message translates to:
  /// **'Ready-made roles can’t be edited. Copy one to make your own.'**
  String get teamReadyNote;

  /// No description provided for @teamNoOwnRoles.
  ///
  /// In en, this message translates to:
  /// **'Make a role of your own, or copy a ready-made one.'**
  String get teamNoOwnRoles;

  /// No description provided for @teamCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare roles'**
  String get teamCompare;

  /// No description provided for @teamCompareHint.
  ///
  /// In en, this message translates to:
  /// **'Pick two roles to see what each can do.'**
  String get teamCompareHint;

  /// No description provided for @teamFirstRole.
  ///
  /// In en, this message translates to:
  /// **'First role'**
  String get teamFirstRole;

  /// No description provided for @teamSecondRole.
  ///
  /// In en, this message translates to:
  /// **'Second role'**
  String get teamSecondRole;

  /// No description provided for @teamDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get teamDelete;

  /// No description provided for @teamRoleName.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get teamRoleName;

  /// No description provided for @teamDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get teamDescription;

  /// No description provided for @teamDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What this role is for (optional)'**
  String get teamDescriptionHint;

  /// No description provided for @teamAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teamAll;

  /// No description provided for @teamSaveRole.
  ///
  /// In en, this message translates to:
  /// **'Save role'**
  String get teamSaveRole;

  /// No description provided for @teamNeedRoleName.
  ///
  /// In en, this message translates to:
  /// **'Give the role a name'**
  String get teamNeedRoleName;

  /// No description provided for @teamNeedPermission.
  ///
  /// In en, this message translates to:
  /// **'Turn on at least one permission'**
  String get teamNeedPermission;

  /// No description provided for @teamRoleSaved.
  ///
  /// In en, this message translates to:
  /// **'Role saved'**
  String get teamRoleSaved;

  /// No description provided for @teamDeleteRoleBody.
  ///
  /// In en, this message translates to:
  /// **'Nobody can be given this role after it is deleted.'**
  String get teamDeleteRoleBody;

  /// No description provided for @teamDeleteRole.
  ///
  /// In en, this message translates to:
  /// **'Delete role'**
  String get teamDeleteRole;

  /// No description provided for @teamRoleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Role deleted'**
  String get teamRoleDeleted;

  /// No description provided for @teamRoleGone.
  ///
  /// In en, this message translates to:
  /// **'This role isn’t there any more'**
  String get teamRoleGone;

  /// No description provided for @teamNoGroups.
  ///
  /// In en, this message translates to:
  /// **'The permissions couldn’t be read. Try again.'**
  String get teamNoGroups;

  /// No description provided for @teamOwnerOnlyRoles.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can make or change roles.'**
  String get teamOwnerOnlyRoles;

  /// No description provided for @teamHomeTotalsSub.
  ///
  /// In en, this message translates to:
  /// **'Sales and payments on Home'**
  String get teamHomeTotalsSub;

  /// No description provided for @outletsTitle.
  ///
  /// In en, this message translates to:
  /// **'Outlets'**
  String get outletsTitle;

  /// No description provided for @outletsAddOutlet.
  ///
  /// In en, this message translates to:
  /// **'Add outlet'**
  String get outletsAddOutlet;

  /// No description provided for @outletsMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get outletsMain;

  /// No description provided for @outletsCashSales.
  ///
  /// In en, this message translates to:
  /// **'Cash sales'**
  String get outletsCashSales;

  /// No description provided for @outletsOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get outletsOrders;

  /// No description provided for @outletsPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get outletsPayments;

  /// No description provided for @outletsBulkWon.
  ///
  /// In en, this message translates to:
  /// **'Bulk won'**
  String get outletsBulkWon;

  /// No description provided for @outletsInStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get outletsInStock;

  /// No description provided for @outletsAvgOrder.
  ///
  /// In en, this message translates to:
  /// **'Average order'**
  String get outletsAvgOrder;

  /// No description provided for @outletsAskMulti.
  ///
  /// In en, this message translates to:
  /// **'This is a single-outlet account. Atomshop can make it multi-outlet so you can add outlets.'**
  String get outletsAskMulti;

  /// No description provided for @outletsAskWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Ask Atomshop on WhatsApp'**
  String get outletsAskWhatsApp;

  /// No description provided for @outletsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No outlets yet'**
  String get outletsEmpty;

  /// No description provided for @outletsEditOutlet.
  ///
  /// In en, this message translates to:
  /// **'Change outlet'**
  String get outletsEditOutlet;

  /// No description provided for @outletsName.
  ///
  /// In en, this message translates to:
  /// **'Outlet name'**
  String get outletsName;

  /// No description provided for @outletsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get outletsPhone;

  /// No description provided for @outletsCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get outletsCity;

  /// No description provided for @outletsChooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose the city'**
  String get outletsChooseCity;

  /// No description provided for @outletsSearchCities.
  ///
  /// In en, this message translates to:
  /// **'Search cities'**
  String get outletsSearchCities;

  /// No description provided for @outletsOpenedOn.
  ///
  /// In en, this message translates to:
  /// **'Opened on'**
  String get outletsOpenedOn;

  /// No description provided for @outletsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get outletsToday;

  /// No description provided for @outletsWhoRunsIt.
  ///
  /// In en, this message translates to:
  /// **'Who runs it?'**
  String get outletsWhoRunsIt;

  /// No description provided for @outletsNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody yet'**
  String get outletsNobody;

  /// No description provided for @outletsManagerHint.
  ///
  /// In en, this message translates to:
  /// **'They become Outlet manager of this outlet only.'**
  String get outletsManagerHint;

  /// No description provided for @outletsAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get outletsAddress;

  /// No description provided for @outletsCitiesServes.
  ///
  /// In en, this message translates to:
  /// **'Cities it serves'**
  String get outletsCitiesServes;

  /// No description provided for @outletsOneOutletPerCity.
  ///
  /// In en, this message translates to:
  /// **'one outlet per city'**
  String get outletsOneOutletPerCity;

  /// No description provided for @outletsAllCities.
  ///
  /// In en, this message translates to:
  /// **'All cities'**
  String get outletsAllCities;

  /// No description provided for @outletsCitiesHint.
  ///
  /// In en, this message translates to:
  /// **'None picked: it serves the city it is in. A city served by another outlet is taken.'**
  String get outletsCitiesHint;

  /// No description provided for @outletsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get outletsAccount;

  /// No description provided for @outletsMultiOutlet.
  ///
  /// In en, this message translates to:
  /// **'Multi-outlet'**
  String get outletsMultiOutlet;

  /// No description provided for @outletsOutletsUsed.
  ///
  /// In en, this message translates to:
  /// **'Outlets used'**
  String get outletsOutletsUsed;

  /// No description provided for @outletsAfterSaving.
  ///
  /// In en, this message translates to:
  /// **'After saving'**
  String get outletsAfterSaving;

  /// No description provided for @outletsSaveOutlet.
  ///
  /// In en, this message translates to:
  /// **'Save outlet'**
  String get outletsSaveOutlet;

  /// No description provided for @outletsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get outletsSaveChanges;

  /// No description provided for @outletsNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes yet'**
  String get outletsNoChanges;

  /// No description provided for @outletsNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Needs internet'**
  String get outletsNeedsInternet;

  /// No description provided for @outletsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get outletsSaved;

  /// No description provided for @outletsCitiesFailed.
  ///
  /// In en, this message translates to:
  /// **'The cities couldn’t be loaded.'**
  String get outletsCitiesFailed;

  /// No description provided for @outletsKpiSales.
  ///
  /// In en, this message translates to:
  /// **'Cash sales this month'**
  String get outletsKpiSales;

  /// No description provided for @outletsKpiOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get outletsKpiOrders;

  /// No description provided for @outletsKpiPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments received'**
  String get outletsKpiPayments;

  /// No description provided for @outletsKpiOpen.
  ///
  /// In en, this message translates to:
  /// **'Open orders'**
  String get outletsKpiOpen;

  /// No description provided for @outletsKpiOpenNote.
  ///
  /// In en, this message translates to:
  /// **'Not yet delivered'**
  String get outletsKpiOpenNote;

  /// No description provided for @outletsOrdersThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Orders this month'**
  String get outletsOrdersThisMonth;

  /// No description provided for @outletsNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders for this outlet yet.'**
  String get outletsNoOrders;

  /// No description provided for @outletsStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get outletsStaff;

  /// No description provided for @outletsStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get outletsStock;

  /// No description provided for @outletsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get outletsContact;

  /// No description provided for @outletsBulkDeals.
  ///
  /// In en, this message translates to:
  /// **'Bulk deals'**
  String get outletsBulkDeals;

  /// No description provided for @outletsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get outletsStatus;

  /// No description provided for @outletsPauseBody.
  ///
  /// In en, this message translates to:
  /// **'New orders from its cities go to the main outlet, and its staff are signed out until you open it again.'**
  String get outletsPauseBody;

  /// No description provided for @outletsCloseBody.
  ///
  /// In en, this message translates to:
  /// **'It is kept for its history. Its cities move to the main outlet and it can’t take orders.'**
  String get outletsCloseBody;

  /// No description provided for @outletsOpenBody.
  ///
  /// In en, this message translates to:
  /// **'It takes new orders for its cities again.'**
  String get outletsOpenBody;

  /// No description provided for @outletsOutletGone.
  ///
  /// In en, this message translates to:
  /// **'This outlet isn’t there any more'**
  String get outletsOutletGone;

  /// No description provided for @outletsClosedNoEdit.
  ///
  /// In en, this message translates to:
  /// **'A closed outlet can’t be changed. Reopen it first.'**
  String get outletsClosedNoEdit;

  /// No description provided for @teamChipOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get teamChipOrders;

  /// No description provided for @teamChipPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get teamChipPayments;

  /// No description provided for @teamChipAtompay.
  ///
  /// In en, this message translates to:
  /// **'AtomPay'**
  String get teamChipAtompay;

  /// No description provided for @teamChipBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk deals'**
  String get teamChipBulk;

  /// No description provided for @teamChipQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get teamChipQuotes;

  /// No description provided for @teamChipProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get teamChipProducts;

  /// No description provided for @teamChipPage.
  ///
  /// In en, this message translates to:
  /// **'Brand page'**
  String get teamChipPage;

  /// No description provided for @teamChipSeeStock.
  ///
  /// In en, this message translates to:
  /// **'See stock'**
  String get teamChipSeeStock;

  /// No description provided for @teamChipStockChanges.
  ///
  /// In en, this message translates to:
  /// **'Stock changes'**
  String get teamChipStockChanges;

  /// No description provided for @teamChipReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get teamChipReports;

  /// No description provided for @teamChipExports.
  ///
  /// In en, this message translates to:
  /// **'Exports'**
  String get teamChipExports;

  /// No description provided for @teamChipAddTeam.
  ///
  /// In en, this message translates to:
  /// **'Add team'**
  String get teamChipAddTeam;

  /// No description provided for @teamCopyTail.
  ///
  /// In en, this message translates to:
  /// **'copy'**
  String get teamCopyTail;

  /// No description provided for @teamCopyTailN.
  ///
  /// In en, this message translates to:
  /// **'copy {n}'**
  String teamCopyTailN(int n);

  /// No description provided for @teamSeenOff.
  ///
  /// In en, this message translates to:
  /// **'Switched off · can\'t sign in'**
  String get teamSeenOff;

  /// No description provided for @teamSeenOffOn.
  ///
  /// In en, this message translates to:
  /// **'Switched off {day} · can\'t sign in'**
  String teamSeenOffOn(String day);

  /// No description provided for @teamSeenTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary: not signed in yet'**
  String get teamSeenTemporary;

  /// No description provided for @teamSeenNever.
  ///
  /// In en, this message translates to:
  /// **'Not signed in yet'**
  String get teamSeenNever;

  /// No description provided for @teamSeenAt.
  ///
  /// In en, this message translates to:
  /// **'Active {time}'**
  String teamSeenAt(String time);

  /// No description provided for @teamSeenYesterday.
  ///
  /// In en, this message translates to:
  /// **'Last active yesterday'**
  String get teamSeenYesterday;

  /// No description provided for @teamSeenOn.
  ///
  /// In en, this message translates to:
  /// **'Last active {day}'**
  String teamSeenOn(String day);

  /// No description provided for @teamNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter their full name.'**
  String get teamNameEmpty;

  /// No description provided for @teamNameLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the name under 80 letters.'**
  String get teamNameLong;

  /// No description provided for @teamNameLetters.
  ///
  /// In en, this message translates to:
  /// **'Use letters and spaces only.'**
  String get teamNameLetters;

  /// No description provided for @teamMobileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter their mobile number.'**
  String get teamMobileEmpty;

  /// No description provided for @teamMobileBad.
  ///
  /// In en, this message translates to:
  /// **'Enter a mobile number like 0300 1234567.'**
  String get teamMobileBad;

  /// No description provided for @teamEmailBad.
  ///
  /// In en, this message translates to:
  /// **'Check the email.'**
  String get teamEmailBad;

  /// No description provided for @teamBlockName.
  ///
  /// In en, this message translates to:
  /// **'Enter their name'**
  String get teamBlockName;

  /// No description provided for @teamBlockNameBad.
  ///
  /// In en, this message translates to:
  /// **'Check the name'**
  String get teamBlockNameBad;

  /// No description provided for @teamBlockMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter their mobile number'**
  String get teamBlockMobile;

  /// No description provided for @teamBlockMobileBad.
  ///
  /// In en, this message translates to:
  /// **'Check the mobile number'**
  String get teamBlockMobileBad;

  /// No description provided for @teamBlockEmail.
  ///
  /// In en, this message translates to:
  /// **'Check the email'**
  String get teamBlockEmail;

  /// No description provided for @teamBlockRole.
  ///
  /// In en, this message translates to:
  /// **'Choose a role'**
  String get teamBlockRole;

  /// No description provided for @teamBlockScope.
  ///
  /// In en, this message translates to:
  /// **'Choose where they work'**
  String get teamBlockScope;

  /// No description provided for @teamBlockOutlet.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one outlet'**
  String get teamBlockOutlet;

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGoodEvening;

  /// No description provided for @homePeriodYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get homePeriodYear;

  /// No description provided for @homePeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get homePeriodAll;

  /// No description provided for @homePeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get homePeriodMonth;

  /// No description provided for @homeBulkNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get homeBulkNew;

  /// No description provided for @homeBulkContacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get homeBulkContacted;

  /// No description provided for @homeBulkQuoted.
  ///
  /// In en, this message translates to:
  /// **'Quoted'**
  String get homeBulkQuoted;

  /// No description provided for @homeBulkWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get homeBulkWon;

  /// No description provided for @homeBulkLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get homeBulkLost;

  /// No description provided for @homeBulkDelivering.
  ///
  /// In en, this message translates to:
  /// **'Delivering'**
  String get homeBulkDelivering;

  /// No description provided for @homeBannerRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Atomshop paused changes'**
  String get homeBannerRestrictedTitle;

  /// No description provided for @homeBannerRestrictedBody.
  ///
  /// In en, this message translates to:
  /// **'You can still see everything. Ask Atomshop support what to do next.'**
  String get homeBannerRestrictedBody;

  /// No description provided for @homeBannerReadOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is read-only'**
  String get homeBannerReadOnlyTitle;

  /// No description provided for @homeBannerReadOnlyLate.
  ///
  /// In en, this message translates to:
  /// **'Your bill is {days} days late. Pay it and everything opens again at once.'**
  String homeBannerReadOnlyLate(int days);

  /// No description provided for @homeBannerReadOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Pay the open bill and everything opens again at once.'**
  String get homeBannerReadOnlyBody;

  /// No description provided for @homeBannerLateDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Your bill is 1 day late} other{Your bill is {days} days late}}'**
  String homeBannerLateDays(int days);

  /// No description provided for @homeBannerLate.
  ///
  /// In en, this message translates to:
  /// **'Your bill is late'**
  String get homeBannerLate;

  /// No description provided for @homeBannerLateBody.
  ///
  /// In en, this message translates to:
  /// **'Pay it to keep making changes. After 15 days the account becomes read-only until it is paid.'**
  String get homeBannerLateBody;

  /// No description provided for @homeBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Message from Atomshop'**
  String get homeBannerMessage;

  /// No description provided for @homeBannerBillReady.
  ///
  /// In en, this message translates to:
  /// **'Your bill is ready'**
  String get homeBannerBillReady;

  /// No description provided for @homeBannerMonthBill.
  ///
  /// In en, this message translates to:
  /// **'{month} bill is ready'**
  String homeBannerMonthBill(String month);

  /// No description provided for @homeBannerDue.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String homeBannerDue(String date);

  /// No description provided for @homeTrialEndsToday.
  ///
  /// In en, this message translates to:
  /// **'{name} trial ends today'**
  String homeTrialEndsToday(String name);

  /// No description provided for @homeTrialEndsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{name} trial ends tomorrow'**
  String homeTrialEndsTomorrow(String name);

  /// No description provided for @homeTrialEndsIn.
  ///
  /// In en, this message translates to:
  /// **'{name} trial ends in {days} days'**
  String homeTrialEndsIn(String name, int days);

  /// No description provided for @homeTrialRenew.
  ///
  /// In en, this message translates to:
  /// **'It stays on and is added to your next bill, unless you switch it off before {day}.'**
  String homeTrialRenew(String day);

  /// No description provided for @homeTrialOff.
  ///
  /// In en, this message translates to:
  /// **'It switches off on {day} unless you keep it.'**
  String homeTrialOff(String day);

  /// No description provided for @homeStepPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your PIN and fingerprint'**
  String get homeStepPinTitle;

  /// No description provided for @homeStepPinSub.
  ///
  /// In en, this message translates to:
  /// **'Open the app fast, even offline'**
  String get homeStepPinSub;

  /// No description provided for @homeStepProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your products'**
  String get homeStepProductsTitle;

  /// No description provided for @homeStepProductsSub.
  ///
  /// In en, this message translates to:
  /// **'At least {count}; Atomshop reviews each one before it goes live'**
  String homeStepProductsSub(int count);

  /// No description provided for @homeStepPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your brand page'**
  String get homeStepPageTitle;

  /// No description provided for @homeStepPageSub.
  ///
  /// In en, this message translates to:
  /// **'Logo, banner, your story and contacts'**
  String get homeStepPageSub;

  /// No description provided for @homeStepPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how customers pay you'**
  String get homeStepPayTitle;

  /// No description provided for @homeStepPaySub.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery, bank transfer, JazzCash or Easypaisa'**
  String get homeStepPaySub;

  /// No description provided for @homeStepTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your team'**
  String get homeStepTeamTitle;

  /// No description provided for @homeStepTeamSub.
  ///
  /// In en, this message translates to:
  /// **'Order handlers and stock keepers, each with their own sign-in'**
  String get homeStepTeamSub;

  /// No description provided for @homePipelineLabel.
  ///
  /// In en, this message translates to:
  /// **'Orders by status: {steps}'**
  String homePipelineLabel(String steps);

  /// No description provided for @homeTeamMember.
  ///
  /// In en, this message translates to:
  /// **'Team member'**
  String get homeTeamMember;

  /// No description provided for @homeMonthSoFar.
  ///
  /// In en, this message translates to:
  /// **'{month} so far'**
  String homeMonthSoFar(String month);

  /// No description provided for @homeChartBarLabel.
  ///
  /// In en, this message translates to:
  /// **'{month}: cash sales {sales}, payments {paid}'**
  String homeChartBarLabel(String month, String sales, String paid);

  /// No description provided for @homeWhenToday.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String homeWhenToday(String time);

  /// No description provided for @homeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get homeYesterday;

  /// No description provided for @homeOutletsLoadError.
  ///
  /// In en, this message translates to:
  /// **'This month\'s figures could not be loaded.'**
  String get homeOutletsLoadError;

  /// No description provided for @homeSearchOffline.
  ///
  /// In en, this message translates to:
  /// **'No signal. Try again when you are back online.'**
  String get homeSearchOffline;

  /// No description provided for @homeSellerRequest.
  ///
  /// In en, this message translates to:
  /// **'Seller request'**
  String get homeSellerRequest;

  /// No description provided for @homeWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get homeWebsite;

  /// No description provided for @homeOrdersNote.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 order} other{{n} orders}}'**
  String homeOrdersNote(int n);

  /// No description provided for @ordersNoSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal. Check your internet and try again.'**
  String get ordersNoSignal;

  /// No description provided for @ordersSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get ordersSomethingWrong;

  /// No description provided for @ordersNextStepEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NEXT STEP'**
  String get ordersNextStepEyebrow;

  /// No description provided for @ordersHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get ordersHistory;

  /// No description provided for @ordersCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get ordersCall;

  /// No description provided for @ordersWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get ordersWhatsApp;

  /// No description provided for @ordersPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added · tap to change'**
  String get ordersPhotoAdded;

  /// No description provided for @ordersScanSerial.
  ///
  /// In en, this message translates to:
  /// **'Scan the serial'**
  String get ordersScanSerial;

  /// No description provided for @ordersCashOrders.
  ///
  /// In en, this message translates to:
  /// **'Cash orders'**
  String get ordersCashOrders;

  /// No description provided for @ordersAtompayOrders.
  ///
  /// In en, this message translates to:
  /// **'AtomPay orders'**
  String get ordersAtompayOrders;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTitle;

  /// No description provided for @ordersAskAtom.
  ///
  /// In en, this message translates to:
  /// **'Ask Atom'**
  String get ordersAskAtom;

  /// No description provided for @ordersSearch.
  ///
  /// In en, this message translates to:
  /// **'Search orders'**
  String get ordersSearch;

  /// No description provided for @ordersNoRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders are not in your role'**
  String get ordersNoRoleTitle;

  /// No description provided for @ordersNoRoleBody.
  ///
  /// In en, this message translates to:
  /// **'Ask the owner if you need to see orders.'**
  String get ordersNoRoleBody;

  /// No description provided for @ordersPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get ordersPayment;

  /// No description provided for @ordersAnyPayment.
  ///
  /// In en, this message translates to:
  /// **'Any payment'**
  String get ordersAnyPayment;

  /// No description provided for @ordersOutlet.
  ///
  /// In en, this message translates to:
  /// **'Outlet'**
  String get ordersOutlet;

  /// No description provided for @ordersAllOutlets.
  ///
  /// In en, this message translates to:
  /// **'All outlets'**
  String get ordersAllOutlets;

  /// No description provided for @ordersAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersAll;

  /// No description provided for @ordersPaymentFilter.
  ///
  /// In en, this message translates to:
  /// **'Payment: {value}'**
  String ordersPaymentFilter(String value);

  /// No description provided for @ordersOutletFilter.
  ///
  /// In en, this message translates to:
  /// **'Outlet: {value}'**
  String ordersOutletFilter(String value);

  /// No description provided for @ordersProductName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get ordersProductName;

  /// No description provided for @ordersNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No orders match these filters.'**
  String get ordersNoMatch;

  /// No description provided for @ordersClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get ordersClearFilters;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Orders for your products on atomshop.pk show here the moment they are placed.'**
  String get ordersEmptyBody;

  /// No description provided for @ordersPickOne.
  ///
  /// In en, this message translates to:
  /// **'Pick an order to see it here'**
  String get ordersPickOne;

  /// No description provided for @ordersConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ordersConfirm;

  /// No description provided for @ordersTakePayment.
  ///
  /// In en, this message translates to:
  /// **'Take payment'**
  String get ordersTakePayment;

  /// No description provided for @ordersReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get ordersReceipt;

  /// No description provided for @ordersNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get ordersNotFound;

  /// No description provided for @ordersNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may be in another outlet, or no longer yours to see.'**
  String get ordersNotFoundBody;

  /// No description provided for @ordersNowStage.
  ///
  /// In en, this message translates to:
  /// **'Order is now {stage}.'**
  String ordersNowStage(String stage);

  /// No description provided for @ordersFor.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String ordersFor(String name);

  /// No description provided for @ordersPlacedOn.
  ///
  /// In en, this message translates to:
  /// **'placed {day} on atomshop.pk'**
  String ordersPlacedOn(String day);

  /// No description provided for @ordersCashOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Cash order {number}'**
  String ordersCashOrderNumber(String number);

  /// No description provided for @ordersOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Order value'**
  String get ordersOrderValue;

  /// No description provided for @ordersToCollect.
  ///
  /// In en, this message translates to:
  /// **'To collect'**
  String get ordersToCollect;

  /// No description provided for @ordersFromCopy.
  ///
  /// In en, this message translates to:
  /// **'Shown from this phone. The customer\'s full details come back with a signal.'**
  String get ordersFromCopy;

  /// No description provided for @ordersCancelledDot.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get ordersCancelledDot;

  /// No description provided for @ordersCancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled on {day}:'**
  String ordersCancelledOn(String day);

  /// No description provided for @ordersNoRefund.
  ///
  /// In en, this message translates to:
  /// **'Nothing was paid, so no refund is needed.'**
  String get ordersNoRefund;

  /// No description provided for @ordersCompletedDot.
  ///
  /// In en, this message translates to:
  /// **'Completed.'**
  String get ordersCompletedDot;

  /// No description provided for @ordersCompletedReceipt.
  ///
  /// In en, this message translates to:
  /// **'Delivered and paid in full. The receipt is ready to share.'**
  String get ordersCompletedReceipt;

  /// No description provided for @ordersCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'Delivered and paid in full.'**
  String get ordersCompletedBody;

  /// No description provided for @ordersAlsoBought.
  ///
  /// In en, this message translates to:
  /// **'Also bought from you'**
  String get ordersAlsoBought;

  /// No description provided for @ordersMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to another outlet'**
  String get ordersMoveTitle;

  /// No description provided for @ordersCompleteStillToPay.
  ///
  /// In en, this message translates to:
  /// **'Complete · {amount} still to pay'**
  String ordersCompleteStillToPay(String amount);

  /// No description provided for @ordersStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ordersStatus;

  /// No description provided for @ordersTapStep.
  ///
  /// In en, this message translates to:
  /// **'Tap a step to preview it'**
  String get ordersTapStep;

  /// No description provided for @ordersArrived.
  ///
  /// In en, this message translates to:
  /// **'The order arrived from atomshop.pk.'**
  String get ordersArrived;

  /// No description provided for @ordersWhatOrdered.
  ///
  /// In en, this message translates to:
  /// **'What was ordered'**
  String get ordersWhatOrdered;

  /// No description provided for @ordersTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ordersTotal;

  /// No description provided for @ordersDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get ordersDue;

  /// No description provided for @ordersPaidSoFar.
  ///
  /// In en, this message translates to:
  /// **'Paid so far'**
  String get ordersPaidSoFar;

  /// No description provided for @ordersReceiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get ordersReceiptPhoto;

  /// No description provided for @ordersVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get ordersVerified;

  /// No description provided for @ordersName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ordersName;

  /// No description provided for @ordersCustomerSince.
  ///
  /// In en, this message translates to:
  /// **'Customer since'**
  String get ordersCustomerSince;

  /// No description provided for @ordersPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get ordersPhone;

  /// No description provided for @ordersEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get ordersEmail;

  /// No description provided for @ordersAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get ordersAddress;

  /// No description provided for @ordersCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get ordersCity;

  /// No description provided for @ordersDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get ordersDelivery;

  /// No description provided for @ordersStepNotOpen.
  ///
  /// In en, this message translates to:
  /// **'This step isn\'t open'**
  String get ordersStepNotOpen;

  /// No description provided for @ordersGateIsNow.
  ///
  /// In en, this message translates to:
  /// **'The order is {stage} now.'**
  String ordersGateIsNow(String stage);

  /// No description provided for @ordersOpenOrder.
  ///
  /// In en, this message translates to:
  /// **'Open the order'**
  String get ordersOpenOrder;

  /// No description provided for @ordersDeliverNotOpen.
  ///
  /// In en, this message translates to:
  /// **'This order can\'t be marked delivered'**
  String get ordersDeliverNotOpen;

  /// No description provided for @ordersDeliverySaved.
  ///
  /// In en, this message translates to:
  /// **'Delivery saved.'**
  String get ordersDeliverySaved;

  /// No description provided for @ordersMarkAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as delivered'**
  String get ordersMarkAsDelivered;

  /// No description provided for @ordersScanReadHeld.
  ///
  /// In en, this message translates to:
  /// **'Read. It is checked against the held unit when you save.'**
  String get ordersScanReadHeld;

  /// No description provided for @ordersScanPoint.
  ///
  /// In en, this message translates to:
  /// **'Point at the serial barcode on the box'**
  String get ordersScanPoint;

  /// No description provided for @ordersHeldUnit.
  ///
  /// In en, this message translates to:
  /// **'The unit held for this order'**
  String get ordersHeldUnit;

  /// No description provided for @ordersChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get ordersChange;

  /// No description provided for @ordersSerialOptional.
  ///
  /// In en, this message translates to:
  /// **'Serial or IMEI (optional)'**
  String get ordersSerialOptional;

  /// No description provided for @ordersTypeFromBox.
  ///
  /// In en, this message translates to:
  /// **'Type it from the box'**
  String get ordersTypeFromBox;

  /// No description provided for @ordersSerialHint.
  ///
  /// In en, this message translates to:
  /// **'Kept on the order and the receipt.'**
  String get ordersSerialHint;

  /// No description provided for @ordersReceivedBy.
  ///
  /// In en, this message translates to:
  /// **'Received by'**
  String get ordersReceivedBy;

  /// No description provided for @ordersFirstCustomer.
  ///
  /// In en, this message translates to:
  /// **'{name} (customer)'**
  String ordersFirstCustomer(String name);

  /// No description provided for @ordersSomeoneElse.
  ///
  /// In en, this message translates to:
  /// **'Someone else'**
  String get ordersSomeoneElse;

  /// No description provided for @ordersNameRelation.
  ///
  /// In en, this message translates to:
  /// **'Name and relation'**
  String get ordersNameRelation;

  /// No description provided for @ordersNameRelationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmed Javed, husband'**
  String get ordersNameRelationHint;

  /// No description provided for @ordersCashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash collected (Rs)'**
  String get ordersCashCollected;

  /// No description provided for @ordersCashCollectedHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {amount} left to pay. Leave 0 if nothing was paid at the door.'**
  String ordersCashCollectedHint(String amount);

  /// No description provided for @ordersPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get ordersPaidBy;

  /// No description provided for @ordersProof.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery'**
  String get ordersProof;

  /// No description provided for @ordersTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get ordersTakePhoto;

  /// No description provided for @ordersSaveDelivery.
  ///
  /// In en, this message translates to:
  /// **'Save delivery'**
  String get ordersSaveDelivery;

  /// No description provided for @ordersNothingToRecord.
  ///
  /// In en, this message translates to:
  /// **'Nothing to record on this order'**
  String get ordersNothingToRecord;

  /// No description provided for @ordersPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get ordersPaymentDate;

  /// No description provided for @ordersPaymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment of {amount} saved.'**
  String ordersPaymentSaved(String amount);

  /// No description provided for @ordersPaymentSavedHere.
  ///
  /// In en, this message translates to:
  /// **'Payment of {amount} saved on this phone'**
  String ordersPaymentSavedHere(String amount);

  /// No description provided for @ordersTheReceipt.
  ///
  /// In en, this message translates to:
  /// **'The receipt comes once the server has it.'**
  String get ordersTheReceipt;

  /// No description provided for @ordersRecordSellerPayment.
  ///
  /// In en, this message translates to:
  /// **'Record seller\'s payment'**
  String get ordersRecordSellerPayment;

  /// No description provided for @ordersRecordAPayment.
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get ordersRecordAPayment;

  /// No description provided for @ordersAtompayNumber.
  ///
  /// In en, this message translates to:
  /// **'AtomPay #A-{id}'**
  String ordersAtompayNumber(String id);

  /// No description provided for @ordersCashPrice.
  ///
  /// In en, this message translates to:
  /// **'Cash price'**
  String get ordersCashPrice;

  /// No description provided for @ordersLeftToReceive.
  ///
  /// In en, this message translates to:
  /// **'Left to receive'**
  String get ordersLeftToReceive;

  /// No description provided for @ordersAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get ordersAmount;

  /// No description provided for @ordersAllAmount.
  ///
  /// In en, this message translates to:
  /// **'All {amount}'**
  String ordersAllAmount(String amount);

  /// No description provided for @ordersHalf.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get ordersHalf;

  /// No description provided for @ordersHowPaid.
  ///
  /// In en, this message translates to:
  /// **'How did they pay?'**
  String get ordersHowPaid;

  /// No description provided for @ordersNoFutureDate.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be a future date.'**
  String get ordersNoFutureDate;

  /// No description provided for @ordersPaymentDateSem.
  ///
  /// In en, this message translates to:
  /// **'Payment date, {day}'**
  String ordersPaymentDateSem(String day);

  /// No description provided for @ordersTodayDay.
  ///
  /// In en, this message translates to:
  /// **'Today, {day}'**
  String ordersTodayDay(String day);

  /// No description provided for @ordersReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get ordersReference;

  /// No description provided for @ordersOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get ordersOptional;

  /// No description provided for @ordersReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID or cheque number'**
  String get ordersReferenceHint;

  /// No description provided for @ordersReceiptPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Photo of the receipt or transfer'**
  String get ordersReceiptPhotoHint;

  /// No description provided for @ordersSavePayment.
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get ordersSavePayment;

  /// No description provided for @ordersEnterUpTo.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount up to {amount}'**
  String ordersEnterUpTo(String amount);

  /// No description provided for @ordersSerialLength.
  ///
  /// In en, this message translates to:
  /// **'A serial is 3 to 60 characters.'**
  String get ordersSerialLength;

  /// No description provided for @ordersScanCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan with the camera'**
  String get ordersScanCamera;

  /// No description provided for @ordersTypeIt.
  ///
  /// In en, this message translates to:
  /// **'Type it'**
  String get ordersTypeIt;

  /// No description provided for @ordersSerialOrImei.
  ///
  /// In en, this message translates to:
  /// **'Serial or IMEI'**
  String get ordersSerialOrImei;

  /// No description provided for @ordersUseSerial.
  ///
  /// In en, this message translates to:
  /// **'Use this serial'**
  String get ordersUseSerial;

  /// No description provided for @ordersScanHelp.
  ///
  /// In en, this message translates to:
  /// **'Point at the serial barcode on the box. No barcode? Tap the keyboard to type it.'**
  String get ordersScanHelp;

  /// No description provided for @ordersCancelledToast.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled.'**
  String get ordersCancelledToast;

  /// No description provided for @ordersCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order'**
  String get ordersCancelTitle;

  /// No description provided for @ordersCancelWhy.
  ///
  /// In en, this message translates to:
  /// **'Why? Pick all that apply'**
  String get ordersCancelWhy;

  /// No description provided for @ordersCancelNote.
  ///
  /// In en, this message translates to:
  /// **'Anything else (optional)'**
  String get ordersCancelNote;

  /// No description provided for @ordersCancelNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What happened? The customer doesn\'t see this note.'**
  String get ordersCancelNoteHint;

  /// No description provided for @ordersCancelWarnHeld.
  ///
  /// In en, this message translates to:
  /// **'The unit held for this order goes back to available in your stock. A cancelled order can\'t be reopened.'**
  String get ordersCancelWarnHeld;

  /// No description provided for @ordersCancelWarn.
  ///
  /// In en, this message translates to:
  /// **'A cancelled order can\'t be reopened.'**
  String get ordersCancelWarn;

  /// No description provided for @ordersCancelWarnBold.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get ordersCancelWarnBold;

  /// No description provided for @ordersKeepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get ordersKeepOrder;

  /// No description provided for @ordersCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get ordersCancelOrder;

  /// No description provided for @ordersPickReason.
  ///
  /// In en, this message translates to:
  /// **'Pick a reason'**
  String get ordersPickReason;

  /// No description provided for @ordersMovedToast.
  ///
  /// In en, this message translates to:
  /// **'Order moved.'**
  String get ordersMovedToast;

  /// No description provided for @ordersNowAt.
  ///
  /// In en, this message translates to:
  /// **'now at {name}'**
  String ordersNowAt(String name);

  /// No description provided for @ordersWhereNowSem.
  ///
  /// In en, this message translates to:
  /// **'{name}, where it is now'**
  String ordersWhereNowSem(String name);

  /// No description provided for @ordersWhereNow.
  ///
  /// In en, this message translates to:
  /// **'where it is now'**
  String get ordersWhereNow;

  /// No description provided for @ordersMoveNoteHeld.
  ///
  /// In en, this message translates to:
  /// **'The new outlet\'s team sees it straight away, and the held unit is freed so they can hold one of theirs. Finished orders can\'t move.'**
  String get ordersMoveNoteHeld;

  /// No description provided for @ordersMoveNote.
  ///
  /// In en, this message translates to:
  /// **'The new outlet\'s team sees it straight away. Finished orders can\'t move.'**
  String get ordersMoveNote;

  /// No description provided for @ordersMoveOrder.
  ///
  /// In en, this message translates to:
  /// **'Move order'**
  String get ordersMoveOrder;

  /// No description provided for @ordersCantMove.
  ///
  /// In en, this message translates to:
  /// **'This order can\'t move'**
  String get ordersCantMove;

  /// No description provided for @ordersCantCancel.
  ///
  /// In en, this message translates to:
  /// **'This order can\'t be cancelled'**
  String get ordersCantCancel;

  /// No description provided for @ordersItIsNow.
  ///
  /// In en, this message translates to:
  /// **'It is {stage} now.'**
  String ordersItIsNow(String stage);

  /// No description provided for @ordersPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t make the PDF on this phone. Try again.'**
  String get ordersPdfFailed;

  /// No description provided for @ordersPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get ordersPdf;

  /// No description provided for @ordersPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get ordersPrint;

  /// No description provided for @ordersReceiptNoteFrom.
  ///
  /// In en, this message translates to:
  /// **'The note at the bottom comes from Shop settings · Receipt note.'**
  String get ordersReceiptNoteFrom;

  /// No description provided for @atompayTheSeller.
  ///
  /// In en, this message translates to:
  /// **'the seller'**
  String get atompayTheSeller;

  /// No description provided for @atompayTheSellerCap.
  ///
  /// In en, this message translates to:
  /// **'The seller'**
  String get atompayTheSellerCap;

  /// No description provided for @atompayNoticeApproving.
  ///
  /// In en, this message translates to:
  /// **'Atomshop is checking the customer. Nothing to do yet: you hear from us when it is approved.'**
  String get atompayNoticeApproving;

  /// No description provided for @atompayNoticeSeller.
  ///
  /// In en, this message translates to:
  /// **'Approved. Atomshop is still finding a seller near the customer. Keep one unit ready.'**
  String get atompayNoticeSeller;

  /// No description provided for @atompayNoticeSellerAt.
  ///
  /// In en, this message translates to:
  /// **'Approved. Atomshop is still finding a seller near the customer. Keep one unit ready at {outlet}.'**
  String atompayNoticeSellerAt(String outlet);

  /// No description provided for @atompayNoticeHandover.
  ///
  /// In en, this message translates to:
  /// **'Atomshop gave this order to {seller}. Hand the unit over to them; they pay you the cash price.'**
  String atompayNoticeHandover(String seller);

  /// No description provided for @atompayNoticeHanded.
  ///
  /// In en, this message translates to:
  /// **'Handed to {seller}. Record their payment when it reaches you.'**
  String atompayNoticeHanded(String seller);

  /// No description provided for @atompayNoticeHandedOn.
  ///
  /// In en, this message translates to:
  /// **'Handed to {seller} on {day}. Record their payment when it reaches you.'**
  String atompayNoticeHandedOn(String seller, String day);

  /// No description provided for @atompayNoticePaid.
  ///
  /// In en, this message translates to:
  /// **'{seller} paid you in full. This cash sale is done.'**
  String atompayNoticePaid(String seller);

  /// No description provided for @atompayNoticeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Atomshop did not approve this order. Nothing to hand over, and any held unit is free again.'**
  String get atompayNoticeCancelled;

  /// No description provided for @atompayEvSerial.
  ///
  /// In en, this message translates to:
  /// **'serial {serial}'**
  String atompayEvSerial(String serial);

  /// No description provided for @atompayEvTo.
  ///
  /// In en, this message translates to:
  /// **'to {name}'**
  String atompayEvTo(String name);

  /// No description provided for @atompayEvSaleDone.
  ///
  /// In en, this message translates to:
  /// **'Cash sale completed'**
  String get atompayEvSaleDone;

  /// No description provided for @atompayEvNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Atomshop did not approve the order'**
  String get atompayEvNotApproved;

  /// No description provided for @atompayEvChecking.
  ///
  /// In en, this message translates to:
  /// **'Atomshop is checking the customer'**
  String get atompayEvChecking;

  /// No description provided for @atompayEvApproved.
  ///
  /// In en, this message translates to:
  /// **'Atomshop approved the order'**
  String get atompayEvApproved;

  /// No description provided for @atompayEvPaid.
  ///
  /// In en, this message translates to:
  /// **'{seller} paid {amount} by {method}'**
  String atompayEvPaid(String seller, String amount, String method);

  /// No description provided for @atompaySaleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sale to the seller completed.'**
  String get atompaySaleCompleted;

  /// No description provided for @atompayHandOverUnit.
  ///
  /// In en, this message translates to:
  /// **'Hand over the unit'**
  String get atompayHandOverUnit;

  /// No description provided for @atompayHandOverBody.
  ///
  /// In en, this message translates to:
  /// **'Note the serial, who received it and a photo of the hand-over.'**
  String get atompayHandOverBody;

  /// No description provided for @atompayPayBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} to receive from {seller}. Complete the order once it is paid.'**
  String atompayPayBody(String amount, String seller);

  /// No description provided for @atompayCompleteSale.
  ///
  /// In en, this message translates to:
  /// **'Complete the sale'**
  String get atompayCompleteSale;

  /// No description provided for @atompayCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'The seller paid in full. Complete the order to close this cash sale.'**
  String get atompayCompleteBody;

  /// No description provided for @atompayStApproved.
  ///
  /// In en, this message translates to:
  /// **'Atomshop approved'**
  String get atompayStApproved;

  /// No description provided for @atompayApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get atompayApproved;

  /// No description provided for @atompayStSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller given'**
  String get atompayStSeller;

  /// No description provided for @atompayYourStep.
  ///
  /// In en, this message translates to:
  /// **'Your step'**
  String get atompayYourStep;

  /// No description provided for @atompayStDone.
  ///
  /// In en, this message translates to:
  /// **'Cash sale done'**
  String get atompayStDone;

  /// No description provided for @atompaySellerPaysYou.
  ///
  /// In en, this message translates to:
  /// **'Seller pays you'**
  String get atompaySellerPaysYou;

  /// No description provided for @atompayFromCopy.
  ///
  /// In en, this message translates to:
  /// **'Shown from this phone. The seller\'s details come back with a signal.'**
  String get atompayFromCopy;

  /// No description provided for @atompayYourStepEyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUR STEP'**
  String get atompayYourStepEyebrow;

  /// No description provided for @atompaySteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get atompaySteps;

  /// No description provided for @atompayPaymentToYou.
  ///
  /// In en, this message translates to:
  /// **'Payment to you'**
  String get atompayPaymentToYou;

  /// No description provided for @atompaySeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get atompaySeller;

  /// No description provided for @atompayShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get atompayShop;

  /// No description provided for @atompayArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get atompayArea;

  /// No description provided for @atompayContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get atompayContact;

  /// No description provided for @atompayHandOverCard.
  ///
  /// In en, this message translates to:
  /// **'Hand-over'**
  String get atompayHandOverCard;

  /// No description provided for @atompayNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get atompayNotYet;

  /// No description provided for @atompayHandTo.
  ///
  /// In en, this message translates to:
  /// **'Hand to'**
  String get atompayHandTo;

  /// No description provided for @atompaySellerNotGiven.
  ///
  /// In en, this message translates to:
  /// **'Seller not given yet'**
  String get atompaySellerNotGiven;

  /// No description provided for @atompayOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'AtomPay order {number}'**
  String atompayOrderNumber(String number);

  /// No description provided for @atompayPlacedOn.
  ///
  /// In en, this message translates to:
  /// **'Placed {day} on atomshop.pk'**
  String atompayPlacedOn(String day);

  /// No description provided for @atompayOnceSeller.
  ///
  /// In en, this message translates to:
  /// **'Once a seller is given'**
  String get atompayOnceSeller;

  /// No description provided for @atompayCustomerPays.
  ///
  /// In en, this message translates to:
  /// **'Customer pays'**
  String get atompayCustomerPays;

  /// No description provided for @atompayMonthly.
  ///
  /// In en, this message translates to:
  /// **'{months} × {amount}'**
  String atompayMonthly(int months, String amount);

  /// No description provided for @atompayMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String atompayMonths(int months);

  /// No description provided for @atompayNoMarkup.
  ///
  /// In en, this message translates to:
  /// **'No advance, 0% markup'**
  String get atompayNoMarkup;

  /// No description provided for @atompayNothingToHand.
  ///
  /// In en, this message translates to:
  /// **'Nothing to hand over'**
  String get atompayNothingToHand;

  /// No description provided for @atompayAtStepNow.
  ///
  /// In en, this message translates to:
  /// **'This order is at \"{step}\" now.'**
  String atompayAtStepNow(String step);

  /// No description provided for @atompayHandoverSaved.
  ///
  /// In en, this message translates to:
  /// **'Hand-over saved. The seller is told.'**
  String get atompayHandoverSaved;

  /// No description provided for @atompayScanRead.
  ///
  /// In en, this message translates to:
  /// **'Read. Serial filled in below.'**
  String get atompayScanRead;

  /// No description provided for @atompaySerialHint.
  ///
  /// In en, this message translates to:
  /// **'Scan or type it from the box'**
  String get atompaySerialHint;

  /// No description provided for @atompayReceivedHint.
  ///
  /// In en, this message translates to:
  /// **'Required. The person from the seller\'s shop who took the unit.'**
  String get atompayReceivedHint;

  /// No description provided for @atompayNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get atompayNote;

  /// No description provided for @atompayNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sealed box, remote and wall bracket included'**
  String get atompayNoteHint;

  /// No description provided for @atompayPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get atompayPhoto;

  /// No description provided for @atompayPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Photo of the hand-over'**
  String get atompayPhotoHint;

  /// No description provided for @atompaySaveHandover.
  ///
  /// In en, this message translates to:
  /// **'Save hand-over'**
  String get atompaySaveHandover;

  /// No description provided for @atompayNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No AtomPay orders match these filters.'**
  String get atompayNoMatch;

  /// No description provided for @atompayEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No AtomPay orders yet'**
  String get atompayEmptyTitle;

  /// No description provided for @atompayEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Switch AtomPay on for a product and orders paid in 3 months show here.'**
  String get atompayEmptyBody;

  /// No description provided for @atompayIntro.
  ///
  /// In en, this message translates to:
  /// **'The customer pays in 3 months, no advance, 0% markup. Atomshop approves the order and gives it to a seller. For you it is a cash sale to that seller: hand the unit over, the seller pays you.'**
  String get atompayIntro;

  /// No description provided for @atompayIntroBold.
  ///
  /// In en, this message translates to:
  /// **'3 months, no advance, 0% markup'**
  String get atompayIntroBold;

  /// No description provided for @atompayNotGiven.
  ///
  /// In en, this message translates to:
  /// **'Not given yet'**
  String get atompayNotGiven;

  /// No description provided for @atompayView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get atompayView;

  /// No description provided for @bulkScanTooShort.
  ///
  /// In en, this message translates to:
  /// **'That is too short for a serial.'**
  String get bulkScanTooShort;

  /// No description provided for @bulkScanAlready.
  ///
  /// In en, this message translates to:
  /// **'{serial} is already on this delivery.'**
  String bulkScanAlready(String serial);

  /// No description provided for @bulkScanTypeIt.
  ///
  /// In en, this message translates to:
  /// **'Type it'**
  String get bulkScanTypeIt;

  /// No description provided for @bulkScanSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get bulkScanSerial;

  /// No description provided for @bulkScanAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get bulkScanAdd;

  /// No description provided for @bulkScanCount.
  ///
  /// In en, this message translates to:
  /// **'{done} of {max} scanned'**
  String bulkScanCount(int done, int max);

  /// No description provided for @bulkScanDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get bulkScanDone;

  /// No description provided for @bulkChooseStatus.
  ///
  /// In en, this message translates to:
  /// **'Choose a status.'**
  String get bulkChooseStatus;

  /// No description provided for @bulkRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get bulkRequestDeclined;

  /// No description provided for @bulkStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Status saved'**
  String get bulkStatusSaved;

  /// No description provided for @bulkDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this request'**
  String get bulkDeclineTitle;

  /// No description provided for @bulkUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update status'**
  String get bulkUpdateStatus;

  /// No description provided for @bulkWhyDeclining.
  ///
  /// In en, this message translates to:
  /// **'Why are you declining?'**
  String get bulkWhyDeclining;

  /// No description provided for @bulkWhyLost.
  ///
  /// In en, this message translates to:
  /// **'Why was it lost?'**
  String get bulkWhyLost;

  /// No description provided for @bulkChooseReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason'**
  String get bulkChooseReason;

  /// No description provided for @bulkReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get bulkReason;

  /// No description provided for @bulkDeclineNote.
  ///
  /// In en, this message translates to:
  /// **'The seller is told in their app. A request you decline can\'t be quoted again.'**
  String get bulkDeclineNote;

  /// No description provided for @bulkContactedHint.
  ///
  /// In en, this message translates to:
  /// **'Use Contacted after you have spoken to them. Quoted is set when you send a quote, and Won when you make a deal.'**
  String get bulkContactedHint;

  /// No description provided for @bulkNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get bulkNote;

  /// No description provided for @bulkOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get bulkOptional;

  /// No description provided for @bulkNoteSellerHint.
  ///
  /// In en, this message translates to:
  /// **'A word for the seller'**
  String get bulkNoteSellerHint;

  /// No description provided for @bulkNoteBuyerHint.
  ///
  /// In en, this message translates to:
  /// **'What did they say?'**
  String get bulkNoteBuyerHint;

  /// No description provided for @bulkDeclineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get bulkDeclineRequest;

  /// No description provided for @bulkWonNeedQuote.
  ///
  /// In en, this message translates to:
  /// **'Send a quote first: a deal is made from the quote they accepted.'**
  String get bulkWonNeedQuote;

  /// No description provided for @bulkDealMade.
  ///
  /// In en, this message translates to:
  /// **'Deal {number} made'**
  String bulkDealMade(String number);

  /// No description provided for @bulkDealMadeShort.
  ///
  /// In en, this message translates to:
  /// **'Deal {number} made. Short in stock: {items}'**
  String bulkDealMadeShort(String number, String items);

  /// No description provided for @bulkSaidYes.
  ///
  /// In en, this message translates to:
  /// **'They said yes'**
  String get bulkSaidYes;

  /// No description provided for @bulkAlreadyDeal.
  ///
  /// In en, this message translates to:
  /// **'This request is already deal {number}.'**
  String bulkAlreadyDeal(String number);

  /// No description provided for @bulkWonNeedQuoteBusiness.
  ///
  /// In en, this message translates to:
  /// **'Send a quote first: a deal is made from the quote the business accepted.'**
  String get bulkWonNeedQuoteBusiness;

  /// No description provided for @bulkAcceptedQuote.
  ///
  /// In en, this message translates to:
  /// **'Accepted quote'**
  String get bulkAcceptedQuote;

  /// No description provided for @bulkSentWhen.
  ///
  /// In en, this message translates to:
  /// **'Sent {when}'**
  String bulkSentWhen(String when);

  /// No description provided for @bulkAdvancePct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% advance'**
  String bulkAdvancePct(int pct);

  /// No description provided for @bulkDeliverFrom.
  ///
  /// In en, this message translates to:
  /// **'Deliver from'**
  String get bulkDeliverFrom;

  /// No description provided for @bulkWonInfo.
  ///
  /// In en, this message translates to:
  /// **'The request becomes Won and a deal opens with these lines.'**
  String get bulkWonInfo;

  /// No description provided for @bulkWonInfoAdvance.
  ///
  /// In en, this message translates to:
  /// **' Take the {pct}% advance before the first delivery.'**
  String bulkWonInfoAdvance(int pct);

  /// No description provided for @bulkOpenDealNumber.
  ///
  /// In en, this message translates to:
  /// **'Open deal {number}'**
  String bulkOpenDealNumber(String number);

  /// No description provided for @bulkMarkWon.
  ///
  /// In en, this message translates to:
  /// **'Mark won and make a deal'**
  String get bulkMarkWon;

  /// No description provided for @bulkSendAQuote.
  ///
  /// In en, this message translates to:
  /// **'Send a quote'**
  String get bulkSendAQuote;

  /// No description provided for @bulkValidUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get bulkValidUntilLabel;

  /// No description provided for @bulkSavedAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Saved as a draft ({name})'**
  String bulkSavedAsDraft(String name);

  /// No description provided for @bulkQuoteSentToast.
  ///
  /// In en, this message translates to:
  /// **'Quote {name} sent'**
  String bulkQuoteSentToast(String name);

  /// No description provided for @bulkDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get bulkDraftSaved;

  /// No description provided for @bulkDraftLine.
  ///
  /// In en, this message translates to:
  /// **'Draft {name} · {total}, not sent yet'**
  String bulkDraftLine(String name, String total);

  /// No description provided for @bulkActFinishQuote.
  ///
  /// In en, this message translates to:
  /// **'Finish quote'**
  String get bulkActFinishQuote;

  /// No description provided for @bulkDraftSavedName.
  ///
  /// In en, this message translates to:
  /// **'Draft saved ({name})'**
  String bulkDraftSavedName(String name);

  /// No description provided for @bulkQuoteFor.
  ///
  /// In en, this message translates to:
  /// **'Quote · {who}'**
  String bulkQuoteFor(String who);

  /// No description provided for @bulkTheyAskedFor.
  ///
  /// In en, this message translates to:
  /// **'They asked for '**
  String get bulkTheyAskedFor;

  /// No description provided for @bulkHopingForTail.
  ///
  /// In en, this message translates to:
  /// **', hoping for {price} a unit'**
  String bulkHopingForTail(String price);

  /// No description provided for @bulkChangingDraft.
  ///
  /// In en, this message translates to:
  /// **'. You are changing draft rev {rev}.'**
  String bulkChangingDraft(String rev);

  /// No description provided for @bulkSendingMakesRev.
  ///
  /// In en, this message translates to:
  /// **'. Sending makes rev {rev}; rev {old} is marked superseded.'**
  String bulkSendingMakesRev(String rev, String old);

  /// No description provided for @bulkTypedNote.
  ///
  /// In en, this message translates to:
  /// **'The seller typed what they need. Quote it with the closest product from your catalogue.'**
  String get bulkTypedNote;

  /// No description provided for @bulkLinesHeader.
  ///
  /// In en, this message translates to:
  /// **'LINES'**
  String get bulkLinesHeader;

  /// No description provided for @bulkUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {max}'**
  String bulkUpTo(String max);

  /// No description provided for @bulkAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add a line'**
  String get bulkAddLine;

  /// No description provided for @bulkTermsHeader.
  ///
  /// In en, this message translates to:
  /// **'TERMS'**
  String get bulkTermsHeader;

  /// No description provided for @bulkDeliveryCharge.
  ///
  /// In en, this message translates to:
  /// **'Delivery charge'**
  String get bulkDeliveryCharge;

  /// No description provided for @bulkNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get bulkNone;

  /// No description provided for @bulkBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get bulkBalance;

  /// No description provided for @bulkNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get bulkNotes;

  /// No description provided for @bulkNotesNote.
  ///
  /// In en, this message translates to:
  /// **'optional, up to 500'**
  String get bulkNotesNote;

  /// No description provided for @bulkNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Delivery lots, warranty, anything the buyer should know'**
  String get bulkNotesHint;

  /// No description provided for @bulkPreviewPdf.
  ///
  /// In en, this message translates to:
  /// **'Preview or download PDF'**
  String get bulkPreviewPdf;

  /// No description provided for @bulkGettingPdf.
  ///
  /// In en, this message translates to:
  /// **'Getting the PDF…'**
  String get bulkGettingPdf;

  /// No description provided for @bulkPdfDraftNote.
  ///
  /// In en, this message translates to:
  /// **'The PDF saves this quote as a draft first; nothing is sent.'**
  String get bulkPdfDraftNote;

  /// No description provided for @bulkProductVariant.
  ///
  /// In en, this message translates to:
  /// **'Product and variant'**
  String get bulkProductVariant;

  /// No description provided for @bulkChooseProduct.
  ///
  /// In en, this message translates to:
  /// **'Choose a product'**
  String get bulkChooseProduct;

  /// No description provided for @bulkSearchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search your products'**
  String get bulkSearchProducts;

  /// No description provided for @bulkRemoveLine.
  ///
  /// In en, this message translates to:
  /// **'Remove line {n}'**
  String bulkRemoveLine(int n);

  /// No description provided for @bulkColour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get bulkColour;

  /// No description provided for @bulkQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get bulkQty;

  /// No description provided for @bulkDiscountPct.
  ///
  /// In en, this message translates to:
  /// **'Discount %'**
  String get bulkDiscountPct;

  /// No description provided for @bulkUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get bulkUnitPrice;

  /// No description provided for @bulkLineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line total'**
  String get bulkLineTotal;

  /// No description provided for @bulkLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get bulkLess;

  /// No description provided for @bulkMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get bulkMore;

  /// No description provided for @bulkQuoteTotal.
  ///
  /// In en, this message translates to:
  /// **'Quote total'**
  String get bulkQuoteTotal;

  /// No description provided for @bulkUnitsSubtotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit · subtotal} other{{count} units · subtotal}}'**
  String bulkUnitsSubtotal(int count);

  /// No description provided for @bulkDiscountDelivery.
  ///
  /// In en, this message translates to:
  /// **'Discount · Delivery'**
  String get bulkDiscountDelivery;

  /// No description provided for @bulkAdvanceNone.
  ///
  /// In en, this message translates to:
  /// **'Advance (none)'**
  String get bulkAdvanceNone;

  /// No description provided for @bulkAdvanceRow.
  ///
  /// In en, this message translates to:
  /// **'Advance {pct}%'**
  String bulkAdvanceRow(int pct);

  /// No description provided for @bulkSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get bulkSaveDraft;

  /// No description provided for @bulkSaveSendWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Save and send on WhatsApp'**
  String get bulkSaveSendWhatsApp;

  /// No description provided for @bulkDeal.
  ///
  /// In en, this message translates to:
  /// **'Deal'**
  String get bulkDeal;

  /// No description provided for @bulkFromOutlet.
  ///
  /// In en, this message translates to:
  /// **'from {outlet}'**
  String bulkFromOutlet(String outlet);

  /// No description provided for @bulkDealNumber.
  ///
  /// In en, this message translates to:
  /// **'Deal {number}'**
  String bulkDealNumber(String number);

  /// No description provided for @bulkWonDate.
  ///
  /// In en, this message translates to:
  /// **'won {date}'**
  String bulkWonDate(String date);

  /// No description provided for @bulkAtomshopSeller.
  ///
  /// In en, this message translates to:
  /// **'Atomshop seller'**
  String get bulkAtomshopSeller;

  /// No description provided for @bulkStepOpenAdvance.
  ///
  /// In en, this message translates to:
  /// **'Open\nAdvance paid'**
  String get bulkStepOpenAdvance;

  /// No description provided for @bulkStepDeliveringOf.
  ///
  /// In en, this message translates to:
  /// **'Delivering\n{done} of {units}'**
  String bulkStepDeliveringOf(int done, int units);

  /// No description provided for @bulkInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get bulkInvoice;

  /// No description provided for @bulkDeliverUnits.
  ///
  /// In en, this message translates to:
  /// **'Deliver units'**
  String get bulkDeliverUnits;

  /// No description provided for @bulkDealValue.
  ///
  /// In en, this message translates to:
  /// **'Deal value'**
  String get bulkDealValue;

  /// No description provided for @bulkDeliveryAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} delivery'**
  String bulkDeliveryAmount(String amount);

  /// No description provided for @bulkFreeDelivery.
  ///
  /// In en, this message translates to:
  /// **'free delivery'**
  String get bulkFreeDelivery;

  /// No description provided for @bulkDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {units}'**
  String bulkDoneOf(int done, int units);

  /// No description provided for @bulkDeliveriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 delivery} other{{count} deliveries}}'**
  String bulkDeliveriesCount(int count);

  /// No description provided for @bulkPctOfDeal.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of the deal'**
  String bulkPctOfDeal(int pct);

  /// No description provided for @bulkBalanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance due'**
  String get bulkBalanceDue;

  /// No description provided for @bulkAdvanceBeforeFirst.
  ///
  /// In en, this message translates to:
  /// **'Advance {amount} before the first delivery'**
  String bulkAdvanceBeforeFirst(String amount);

  /// No description provided for @bulkTakeBeforeNext.
  ///
  /// In en, this message translates to:
  /// **'Take payment before the next delivery'**
  String get bulkTakeBeforeNext;

  /// No description provided for @bulkDueBeforeLast.
  ///
  /// In en, this message translates to:
  /// **'Due before the last delivery'**
  String get bulkDueBeforeLast;

  /// No description provided for @bulkTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get bulkTerms;

  /// No description provided for @bulkAdvancePaidPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% · paid'**
  String bulkAdvancePaidPct(int pct);

  /// No description provided for @bulkAdvanceToTake.
  ///
  /// In en, this message translates to:
  /// **'{pct}% · {amount} to take'**
  String bulkAdvanceToTake(int pct, String amount);

  /// No description provided for @bulkDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get bulkDelivery;

  /// No description provided for @bulkInParts.
  ///
  /// In en, this message translates to:
  /// **'In parts'**
  String get bulkInParts;

  /// No description provided for @bulkFromQuote.
  ///
  /// In en, this message translates to:
  /// **'From quote'**
  String get bulkFromQuote;

  /// No description provided for @bulkItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get bulkItems;

  /// No description provided for @bulkProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get bulkProduct;

  /// No description provided for @bulkOrdered.
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get bulkOrdered;

  /// No description provided for @bulkLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get bulkLeft;

  /// No description provided for @bulkAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get bulkAmount;

  /// No description provided for @bulkNDelivered.
  ///
  /// In en, this message translates to:
  /// **'{count} delivered'**
  String bulkNDelivered(int count);

  /// No description provided for @bulkTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bulkTotal;

  /// No description provided for @bulkSerialOne.
  ///
  /// In en, this message translates to:
  /// **'Serial {serial}'**
  String bulkSerialOne(String serial);

  /// No description provided for @bulkSerialsList.
  ///
  /// In en, this message translates to:
  /// **'Serials {serials}'**
  String bulkSerialsList(String serials);

  /// No description provided for @bulkSerialsRange.
  ///
  /// In en, this message translates to:
  /// **'Serials {first} to {last}'**
  String bulkSerialsRange(String first, String last);

  /// No description provided for @bulkDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get bulkDeliveries;

  /// No description provided for @bulkReceivedByName.
  ///
  /// In en, this message translates to:
  /// **'received by {name}'**
  String bulkReceivedByName(String name);

  /// No description provided for @bulkWaitingSeller.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the seller to confirm'**
  String get bulkWaitingSeller;

  /// No description provided for @bulkSellerConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Seller confirmed {date} · in their stock'**
  String bulkSellerConfirmed(String date);

  /// No description provided for @bulkSignedNote.
  ///
  /// In en, this message translates to:
  /// **'Signed note'**
  String get bulkSignedNote;

  /// No description provided for @bulkSellerConfirmsNote.
  ///
  /// In en, this message translates to:
  /// **'The seller confirms each delivery note in their app; the units go into their stock with your serials.'**
  String get bulkSellerConfirmsNote;

  /// No description provided for @bulkPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get bulkPayments;

  /// No description provided for @bulkNoPayment.
  ///
  /// In en, this message translates to:
  /// **'No payment yet.'**
  String get bulkNoPayment;

  /// No description provided for @bulkPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get bulkPayment;

  /// No description provided for @bulkRef.
  ///
  /// In en, this message translates to:
  /// **'ref {ref}'**
  String bulkRef(String ref);

  /// No description provided for @bulkReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get bulkReceipt;

  /// No description provided for @bulkBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get bulkBusiness;

  /// No description provided for @bulkShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get bulkShop;

  /// No description provided for @bulkShopVerified.
  ///
  /// In en, this message translates to:
  /// **'{name} ✓ Verified'**
  String bulkShopVerified(String name);

  /// No description provided for @bulkBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get bulkBranch;

  /// No description provided for @bulkSellerCode.
  ///
  /// In en, this message translates to:
  /// **'Seller code'**
  String get bulkSellerCode;

  /// No description provided for @bulkContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get bulkContact;

  /// No description provided for @bulkWebsiteBuyer.
  ///
  /// In en, this message translates to:
  /// **'{name} · Website buyer'**
  String bulkWebsiteBuyer(String name);

  /// No description provided for @bulkPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get bulkPhone;

  /// No description provided for @bulkCommission.
  ///
  /// In en, this message translates to:
  /// **'Atomshop commission'**
  String get bulkCommission;

  /// No description provided for @bulkFromSellerRequest.
  ///
  /// In en, this message translates to:
  /// **'From seller request'**
  String get bulkFromSellerRequest;

  /// No description provided for @bulkFromBulkRequest.
  ///
  /// In en, this message translates to:
  /// **'From bulk request'**
  String get bulkFromBulkRequest;

  /// No description provided for @bulkHistDelivered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delivered 1 unit ({number})} other{Delivered {count} units ({number})}}'**
  String bulkHistDelivered(int count, String number);

  /// No description provided for @bulkHistPayment.
  ///
  /// In en, this message translates to:
  /// **'{kind} {amount}'**
  String bulkHistPayment(String kind, String amount);

  /// No description provided for @bulkHistBy.
  ///
  /// In en, this message translates to:
  /// **'by {method}'**
  String bulkHistBy(String method);

  /// No description provided for @bulkDealMadeEvent.
  ///
  /// In en, this message translates to:
  /// **'Deal made'**
  String get bulkDealMadeEvent;

  /// No description provided for @bulkWonFromQuote.
  ///
  /// In en, this message translates to:
  /// **'Won from quote {quote}'**
  String bulkWonFromQuote(String quote);

  /// No description provided for @bulkHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get bulkHistory;

  /// No description provided for @bulkPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get bulkPhotoAdded;

  /// No description provided for @bulkRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove the photo'**
  String get bulkRemovePhoto;

  /// No description provided for @bulkGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get bulkGallery;

  /// No description provided for @bulkSerialsFull.
  ///
  /// In en, this message translates to:
  /// **'There is a serial for every unit already.'**
  String get bulkSerialsFull;

  /// No description provided for @bulkScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan {title}'**
  String bulkScanTitle(String title);

  /// No description provided for @bulkDeliveredOn.
  ///
  /// In en, this message translates to:
  /// **'Delivered on'**
  String get bulkDeliveredOn;

  /// No description provided for @bulkDeliverySaved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delivery of 1 unit saved} other{Delivery of {count} units saved}}'**
  String bulkDeliverySaved(int count);

  /// No description provided for @bulkRuleAdvance.
  ///
  /// In en, this message translates to:
  /// **'Take the advance of {advance} before the first delivery. Paid so far: {paid}.'**
  String bulkRuleAdvance(String advance, String paid);

  /// No description provided for @bulkAdvancePaidPrefix.
  ///
  /// In en, this message translates to:
  /// **'Advance paid. '**
  String get bulkAdvancePaidPrefix;

  /// No description provided for @bulkRuleEach.
  ///
  /// In en, this message translates to:
  /// **'Balance is due before each delivery: payments so far cover {amount} more.'**
  String bulkRuleEach(String amount);

  /// No description provided for @bulkRuleLast.
  ///
  /// In en, this message translates to:
  /// **'The balance is due before the last delivery.'**
  String get bulkRuleLast;

  /// No description provided for @bulkBlockPayUnits.
  ///
  /// In en, this message translates to:
  /// **'This delivery is worth more than what has been paid. Record a payment of at least {amount} first.'**
  String bulkBlockPayUnits(String amount);

  /// No description provided for @bulkBlockBalance.
  ///
  /// In en, this message translates to:
  /// **'This delivery completes the deal: the balance of {amount} must be paid first. Bulk deals have no credit.'**
  String bulkBlockBalance(String amount);

  /// No description provided for @bulkBlockTooMany.
  ///
  /// In en, this message translates to:
  /// **'{title}: only {left} left to deliver.'**
  String bulkBlockTooMany(String title, int left);

  /// No description provided for @bulkReasonPick.
  ///
  /// In en, this message translates to:
  /// **'Choose how many units go out.'**
  String get bulkReasonPick;

  /// No description provided for @bulkReasonAdvance.
  ///
  /// In en, this message translates to:
  /// **'The advance comes first.'**
  String get bulkReasonAdvance;

  /// No description provided for @bulkReasonPay.
  ///
  /// In en, this message translates to:
  /// **'Record a payment first.'**
  String get bulkReasonPay;

  /// No description provided for @bulkReasonTooMany.
  ///
  /// In en, this message translates to:
  /// **'More than is left.'**
  String get bulkReasonTooMany;

  /// No description provided for @bulkDeliverTitle.
  ///
  /// In en, this message translates to:
  /// **'Deliver units · {number}'**
  String bulkDeliverTitle(String number);

  /// No description provided for @bulkRecordAPayment.
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get bulkRecordAPayment;

  /// No description provided for @bulkGoesOutHeader.
  ///
  /// In en, this message translates to:
  /// **'WHAT GOES OUT NOW'**
  String get bulkGoesOutHeader;

  /// No description provided for @bulkAllDelivered.
  ///
  /// In en, this message translates to:
  /// **'Everything on this deal is delivered.'**
  String get bulkAllDelivered;

  /// No description provided for @bulkReceivedBy.
  ///
  /// In en, this message translates to:
  /// **'Received by'**
  String get bulkReceivedBy;

  /// No description provided for @bulkReceivedByHint.
  ///
  /// In en, this message translates to:
  /// **'Name, and who they are'**
  String get bulkReceivedByHint;

  /// No description provided for @bulkTodayDate.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String bulkTodayDate(String date);

  /// No description provided for @bulkDeliverNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Second lot, by our van'**
  String get bulkDeliverNoteHint;

  /// No description provided for @bulkSignedDeliveryNote.
  ///
  /// In en, this message translates to:
  /// **'Signed delivery note'**
  String get bulkSignedDeliveryNote;

  /// No description provided for @bulkTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get bulkTakePhoto;

  /// No description provided for @bulkLastNeedsBalance.
  ///
  /// In en, this message translates to:
  /// **'The last delivery needs the full balance paid first.'**
  String get bulkLastNeedsBalance;

  /// No description provided for @bulkSaveDelivery.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save delivery · 1 unit} other{Save delivery · {count} units}}'**
  String bulkSaveDelivery(int count);

  /// No description provided for @bulkLeftOf.
  ///
  /// In en, this message translates to:
  /// **'{left} left of {qty}'**
  String bulkLeftOf(int left, int qty);

  /// No description provided for @bulkSerials.
  ///
  /// In en, this message translates to:
  /// **'Serials'**
  String get bulkSerials;

  /// No description provided for @bulkOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'one per line'**
  String get bulkOnePerLine;

  /// No description provided for @bulkOptionalCap.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get bulkOptionalCap;

  /// No description provided for @bulkSerialsHint.
  ///
  /// In en, this message translates to:
  /// **'One per unit, or none'**
  String get bulkSerialsHint;

  /// No description provided for @bulkScanSerialsFor.
  ///
  /// In en, this message translates to:
  /// **'Scan serials for {title}'**
  String bulkScanSerialsFor(String title);

  /// No description provided for @bulkFewer.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get bulkFewer;

  /// No description provided for @bulkPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get bulkPaymentDate;

  /// No description provided for @bulkPaymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment of {amount} saved'**
  String bulkPaymentSaved(String amount);

  /// No description provided for @bulkRecordPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Record payment · {number}'**
  String bulkRecordPaymentTitle(String number);

  /// No description provided for @bulkDealPaidFull.
  ///
  /// In en, this message translates to:
  /// **'This deal is paid in full.'**
  String get bulkDealPaidFull;

  /// No description provided for @bulkWhoBalance.
  ///
  /// In en, this message translates to:
  /// **'{who} · balance {amount}'**
  String bulkWhoBalance(String who, String amount);

  /// No description provided for @bulkHowPaid.
  ///
  /// In en, this message translates to:
  /// **'How did they pay?'**
  String get bulkHowPaid;

  /// No description provided for @bulkReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get bulkReference;

  /// No description provided for @bulkSlipPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of the slip'**
  String get bulkSlipPhoto;

  /// No description provided for @bulkSavePayment.
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get bulkSavePayment;

  /// No description provided for @bulkSellerRequest.
  ///
  /// In en, this message translates to:
  /// **'Seller request'**
  String get bulkSellerRequest;

  /// No description provided for @bulkBulkRequest.
  ///
  /// In en, this message translates to:
  /// **'Bulk request'**
  String get bulkBulkRequest;

  /// No description provided for @bulkSellerRequestWhen.
  ///
  /// In en, this message translates to:
  /// **'Seller request · {when}'**
  String bulkSellerRequestWhen(String when);

  /// No description provided for @bulkStepAsked.
  ///
  /// In en, this message translates to:
  /// **'Asked'**
  String get bulkStepAsked;

  /// No description provided for @bulkStepSellerAnswers.
  ///
  /// In en, this message translates to:
  /// **'Seller answers'**
  String get bulkStepSellerAnswers;

  /// No description provided for @bulkNoQuoteSeller.
  ///
  /// In en, this message translates to:
  /// **'No quote yet. A quote can carry a lower unit price, a discount, a delivery charge, the advance and how the balance is paid.'**
  String get bulkNoQuoteSeller;

  /// No description provided for @bulkDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get bulkDecline;

  /// No description provided for @bulkSendANewQuote.
  ///
  /// In en, this message translates to:
  /// **'Send a new quote'**
  String get bulkSendANewQuote;

  /// No description provided for @bulkReplySoon.
  ///
  /// In en, this message translates to:
  /// **'Reply soon.'**
  String get bulkReplySoon;

  /// No description provided for @bulkNeededByLate.
  ///
  /// In en, this message translates to:
  /// **'Needed by {day}: {rest}.'**
  String bulkNeededByLate(String day, String rest);

  /// No description provided for @bulkNeededByLeft.
  ///
  /// In en, this message translates to:
  /// **'Needed by {day}: {rest} left.'**
  String bulkNeededByLeft(String day, String rest);

  /// No description provided for @bulkNeededByWhen.
  ///
  /// In en, this message translates to:
  /// **'Needed by {day}: {rest}.'**
  String bulkNeededByWhen(String day, String rest);

  /// No description provided for @bulkAskOthers.
  ///
  /// In en, this message translates to:
  /// **'The seller can ask other brands too. Send your quote today.'**
  String get bulkAskOthers;

  /// No description provided for @bulkChangeAskedTitle.
  ///
  /// In en, this message translates to:
  /// **'The seller asked for a change'**
  String get bulkChangeAskedTitle;

  /// No description provided for @bulkOnQuote.
  ///
  /// In en, this message translates to:
  /// **'On quote {name}. '**
  String bulkOnQuote(String name);

  /// No description provided for @bulkSendRevisionNote.
  ///
  /// In en, this message translates to:
  /// **'Send a new revision: the old one is replaced and the seller is told.'**
  String get bulkSendRevisionNote;

  /// No description provided for @bulkValidUntilSentence.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}.'**
  String bulkValidUntilSentence(String date);

  /// No description provided for @bulkQuoteExpiredLead.
  ///
  /// In en, this message translates to:
  /// **'Quote {name} has expired.'**
  String bulkQuoteExpiredLead(String name);

  /// No description provided for @bulkKeepSeller.
  ///
  /// In en, this message translates to:
  /// **'Send a new revision to keep the seller.'**
  String get bulkKeepSeller;

  /// No description provided for @bulkQuoteWithSellerLead.
  ///
  /// In en, this message translates to:
  /// **'Quote {name} is with the seller.'**
  String bulkQuoteWithSellerLead(String name);

  /// No description provided for @bulkQuoteWithSellerBody.
  ///
  /// In en, this message translates to:
  /// **'They accept, ask for a change or decline it in their Atom Seller app.'**
  String get bulkQuoteWithSellerBody;

  /// No description provided for @bulkTurnedDownDot.
  ///
  /// In en, this message translates to:
  /// **'The seller turned your quote down.'**
  String get bulkTurnedDownDot;

  /// No description provided for @bulkTurnedDownColon.
  ///
  /// In en, this message translates to:
  /// **'The seller turned your quote down:'**
  String get bulkTurnedDownColon;

  /// No description provided for @bulkRequestClosed.
  ///
  /// In en, this message translates to:
  /// **'The request is closed.'**
  String get bulkRequestClosed;

  /// No description provided for @bulkStillQuote.
  ///
  /// In en, this message translates to:
  /// **'You can still send a new quote while the request is open.'**
  String get bulkStillQuote;

  /// No description provided for @bulkYouDeclined.
  ///
  /// In en, this message translates to:
  /// **'You declined this request.'**
  String get bulkYouDeclined;

  /// No description provided for @bulkReasonSentence.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}.'**
  String bulkReasonSentence(String reason);

  /// No description provided for @bulkAcceptedDot.
  ///
  /// In en, this message translates to:
  /// **'Accepted.'**
  String get bulkAcceptedDot;

  /// No description provided for @bulkAcceptedDeal.
  ///
  /// In en, this message translates to:
  /// **'Accepted: deal {number} is open.'**
  String bulkAcceptedDeal(String number);

  /// No description provided for @bulkCode.
  ///
  /// In en, this message translates to:
  /// **'Code {code}'**
  String bulkCode(String code);

  /// No description provided for @bulkOnAtomshopSince.
  ///
  /// In en, this message translates to:
  /// **'On Atomshop since'**
  String get bulkOnAtomshopSince;

  /// No description provided for @bulkBoughtFromYou.
  ///
  /// In en, this message translates to:
  /// **'Bought from you'**
  String get bulkBoughtFromYou;

  /// No description provided for @bulkNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get bulkNotYet;

  /// No description provided for @bulkPaidOnTime.
  ///
  /// In en, this message translates to:
  /// **'Paid on time'**
  String get bulkPaidOnTime;

  /// No description provided for @bulkOtherOpen.
  ///
  /// In en, this message translates to:
  /// **'Other open requests'**
  String get bulkOtherOpen;

  /// No description provided for @bulkWhatTheyNeed.
  ///
  /// In en, this message translates to:
  /// **'What they need'**
  String get bulkWhatTheyNeed;

  /// No description provided for @bulkFromCatalogue.
  ///
  /// In en, this message translates to:
  /// **'From your catalogue'**
  String get bulkFromCatalogue;

  /// No description provided for @bulkHopesToPay.
  ///
  /// In en, this message translates to:
  /// **'Seller hopes to pay'**
  String get bulkHopesToPay;

  /// No description provided for @bulkAUnit.
  ///
  /// In en, this message translates to:
  /// **'a unit'**
  String get bulkAUnit;

  /// No description provided for @bulkCashPrice.
  ///
  /// In en, this message translates to:
  /// **'Your cash price'**
  String get bulkCashPrice;

  /// No description provided for @bulkSamePrice.
  ///
  /// In en, this message translates to:
  /// **'the same as their price'**
  String get bulkSamePrice;

  /// No description provided for @bulkAbovePrice.
  ///
  /// In en, this message translates to:
  /// **'{pct}% above their price'**
  String bulkAbovePrice(int pct);

  /// No description provided for @bulkBelowPrice.
  ///
  /// In en, this message translates to:
  /// **'{pct}% below their price'**
  String bulkBelowPrice(int pct);

  /// No description provided for @bulkDeliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get bulkDeliverTo;

  /// No description provided for @bulkAtYourPrice.
  ///
  /// In en, this message translates to:
  /// **'At your price'**
  String get bulkAtYourPrice;

  /// No description provided for @bulkSellersNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Seller\'s note'**
  String get bulkSellersNoteLabel;

  /// No description provided for @bulkQuotesSent.
  ///
  /// In en, this message translates to:
  /// **'Quotes sent'**
  String get bulkQuotesSent;

  /// No description provided for @bulkQuoteSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {amount}, {label}. Share the PDF'**
  String bulkQuoteSemantics(String name, String amount, String label);

  /// No description provided for @bulkSentDate.
  ///
  /// In en, this message translates to:
  /// **'Sent {date}'**
  String bulkSentDate(String date);

  /// No description provided for @bulkCommissionFixed.
  ///
  /// In en, this message translates to:
  /// **'The commission was fixed when the deal opened: see the deal.'**
  String get bulkCommissionFixed;

  /// No description provided for @bulkCommissionInfo.
  ///
  /// In en, this message translates to:
  /// **'If Atomshop sets a rate on seller deals, it is shown here before you send a quote and fixed when the deal opens. It is added to your monthly bill, never taken from the seller\'s payment.'**
  String get bulkCommissionInfo;

  /// No description provided for @bulkOnThisRequest.
  ///
  /// In en, this message translates to:
  /// **'On this request'**
  String get bulkOnThisRequest;

  /// No description provided for @bulkTheSeller.
  ///
  /// In en, this message translates to:
  /// **'The seller'**
  String get bulkTheSeller;

  /// No description provided for @bulkYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get bulkYou;

  /// No description provided for @bulkBulkRequestWhen.
  ///
  /// In en, this message translates to:
  /// **'Bulk request · {when}'**
  String bulkBulkRequestWhen(String when);

  /// No description provided for @bulkStepDeliveredPaid.
  ///
  /// In en, this message translates to:
  /// **'Delivered and paid'**
  String get bulkStepDeliveredPaid;

  /// No description provided for @bulkStatusButton.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get bulkStatusButton;

  /// No description provided for @bulkQuoteReady.
  ///
  /// In en, this message translates to:
  /// **'Quote {name} is ready.'**
  String bulkQuoteReady(String name);

  /// No description provided for @bulkOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get bulkOpenWhatsApp;

  /// No description provided for @bulkDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get bulkDownloadPdf;

  /// No description provided for @bulkWonDot.
  ///
  /// In en, this message translates to:
  /// **'Won.'**
  String get bulkWonDot;

  /// No description provided for @bulkWonDeal.
  ///
  /// In en, this message translates to:
  /// **'Won: deal {number}.'**
  String bulkWonDeal(String number);

  /// No description provided for @bulkLostDot.
  ///
  /// In en, this message translates to:
  /// **'Lost.'**
  String get bulkLostDot;

  /// No description provided for @bulkLostReason.
  ///
  /// In en, this message translates to:
  /// **'Lost: {reason}.'**
  String bulkLostReason(String reason);

  /// No description provided for @bulkTheRequest.
  ///
  /// In en, this message translates to:
  /// **'The request'**
  String get bulkTheRequest;

  /// No description provided for @bulkQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get bulkQuantity;

  /// No description provided for @bulkAtListPrice.
  ///
  /// In en, this message translates to:
  /// **'At list price'**
  String get bulkAtListPrice;

  /// No description provided for @bulkPriceHope.
  ///
  /// In en, this message translates to:
  /// **'Price they hope for'**
  String get bulkPriceHope;

  /// No description provided for @bulkPriceAUnit.
  ///
  /// In en, this message translates to:
  /// **'{price} a unit'**
  String bulkPriceAUnit(String price);

  /// No description provided for @bulkLostBecause.
  ///
  /// In en, this message translates to:
  /// **'Lost because'**
  String get bulkLostBecause;

  /// No description provided for @bulkNewRevision.
  ///
  /// In en, this message translates to:
  /// **'New revision'**
  String get bulkNewRevision;

  /// No description provided for @bulkSaidYesQ.
  ///
  /// In en, this message translates to:
  /// **'They said yes?'**
  String get bulkSaidYesQ;

  /// No description provided for @bulkMarkWonNote.
  ///
  /// In en, this message translates to:
  /// **'Mark the request won. It becomes a deal you deliver and collect on.'**
  String get bulkMarkWonNote;

  /// No description provided for @bulkConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation history'**
  String get bulkConversation;

  /// No description provided for @bulkContactStanding.
  ///
  /// In en, this message translates to:
  /// **'Contact and standing'**
  String get bulkContactStanding;

  /// No description provided for @bulkName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get bulkName;

  /// No description provided for @bulkEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get bulkEmail;

  /// No description provided for @bulkVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get bulkVerified;

  /// No description provided for @bulkAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get bulkAccount;

  /// No description provided for @bulkGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest, no Atomshop account'**
  String get bulkGuest;

  /// No description provided for @bulkOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order} other{{count} orders}}'**
  String bulkOrdersCount(int count);

  /// No description provided for @bulkOtherRequests.
  ///
  /// In en, this message translates to:
  /// **'Other requests'**
  String get bulkOtherRequests;

  /// No description provided for @bulkNewQuoteRevision.
  ///
  /// In en, this message translates to:
  /// **'New quote revision'**
  String get bulkNewQuoteRevision;

  /// No description provided for @bulkAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bulkAll;

  /// No description provided for @bulkReceivedFilter.
  ///
  /// In en, this message translates to:
  /// **'Received: {when}'**
  String bulkReceivedFilter(String when);

  /// No description provided for @bulkReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get bulkReceivedTitle;

  /// No description provided for @bulkAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get bulkAnyTime;

  /// No description provided for @bulkRangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get bulkRangeToday;

  /// No description provided for @bulkRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get bulkRangeWeek;

  /// No description provided for @bulkRangeDays30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get bulkRangeDays30;

  /// No description provided for @bulkRangeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get bulkRangeThisMonth;

  /// No description provided for @bulkRangePick.
  ///
  /// In en, this message translates to:
  /// **'Pick dates'**
  String get bulkRangePick;

  /// No description provided for @bulkRangeDates.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String bulkRangeDates(String from, String to);

  /// No description provided for @bulkEmptyReceived.
  ///
  /// In en, this message translates to:
  /// **'No requests received then'**
  String get bulkEmptyReceived;

  /// No description provided for @bulkEmptyReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'Try another time, or Any time.'**
  String get bulkEmptyReceivedBody;

  /// No description provided for @bulkLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t load'**
  String get bulkLoadErrorTitle;

  /// No description provided for @bulkLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Atomshop couldn\'t load this just now. Nothing was changed.'**
  String get bulkLoadErrorBody;

  /// No description provided for @bulkNoDelivery.
  ///
  /// In en, this message translates to:
  /// **'No delivery yet.'**
  String get bulkNoDelivery;

  /// No description provided for @bulkFromRequest.
  ///
  /// In en, this message translates to:
  /// **'From request'**
  String get bulkFromRequest;

  /// No description provided for @bulkAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bulkAddress;

  /// No description provided for @bulkCommissionNoneInfo.
  ///
  /// In en, this message translates to:
  /// **'Seller deals carry no commission for your brand today. If Atomshop sets a rate, it is shown here before you send a quote and fixed when the deal opens; it is added to your monthly bill, never taken from the seller\'s payment.'**
  String get bulkCommissionNoneInfo;

  /// No description provided for @bulkReceivedFromAtomshop.
  ///
  /// In en, this message translates to:
  /// **'Request received from Atomshop'**
  String get bulkReceivedFromAtomshop;

  /// No description provided for @bulkAddPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get bulkAddPhotoTitle;

  /// No description provided for @teamSemYes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get teamSemYes;

  /// No description provided for @teamSemNo.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get teamSemNo;

  /// No description provided for @outletsHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash sales, all outlets · {period}'**
  String outletsHeroLabel(String period);

  /// No description provided for @outletsUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} outlets'**
  String outletsUsedOf(int used, int limit);

  /// No description provided for @outletsHeroMeta.
  ///
  /// In en, this message translates to:
  /// **'{outlets, plural, =1{Delivered {delivered} · Payments received {paid} · 1 outlet} other{Delivered {delivered} · Payments received {paid} · {outlets} outlets}}'**
  String outletsHeroMeta(int delivered, String paid, int outlets);

  /// No description provided for @outletsUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit} other{{count} units}}'**
  String outletsUnits(int count);

  /// No description provided for @outletsOfSales.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of sales'**
  String outletsOfSales(int pct);

  /// No description provided for @outletsAskMore.
  ///
  /// In en, this message translates to:
  /// **'Need more than {limit} outlets? Ask Atomshop on WhatsApp'**
  String outletsAskMore(int limit);

  /// No description provided for @outletsFull.
  ///
  /// In en, this message translates to:
  /// **'You have used all {limit} outlets on your account. Ask Atomshop for more.'**
  String outletsFull(int limit);

  /// No description provided for @outletsWaAskMore.
  ///
  /// In en, this message translates to:
  /// **'Assalam o Alaikum, I would like more outlets for {brand} on Atombrand.'**
  String outletsWaAskMore(String brand);

  /// No description provided for @outletsWaAskMulti.
  ///
  /// In en, this message translates to:
  /// **'Assalam o Alaikum, I would like to make {brand} a multi-outlet account on Atombrand.'**
  String outletsWaAskMulti(String brand);

  /// No description provided for @outletsUsedLine.
  ///
  /// In en, this message translates to:
  /// **'Outlets used: {used} of {limit}'**
  String outletsUsedLine(int used, int limit);

  /// No description provided for @outletsTakenBy.
  ///
  /// In en, this message translates to:
  /// **'{city} · {outlet}'**
  String outletsTakenBy(String city, String outlet);

  /// No description provided for @outletsTakenAria.
  ///
  /// In en, this message translates to:
  /// **'{city}, served by {outlet}'**
  String outletsTakenAria(String city, String outlet);

  /// No description provided for @outletsOfLimit.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit}'**
  String outletsOfLimit(int used, int limit);

  /// No description provided for @outletsOpenedDay.
  ///
  /// In en, this message translates to:
  /// **'opened {day}'**
  String outletsOpenedDay(String day);

  /// No description provided for @outletsRunBy.
  ///
  /// In en, this message translates to:
  /// **'run by {name}'**
  String outletsRunBy(String name);

  /// No description provided for @outletsKpiSalesNote.
  ///
  /// In en, this message translates to:
  /// **'{delivered} delivered'**
  String outletsKpiSalesNote(int delivered);

  /// No description provided for @outletsKpiOrdersNote.
  ///
  /// In en, this message translates to:
  /// **'{toConfirm} to confirm'**
  String outletsKpiOrdersNote(int toConfirm);

  /// No description provided for @outletsKpiDue.
  ///
  /// In en, this message translates to:
  /// **'{rs} still due'**
  String outletsKpiDue(String rs);

  /// No description provided for @outletsStaffHere.
  ///
  /// In en, this message translates to:
  /// **'{own} here'**
  String outletsStaffHere(int own);

  /// No description provided for @outletsStaffAll.
  ///
  /// In en, this message translates to:
  /// **'{own} here · {all} work in every outlet'**
  String outletsStaffAll(int own, int all);

  /// No description provided for @outletsStatusDone.
  ///
  /// In en, this message translates to:
  /// **'{name} is {status}'**
  String outletsStatusDone(String name, String status);

  /// No description provided for @outletsPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause {name}?'**
  String outletsPauseTitle(String name);

  /// No description provided for @outletsCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close {name}?'**
  String outletsCloseTitle(String name);

  /// No description provided for @outletsOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Open {name} again?'**
  String outletsOpenTitle(String name);

  /// No description provided for @outletsStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get outletsStatusOpen;

  /// No description provided for @outletsStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get outletsStatusPaused;

  /// No description provided for @outletsStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get outletsStatusClosed;

  /// No description provided for @outletsPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get outletsPeriodMonth;

  /// No description provided for @outletsPeriodLast.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get outletsPeriodLast;

  /// No description provided for @outletsPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get outletsPeriodYear;

  /// No description provided for @outletsCardPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused · no new orders'**
  String get outletsCardPaused;

  /// No description provided for @outletsCardClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed · history only'**
  String get outletsCardClosed;

  /// No description provided for @outletsStaffCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 staff} other{{count} staff}}'**
  String outletsStaffCount(int count);

  /// No description provided for @outletsItsCities.
  ///
  /// In en, this message translates to:
  /// **'its cities'**
  String get outletsItsCities;

  /// No description provided for @outletsAnd.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b}'**
  String outletsAnd(String a, String b);

  /// No description provided for @outletsPlanMainNote.
  ///
  /// In en, this message translates to:
  /// **'The main outlet can’t be paused or closed: orders from cities no other outlet serves go to it.'**
  String get outletsPlanMainNote;

  /// No description provided for @outletsPlanMainButton.
  ///
  /// In en, this message translates to:
  /// **'Main outlet'**
  String get outletsPlanMainButton;

  /// No description provided for @outletsPlanOpenNote.
  ///
  /// In en, this message translates to:
  /// **'Open: takes new orders for {where}.'**
  String outletsPlanOpenNote(String where);

  /// No description provided for @outletsKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep it open'**
  String get outletsKeepOpen;

  /// No description provided for @outletsReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen outlet'**
  String get outletsReopen;

  /// No description provided for @outletsOpenAgain.
  ///
  /// In en, this message translates to:
  /// **'Open it again'**
  String get outletsOpenAgain;

  /// No description provided for @outletsPlanPausedNote.
  ///
  /// In en, this message translates to:
  /// **'Paused: new orders for {where} go to the main outlet and its staff can’t sign in.'**
  String outletsPlanPausedNote(String where);

  /// No description provided for @outletsPlanPausingNote.
  ///
  /// In en, this message translates to:
  /// **'Pausing stops new orders for {where} and signs its staff out. Orders already placed carry on.'**
  String outletsPlanPausingNote(String where);

  /// No description provided for @outletsKeepPaused.
  ///
  /// In en, this message translates to:
  /// **'Keep it paused'**
  String get outletsKeepPaused;

  /// No description provided for @outletsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get outletsPause;

  /// No description provided for @outletsPlanClosedNote.
  ///
  /// In en, this message translates to:
  /// **'Closed: kept for its history. Reopen it to change it or take orders again.'**
  String get outletsPlanClosedNote;

  /// No description provided for @outletsWhyOrders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order is still open} other{{count} orders are still open}}'**
  String outletsWhyOrders(int count);

  /// No description provided for @outletsWhyUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit is still in stock} other{{count} units are still in stock}}'**
  String outletsWhyUnits(int count);

  /// No description provided for @outletsPlanCloseNote.
  ///
  /// In en, this message translates to:
  /// **'Closing needs no open orders, no running bulk deals and zero stock. Its cities move to the main outlet.'**
  String get outletsPlanCloseNote;

  /// No description provided for @outletsPlanCantCloseNote.
  ///
  /// In en, this message translates to:
  /// **'Can’t close yet: {why}. Deliver, cancel or move them first, or pause the outlet instead.'**
  String outletsPlanCantCloseNote(String why);

  /// No description provided for @outletsCloseOutlet.
  ///
  /// In en, this message translates to:
  /// **'Close outlet'**
  String get outletsCloseOutlet;

  /// No description provided for @outletsCantClose.
  ///
  /// In en, this message translates to:
  /// **'Can’t close yet'**
  String get outletsCantClose;

  /// No description provided for @outletsPhoneEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the outlet’s phone number.'**
  String get outletsPhoneEmpty;

  /// No description provided for @outletsPhoneBad.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number, e.g. 0300 1234567 or 042 35761234.'**
  String get outletsPhoneBad;

  /// No description provided for @outletsBlockName.
  ///
  /// In en, this message translates to:
  /// **'Give the outlet a name'**
  String get outletsBlockName;

  /// No description provided for @outletsBlockNameLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the name to 40 letters'**
  String get outletsBlockNameLong;

  /// No description provided for @outletsBlockPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone number'**
  String get outletsBlockPhone;

  /// No description provided for @outletsBlockPhoneBad.
  ///
  /// In en, this message translates to:
  /// **'Check the phone number'**
  String get outletsBlockPhoneBad;

  /// No description provided for @outletsBlockAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter the address'**
  String get outletsBlockAddress;

  /// No description provided for @outletsBlockAddressLong.
  ///
  /// In en, this message translates to:
  /// **'Shorten the address'**
  String get outletsBlockAddressLong;

  /// No description provided for @outletsOpenIt.
  ///
  /// In en, this message translates to:
  /// **'Open it'**
  String get outletsOpenIt;

  /// No description provided for @outletsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get outletsEdit;

  /// No description provided for @outletsOrderPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get outletsOrderPending;

  /// No description provided for @outletsOrderConfirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming'**
  String get outletsOrderConfirming;

  /// No description provided for @outletsOrderProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get outletsOrderProcessing;

  /// No description provided for @outletsOrderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get outletsOrderDelivered;

  /// No description provided for @outletsOrderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get outletsOrderCompleted;

  /// No description provided for @outletsOrderInstalments.
  ///
  /// In en, this message translates to:
  /// **'Instalments'**
  String get outletsOrderInstalments;

  /// No description provided for @outletsOrderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get outletsOrderCancelled;

  /// No description provided for @outletsMyBrand.
  ///
  /// In en, this message translates to:
  /// **'my brand'**
  String get outletsMyBrand;

  /// No description provided for @teamSemOn.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get teamSemOn;

  /// No description provided for @teamSemOff.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get teamSemOff;

  /// No description provided for @ordersClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get ordersClearSearch;

  /// No description provided for @ordersSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Order number, customer, phone or product'**
  String get ordersSearchPlaceholder;

  /// No description provided for @atompaySearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Order number or product'**
  String get atompaySearchPlaceholder;

  /// No description provided for @ordersPlacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get ordersPlacedTitle;

  /// No description provided for @ordersPlacedFilter.
  ///
  /// In en, this message translates to:
  /// **'Placed: {when}'**
  String ordersPlacedFilter(String when);

  /// No description provided for @ordersLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t load'**
  String get ordersLoadErrorTitle;

  /// No description provided for @ordersLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Atomshop couldn\'t load this just now. Nothing was changed.'**
  String get ordersLoadErrorBody;

  /// No description provided for @ordersErrorRef.
  ///
  /// In en, this message translates to:
  /// **'Ref {ref}'**
  String ordersErrorRef(String ref);

  /// No description provided for @ordersSaveErrorBody.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Nothing was changed; try again.'**
  String get ordersSaveErrorBody;

  /// No description provided for @ordersDeliveryFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get ordersDeliveryFree;

  /// No description provided for @ordersNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get ordersNotVerified;

  /// No description provided for @ordersNotGiven.
  ///
  /// In en, this message translates to:
  /// **'Not given'**
  String get ordersNotGiven;

  /// No description provided for @ordersDeliveredBy.
  ///
  /// In en, this message translates to:
  /// **'Delivered by'**
  String get ordersDeliveredBy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
