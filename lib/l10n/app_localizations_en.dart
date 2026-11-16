// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get applyCategoryPlaceholder => 'e.g. Mobiles, Smart TVs';

  @override
  String get authSplashOffline => 'Offline · your data is on this phone';

  @override
  String authSplashWaiting(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String authSplashLastSynced(String when) {
    return 'Last synced $when';
  }

  @override
  String authSplashToday(String time) {
    return 'today, $time';
  }

  @override
  String authSplashDaysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Offline for $n more days',
      one: 'Offline for 1 more day',
      zero: 'Offline time is up',
    );
    return '$_temp0';
  }

  @override
  String get authPinOfflineTitle => 'Work offline';

  @override
  String get authPinOfflineSub => 'Keep 30 days of your brand on this phone';

  @override
  String get authPinOfflineOn => 'On';

  @override
  String authOutletAllSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Combined figures for all $count outlets',
      one: 'Combined figures for 1 outlet',
    );
    return '$_temp0';
  }

  @override
  String authOutletServes(String city, String cities) {
    return '$city · serves $cities';
  }

  @override
  String authOutletServesOnly(String cities) {
    return 'Serves $cities';
  }

  @override
  String get authOutletPausedByYou => 'Paused by you';

  @override
  String get authOutletPausedByOwner => 'Paused by your brand owner';

  @override
  String get authOutletKeepAll =>
      'Keep all open outlets on this phone for offline work';

  @override
  String authOutletKeepOne(String name) {
    return 'Keep $name on this phone for offline work';
  }

  @override
  String get authReadyOnlineWifi => 'Online · Wi-Fi';

  @override
  String authReadySecondsLeft(int n) {
    return 'About $n seconds left';
  }

  @override
  String authReadyMinutesLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'About $n minutes left',
      one: 'About a minute left',
    );
    return '$_temp0';
  }

  @override
  String get homeNoticedTitle => 'Atom noticed';

  @override
  String get homeNoticedMorning => 'From your data this morning';

  @override
  String get homeNoticedAfternoon => 'From your data this afternoon';

  @override
  String get homeNoticedEvening => 'From your data this evening';

  @override
  String get homeNoticedSeeStock => 'See stock';

  @override
  String get homeNoticedOpenOutlet => 'Open outlet';

  @override
  String get homeNoticedFollowUp => 'Follow up';

  @override
  String statesKeptOnPhone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n changes are kept on this phone. They are sent as soon as you sign in again.',
      one: '1 change is kept on this phone. It is sent as soon as you sign in again.',
    );
    return '$_temp0';
  }

  @override
  String statesKeptOnPhoneBold(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n changes are kept on this phone.',
      one: '1 change is kept on this phone.',
    );
    return '$_temp0';
  }

  @override
  String get statesPlaceSearch => 'Search';

  @override
  String get statesPlaceOrder => 'the order';

  @override
  String get statesPlaceAtompay => 'the AtomPay order';

  @override
  String get statesPlaceDeal => 'the bulk deal';

  @override
  String get statesPlaceBulkRequest => 'the bulk request';

  @override
  String get statesPlaceProduct => 'the product';

  @override
  String get statesPlaceBrandPage => 'Brand page';

  @override
  String get statesPlaceStock => 'Stock';

  @override
  String get statesPlaceTeam => 'Team';

  @override
  String get statesPlaceOutlets => 'Outlets';

  @override
  String get statesPlacePlan => 'Plan & billing';

  @override
  String get statesPlaceReports => 'Reports';

  @override
  String get statesPlaceAskAtom => 'Ask Atom';

  @override
  String get statesPlaceSync => 'Sync centre';

  @override
  String get statesPlaceHelp => 'Help';

  @override
  String get statesPlaceSettings => 'Settings';

  @override
  String get statesPlaceNotifications => 'Notifications';

  @override
  String get statesPlaceMenu => 'Menu';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonChoose => 'Choose';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonSomethingWrong => 'Something went wrong';

  @override
  String get selectSearchHint => 'Search';

  @override
  String get selectClearSearch => 'Clear search';

  @override
  String selectNoMatch(String query) {
    return 'No match for \"$query\"';
  }

  @override
  String get selectNoMatchHint =>
      'Check the spelling, or try part of the name.';

  @override
  String get selectOfflineNote =>
      'Offline: searching the list saved on this phone.';

  @override
  String selectDoneChosen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Done · $count chosen',
      zero: 'Done',
    );
    return '$_temp0';
  }

  @override
  String get selectCouldNotLoad => 'Couldn\'t load the list';

  @override
  String get leaveTitle => 'Leave without saving?';

  @override
  String get leaveBody => 'Your changes on this screen will be lost.';

  @override
  String get leaveDiscard => 'Discard';

  @override
  String get leaveKeepEditing => 'Keep editing';

  @override
  String get appName => 'Brand Partner';

  @override
  String get commonOk => 'OK';

  @override
  String get keypadDelete => 'Delete';

  @override
  String get keypadFingerprint => 'Use fingerprint';

  @override
  String pinDotsLabel(int filled, int length) {
    return '$filled of $length digits entered';
  }

  @override
  String get tabHome => 'Home';

  @override
  String get tabOrders => 'Orders';

  @override
  String get backAgainToClose => 'Press back again to close';

  @override
  String get welcomeLanguage => 'English';

  @override
  String get languageTitle => 'Language';

  @override
  String get welcomeCollectedToday => 'Cash sales today';

  @override
  String get welcomePaidCount => '7 orders';

  @override
  String get welcomeDueToday => 'To confirm';

  @override
  String get welcomeDueCustomers => '4 new orders';

  @override
  String get welcomeNewLeads => 'New bulk requests';

  @override
  String get welcomeLeadsInAreas => '3 waiting';

  @override
  String get welcomeFromWebsite => 'From Atomshop sellers';

  @override
  String get welcomeTitle => 'Your brand on Atomshop, in your pocket';

  @override
  String get welcomeBody =>
      'Orders, AtomPay, bulk deals, products and stock, online or with no signal at all.';

  @override
  String get welcomeFeaturePaymentsBold => 'Confirm and deliver orders';

  @override
  String get welcomeFeaturePaymentsRest => ' with a proof photo';

  @override
  String get welcomeFeatureOfflineBold => 'Reply to bulk requests';

  @override
  String get welcomeFeatureOfflineRest => ' with quotes on WhatsApp';

  @override
  String get welcomeFeatureTeamBold => 'Stock, team and outlets';

  @override
  String get welcomeFeatureTeamRest => ', even offline';

  @override
  String get welcomeSignIn => 'Sign in';

  @override
  String get welcomeBecomeSeller => 'Apply to list your brand';

  @override
  String get signInTitle => 'Sign in to Brand Partner';

  @override
  String get signInSubtitle =>
      'Use the same account as your Brand Partner Portal.';

  @override
  String get signInOwner => 'Brand owner';

  @override
  String get signInAgent => 'Team member';

  @override
  String get signInEmail => 'Email';

  @override
  String get signInMobile => 'Mobile number';

  @override
  String get signInMobileHint =>
      'The number your brand owner added you with. Owners use their email.';

  @override
  String get signInPassword => 'Password';

  @override
  String get signInForgot => 'Forgot password?';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signInSigningIn => 'Signing in…';

  @override
  String get signInShowPassword => 'Show password';

  @override
  String get signInHidePassword => 'Hide password';

  @override
  String get signInTrouble => 'Trouble signing in?';

  @override
  String get signInWhatsApp => 'WhatsApp Atomshop';

  @override
  String get signInEmailInvalid => 'Enter your email, like name@example.com';

  @override
  String get signInMobileInvalid =>
      'Enter an 11-digit mobile number starting with 03';

  @override
  String get signInPasswordEmpty => 'Enter your password';

  @override
  String get signInOffline =>
      'No internet. Turn on mobile data or Wi-Fi and try again.';

  @override
  String get signInFailed => 'Couldn\'t sign in. Try again in a moment.';

  @override
  String get agentPasswordTitle => 'Choose your own password';

  @override
  String get agentPasswordBody =>
      'Your brand owner gave you a temporary one. Pick a password only you know: you will need it on a new phone.';

  @override
  String get agentPasswordNew => 'New password';

  @override
  String get agentPasswordConfirm => 'Type it again';

  @override
  String get agentPasswordHint => '8 or more characters';

  @override
  String get agentPasswordTooShort => 'Use 8 or more characters';

  @override
  String get agentPasswordMismatch => 'The two passwords are not the same.';

  @override
  String get agentPasswordSave => 'Save and continue';

  @override
  String get signedOutTitle => 'Please sign in again';

  @override
  String get signedOutBody =>
      'For your safety you were signed out. Your brand\'s data is safe.';

  @override
  String get signedOutChosenTitle => 'You\'re signed out';

  @override
  String get signedOutChosenBody => 'Sign in to carry on where you left off.';

  @override
  String get signedOutReturn =>
      'After you sign in, you go back to where you were.';

  @override
  String get signedOutSignIn => 'Sign in again';

  @override
  String get signedOutForgot => 'Forgot password';

  @override
  String get maintenanceTitle => 'Atomshop is being updated';

  @override
  String get maintenanceData => 'Your data';

  @override
  String get maintenanceDataSafe => 'Safe with Atomshop';

  @override
  String get maintenanceCustomers => 'Orders';

  @override
  String get maintenanceCustomersOk => 'Not affected';

  @override
  String get maintenanceUsing => 'Using the app';

  @override
  String get maintenanceUsingWait => 'Wait';

  @override
  String get removedTitle => 'Choose a package to carry on';

  @override
  String removedBody(String business) {
    return 'Your package on $business has ended. Everything you saved is kept safe: products, orders, bulk deals and stock.';
  }

  @override
  String get removedOpenNow => 'Open now';

  @override
  String get removedOpenNowValue => 'Plan & billing, your profile';

  @override
  String get removedAfterPaying => 'After paying';

  @override
  String get removedAfterPayingValue => 'Everything, as before';

  @override
  String get removedSeePackages => 'See packages & prices';

  @override
  String get removedTalk => 'Talk to Atomshop';

  @override
  String get removedAgentNote =>
      'Only the brand owner can choose a package. Ask them to open Plan & billing.';

  @override
  String get noPlanTitle => 'No active package';

  @override
  String get noPlanBody =>
      'This account has no package yet. Choose one to start using Brand Partner.';

  @override
  String get notInRoleTitle => 'Your role doesn\'t include this';

  @override
  String get statesAskWhyQuestion => 'Why doesn\'t my role include this?';

  @override
  String get statesCanEverything => 'Everything: you own the brand';

  @override
  String get statesCanPayments => 'payments';

  @override
  String get statesCanAtompay => 'AtomPay';

  @override
  String get statesCanTeam => 'team';

  @override
  String statesCanSee(String list) {
    return 'see $list';
  }

  @override
  String get notInRoleBody =>
      'The brand owner decides what each person can do. Ask them to change your role if you need it.';

  @override
  String get notInRoleYourRole => 'Your role';

  @override
  String get notFoundTitle => 'Not found';

  @override
  String get notFoundBody =>
      'This page doesn\'t exist, or it isn\'t part of your brand.';

  @override
  String get notFoundHome => 'Go to Home';

  @override
  String get noInternetTitle => 'No internet';

  @override
  String get noInternetBody =>
      'Brand Partner needs a connection to show and save your work. Turn on mobile data or Wi-Fi.';

  @override
  String get noInternetAuto =>
      'It tries again by itself when the signal comes back.';

  @override
  String get restrictedTitle => 'Atomshop has paused changes on your account';

  @override
  String get restrictedPayments => 'Recording payments and deliveries';

  @override
  String get restrictedWorks => 'Works';

  @override
  String get restrictedCloseDeals => 'AtomPay hand-overs, Ask Atom';

  @override
  String get restrictedNewThings => 'Products, quotes, stock';

  @override
  String get restrictedPaused => 'Paused';

  @override
  String get restrictedWhatsApp => 'Message Atomshop on WhatsApp';

  @override
  String restrictedCall(String phone) {
    return 'Call $phone';
  }

  @override
  String get restrictedNote =>
      'This isn\'t about a bill, so there is nothing to pay. Orders already placed carry on.';

  @override
  String get bannerPay => 'Pay';

  @override
  String get menuOwner => 'Brand owner';

  @override
  String get menuSignOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out of Brand Partner?';

  @override
  String signOutUnsentBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes you made haven\'t reached Atomshop yet.',
      one: '1 change you made hasn\'t reached Atomshop yet.',
    );
    return '$_temp0 It stays on this phone and goes up when you sign in here again. Nobody else who signs in can send it.';
  }

  @override
  String get signOutConfirmBody =>
      'You\'ll need your password to sign in on this phone again. Your brand\'s data stays safe with Atomshop.';

  @override
  String get passwordWeak => 'Weak password';

  @override
  String get passwordFair => 'Fair password';

  @override
  String get passwordGood => 'Good password';

  @override
  String get passwordStrong => 'Strong password';

  @override
  String get forgotTitle => 'Forgot your password?';

  @override
  String get forgotBody =>
      'We will send a 6-digit code to the WhatsApp number or email on your account.';

  @override
  String get forgotLogin => 'Email or mobile number';

  @override
  String get forgotLoginInvalid =>
      'Enter your email, or a mobile number starting with 03';

  @override
  String get forgotSendBy => 'Send the code by';

  @override
  String get forgotWhatsApp => 'WhatsApp';

  @override
  String get forgotWhatsAppSub => 'Fastest · to the number on your account';

  @override
  String get forgotEmail => 'Email';

  @override
  String get forgotEmailSub => 'Check spam if it does not arrive';

  @override
  String get forgotSend => 'Send code';

  @override
  String get forgotNote =>
      'Needs internet. Team members can also ask their brand owner to reset it.';

  @override
  String get codeTitle => 'Enter the 6-digit code';

  @override
  String get codeSentWhatsApp =>
      'We sent it on WhatsApp to the number on your account.';

  @override
  String get codeSentEmail =>
      'We sent it by email to the address on your account.';

  @override
  String get codeLabel => 'Code';

  @override
  String get codeDidntGet => 'Didn\'t get it?';

  @override
  String codeResendIn(String time) {
    return 'Resend in $time';
  }

  @override
  String get codeResend => 'Send it again';

  @override
  String codeNote(int minutes) {
    return 'The code works for $minutes minutes. Atomshop will never ask you for it on a call.';
  }

  @override
  String get codeVerify => 'Verify';

  @override
  String get codeByEmail => 'Send by email instead';

  @override
  String get codeByWhatsApp => 'Send on WhatsApp instead';

  @override
  String get codeIncomplete => 'Type all 6 digits';

  @override
  String get codeSentAgain => 'A new code is on its way.';

  @override
  String get newPasswordTitle => 'Set a new password';

  @override
  String newPasswordFor(String login) {
    return 'For $login. You will be signed out on every other phone.';
  }

  @override
  String get newPasswordSave => 'Save new password';

  @override
  String get passwordDoneTitle => 'Password changed';

  @override
  String get passwordDoneBody => 'Sign in with your new password.';

  @override
  String get termsTitle => 'Terms & conditions';

  @override
  String termsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get termsBody =>
      'The agreement between your brand and Atomshop.pk for using Brand Partner.';

  @override
  String get termsRead => 'Read the terms';

  @override
  String get termsNotPublished =>
      'The full text isn\'t on the app yet. Ask Atomshop for it before you accept.';

  @override
  String get termsAskAtomshop => 'Ask Atomshop on WhatsApp';

  @override
  String termsAcceptBox(String business) {
    return 'I have read and accept the terms for $business';
  }

  @override
  String get termsAccept => 'Accept and continue';

  @override
  String get termsTickFirst => 'Tick the box to continue';

  @override
  String get termsChanged =>
      'These terms have changed. They are shown again below.';

  @override
  String get notifTitle => 'Know the moment an order comes in';

  @override
  String get notifWhyPayments =>
      'New orders to confirm, and AtomPay units to hand over';

  @override
  String get notifWhyLeads =>
      'New bulk requests, so you reply before other brands';

  @override
  String get notifWhyAtomshop =>
      'Product review decisions, messages and bills from Atomshop';

  @override
  String get notifAllow => 'Allow notifications';

  @override
  String get notifNotNow => 'Not now';

  @override
  String get notifFootnote =>
      'Shown once after sign-in, before the phone asks. Change it any time in Settings.';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get dateTwoDaysAgo => '2 days ago';

  @override
  String get datePreviousMonth => 'Previous month';

  @override
  String get dateNextMonth => 'Next month';

  @override
  String dateUse(String day) {
    return 'Use $day';
  }

  @override
  String get payOffline =>
      'No internet, so it isn\'t saved yet. Everything you typed is still here; save it when you are back online.';

  @override
  String get customerMobile => 'Mobile';

  @override
  String get customerName => 'Name';

  @override
  String get customerOptional => 'optional';

  @override
  String get customerPhoneMissing => 'Type an 11-digit mobile, 03…';

  @override
  String get commonNo => 'No';

  @override
  String get commonSave => 'Save';

  @override
  String get commonYes => 'Yes';

  @override
  String get acctCloseTitle => 'Close the account';

  @override
  String acctCloseSub(String shop) {
    return 'Ask Atomshop to close $shop';
  }

  @override
  String get acctCloseSignIn => 'Sign-in for you and your team';

  @override
  String get acctCloseShopPage => 'Brand page and new orders';

  @override
  String get acctCloseRecords => 'Orders, deals, payments';

  @override
  String get acctCloseBills => 'Unpaid bills';

  @override
  String get acctCloseStops => 'Stops';

  @override
  String get acctCloseKept => 'Kept by Atomshop';

  @override
  String get acctCloseStillDue => 'Still due';

  @override
  String get acctCloseWhyKept =>
      'Records are kept because your orders, deals and the law need them. Atomshop calls you before anything is closed. Export your data first if you want a copy.';

  @override
  String get acctCloseExportFirst => 'Export my data first';

  @override
  String get acctCloseReason => 'Why are you leaving?';

  @override
  String get acctCloseReasonHint => 'It helps us improve';

  @override
  String get acctClosePassword => 'Your password';

  @override
  String get acctCloseTypePassword => 'Type your password';

  @override
  String get acctCloseButton => 'Ask Atomshop to close the account';

  @override
  String get acctCloseSent =>
      'Your request went to Atomshop. They will call you before anything is closed.';

  @override
  String get dataTitle => 'Your data';

  @override
  String get dataSub => 'What is kept, where, and for how long';

  @override
  String get dataKept => 'What Brand Partner keeps';

  @override
  String get dataShop => 'Your brand';

  @override
  String get dataShopBody =>
      'Products, orders, payments, bulk deals and stock, on Atomshop\'s servers.';

  @override
  String get dataPhone => 'On this phone';

  @override
  String get dataPhoneBody =>
      'Only what is on screen; nothing stays after you sign out.';

  @override
  String get dataPhoneOfflineBody =>
      'An encrypted copy for offline work, deleted when you sign out or the phone is signed out.';

  @override
  String get dataCamera => 'Camera and photos';

  @override
  String get dataUsage => 'App usage';

  @override
  String get dataUsageBody =>
      'Crash reports and which screens are used, without buyer details.';

  @override
  String get dataExport => 'Export';

  @override
  String get dataExportButton => 'Request the export';

  @override
  String exportStarted(String email) {
    return 'Atomshop is making your file. A download link will reach $email shortly.';
  }

  @override
  String get devicesTitle => 'Devices & sessions';

  @override
  String get devicesSub => 'Where you are signed in';

  @override
  String get devicesSignedIn => 'Signed in now';

  @override
  String devicesThisPhone(String name) {
    return 'This phone · $name';
  }

  @override
  String get devicesThisOne => 'This one';

  @override
  String get devicesNow => 'Brand Partner app · now';

  @override
  String get devicesSignOutOthers => 'Sign out all other devices';

  @override
  String get devicesSignedOut => 'Signed out';

  @override
  String get devicesNone => 'Not signed in anywhere.';

  @override
  String get feedbackTitle => 'Send feedback';

  @override
  String get feedbackSub => 'An idea, a problem, or praise';

  @override
  String get feedbackIdea => 'Idea';

  @override
  String get feedbackProblem => 'Problem';

  @override
  String get feedbackPraise => 'Praise';

  @override
  String get feedbackIdeaLabel => 'Your idea';

  @override
  String get feedbackIdeaHint =>
      'What would make Brand Partner better for your brand?';

  @override
  String get feedbackProblemLabel => 'What went wrong?';

  @override
  String get feedbackProblemHint => 'What were you doing, and what happened?';

  @override
  String get feedbackPraiseLabel => 'What do you like?';

  @override
  String get feedbackPraiseHint => 'Tell us what works well';

  @override
  String get feedbackScreenshot => 'Add a screenshot';

  @override
  String get feedbackScreenshotAdded => 'Screenshot added · change';

  @override
  String get feedbackWithDevice => 'Include phone model and app version';

  @override
  String get feedbackWriteFirst => 'Write a few words first';

  @override
  String get feedbackSend => 'Send to Atomshop';

  @override
  String get feedbackSent => 'Thank you. Your feedback went to Atomshop.';

  @override
  String get languageApp => 'App';

  @override
  String get languageSoon => 'Coming soon';

  @override
  String get menuWork => 'Work';

  @override
  String get menuAccount => 'Account';

  @override
  String menuVersion(String version) {
    return 'Brand Partner $version · a partner app of Atomshop.pk';
  }

  @override
  String get passwordTitle => 'Change password';

  @override
  String get passwordSub => 'Signs out other devices';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordNew => 'New password';

  @override
  String get passwordAgain => 'New password again';

  @override
  String get passwordTypeCurrent => 'Type your current password';

  @override
  String get passwordTooWeak => 'Make the new password stronger';

  @override
  String get passwordMismatch => 'The new passwords don\'t match';

  @override
  String get passwordSave => 'Change password';

  @override
  String get passwordSignOutOthers => 'Sign out my other phones';

  @override
  String get passwordSignOutOthersSub =>
      'Anyone signed in elsewhere with the old password is signed out';

  @override
  String get profileTitle => 'Your profile';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profileNameHint => 'Letters and spaces only';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profilePhotoSaved => 'Photo saved';

  @override
  String get rateTitle => 'Rate Brand Partner';

  @override
  String get rateSub => 'On Google Play';

  @override
  String get rateQuestion => 'How is Brand Partner for your brand?';

  @override
  String rateStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get rateHigh =>
      'Thank you! A rating on Google Play helps other brands find us.';

  @override
  String get rateLow =>
      'Sorry to hear that. Tell us what to fix; it goes straight to Atomshop.';

  @override
  String get rateOnPlay => 'Rate on Google Play';

  @override
  String get rateNotNow => 'Not now';

  @override
  String get settingsTitle => 'Settings';

  @override
  String settingsProfileCard(String name) {
    return '$name, your profile';
  }

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsProfileSub => 'Name, photo, mobile number';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsPrivacy => 'Privacy & data';

  @override
  String get settingsHelp => 'Help & feedback';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsSignOutGroup => 'Sign out & account';

  @override
  String get settingsSignOutSub =>
      'Of Brand Partner on this phone · asks first';

  @override
  String get bannerOpen => 'Open';

  @override
  String get bannerLater => 'Later';

  @override
  String get noticeAlwaysOn => 'Always on';

  @override
  String get noticeHow => 'How they arrive';

  @override
  String get noticeOpenFromList => 'Open this message from Notifications.';

  @override
  String get noticeSettingsFoot =>
      'These are for you on this phone. The brand portal has its own bell; the morning message is in Settings › Daily summary.';

  @override
  String get notifMorningTitle => 'Morning summary';

  @override
  String get notifMorningSub => 'One message with today\'s work';

  @override
  String get notifMorningAt => '8:30 am';

  @override
  String get notifActFollowUp => 'Follow up';

  @override
  String get noticeSettingsSub => 'What you get, quiet hours';

  @override
  String get noticeSettingsTitle => 'Notification settings';

  @override
  String get noticesAccount => 'Account';

  @override
  String get noticesAll => 'All';

  @override
  String get noticesEarlier => 'Earlier';

  @override
  String get noticesShowOlder => 'Show older';

  @override
  String get noticesEmptyAction => 'Go to orders';

  @override
  String get notifEmptyHome => 'Go to Home';

  @override
  String get noticesEmptyBody =>
      'New orders, bulk requests, AtomPay hand-overs and product reviews show here. Older ones are kept for 90 days.';

  @override
  String get noticesEmptyTitle => 'You\'re all caught up';

  @override
  String get noticesFromAtomshop => 'From Atomshop';

  @override
  String get noticesFromAtomshopNew => 'From Atomshop · new';

  @override
  String get noticesOrders => 'Orders';

  @override
  String get noticesReadAll => 'Mark all as read';

  @override
  String get notifActConfirm => 'Confirm';

  @override
  String get notifActHandOver => 'Hand over';

  @override
  String get notifActSendQuote => 'Send quote';

  @override
  String get notifActReply => 'Reply';

  @override
  String get notifActAnswer => 'Answer';

  @override
  String get notifActOpenDeal => 'Open deal';

  @override
  String get notifActStockIn => 'Stock in';

  @override
  String get notifActFix => 'Fix and resend';

  @override
  String get noticesStock => 'Stock';

  @override
  String get noticesTeam => 'Team';

  @override
  String get noticesTitle => 'Notifications';

  @override
  String get noticesToday => 'Today';

  @override
  String get noticesYesterday => 'Yesterday';

  @override
  String get quietFrom => 'Quiet from';

  @override
  String get quietTo => 'Quiet until';

  @override
  String get quietTitle => 'Quiet hours';

  @override
  String get bioTitle => 'Fingerprint or face';

  @override
  String get lockAfterTitle => 'Lock the app after';

  @override
  String get lockAfterSub => 'When it is in the background';

  @override
  String get lockImmediately => 'Immediately';

  @override
  String lockAfterSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get lockBioReason => 'Open Brand Partner';

  @override
  String lockTitle(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get permissionsSub => 'What the app may use on this phone';

  @override
  String get permissionsBody =>
      'Brand Partner asks only when you first use a feature.';

  @override
  String get permissionsNotifications => 'Notifications';

  @override
  String get permissionsNotificationsSub =>
      'New orders, bulk requests, AtomPay, product reviews';

  @override
  String get permissionsTurnOn => 'Turn on';

  @override
  String get permissionsAllowed => 'Allowed';

  @override
  String get permissionsCamera => 'Camera';

  @override
  String get permissionsPhotos => 'Photos';

  @override
  String get permissionsPhotosSub => 'Only the ones you pick';

  @override
  String get permissionsWhenUsed => 'Asked when used';

  @override
  String get pinSet => 'Set a PIN';

  @override
  String get pinChange => 'Change PIN';

  @override
  String get pinSub => '4 digits, for quick unlock';

  @override
  String pinStepOf(int step) {
    return 'Step $step of 2';
  }

  @override
  String get pinCreateTitle => 'Set a 4-digit PIN';

  @override
  String get pinConfirmTitle => 'Type your PIN again';

  @override
  String get pinCreateBody =>
      'You will use it to open the app, even offline. Avoid 1234 or your birth year.';

  @override
  String get pinMismatch => 'The PINs did not match. Start again.';

  @override
  String get pinDoneTitle => 'You are all set';

  @override
  String get pinDoneBody =>
      'Next time, open Brand Partner with your PIN or fingerprint, with or without internet.';

  @override
  String get pinSkip => 'Skip for now, set it later in Settings';

  @override
  String get pinRemove => 'Remove PIN';

  @override
  String get pinRemoveSub => 'This phone opens without a PIN or fingerprint';

  @override
  String get pinRemoveTitle => 'Remove the PIN?';

  @override
  String get pinRemoveBody =>
      'Brand Partner will open without asking for a PIN or fingerprint on this phone. Any sign-in saved behind the fingerprint is erased. You can set a PIN again any time.';

  @override
  String get remindersTitle => 'WhatsApp reminders';

  @override
  String get securityTitle => 'Account security';

  @override
  String get securitySub => 'Password, PIN, fingerprint, auto-lock';

  @override
  String get securitySignIn => 'Sign in';

  @override
  String get securityThisPhone => 'On this phone';

  @override
  String get securityEverywhere => 'Everywhere';

  @override
  String get securitySignOutOthersSub => 'Keeps you signed in on this phone';

  @override
  String get securityNote =>
      'Biometrics never leave the phone; Atomshop only learns that the unlock succeeded.';

  @override
  String get settingsShop => 'Brand';

  @override
  String get settingsShopNote =>
      'Only you see these. They apply to all your outlets.';

  @override
  String get storageTitle => 'Storage';

  @override
  String get storageCache => 'Cache';

  @override
  String get storageClear => 'Clear cache';

  @override
  String get storageClearBody =>
      'Pictures and PDFs download again when you open them. Orders, products and stock are not touched.';

  @override
  String get storageClearButton => 'Clear';

  @override
  String get menuPlan => 'Plan & billing';

  @override
  String get syncActionOrderStatus => 'Order status changed';

  @override
  String get syncActionStockAdjust => 'Stock adjusted';

  @override
  String get syncActionStockIn => 'Stock in';

  @override
  String get syncTitle => 'Sync';

  @override
  String syncOnline(String time) {
    return 'Online · synced $time';
  }

  @override
  String get syncOffline => 'Offline · working from this phone';

  @override
  String get syncNeverSynced => 'Not synced yet';

  @override
  String get syncAllSent => 'Everything is sent.';

  @override
  String syncSomeWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes are waiting to send.',
      one: '1 change is waiting to send.',
    );
    return '$_temp0';
  }

  @override
  String syncSomeAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need you.',
      one: '1 needs you.',
    );
    return '$_temp0';
  }

  @override
  String syncWorksUntil(String day) {
    return 'Works offline until $day';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncNeedsInternet => 'Needs internet';

  @override
  String get syncAttentionTitle => 'Needs attention';

  @override
  String get syncAttentionSub =>
      'Saved here, but the server couldn\'t apply them';

  @override
  String get syncAttentionLead =>
      'These were saved on your phone, but the server found something had changed meanwhile. Nothing was applied, so nothing happened twice.';

  @override
  String get syncAttentionSecondPay =>
      'If it was a second payment, record it on the plan, then discard this one.';

  @override
  String get syncAttentionOpenPlan => 'Open the plan';

  @override
  String get syncAttentionEmpty => 'Nothing needs you';

  @override
  String get syncAttentionEmptyBody =>
      'Nothing saved on this phone is waiting for you to sort out.';

  @override
  String get syncWaitingTitle => 'Waiting to send';

  @override
  String get syncWaitingSub =>
      'Deliveries, payments, stock in, notes made on this phone';

  @override
  String get syncWaitingNone => 'Nothing is waiting';

  @override
  String get syncWaitingNoneBody =>
      'Everything made on this phone has been sent.';

  @override
  String get syncWaitingOrder =>
      'No signal. These go in this order as soon as there is.';

  @override
  String syncChangesCount(int count) {
    return 'Changes · $count';
  }

  @override
  String get syncUndo => 'Undo';

  @override
  String get syncUndoNote => 'Undo works only before it is sent.';

  @override
  String get syncUndone => 'Taken out of the queue';

  @override
  String get syncTooLate => 'It has gone to the server already';

  @override
  String get syncDiscard => 'Discard';

  @override
  String get syncDiscardTitle => 'Discard this change?';

  @override
  String get syncDiscardBody =>
      'It was never applied on the server, and it will not be. This cannot be undone.';

  @override
  String get syncRetried =>
      'Sent again. If it is still refused, it comes back here.';

  @override
  String get syncRetryGone => 'This one is already sorted';

  @override
  String get syncAttentionNotYou =>
      'Not your work, or need to sign in again? Sign out here. Nothing on this list is lost: it waits on this phone for you.';

  @override
  String get syncOnThisPhone => 'On this phone';

  @override
  String syncCopyLine(int customers, int orders) {
    return '$customers orders · $orders products · encrypted';
  }

  @override
  String get syncNothingYet => 'Nothing downloaded yet';

  @override
  String syncSentOf(int sent, int total) {
    return '$sent of $total sent';
  }

  @override
  String get syncKeepWorking =>
      'You can keep working; new changes join the queue.';

  @override
  String get syncDownloading => 'Getting others\' changes';

  @override
  String get syncFootnote =>
      'The app sends changes by itself when there is signal, in the order you made them. Nothing is ever paid or added twice.';

  @override
  String get syncStopNote =>
      'If the signal drops, it stops and carries on later from the same place.';

  @override
  String get syncFailed => 'Could not sync';

  @override
  String get syncOffBar => 'Offline';

  @override
  String syncOffBarChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to send',
      one: '1 change waiting to send',
    );
    return '$_temp0';
  }

  @override
  String get syncOffBarDetails => 'Details';

  @override
  String get syncUpdateTitle => 'Update Brand Partner to send your changes';

  @override
  String get syncEndedTitle => 'This phone now works online only';

  @override
  String get syncEndedBody =>
      'Offline working is no longer on this account. Your phone is sending what it saved, then it will work online only.';

  @override
  String get planTitle => 'Plan & billing';

  @override
  String get ecosystemTitle => 'Our ecosystem';

  @override
  String get faqsNone =>
      'No answer matches. Try other words, or ask Atomshop on WhatsApp.';

  @override
  String get helpFaqsEmpty => 'No answers here yet';

  @override
  String get helpFaqsEmptySub =>
      'Atomshop is still writing answers for this topic. Ask Atomshop on WhatsApp meanwhile.';

  @override
  String get faqsTitle => 'FAQs';

  @override
  String get helpAllFaqs => 'All FAQs';

  @override
  String get helpCall => 'Call';

  @override
  String get helpEmail => 'Email';

  @override
  String get helpPopular => 'Popular';

  @override
  String get helpSearch => 'Search help: \"hand over\", \"quote\"…';

  @override
  String get helpTalk => 'Talk to Atomshop';

  @override
  String get helpTitle => 'How can we help?';

  @override
  String get helpTopics => 'Topics';

  @override
  String get helpVersion => 'App version';

  @override
  String get menuHelp => 'Help & FAQs';

  @override
  String get privacyTitle => 'Privacy policy';

  @override
  String get supportAnswered => 'Answered';

  @override
  String get supportAtomshop => 'Atomshop support';

  @override
  String get supportEmptyBody =>
      'Questions Ask Atom sends to Atomshop for you show here with the answer.';

  @override
  String get supportOpenFromList =>
      'Open this request from Your support requests.';

  @override
  String get supportSub => 'Questions sent to Atomshop, and the answers';

  @override
  String get supportTitle => 'Your support requests';

  @override
  String get supportWaiting => 'Waiting';

  @override
  String get supportWaitingNote =>
      'Atomshop hasn\'t answered yet. The answer comes as a notification.';

  @override
  String get supportWhatsApp => 'Message Atomshop on WhatsApp';

  @override
  String get supportYou => 'You';

  @override
  String get tourNext => 'Next';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourStart => 'Start';

  @override
  String get tourOrdersTitle => 'Confirm orders in a tap';

  @override
  String get tourOrdersText =>
      'New orders are on Home. Call the customer, confirm, and mark it delivered with a proof photo.';

  @override
  String get tourOrdersChip1 => '#48213 · AC 1.5 ton';

  @override
  String get tourOrdersChip2 => 'Confirmed';

  @override
  String get tourBulkTitle => 'Win bulk deals first';

  @override
  String get tourBulkText =>
      'Reply to bulk requests with a quote on WhatsApp, then deliver and take payments on the deal.';

  @override
  String get tourBulkChip1 => '40 × 55\" TV';

  @override
  String get tourBulkChip2 => 'Quote sent';

  @override
  String get tourOfflineTitle => 'Works without signal';

  @override
  String get tourOfflineText =>
      'Orders, stock and deals are on this phone. What you do offline is sent when the signal comes back.';

  @override
  String get tourOfflineChip1 => 'Offline';

  @override
  String get tourOfflineChip2 => '3 waiting to send';

  @override
  String get tourAtomTitle => 'Ask Atom anything';

  @override
  String get tourAtomText =>
      'Orders to confirm, quotes running out, what is low. In English, Roman Urdu or اردو.';

  @override
  String get tourAtomChip1 => 'What is running low?';

  @override
  String get tourAtomChip2 => '4 products';

  @override
  String get tourWhoTitle => 'One ecosystem, built in Lahore';

  @override
  String get tourWhoBody =>
      'Buyers find products on Atomshop and pay in steps. Verified sellers run the deals. Brands like yours supply them.';

  @override
  String get tourPayInSteps => 'Pay in Steps';

  @override
  String get tourSellerSub => 'The app for brands';

  @override
  String get tourEcoTitle => 'Four apps, one business';

  @override
  String get tourEcoBody =>
      'You sit at the source: orders and bulk requests for your products come to you.';

  @override
  String get tourEcoSupply => 'supply stock';

  @override
  String get tourFeaturesTitle => 'Everything your brand runs on';

  @override
  String get tourFeaturesBody => 'Online, or with no signal at all.';

  @override
  String get tourFeatureOrders => 'Orders';

  @override
  String get tourFeatureOrdersSub =>
      'Cash and AtomPay orders: confirm, deliver, get paid';

  @override
  String get tourFeatureCollections => 'Bulk deals';

  @override
  String get tourFeatureCollectionsSub =>
      'Seller and website requests, quotes and deals';

  @override
  String get tourFeatureCustomers => 'Products';

  @override
  String get tourFeatureCustomersSub =>
      'Your catalogue and brand page on atomshop.pk';

  @override
  String get tourFeatureStock => 'Stock';

  @override
  String get tourFeatureStockSub =>
      'Purchases, stock on hand and what it is worth';

  @override
  String get tourFeatureTeam => 'Team and outlets';

  @override
  String get tourFeatureTeamSub =>
      'Each with their own sign-in and what they may do';

  @override
  String get tourFeatureReports => 'Reports';

  @override
  String get tourFeatureReportsSub =>
      'Sales, payments received and what is still due';

  @override
  String get tourOfflineNote =>
      'Works with no signal. It syncs when you are back.';

  @override
  String get tourAddonsTitle => 'Turn on only what you need';

  @override
  String get tourAddonsPath => 'Menu › Plan & billing › Add-ons';

  @override
  String get tourAddonsOnLead => 'Switch on';

  @override
  String get tourAddonsOnRest =>
      ' starts a free trial where there is one, or pays for the rest of the period.';

  @override
  String get tourAddonsOffLead => 'Switch off';

  @override
  String get tourAddonsOffRest =>
      ' keeps it working until the period ends, then it stops renewing.';

  @override
  String get tourAddonInventory => 'Inventory';

  @override
  String get tourAddonInventorySub => 'Purchases, stock and its value';

  @override
  String get tourAddonAskAtom => 'Ask Atom';

  @override
  String get tourAddonAskAtomSub => 'Free trial';

  @override
  String get tourAddonRoles => 'Roles management';

  @override
  String get tourAddonRolesSub => 'Team members and what each may do';

  @override
  String get tourAddonAlerts => 'Live alerts';

  @override
  String get tourAddonAlertsSub => 'A push the moment something changes';

  @override
  String tourStep(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String get atomLangAuto => 'The way I write';

  @override
  String get atomLangAutoSub => 'Matches English, Roman Urdu or Urdu';

  @override
  String get atomLangTitle => 'Ask Atom answers in';

  @override
  String get atomTitle => 'Ask Atom';

  @override
  String get scanSerial => 'Serial';

  @override
  String get menuBusiness => 'Business';

  @override
  String get liveBPdfGetting => 'Getting the PDF…';

  @override
  String get pdfOffline =>
      'No internet. Turn on mobile data or Wi-Fi to get the PDF.';

  @override
  String pdfFailedRef(String message, String ref) {
    return '$message Ref: $ref';
  }

  @override
  String askAPasswordSignedOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Password changed. $count other phones were signed out',
      one: 'Password changed. 1 other phone was signed out',
      zero: 'Password changed',
    );
    return '$_temp0';
  }

  @override
  String get auth2Tagline => 'Connect. Sell. Grow.';

  @override
  String auth2SplashBy(String brand) {
    return 'by $brand · Pay in Steps';
  }

  @override
  String get auth2MainShop => 'All outlets';

  @override
  String get auth2Online => 'Online';

  @override
  String get auth2NoInternet => 'No internet';

  @override
  String get auth2Or => 'or';

  @override
  String get auth2SignInFingerprint => 'Sign in with fingerprint';

  @override
  String auth2PasswordOnce(String quick) {
    return 'Sign in once with your password on a new phone (needs internet). After that, use your $quick, even with no signal.';
  }

  @override
  String get auth2PasswordOnceBold => 'fingerprint or PIN';

  @override
  String get auth2WrongOwner =>
      'Email or password is wrong. Check both and try again.';

  @override
  String get auth2WrongAgent =>
      'Mobile number or password is wrong. Check both and try again.';

  @override
  String get auth2OfflineTitle => 'No internet.';

  @override
  String get auth2OfflineBody =>
      'The first sign-in on this phone needs internet, so we can check your account. Connect to Wi-Fi or mobile data.';

  @override
  String get auth2WaitingForInternet => 'Waiting for internet…';

  @override
  String get auth2PendingTitle => 'Your application is being checked.';

  @override
  String get auth2PendingBody =>
      'Atomshop reviews every brand before it can sign in, then creates your login. We will message you on WhatsApp when it is ready, usually within two working days.';

  @override
  String get auth2AskOnWhatsApp => 'Ask Atomshop on WhatsApp';

  @override
  String get auth2RuleLength => 'At least 8 characters';

  @override
  String get auth2RuleMix => 'Letters and numbers';

  @override
  String get auth2RuleNotTemp => 'Not the temporary password';

  @override
  String get auth2PinSavedBold => 'PIN saved on this phone.';

  @override
  String get auth2PinSavedRest => 'It never leaves the phone.';

  @override
  String get auth2BioRowTitle => 'Open with fingerprint';

  @override
  String get auth2BioRowSub => 'Faster than typing your PIN';

  @override
  String get auth2PinSmallPrint =>
      'Anyone who knows your PIN can open the app on this phone. Lost the phone? Sign out all phones from the dashboard: Settings › Security.';

  @override
  String get auth2Continue => 'Continue';

  @override
  String get auth2FpBody =>
      'Touch the fingerprint sensor on your phone. Works with or without internet.';

  @override
  String get auth2FpOkTitle => 'Welcome back';

  @override
  String auth2FpOpening(String shop) {
    return 'Opening $shop…';
  }

  @override
  String get auth2FpTap => 'Tap the circle to try it';

  @override
  String get auth2FpFailed => 'Not recognised. Try again, or use your PIN.';

  @override
  String get auth2FpOk => 'Signed in';

  @override
  String get auth2FpButton => 'Touch to sign in with fingerprint';

  @override
  String get auth2UsePin => 'Use PIN instead';

  @override
  String get auth2SignInPassword => 'Sign in with password';

  @override
  String get auth2EnterPin => 'Enter your PIN';

  @override
  String auth2WrongPinWait(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'Wrong PIN. $left tries left before a 5-minute wait.',
      one: 'Wrong PIN. 1 try left before a 5-minute wait.',
    );
    return '$_temp0';
  }

  @override
  String auth2WrongPinPassword(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'Wrong PIN. $left tries left before you need your password.',
      one: 'Wrong PIN. 1 try left before you need your password.',
    );
    return '$_temp0';
  }

  @override
  String get auth2ForgotPin => 'Forgot PIN?';

  @override
  String get auth2SwitchAccount => 'Switch account';

  @override
  String get auth2TooManyTitle => 'Too many wrong PINs';

  @override
  String get auth2TooManyBody =>
      'To keep your brand\'s orders and customer details safe, the app is paused for a few minutes.';

  @override
  String get auth2TryAgainIn => 'Try again in';

  @override
  String auth2TenPins(String count) {
    return 'After $count you will need your password and internet to open the app.';
  }

  @override
  String get auth2TenPinsBold => '10 wrong PINs';

  @override
  String get auth2PasswordInstead => 'Sign in with password instead';

  @override
  String get auth2DonePinKept => 'Your PIN on this phone stays as it was.';

  @override
  String get auth2DoneOthersTitle => 'Your other phones are signed out';

  @override
  String get auth2DoneOthersSub =>
      'They need the new password to sign in again';

  @override
  String auth2SignedOutPlace(String place) {
    return 'After you sign in you go back to $place';
  }

  @override
  String get auth3PromptTitle => 'Brand Partner';

  @override
  String get auth3PromptRead => 'Sign in with your fingerprint';

  @override
  String get auth3PromptSave =>
      'Confirm with your fingerprint to save your sign-in on this phone';

  @override
  String get copyBioPromptSub =>
      'Confirm your fingerprint to open the app, and what is saved on this phone, with it';

  @override
  String get lockPinOnceToProtect =>
      'Enter your PIN once to lock what is saved on this phone behind it. Your fingerprint opens it after that.';

  @override
  String get lockBioUsePin =>
      'Your fingerprint can\'t open what is saved on this phone any more. Enter your PIN this once.';

  @override
  String get auth3FpFailed =>
      'Not recognised. Try again, or sign in with your password.';

  @override
  String get auth3FingerprintsChanged =>
      'Your fingerprints changed on this phone. Sign in with your password.';

  @override
  String get auth3PasswordChanged =>
      'Your password has changed. Sign in with your password.';

  @override
  String get auth3NotSaved =>
      'Fingerprint sign-in is off. You can turn it on in Settings › Account security.';

  @override
  String get auth3SheetTitle =>
      'Type your password to sign in with your fingerprint';

  @override
  String get auth3SheetBody =>
      'It is kept on this phone, behind your fingerprint, and sent only to sign you in.';

  @override
  String get auth3SheetSave => 'Turn on';

  @override
  String get auth3BioSub => 'Unlock with this phone\'s biometrics';

  @override
  String get auth3SignOutBodyQuick =>
      'Next time, sign in on this phone with your fingerprint or your password. Your brand\'s data stays safe with Atomshop.';

  @override
  String dpETNoInternetKept(String what) {
    return 'The payment you were typing ($what) is kept on this screen. Nothing was saved yet; save it when you are back online.';
  }

  @override
  String get dpDbRoleOrderTitle => 'Your role doesn\'t include making orders';

  @override
  String get dpDbRoleOrderBody =>
      'The owner decides what each person can do. Ask them to change your role if you need it.';

  @override
  String get dpDbRoleStockTitle => 'Your role doesn\'t include stock';

  @override
  String get dpDbRoleStockBody =>
      'You can still sell items the owner gives you. Ask the owner if you need to see stock.';

  @override
  String get dpDbRoleDiscountTitle => 'You can\'t give discounts';

  @override
  String get dpDbRoleDiscountBody =>
      'Only the owner, or roles with \"Give discounts\", can lower a price. The full price is kept.';

  @override
  String get dpDbRoleYouCan => 'You can';

  @override
  String get dpDbRoleAskAtom => 'Ask Atom why';

  @override
  String get dpDbCanCollections => 'deals';

  @override
  String get dpDbCanCustomers => 'products';

  @override
  String get dpDbCanOrders => 'orders';

  @override
  String get dpDbCanStock => 'stock';

  @override
  String get dpDbCanLeads => 'bulk requests';

  @override
  String get dpDbCanReports => 'reports';

  @override
  String dpDbCanList(String first, String last) {
    return '$first and $last';
  }

  @override
  String get dpDbSeeBill => 'See bill';

  @override
  String get dpDbErrorTitle => 'That didn\'t save';

  @override
  String dpDbErrorBody(String what) {
    return 'Atomshop couldn\'t save the $what just now. Nothing was changed, and what you typed is still here.';
  }

  @override
  String dpDbErrorRef(String ref, String when) {
    return 'Ref $ref · $when';
  }

  @override
  String get dpDbErrorRefNote =>
      'The reference helps Atomshop find it if you contact them.';

  @override
  String get dpDbLoadingToday => 'Getting today\'s work…';

  @override
  String get dpDbMaintenanceBody => 'We’ll let you know when it’s ready.';

  @override
  String get dpDbUpdateTitle => 'Please update Brand Partner';

  @override
  String get dpDbUpdateBody =>
      'This version is too old to talk to Atomshop. The update takes about a minute.';

  @override
  String get dpDbUpdateUsing => 'After the update';

  @override
  String get dpDbUpdateButton => 'Update on Google Play';

  @override
  String get dpDcMessages => 'Messages';

  @override
  String get dpDcUnread => 'Unread';

  @override
  String get dpDcAtomshop => 'Atomshop';

  @override
  String get dpDcAskAtomAbout => 'Ask Atom about this';

  @override
  String get dpDcReplyAtomshop => 'Reply to Atomshop';

  @override
  String dpDcReplyText(String title) {
    return 'About your message \"$title\": ';
  }

  @override
  String get dpDcQuietSub => 'No sound or popups; they wait in Notifications';

  @override
  String get dpDcQuietChange => 'Change the hours';

  @override
  String get dpDcQuietOff => 'Turn quiet hours off';

  @override
  String get dpDcOff => 'Off';

  @override
  String get dpDcSound => 'Sound & vibration';

  @override
  String get dpDcPhoneSettings => 'Phone settings';

  @override
  String get dpDcOpen => 'Open';

  @override
  String get dpDcRead => 'Read';

  @override
  String get dpDdDevicesLoading => 'Checking your devices…';

  @override
  String get dpDdDevicesError =>
      'Couldn’t load your devices · tap to try again';

  @override
  String get dpDdRemindersSub => 'Due day, then 1 and 3 days late';

  @override
  String get dpDdLanguageSub => 'App and Ask Atom';

  @override
  String get dpDdPermissionsOff => 'Notifications are off';

  @override
  String get dpDdStorageSub => 'Cache';

  @override
  String get dpDdDataUse => 'How we use your data';

  @override
  String get dpDdExport => 'Export your data';

  @override
  String get dpDdExportSub => 'Orders, deals and payments as Excel';

  @override
  String get dpDdPrivacy => 'Privacy policy';

  @override
  String get dpDdPrivacySub => 'Saved on the phone, opens offline';

  @override
  String get dpDdTerms => 'Terms & conditions';

  @override
  String dpDdTermsSub(String version) {
    return 'Version $version';
  }

  @override
  String get dpDdHelpSub => 'Answers, Ask Atom, contact Atomshop';

  @override
  String dpDdVersion(String version) {
    return 'Version $version · up to date';
  }

  @override
  String get dpDdEcosystem => 'Our ecosystem';

  @override
  String get dpDdByline => 'by Atomshop.pk';

  @override
  String get dpDdNeedsInternet => 'Needs internet';

  @override
  String get dpDdOfflineFoot =>
      'You are offline. Rows marked Needs internet open again when you are back online.';

  @override
  String dpDdCacheFreed(String size) {
    return 'Cache cleared · $size freed';
  }

  @override
  String get dpDdSignInWithIt => 'you sign in with it';

  @override
  String get dpDdOwnerChangesPhone => 'Only the owner can change it.';

  @override
  String get dpDdPasswordSub => 'Signs you out on other phones';

  @override
  String get dpDdDeviceApp => 'Brand Partner app';

  @override
  String dpDdDeviceLastUsed(String app, String day) {
    return '$app · last used $day';
  }

  @override
  String get dpDdTeamPhones => 'Your team\'s phones';

  @override
  String get dpDdDevicesNote =>
      'A device you sign out is signed out at once. Needs internet.';

  @override
  String get dpDdStop => 'Stop';

  @override
  String dpDdCloseLead(String shop) {
    return 'This asks Atomshop to close $shop.';
  }

  @override
  String get dpDdCloseRest => 'It can\'t be undone from the app.';

  @override
  String get dpDdDataCameraBody =>
      'Only when you scan a serial or take a delivery or product photo. Scanning runs on the phone; nothing goes to Google.';

  @override
  String get dpDdDataAtom => 'Ask Atom';

  @override
  String get dpDdDataAtomBody =>
      'Questions are kept 90 days with phone numbers removed.';

  @override
  String get dpDdDownloadAll => 'Download everything as Excel';

  @override
  String get dpDdDownloadAllSub =>
      'Orders, payments, products, bulk deals, stock';

  @override
  String get dpDdExportNote =>
      'Atomshop makes the file and emails a link valid for 24 hours. Delivery photos are not included.';

  @override
  String get dpDdMore => 'More';

  @override
  String get dpDdOnThisPhone => 'On this phone';

  @override
  String get dpDdCameraSub =>
      'Scan serials and IMEIs, delivery and product photos';

  @override
  String get dpDdSelected => 'Selected';

  @override
  String get dpDdBioSub => 'Quick unlock';

  @override
  String get dpDdNotAsked => 'Not asked';

  @override
  String get dpDdOpenPhoneSettings => 'Open phone settings';

  @override
  String get dpDdPermissionsNever =>
      'Brand Partner never asks for your contacts, location or call log.';

  @override
  String get dpDdUsed => 'Used by Brand Partner';

  @override
  String get dpDdCacheKey => 'Amber: cache';

  @override
  String get dpDdStorageNote => 'Nothing else is stored on this phone.';

  @override
  String dpDdClearTitle(String size) {
    return 'Clear $size of cache?';
  }

  @override
  String get dpDdDetails => 'Details';

  @override
  String get dpDaMenuTeam => 'Team';

  @override
  String get dpDaLogoLabel => 'Atomshop.pk';

  @override
  String dpDdToday(String time) {
    return 'today $time';
  }

  @override
  String get dpDdCacheSub => 'Product pictures and PDFs you opened';

  @override
  String get dpAMore => 'More';

  @override
  String get dpDcTopicStart => 'Getting started';

  @override
  String get dpDcTopicInventory => 'Inventory';

  @override
  String get helpTopicAtompay => 'AtomPay';

  @override
  String get helpTopicPayments => 'Payments';

  @override
  String get helpTopicBrandPage => 'Brand page';

  @override
  String get dpDcTopicPlan => 'Plan & billing';

  @override
  String get dpDcTopicReports => 'Reports';

  @override
  String get dpDcTopicGeneral => 'General';

  @override
  String dpDcSupportCounts(int answered, int waiting) {
    return '$answered answered, $waiting waiting';
  }

  @override
  String get dpDcEcosystemSub =>
      'Atomshop, AtomPay, Atom Seller, Brand Partner';

  @override
  String dpDcVersionOk(String version) {
    return 'Brand Partner $version · up to date';
  }

  @override
  String dpDcVersionOld(String version) {
    return 'Brand Partner $version · an update is needed';
  }

  @override
  String get dpDcAskAtomFastest =>
      'Fastest: it knows your brand and answers in seconds';

  @override
  String dpDcAnswers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count answers',
      one: '1 answer',
    );
    return '$_temp0';
  }

  @override
  String get dpDcFaqSearchHint => 'Search in English or Roman Urdu';

  @override
  String get dpDcFaqSearchLabel => 'Search FAQs';

  @override
  String get dpDcFaqFoot =>
      'Answers are kept up to date by Atomshop. Saved on your phone for offline.';

  @override
  String get dpDcReadMore => 'Read more';

  @override
  String get dpDcFaqOpenFromList => 'Open this answer from FAQs.';

  @override
  String get dpDcDidThisHelp => 'Did this help?';

  @override
  String get dpDcAskAtomCase => 'Ask Atom about your case';

  @override
  String get dpDcThanks => 'Thank you. It helps Atomshop improve the answers.';

  @override
  String dpDcTodayAt(String time) {
    return 'today $time';
  }

  @override
  String get dpDcClosed => 'Closed';

  @override
  String get dpDcWaitingAtomshop => 'Waiting for Atomshop';

  @override
  String dpDcSince(String when) {
    return 'since $when';
  }

  @override
  String get dpDcHelpSupport => 'Help & support';

  @override
  String get dpDcAskAtomFirst => 'Ask Atom first';

  @override
  String get dpDcAskAtomFirstSub =>
      'Most answers come in seconds. Atom passes it to Atomshop if it can\'t help.';

  @override
  String get dpDcNoOpen => 'No open requests';

  @override
  String get dpDcNoClosed => 'No closed requests';

  @override
  String dpDcWhatsAppAtomshop(String phone) {
    return 'WhatsApp Atomshop · $phone';
  }

  @override
  String dpDcLastAtomshop(String text) {
    return 'Atomshop: \"$text\"';
  }

  @override
  String dpDcLastYou(String text) {
    return 'You: \"$text\"';
  }

  @override
  String get dpDcClosedToast => 'Request closed';

  @override
  String get dpDcFromAskAtom => 'From Ask Atom';

  @override
  String dpDcFromAskAtomAbout(String about) {
    return 'From Ask Atom · about $about';
  }

  @override
  String get dpDcSolved => 'Did this solve it?';

  @override
  String get dpDcYesClose => 'Yes, close it';

  @override
  String get dpDcOrReply => '· or reply below.';

  @override
  String get dpDcSend => 'Send';

  @override
  String get dpDcOpenOnSite => 'Open on atomshop.pk';

  @override
  String dpDcLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get dpDcPrivacyLead =>
      'How Atomshop.pk and Brand Partner keep your brand\'s information and the details of buyers who order from you.';

  @override
  String dpDcPrivacyFoot(String email) {
    return 'Saved on this phone, so it opens offline. Questions? $email';
  }

  @override
  String get dpDcEcoTitle => 'One ecosystem, built in Lahore';

  @override
  String get dpDcEcoLead =>
      'Customers find products on Atomshop. Brands like yours list them and deliver. Verified local sellers handle AtomPay orders and buy in bulk. AtomPay gives verified customers a 0% markup limit.';

  @override
  String get dpDcEcoFlowLabel =>
      'Customers order on Atomshop, you deliver, sellers buy in bulk and handle AtomPay';

  @override
  String get dpDcEcoCustomers => 'Customers';

  @override
  String get dpDcEcoCustomersSub => 'order on Atomshop';

  @override
  String get dpDcEcoYou => 'You';

  @override
  String get dpDcEcoYouSub => 'confirm and deliver in Brand Partner';

  @override
  String get dpDcEcoBrands => 'Sellers';

  @override
  String get dpDcEcoBrandsSub => 'buy in bulk and take AtomPay units';

  @override
  String get dpDcYouAreHere => 'You are here';

  @override
  String get dpDcEcoSeller =>
      'Run your brand on Atomshop: orders, AtomPay hand-overs, bulk deals, products, stock and your team.';

  @override
  String get dpDcShareSeller => 'Share with your team';

  @override
  String dpDcShareSellerText(String link) {
    return 'Get Brand Partner to work on our Atomshop orders with me: $link';
  }

  @override
  String get dpDcEcoAtomshop =>
      'For customers: browse your brand page, order cash or with AtomPay. Their orders come to you.';

  @override
  String get dpDcSendCustomer => 'Send to a buyer';

  @override
  String dpDcSendCustomerText(String link) {
    return 'Shop on Atomshop and pay in steps: $link';
  }

  @override
  String get dpDcEcoPay =>
      'Verified customers get a 0% markup limit for eligible products: 3 months, no advance.';

  @override
  String get dpDcEcoBrand =>
      'For verified local sellers: they take AtomPay units from you and send bulk requests.';

  @override
  String get dpDcEcoSiteShop =>
      'Where customers find you. Your brand page shows your story, slides and live products.';

  @override
  String get dpDcEcoSite => 'Where customers find you and order your products.';

  @override
  String get dpDcOpenSite => 'Open atomshop.pk';

  @override
  String get dpDcYourShopPage => 'Your brand page';

  @override
  String get dpDcFollow => 'Follow Atomshop';

  @override
  String dpDcTermsPill(String version, String date) {
    return 'Version $version · $date';
  }

  @override
  String dpDcTermsAccepted(String name, String date, String version) {
    return 'Accepted by $name on $date · version $version';
  }

  @override
  String get qa3PinCurrentTitle => 'Enter your current PIN';

  @override
  String get qa3PinCurrentBody =>
      'To change your PIN, first type the one you use now.';

  @override
  String qa3PinCurrentWrong(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: 'Wrong PIN. $left tries left.',
      one: 'Wrong PIN. 1 try left.',
    );
    return '$_temp0';
  }

  @override
  String get qa3PinCurrentTooMany =>
      'Too many wrong PINs. Your PIN was not changed.';

  @override
  String qa3PinCurrentWait(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Too many wrong PINs. Try again in $minutes minutes. Your PIN was not changed.',
      one: 'Too many wrong PINs. Try again in 1 minute. Your PIN was not changed.',
    );
    return '$_temp0';
  }

  @override
  String get qa3PinTooEasy => 'Too easy to guess. Pick another PIN.';

  @override
  String get secHideAmounts => 'Hide amounts on the lock screen';

  @override
  String get secHideAmountsSub => 'Notifications say \"tap to see\"';

  @override
  String get secBlockShots => 'Block screenshots';

  @override
  String get secBlockShotsSub => 'Of orders, buyer phone numbers and invoices';

  @override
  String get recoTitle => 'Recommendations';

  @override
  String get recoEmptyTitle => 'No recommendations yet';

  @override
  String get recoEmptyBody =>
      'Atomshop sends news and tips for your brand. It shows here.';

  @override
  String emuP4DevicesSummary(int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'This phone, $others more devices',
      one: 'This phone, 1 more device',
      zero: 'This phone only',
    );
    return '$_temp0';
  }

  @override
  String get emuP4TryItNow => 'Try it now';

  @override
  String get savedHereTitle => 'Saved on this phone';

  @override
  String get savedHereBody =>
      'There is no signal, so this is waiting on your phone. It goes to Atomshop by itself as soon as you are back online.';

  @override
  String get savedHereSee => 'See what is waiting';

  @override
  String get savedHereDone => 'Done';

  @override
  String get savedHereToast =>
      'Saved on this phone. It goes when you are back online.';

  @override
  String get syncLimitTitle => 'Connect to keep working';

  @override
  String get syncLimitBody =>
      'This phone has worked on its own for as long as Atomshop allows. Find a signal for a minute and everything you saved goes up.';

  @override
  String syncLimitWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes are waiting on this phone.',
      one: '1 change is waiting on this phone.',
    );
    return '$_temp0';
  }

  @override
  String get syncLimitSafe =>
      'Nothing is lost. It stays here until it is sent.';

  @override
  String get syncLimitTry => 'Try now';

  @override
  String get syncEndedSending => 'Sending what is left…';

  @override
  String get syncEndedDone => 'Everything is sent.';

  @override
  String get syncEndedContinue => 'Carry on';

  @override
  String get updateButtonIos => 'Update on the App Store';

  @override
  String get updatePulledTitle => 'This version needs an update';

  @override
  String get updatePulledBody =>
      'We found a problem in this version and fixed it. Update to keep working: it takes about a minute.';

  @override
  String get updateWaitingLabel => 'Waiting to send';

  @override
  String updateWaitingValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes, safe on this phone',
      one: '1 change, safe on this phone',
    );
    return '$_temp0';
  }

  @override
  String get updateNewVersion => 'New version';

  @override
  String updateWhatsNewTitle(String version) {
    return 'What\'s new in $version';
  }

  @override
  String get updateWhatsNewTitleNoVersion => 'What\'s new';

  @override
  String get updateWhatsNewDone => 'Got it';

  @override
  String get signInNewBrand => 'New brand?';

  @override
  String get noticesBulk => 'Bulk deals';

  @override
  String get noticesProducts => 'Products';

  @override
  String get tabBulk => 'Bulk deals';

  @override
  String get tabAtompay => 'AtomPay';

  @override
  String get tabProducts => 'Products';

  @override
  String get tabBusiness => 'Business';

  @override
  String get tabInsights => 'Insights';

  @override
  String get tabAccount => 'Account';

  @override
  String get businessSub => 'Orders, bulk deals, products and stock';

  @override
  String get insightsSub => 'Reports and answers about your brand';

  @override
  String get bizOrdersSub => 'Confirm, deliver and track orders';

  @override
  String get bizAtompaySub => 'AtomPay orders to hand over';

  @override
  String get bizBulkSub => 'Requests from Atomshop sellers, quotes and deals';

  @override
  String get bizProductsSub => 'Your catalogue on Atomshop';

  @override
  String get bizStockSub => 'What you have, by product and warehouse';

  @override
  String get bizWarehousesSub => 'Where your stock is kept';

  @override
  String get insReportsSub => 'Sales, orders and stock, to view or download';

  @override
  String get insAskAtomSub => 'Ask about your sales, orders and stock';

  @override
  String get tabQuickActions => 'New';

  @override
  String get applyRequired => 'Fill this in.';

  @override
  String applyStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get applyTitle => 'Become a brand partner';

  @override
  String get applyBody =>
      'Sell your catalogue to buyers across Pakistan on atomshop.pk. It takes about two minutes, and we reply within two working days.';

  @override
  String get applyAboutYou => 'About you';

  @override
  String get applyName => 'Your name';

  @override
  String get applyMobile => 'Mobile (WhatsApp)';

  @override
  String get applyEmailHint => 'Your login is sent here once approved';

  @override
  String get applyBusiness => 'Your business';

  @override
  String get applyCompany => 'Company / brand name';

  @override
  String get applyBusinessType => 'Business type';

  @override
  String get applyCategory => 'Main category';

  @override
  String get applyOptional => '(optional)';

  @override
  String get applyWebsite => 'Website';

  @override
  String get applyProducts => 'Number of products';

  @override
  String get applyProductsHint => 'At least 3 to get listed';

  @override
  String get applyPartnership => 'Partnership';

  @override
  String get applyShare => 'AtomShop share per sale';

  @override
  String get applyMessage => 'Anything else?';

  @override
  String get applyWhoTitle => 'Who can apply:';

  @override
  String get applyWhoBody =>
      'manufacturers, official distributors and authorised importers with genuine, warrantied products.';

  @override
  String get applyVerify => 'Verify phone & continue';

  @override
  String get applyAlreadyPartner => 'Already a partner?';

  @override
  String get applyCodeTitle => 'Enter the 6-digit code';

  @override
  String applyCodeBody(String phone) {
    return 'We sent it on WhatsApp to $phone, so we know the number is yours.';
  }

  @override
  String get applyResend => 'Didn\'t get it? Send again';

  @override
  String get applySend => 'Send application';

  @override
  String get applyChange => 'Change my details';

  @override
  String get applyDoneTitle => 'Application received';

  @override
  String applyDoneBody(String name, String company) {
    return 'Thank you, $name. $company is in the queue for review.';
  }

  @override
  String get applyNext => 'What happens next';

  @override
  String get applyNextSent => 'Application sent';

  @override
  String get applyNextSentBody => 'Your details and phone number are verified.';

  @override
  String get applyNextReview => 'Review';

  @override
  String get applyNextReviewBody =>
      'Our team checks your brand and agrees pricing and margins with you.';

  @override
  String get applyNextLogin => 'Your login arrives';

  @override
  String applyNextLoginBody(String email) {
    return 'We email $email and message you on WhatsApp.';
  }

  @override
  String get applyBackToStart => 'Back to start';

  @override
  String get outletTitle => 'Where are you working today?';

  @override
  String get outletBody =>
      'You can switch outlet any time from the top of the app.';

  @override
  String get outletAll => 'All outlets';

  @override
  String get outletAllSub => 'See every outlet together';

  @override
  String get outletMain => 'Main';

  @override
  String outletContinue(String name) {
    return 'Continue to $name';
  }

  @override
  String get outletNone => 'No outlets yet';

  @override
  String get menuOutlets => 'Outlets';

  @override
  String get menuStock => 'Stock';

  @override
  String get menuBrandPage => 'Brand page';

  @override
  String get menuBrandPageSub => 'Your page on atomshop.pk';

  @override
  String get menuShopSettings => 'Shop settings';

  @override
  String get menuShopSettingsSub => 'Brand details, receipts and defaults';

  @override
  String get menuSell => 'Sell';

  @override
  String get menuAtompay => 'AtomPay orders';

  @override
  String get menuInventory => 'Inventory';

  @override
  String get menuStockIn => 'Stock in';

  @override
  String get menuWarehouses => 'Warehouses';

  @override
  String get menuStockHistory => 'Stock history';

  @override
  String get menuCatalogue => 'Catalogue';

  @override
  String get menuReports => 'Reports';

  @override
  String get menuLogOut => 'Log out';

  @override
  String get menuRoleOwner => 'Owner';

  @override
  String get menuTeamRoles => 'Team & roles';

  @override
  String get menuProfileSettings => 'Profile & settings';

  @override
  String get menuHelpSupport => 'Help and support';

  @override
  String get menuGroupHelp => 'Help';

  @override
  String menuBadgeNew(int count) {
    return '$count new';
  }

  @override
  String menuBadgeOut(int count) {
    return '$count out';
  }

  @override
  String menuPaidUntil(String date) {
    return 'Paid until $date';
  }

  @override
  String menuPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String menuOutletsOpen(int count) {
    return '$count open';
  }

  @override
  String menuSyncedAt(String time) {
    return 'Synced $time';
  }

  @override
  String get menuMyPassword => 'My password';

  @override
  String get syncActionOrderDeliver => 'Order delivered';

  @override
  String get syncActionOrderPayment => 'Payment recorded';

  @override
  String get syncActionAtompayHandover => 'AtomPay unit handed over';

  @override
  String get syncActionDealDeliver => 'Deal units delivered';

  @override
  String get syncActionDealPayment => 'Deal payment recorded';

  @override
  String get syncActionOrderCancel => 'Order cancelled';

  @override
  String get syncActionBulkStatus => 'Bulk request status changed';

  @override
  String get syncActionStockTransfer => 'Stock moved';

  @override
  String get catProductsTitle => 'Products';

  @override
  String get catAddProduct => 'Add product';

  @override
  String get catAskAtom => 'Ask Atom';

  @override
  String get catFilterByStatus => 'Filter by status';

  @override
  String get catSearchLabel => 'Search products';

  @override
  String get catSearchHint => 'Product name or PR number';

  @override
  String get catAllProducts => 'All products';

  @override
  String get catShowAll => 'Show all';

  @override
  String get catNoProductsHere => 'No products here.';

  @override
  String get catNoProductsFound => 'No products match your search.';

  @override
  String get catFirstProductTitle => 'Add your first product';

  @override
  String get catFirstProductBody =>
      'Atomshop reviews it and puts it live on atomshop.pk, usually within one working day.';

  @override
  String get catReviewFoot =>
      'New products and edits to live ones go to Atomshop for review, usually within one working day.';

  @override
  String get catShowMore => 'Show more';

  @override
  String get catOfflineList =>
      'No signal: this is the list your phone keeps. Changes wait until you are back online.';

  @override
  String get catOnHoldManyBody =>
      'Atomshop asked for changes before publishing';

  @override
  String get catFix => 'Fix';

  @override
  String get catSee => 'See';

  @override
  String get catNewCode => 'New';

  @override
  String get catFeaturedTag => '★ Featured';

  @override
  String get catAtompayOnTag => 'AtomPay on';

  @override
  String get catNoneAvailable => 'None available';

  @override
  String get catNotInStockYet => 'Not in stock yet';

  @override
  String get catSortTitle => 'Sort products';

  @override
  String get catSortNewest => 'Newest';

  @override
  String get catSortOldest => 'Oldest';

  @override
  String get catSortPriceLow => 'Price: low to high';

  @override
  String get catSortPriceHigh => 'Price: high to low';

  @override
  String get catSortName => 'Name A–Z';

  @override
  String get catSortStock => 'Fewest in stock';

  @override
  String get catEditProduct => 'Edit product';

  @override
  String get catEditProductNote => 'Changes to a live product go for review';

  @override
  String get catViewProduct => 'View product';

  @override
  String get catStockAndSerials => 'Stock and serials';

  @override
  String get catFeatureOnPage => 'Feature on your brand page';

  @override
  String get catFeatureNote => 'Up to 5 products · live products only';

  @override
  String get catAtompay => 'AtomPay';

  @override
  String get catAtompayNote => '3 monthly payments, no advance, 0% markup';

  @override
  String get catAtompayBrandWideNote =>
      'Atomshop turned AtomPay on for every product of this brand';

  @override
  String get catMarkOut => 'Mark out of stock';

  @override
  String get catMarkOutNote =>
      'Customers can\'t order it until you mark it back';

  @override
  String get catBackIn => 'Back in stock';

  @override
  String get catBackInNote => 'Customers can order it again';

  @override
  String get catDeleteProduct => 'Delete product';

  @override
  String get catDeleteNote => 'Not possible once it has been ordered';

  @override
  String get catDeleteConfirmBody =>
      'It is removed from your catalogue and from atomshop.pk. This can’t be undone.';

  @override
  String get catDelete => 'Delete';

  @override
  String get catDeleted => 'Product deleted';

  @override
  String get catFeaturedOn => 'Featured on your brand page';

  @override
  String get catFeaturedOff => 'Removed from your featured products';

  @override
  String get catAtompayOn => 'AtomPay turned on';

  @override
  String get catAtompayOff => 'AtomPay turned off';

  @override
  String get catMarkedOut => 'Marked out of stock';

  @override
  String get catMarkedIn => 'Back in stock';

  @override
  String get catBackInTitle => 'Back in stock';

  @override
  String get catBackInBody => 'How many units can customers order?';

  @override
  String get catUnitsLabel => 'Units in stock';

  @override
  String get catUnitsError => 'Enter at least 1 unit';

  @override
  String get catEditTitle => 'Edit product';

  @override
  String get catNotSentYet => 'Not sent yet';

  @override
  String get catSections => 'Sections';

  @override
  String get catJumpPhotos => 'Photos';

  @override
  String get catJumpDetails => 'Details';

  @override
  String get catJumpPrice => 'Price';

  @override
  String get catJumpVariants => 'Variants';

  @override
  String get catJumpDescription => 'Description';

  @override
  String get catNoteNew =>
      'Atomshop reviews every new product before it goes live on atomshop.pk, usually within one working day.';

  @override
  String get catNoteLive =>
      'This product is live. Your changes go to Atomshop for review; customers keep seeing the current version until they\'re approved.';

  @override
  String get catNoteHoldLead => 'Atomshop put this on hold:';

  @override
  String get catNoteReview =>
      'Atomshop is reviewing this product. Saving sends them your latest version.';

  @override
  String get catNoteOutOfStock =>
      'This product is out of stock. Saving keeps it out of stock.';

  @override
  String get catNoteClosed =>
      'Atomshop closed this product. Contact Atomshop to list it again.';

  @override
  String get catNoteReadOnly =>
      'You can see this product. Your role can\'t change it.';

  @override
  String get catSectionPhotos => 'Photos';

  @override
  String get catFeatureImage => 'Feature image';

  @override
  String get catFeatureImageNote => 'Required · up to 4 MB';

  @override
  String get catFeatureImageMissing => 'Add a feature image';

  @override
  String get catChange => 'Change';

  @override
  String get catAddPhoto => 'Add photo';

  @override
  String get catMorePhotos => 'More photos';

  @override
  String get catAdd => 'Add';

  @override
  String get catPhotosTip =>
      'Front, back, side, box and remote. Plain background works best.';

  @override
  String get catRemovePhotoTitle => 'Remove this photo?';

  @override
  String get catRemovePhotoBody =>
      'It is taken off the product straight away, also on atomshop.pk.';

  @override
  String get catRemove => 'Remove';

  @override
  String get catPhotoRemoved => 'Photo removed';

  @override
  String get catPhotoTooLarge => 'That photo is too large. Use one under 4 MB.';

  @override
  String get catLogoTooLarge => 'That logo is too large. Use one under 2 MB.';

  @override
  String get catPickCamera => 'Take a photo';

  @override
  String get catPickGallery => 'Choose from gallery';

  @override
  String get catSectionDetails => 'Product details';

  @override
  String get catTitleLabel => 'Product title';

  @override
  String get catTitleHint => 'As customers search for it: brand, size, model.';

  @override
  String get catCategory => 'Category';

  @override
  String get catCategorySearch => 'Search categories';

  @override
  String get catBrand => 'Brand';

  @override
  String get catBrandSearch => 'Search brands';

  @override
  String get catBrandsInCategory => 'Sell in this category';

  @override
  String get catOtherBrands => 'Other brands';

  @override
  String get catDetailHeading => 'Detail page heading';

  @override
  String get catOptional => '(optional)';

  @override
  String get catOptionalTag => 'Optional';

  @override
  String get catDetailHeadingHint => 'Shown at the top of the product page';

  @override
  String get catSectionPrice => 'Price and AtomPay';

  @override
  String get catCashPrice => 'Cash price';

  @override
  String get catMinAdvance => 'Minimum advance';

  @override
  String get catAdvanceHint =>
      'The advance can\'t be more than the cash price.';

  @override
  String get catAdvanceTooHigh =>
      'The advance can\'t be more than the cash price';

  @override
  String get catSellWithAtompay => 'Sell with AtomPay';

  @override
  String get catSellWithAtompayBody =>
      'Customer pays in 3 months, no advance, 0% markup. Atomshop gives the order to a seller; for you it is a cash sale.';

  @override
  String get catSectionVariants => 'Variants';

  @override
  String get catColours => 'Colours';

  @override
  String get catChooseColours => 'Choose colours';

  @override
  String get catSearchColours => 'Search colours';

  @override
  String get catStorageLabel => 'Storage, each with its own price';

  @override
  String get catSizesLabel => 'Screen sizes, each with its own price';

  @override
  String get catAddStorage => 'Add a storage';

  @override
  String get catAddSize => 'Add a size';

  @override
  String get catStorage => 'Storage';

  @override
  String get catSize => 'Screen size';

  @override
  String get catPriceForThis => 'Price for this option';

  @override
  String get catVariantsTip =>
      'The options follow the category: storage for phones, screen size for TVs.';

  @override
  String get catVariantIncomplete => 'Choose the option and its price';

  @override
  String get catSectionDescription => 'Description';

  @override
  String get catShortDescription => 'Short description';

  @override
  String get catShortTooLong => 'Keep it under 500 characters';

  @override
  String get catFullDescription => 'Full description';

  @override
  String get catFullHint =>
      'One feature per line. Start a line with • or - for a bullet.';

  @override
  String get catSendForReview => 'Send for review';

  @override
  String get catFixAndSend => 'Fix and send again';

  @override
  String get catSaveAndSend => 'Save and send for review';

  @override
  String get catSaveChanges => 'Save changes';

  @override
  String get catReviewedBy =>
      'Reviewed by Atomshop, usually within one working day';

  @override
  String get catSentForReview => 'Sent to Atomshop for review';

  @override
  String get catChangesSaved => 'Changes saved';

  @override
  String get catSendLiveTitle => 'Send your changes for review?';

  @override
  String get catSendLiveBody =>
      'Customers keep seeing the current version until Atomshop approves the new one.';

  @override
  String get catSend => 'Send';

  @override
  String get catGapPicture => 'a feature image';

  @override
  String get catGapTitle => 'a title';

  @override
  String get catGapCategory => 'a category';

  @override
  String get catGapBrand => 'a brand';

  @override
  String get catGapPrice => 'a price';

  @override
  String get catGapAdvance => 'the minimum advance';

  @override
  String get catGapAdvanceHigh => 'a lower advance';

  @override
  String get catGapShort => 'a short description';

  @override
  String get catGapShortLong => 'a shorter description';

  @override
  String get catGapVariants => 'a price for each option';

  @override
  String get catProductNotFound =>
      'This product is no longer in your catalogue.';

  @override
  String get catBrandPageTitle => 'Brand page';

  @override
  String get catViewOnAtomshop => 'View on atomshop.pk';

  @override
  String get catPage => 'Page';

  @override
  String get catAddress => 'Address';

  @override
  String get catLiveProducts => 'Live products';

  @override
  String get catFeatured => 'Featured';

  @override
  String get catAddressFixed =>
      'The address is fixed. Ask Atomshop to change it.';

  @override
  String get catLogoAndBanner => 'Logo and banner';

  @override
  String get catChangeLogo => 'Change logo';

  @override
  String get catChangeBanner => 'Change banner';

  @override
  String get catLogoBannerHint => 'Logo up to 2 MB, banner up to 4 MB.';

  @override
  String get catNewLogo => 'New logo, not saved yet';

  @override
  String get catNewBanner => 'New banner, not saved yet';

  @override
  String get catNoBanner => 'No banner yet';

  @override
  String get catYourStory => 'Your story';

  @override
  String get catDisplayName => 'Display name';

  @override
  String get catDisplayNameError => 'Enter the name customers see';

  @override
  String get catTagline => 'Tagline';

  @override
  String get catIntro => 'Intro';

  @override
  String get catIntroHint => 'Up to 300 characters, under your name.';

  @override
  String get catIntroTooLong => 'Keep the intro under 300 characters';

  @override
  String get catAbout => 'About the brand';

  @override
  String get catPromoBanner => 'Promo banner';

  @override
  String get catSmallLabel => 'Small label';

  @override
  String get catHeadline => 'Headline';

  @override
  String get catSupportingLine => 'Supporting line';

  @override
  String get catAddSlide => 'Add a slide';

  @override
  String get catSlideNoHeadline => 'A slide without a headline is not shown.';

  @override
  String get catContact => 'Contact';

  @override
  String get catWebsite => 'Website';

  @override
  String get catWebsiteError => 'Enter a web address, like zenvo.pk';

  @override
  String get catSupportEmail => 'Support email';

  @override
  String get catSupportEmailError =>
      'Enter an email address, like care@zenvo.pk';

  @override
  String get catSupportPhone => 'Support phone';

  @override
  String get catFeaturedOnPage => 'Featured on your page';

  @override
  String get catFeaturedHint =>
      'Feature live products with the star on Products. Up to 5 show.';

  @override
  String get catNoFeatured => 'No featured products yet.';

  @override
  String get catSavePage => 'Save brand page';

  @override
  String get catDiscardChanges => 'Discard changes';

  @override
  String get catPageSaved => 'Brand page saved';

  @override
  String get catFixFields => 'Check the fields marked in red';

  @override
  String catProductsSummary(int total, int live) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total products · $live live on atomshop.pk',
      one: '1 product · $live live on atomshop.pk',
    );
    return '$_temp0';
  }

  @override
  String catOnHoldOne(String title) {
    return '$title is on hold';
  }

  @override
  String catOnHoldMany(int n) {
    return '$n products are on hold';
  }

  @override
  String catMoreActionsFor(String title) {
    return 'More actions for $title';
  }

  @override
  String catAvailableUnits(int n) {
    return '$n available';
  }

  @override
  String catOnlyLeft(int n) {
    return 'Only $n left';
  }

  @override
  String catDeleteConfirmTitle(String title) {
    return 'Delete $title?';
  }

  @override
  String catNoteHold(String reason) {
    return 'Atomshop put this on hold: “$reason” Fix it and send it again.';
  }

  @override
  String catPhotosOf(int n, int max) {
    return '$n of $max';
  }

  @override
  String catPhotoN(int n) {
    return 'Photo $n';
  }

  @override
  String catRemovePhotoN(int n) {
    return 'Remove photo $n';
  }

  @override
  String catCustomerPays(String monthly) {
    return 'Customer pays 3 × $monthly';
  }

  @override
  String catColoursPicked(int n) {
    return '$n picked';
  }

  @override
  String catRemoveVariant(String name) {
    return 'Remove $name';
  }

  @override
  String catShortCount(int n, int max) {
    return '$n / $max · shown next to the price';
  }

  @override
  String catAddToSend(String list) {
    return 'Add $list to send';
  }

  @override
  String catFeaturedOf(int n, int max) {
    return '$n of $max';
  }

  @override
  String catUpToSlides(int n) {
    return 'Up to $n slides';
  }

  @override
  String catSlideN(int n) {
    return 'Slide $n';
  }

  @override
  String catAndMore(int n) {
    return 'And $n more';
  }

  @override
  String get homeAllOutlets => 'All outlets';

  @override
  String get homeBrandPartner => 'Brand partner';

  @override
  String get homeSearch => 'Search';

  @override
  String get homeNotifications => 'Notifications';

  @override
  String get homeMenu => 'Menu and profile';

  @override
  String get homeSwitchOutlet => 'Switch outlet';

  @override
  String get homeAskBar => 'Ask Atom: what sold best this week…';

  @override
  String get homeToday => 'Today';

  @override
  String get homeDashboard => 'Dashboard';

  @override
  String get homeOrdersToConfirm => 'New orders to confirm';

  @override
  String get homeUnitsToHandOver => 'AtomPay units to hand over';

  @override
  String get homeRequestsToQuote => 'Seller & bulk requests to quote';

  @override
  String get homeConfirmOrders => 'Confirm orders';

  @override
  String get homeReplyToBulk => 'Reply to bulk';

  @override
  String get homeOfflineLegend => 'New orders arrive when you are back online';

  @override
  String get homeNeedsAttention => 'Needs your attention';

  @override
  String get homeNothingToDo =>
      'All done. New tasks show here as they come in.';

  @override
  String get homeFromCopy => 'From this phone\'s copy';

  @override
  String get homeYourSales => 'Your sales on Atomshop';

  @override
  String get homeReport => 'Report';

  @override
  String get homeCashSales => 'Cash sales';

  @override
  String get homePaymentsReceived => 'Payments received';

  @override
  String get homeUnitsSold => 'Units sold';

  @override
  String get homeUnitsNote => 'Cash and AtomPay orders';

  @override
  String get homeLiveOnAtomshop => 'Live on atomshop.pk';

  @override
  String get homeNothingDue => 'Nothing still due';

  @override
  String get homeSalesAndPayments => 'Cash sales and payments';

  @override
  String get homeAllOrders => 'All orders';

  @override
  String get homeOrderPipeline => 'Order pipeline';

  @override
  String get homeBulkDeals => 'Bulk deals';

  @override
  String get homeAllRequests => 'All requests';

  @override
  String get homeOutletsThisMonth => 'Your outlets this month';

  @override
  String get homeOutlets => 'Outlets';

  @override
  String get homeOpenPill => 'Open';

  @override
  String get homePausedPill => 'Paused';

  @override
  String get homeTopProducts => 'Top products';

  @override
  String homeCashPriceLine(String price) {
    return '$price cash price';
  }

  @override
  String get homeCatalogue => 'Catalogue';

  @override
  String get homeLatestOrders => 'Latest orders';

  @override
  String get homeViewAll => 'View all';

  @override
  String get homeCash => 'Cash';

  @override
  String get homeAtompay => 'AtomPay';

  @override
  String get homeNoOrdersYet =>
      'No orders yet. They show here the moment a customer orders.';

  @override
  String get homeRecentActivity => 'Recent activity';

  @override
  String get homeAll => 'All';

  @override
  String get homePlanAndBilling => 'Plan & billing';

  @override
  String get homeNoAddons => 'no add-ons';

  @override
  String get homeWithProof => 'With the proof photo · sent when online';

  @override
  String get homeDeliver => 'Deliver';

  @override
  String get homeWorksOffline => 'Works offline · sent when online';

  @override
  String get homeRecord => 'Record';

  @override
  String get homeQuoteNeedsInternet => 'Sending a quote needs internet';

  @override
  String get homeOnlineOnly => 'Online only';

  @override
  String get homeNothingOffline => 'Nothing waiting on this phone.';

  @override
  String get homeWelcome => 'Welcome to Brand Partner';

  @override
  String get homeLetsSell => 'Let\'s get your brand selling';

  @override
  String get homeFirstSteps => 'Your first steps';

  @override
  String get homeAboutTen => 'About 10 minutes';

  @override
  String get homeStuck => 'Stuck? Ask Atom';

  @override
  String get homeStuckQ =>
      '\"How do I add a product with colours and storage options?\"';

  @override
  String get homeHide => 'Hide';

  @override
  String get homeKeepIt => 'Keep it';

  @override
  String get homeSwitchOff => 'Switch off';

  @override
  String get homePay => 'Pay';

  @override
  String get homeSeeBill => 'See bill';

  @override
  String get homeRead => 'Read';

  @override
  String get homeReadMore => 'Read more';

  @override
  String get homeWhatToDo => 'What do you want to do?';

  @override
  String get homeOnlyYourRole => 'Only what your role allows is shown.';

  @override
  String get homeAddProduct => 'Add product';

  @override
  String get homeAddProductSub => 'Atomshop reviews it before it goes live';

  @override
  String get homeStockIn => 'Stock in';

  @override
  String get homeStockInSub =>
      'Units that arrived from the factory, with serials';

  @override
  String get homeRecordPayment => 'Record payment';

  @override
  String get homeRecordPaymentSub =>
      'On a delivered cash order, with a receipt photo';

  @override
  String get homeSendQuote => 'Send a quote';

  @override
  String get homeSendQuoteSub => 'Reply to a bulk request on WhatsApp';

  @override
  String get homeHandOver => 'Hand over AtomPay unit';

  @override
  String get homeHandOverSub => 'To the seller Atomshop gave the order to';

  @override
  String get homeAskAtom => 'Ask Atom';

  @override
  String get homeAskAtomSub => 'Answers from your own records';

  @override
  String get homeNothingForRole =>
      'Your role has nothing to add here. Ask your brand owner if you need more.';

  @override
  String get homeSales => 'Sales';

  @override
  String get homeToConfirm => 'To confirm';

  @override
  String get homeMain => 'Main';

  @override
  String get homeAddOutlet => 'Add an outlet';

  @override
  String get homeManageOutlets => 'Manage outlets';

  @override
  String get homeSearchHint => 'Order number, product or PR number';

  @override
  String get homeScan => 'Scan a serial or IMEI';

  @override
  String get homeTypeMore => 'Type at least 2 letters or digits.';

  @override
  String get homeFirstFive => 'Showing the first 5. Open the list to see all.';

  @override
  String get homeSearchTip =>
      'Search by order number, product, PR number, serial or business.';

  @override
  String get homeSearchTipOffline =>
      'Search by order number, product, PR number, serial or business. Works offline.';

  @override
  String get homeFromCopyNote =>
      'No signal: these come from this phone\'s copy.';

  @override
  String homeSalam(String name) {
    return 'Salam, $name';
  }

  @override
  String homeSynced(String time) {
    return 'Synced $time';
  }

  @override
  String homeUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String homeAsOf(String time) {
    return 'As of $time';
  }

  @override
  String homeThingsNeedYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n things need you today',
      one: '1 thing needs you today',
      zero: 'Nothing needs you right now',
    );
    return '$_temp0';
  }

  @override
  String homeOrdersToConfirmLine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'new orders to confirm',
      one: 'new order to confirm',
    );
    return '$_temp0';
  }

  @override
  String homeUnitsToHandOverLine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'AtomPay units to hand over',
      one: 'AtomPay unit to hand over',
    );
    return '$_temp0';
  }

  @override
  String homeRequestsLine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'bulk requests to quote',
      one: 'bulk request to quote',
    );
    return '$_temp0';
  }

  @override
  String homeOpen(int n) {
    return '$n open';
  }

  @override
  String homeLiveOf(int live, int total) {
    return '$live of $total';
  }

  @override
  String homeStillDue(String amount) {
    return '$amount still due';
  }

  @override
  String homeReceived(String amount) {
    return 'Received $amount';
  }

  @override
  String homeOutletLine(int orders, int toConfirm) {
    String _temp0 = intl.Intl.pluralLogic(
      orders,
      locale: localeName,
      other: '$orders orders · $toConfirm to confirm',
      one: '1 order · $toConfirm to confirm',
    );
    return '$_temp0';
  }

  @override
  String homeSold(int n) {
    return '$n sold';
  }

  @override
  String homePaidUntil(String day) {
    return 'Paid until $day';
  }

  @override
  String homeAgentNote(String role) {
    return 'Business totals and reports are for your brand owner. Your role: $role.';
  }

  @override
  String homeMarkDelivered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mark $n orders delivered',
      one: 'Mark 1 order delivered',
    );
    return '$_temp0';
  }

  @override
  String homeToRecord(String amount, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$amount to record from $n delivered orders',
      one: '$amount to record from 1 delivered order',
    );
    return '$_temp0';
  }

  @override
  String homeReplyRequests(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Reply to $n new bulk requests',
      one: 'Reply to 1 new bulk request',
    );
    return '$_temp0';
  }

  @override
  String homeDoneOf(int done, int total) {
    return '$done of $total done';
  }

  @override
  String homePayNow(String amount) {
    return 'Pay $amount now';
  }

  @override
  String homeOutletsSub(String brand, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$brand · $n outlets · this month',
      one: '$brand · 1 outlet · this month',
    );
    return '$_temp0';
  }

  @override
  String homeUsed(int used, int limit) {
    return '$used of $limit used';
  }

  @override
  String homeSwitched(String name) {
    return 'Now showing $name';
  }

  @override
  String homeAllCount(int n) {
    return 'All · $n';
  }

  @override
  String homeOrdersCount(String n) {
    return 'Orders · $n';
  }

  @override
  String homeProductsCount(String n) {
    return 'Products · $n';
  }

  @override
  String homeBulkCount(String n) {
    return 'Bulk · $n';
  }

  @override
  String homeRequestsCount(String n) {
    return 'Bulk requests · $n';
  }

  @override
  String homeNoneFound(String q) {
    return 'Nothing found for \"$q\".';
  }

  @override
  String homeAvailable(int n) {
    return '$n available';
  }

  @override
  String get catNewProduct => 'New product';

  @override
  String catNewSubtitle(String brand) {
    return '$brand · new';
  }

  @override
  String get catStatusLive => 'Live';

  @override
  String get catStatusInReview => 'In review';

  @override
  String get catStatusOutOfStock => 'Out of stock';

  @override
  String get catStatusOnHold => 'On hold';

  @override
  String get catStatusClosed => 'Closed';

  @override
  String catListAnd(String head, String last) {
    return '$head and $last';
  }

  @override
  String get settingsMyProfile => 'My profile';

  @override
  String get settingsProfileSubOwner =>
      'Contact name, email for sign-in, mobile number';

  @override
  String get settingsProfileSubAgent =>
      'Your name and the mobile you sign in with';

  @override
  String get settingsPasswordSubOwner =>
      'Changing it signs out your other devices';

  @override
  String get settingsPasswordSubAgent => 'The password you sign in with';

  @override
  String get settingsSecuritySub => 'PIN, fingerprint, auto-lock';

  @override
  String get settingsShopNoteEvery =>
      'Only you see these. They apply to every outlet.';

  @override
  String get settingsPayTitle => 'How customers pay you';

  @override
  String get settingsPaySub =>
      'Cash on delivery, bank transfer, JazzCash or Easypaisa';

  @override
  String get settingsPayCod => 'Cash on delivery';

  @override
  String get settingsPayBank => 'bank transfer';

  @override
  String get settingsPayWallet => 'JazzCash or Easypaisa';

  @override
  String get settingsOrdersTitle => 'Orders and the portal';

  @override
  String get settingsOrdersSub => 'Confirm time and idle sign-out';

  @override
  String settingsOrdersSubSet(int hours, int minutes) {
    return 'Confirm within $hours hours · sign out after $minutes minutes idle';
  }

  @override
  String get settingsReceipts => 'Receipts';

  @override
  String get settingsReceiptsSub => 'Note printed on every receipt';

  @override
  String get settingsDaily => 'Daily summary';

  @override
  String get settingsDailySub => 'Orders to confirm and quotes running out';

  @override
  String get settingsBrandAccount => 'Brand account';

  @override
  String get settingsBrandAccountNote =>
      'Set by Atomshop. Ask them to change any of it.';

  @override
  String get settingsStatus => 'Status';

  @override
  String settingsPartnerSince(String date) {
    return 'partner since $date';
  }

  @override
  String get settingsAccountType => 'Account type';

  @override
  String settingsMultiOutlet(int used, int limit) {
    return 'Multi-outlet · outlets $used of $limit';
  }

  @override
  String get settingsSingleOutlet => 'Single outlet';

  @override
  String get settingsAtompayWhole => 'AtomPay for the whole brand';

  @override
  String get settingsAtompayWholeOn => 'Every product can be sold on AtomPay';

  @override
  String get settingsAtompayWholeOff => 'Product by product, as Atomshop sets';

  @override
  String get settingsOn => 'On';

  @override
  String settingsDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get settingsTalkSub => 'WhatsApp the partner team';

  @override
  String get settingsPasswordRow => 'Password';

  @override
  String get settingsPageLive => 'Live';

  @override
  String get settingsPageNotLive => 'Not live';

  @override
  String get settingsDeleteRowSub => 'Delete your account · password-confirmed';

  @override
  String get settingsStatusActivePartner => 'Active partner';

  @override
  String get settingsBioNoneSub =>
      'Set up a fingerprint or face in the phone\'s settings first';

  @override
  String get settingsBioPinFirst => 'Set a PIN first, then switch this on';

  @override
  String get settingsOfflineCopy => 'Offline copy';

  @override
  String get settingsOfflineCopySub =>
      'Orders, products, stock, bulk deals · encrypted';

  @override
  String get settingsBlueKey => 'Blue: offline copy';

  @override
  String get settingsOfflineCopyNote =>
      'The offline copy is removed only when you sign out, so nothing waiting is lost.';

  @override
  String get settingsMic => 'Microphone';

  @override
  String get settingsMicSub => 'Only for speaking to Ask Atom';

  @override
  String get settingsSignOutOthersDone => 'Your other devices are signed out';

  @override
  String get settingsSignOutOthersNone =>
      'You weren\'t signed in anywhere else';

  @override
  String get settingsSignOutOthersTitle => 'Sign out all other devices?';

  @override
  String get settingsSignOutOthersBody =>
      'Every other phone, tablet and the brand portal signs out at once. This phone stays signed in.';

  @override
  String get settingsSessionsNote =>
      'A device you sign out is signed out at once. With Offline working, its saved copy is deleted the next time it goes online. Needs internet.';

  @override
  String get settingsSessionsNow => 'Signed in now';

  @override
  String get settingsDailyPreviewNone =>
      'Nothing to report today, so no message would go out.';

  @override
  String get settingsNoticesSub => 'What you get, quiet hours';

  @override
  String get settingsLanguageSubAtom => 'App and Ask Atom';

  @override
  String get settingsStorageSubOffline => 'Offline copy and cache';

  @override
  String get settingsDataSub => 'What is kept, where, and for how long';

  @override
  String get settingsExportSub =>
      'Orders, payments, products and stock as Excel';

  @override
  String get settingsPrivacySub => 'Saved on the phone, opens offline';

  @override
  String get settingsHelpSubAtom => 'Answers, Ask Atom, contact Atomshop';

  @override
  String get settingsHelpSub => 'Answers, contact Atomshop';

  @override
  String get settingsBrandPartner => 'Brand partner';

  @override
  String get settingsOwnerOnly => 'Only the owner can change it.';

  @override
  String get settingsPasswordChangedOwner =>
      'Password changed. Your other phones are signed out.';

  @override
  String get settingsPasswordSaved => 'Your password is saved.';

  @override
  String get settingsPasswordNoteOwner =>
      'Changing it signs you out on your other phones. This one stays signed in.';

  @override
  String get settingsPasswordNoteAgent =>
      'At least 8 characters. You sign in with your mobile number and this password.';

  @override
  String get settingsFeedbackOff =>
      'Feedback from the app isn’t switched on yet. Send it from Help, Talk to Atomshop.';

  @override
  String get settingsExportOff =>
      'Export from the app isn’t switched on yet. Download your data on the brand portal.';

  @override
  String get settingsDeleteConfirmTitle => 'Delete your account?';

  @override
  String get settingsDeleteConfirmBody =>
      'Your brand page and live products come off atomshop.pk, and everyone on your team is signed out. It can’t be undone.';

  @override
  String get settingsDeleteMine => 'Delete my account';

  @override
  String get settingsDeleted => 'Your account has been deleted.';

  @override
  String get settingsDeleteTitle => 'Delete account';

  @override
  String get settingsDeleteWarn =>
      'This deletes your Brand Partner login. It can’t be undone.';

  @override
  String get settingsDeleteWarnBold => 'This deletes your Brand Partner login.';

  @override
  String get settingsDeleteSignIn =>
      'Your sign-in on every phone and the portal';

  @override
  String get settingsDeletePage => 'Brand page and live products';

  @override
  String get settingsDeleteTakenOff => 'Taken off atomshop.pk';

  @override
  String get settingsDeleteRecords => 'Orders, payments and invoices';

  @override
  String get settingsDeleteWhyKept =>
      'Order and payment records are kept because the law needs them. Open orders must be delivered or cancelled first. Export your data first if you want a copy.';

  @override
  String get settingsStatusActive => 'Active';

  @override
  String get settingsStatusInactive => 'Inactive';

  @override
  String get settingsTypeName => 'Type your name';

  @override
  String get settingsTypeMobile => 'Type a mobile number like 0300 1234567';

  @override
  String get settingsMax100 => 'At most 100 characters';

  @override
  String get settingsPasswordsDiffer => 'The two passwords don’t match';

  @override
  String get settingsPasswordReused =>
      'Choose a password you haven’t used here';

  @override
  String get notifKindReviews => 'Product reviews';

  @override
  String get notifLiveOffTitle => 'Live alerts is off.';

  @override
  String get notifLiveOffOwner =>
      'Nothing pops up on your phone; everything still reaches the inbox. Switch it on in Plan & billing.';

  @override
  String get notifLiveOffAgent =>
      'Nothing pops up on your phone; everything still reaches the inbox.';

  @override
  String get helpRepliesOff =>
      'Replies from the app aren’t switched on yet. WhatsApp Atomshop instead.';

  @override
  String get helpAtomshopLogo => 'Atomshop.pk, Pay in Steps';

  @override
  String syncLastSyncWaiting(String when, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last sync $when. $count changes are waiting to send.',
      one: 'Last sync $when. 1 change is waiting to send.',
    );
    return '$_temp0';
  }

  @override
  String syncAllSentExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Everything is sent, except $count that need you.',
      one: 'Everything is sent, except 1 that needs you.',
    );
    return '$_temp0';
  }

  @override
  String get syncWorksUntilLead => 'Works offline until';

  @override
  String get syncUntilWhy => 'paid-until date';

  @override
  String get syncPhotos => 'Photos';

  @override
  String syncPhotosWaiting(int n) {
    return '$n waiting to upload';
  }

  @override
  String get syncPhotosNone => 'Proof and receipt photos go with their change';

  @override
  String get syncPhones => 'Phones signed in';

  @override
  String syncPhonesTeam(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You and $count team phones',
      one: 'You and 1 team phone',
    );
    return '$_temp0';
  }

  @override
  String get syncPhonesThis => 'This phone';

  @override
  String syncPhonesMore(int count) {
    return 'This phone and $count more';
  }

  @override
  String get syncPhonesLoading => 'Your phones and your team’s';

  @override
  String get syncEncrypted => 'encrypted';

  @override
  String get syncCopyLocked => 'Unlock with your PIN to see what is kept here';

  @override
  String get syncCopyNothing => 'Nothing yet. The first sync copies your work.';

  @override
  String get syncReadOnly =>
      'Your account is read-only: changes wait here, payments still go.';

  @override
  String syncChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String get syncUndoNoteFull =>
      'Undo works only before it is sent. Undoing a stock in also undoes anything later that used its units.';

  @override
  String syncPhotosLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos go with these changes',
      one: '1 photo goes with these changes',
    );
    return '$_temp0';
  }

  @override
  String get syncPhotoWaiting => 'Waiting';

  @override
  String get syncCheckIt => 'Check it';

  @override
  String get syncFix => 'Fix';

  @override
  String syncAlreadyMoved(String now) {
    return 'It is $now on the server now.';
  }

  @override
  String get syncReasonOrderChanged => 'Order changed meanwhile';

  @override
  String get syncReasonDealChanged => 'Deal changed meanwhile';

  @override
  String get syncReasonRequestChanged => 'Request changed meanwhile';

  @override
  String get syncReasonChanged => 'Changed meanwhile';

  @override
  String get syncReasonSerial => 'Serial already taken';

  @override
  String get syncReasonNotFound => 'Not found any more';

  @override
  String get syncReasonNotAllowed => 'Your role doesn’t allow this';

  @override
  String get syncReasonReadOnly => 'Account is read-only';

  @override
  String get syncReasonAddon => 'Add-on is off';

  @override
  String get syncReasonRefused => 'Not accepted';

  @override
  String get syncReasonCantSend => 'This app can’t send it';

  @override
  String get syncReasonNotApplied => 'Not applied';

  @override
  String get syncClashTitle => 'Serial already in stock';

  @override
  String get syncClashOther => 'Already on the server';

  @override
  String get syncClashMine => 'You added it';

  @override
  String get syncClashWhat => 'What happened?';

  @override
  String get syncClashTwice => 'Same box, counted twice';

  @override
  String get syncClashTwiceSub =>
      'Keep the one already in stock. Yours is dropped; stock stays right.';

  @override
  String get syncClashTwiceDo => 'Drop mine';

  @override
  String syncClashMove(String where) {
    return 'It is now at $where';
  }

  @override
  String syncClashMoveSub(String where) {
    return 'Keep the unit and move it to $where.';
  }

  @override
  String syncClashMoveDo(String where) {
    return 'Move it to $where';
  }

  @override
  String get syncClashWrong => 'I scanned the wrong box';

  @override
  String get syncClashWrongSub => 'Scan the box you meant to add.';

  @override
  String get syncClashWrongDo => 'Scan the right box';

  @override
  String get syncClashDiscard => 'Drop this change';

  @override
  String get syncClashDiscardSub =>
      'The server keeps what it has. Nothing of yours is applied.';

  @override
  String syncClashRest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The other $count units of this stock in are sent again on their own.',
      one: 'The other 1 unit of this stock in are sent again on their own.',
    );
    return '$_temp0';
  }

  @override
  String get syncClashFixed => 'Sorted. The rest goes with the next sync.';

  @override
  String get syncClashGone => 'This change has already been sorted.';

  @override
  String get syncClashSentFirst => 'Sent first';

  @override
  String get syncSendingTitle => 'Sending your changes';

  @override
  String get syncStepOrders => 'Deliveries & payments';

  @override
  String get syncStepBulk => 'Bulk deals';

  @override
  String get syncStepStock => 'Stock in & moves';

  @override
  String get syncStepDown => 'Getting others’ changes';

  @override
  String syncStepSent(int n) {
    return '$n sent';
  }

  @override
  String syncStepSending(int n, int total) {
    return 'sending $n of $total';
  }

  @override
  String syncStepWaiting(int n) {
    return '$n waiting';
  }

  @override
  String get syncStepNext => 'next';

  @override
  String get syncStepDone => 'done';

  @override
  String get syncStepNothing => 'nothing to send';

  @override
  String get syncSignalNote =>
      'If the signal drops, it stops and carries on later from the same place. A change is never sent twice.';

  @override
  String get syncAllDone => 'All sent. This phone is up to date.';

  @override
  String get syncUpdateAppTitle => 'Update Atombrand to send your changes';

  @override
  String syncUpdateBody(String version, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This version$version can’t send to Atomshop any more. Your $count changes are safe on this phone and go out right after the update.',
      one:
          'This version$version can’t send to Atomshop any more. Your 1 change is safe on this phone and go out right after the update.',
    );
    return '$_temp0';
  }

  @override
  String get syncUpdateOnPlay => 'Update on Google Play';

  @override
  String get syncUpdateLater => 'Keep working, update later';

  @override
  String get syncUpdateSafe =>
      'Updating never deletes what is saved on the phone.';

  @override
  String get syncYours => 'Yours';

  @override
  String get syncYourTeam => 'Your team';

  @override
  String get syncNowTag => 'Now';

  @override
  String get syncSignOut => 'Sign out';

  @override
  String syncSynced(String when) {
    return 'Synced $when';
  }

  @override
  String syncLastSync(String when) {
    return 'Last sync $when';
  }

  @override
  String syncOfflineUntil(String day) {
    return 'works offline until $day';
  }

  @override
  String syncNotSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes not sent',
      one: '1 change not sent',
    );
    return '$_temp0';
  }

  @override
  String get syncNothingWaiting => 'nothing waiting';

  @override
  String get syncAllOut => 'Sign out all other phones';

  @override
  String get syncAllOutTeam => 'Sign out all other phones, team too';

  @override
  String get syncPhonesNote =>
      'A phone that is signed out deletes its saved copy the next time it goes online. Lost a phone? Sign it out here.';

  @override
  String get syncPhonesEmpty => 'Only this phone is signed in.';

  @override
  String get syncUnknownPhone => 'Phone';

  @override
  String syncDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get syncSignOutThisTitle => 'Sign out this phone?';

  @override
  String syncSignOutOwnerTitle(String owner) {
    return 'Sign out $owner’s phone?';
  }

  @override
  String syncUnsentWarn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes on that phone were never sent. If you sign it out, they are lost.',
      one: '1 change on that phone was never sent. If you sign it out, they are lost.',
    );
    return '$_temp0';
  }

  @override
  String syncUnsentAsk(String owner) {
    return 'Ask $owner to open the app with internet first, if you can.';
  }

  @override
  String get syncNextOnline => 'Next time it goes online';

  @override
  String get syncCopyDeleted => 'Its saved copy is deleted';

  @override
  String get syncLoginYours => 'Your login';

  @override
  String syncLoginOwner(String owner) {
    return '$owner’s login';
  }

  @override
  String get syncLoginStays => 'Stays; can sign in again';

  @override
  String get syncStopCompletely =>
      'To stop someone completely, switch them off in Team & roles instead.';

  @override
  String get syncKeepIt => 'Keep it';

  @override
  String get syncSignItOut => 'Sign it out';

  @override
  String get syncSignedOutOk =>
      'That phone is signed out. Its copy is deleted the next time it connects.';

  @override
  String syncAllOutOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phones are signed out.',
      one: '1 phone is signed out.',
      zero: 'No other phone was signed in.',
    );
    return '$_temp0';
  }

  @override
  String get syncAllOutTitle => 'Sign out the other phones?';

  @override
  String get syncAllOutBody =>
      'Each one deletes its saved copy the next time it goes online. Changes not sent from those phones are lost.';

  @override
  String get syncNoInternetBody =>
      'Atombrand needs a connection to show and save your work. Turn on mobile data or Wi-Fi.';

  @override
  String get syncNoInternetDraft =>
      'What you were typing is kept on this screen. Nothing was saved yet; save it when you are back online.';

  @override
  String get syncEndedBodyFull =>
      'Offline working has ended on your account. First, everything saved on this phone is sent, so nothing is lost.';

  @override
  String syncEndedSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count waiting changes',
      one: 'Send 1 waiting change',
    );
    return '$_temp0';
  }

  @override
  String syncEndedPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count photos',
      one: 'Send 1 photo',
    );
    return '$_temp0';
  }

  @override
  String get syncEndedDelete => 'Delete the copy on this phone';

  @override
  String get syncEndedSendingTag => 'sending';

  @override
  String syncEndedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes need you before the copy can be deleted.',
      one: '1 change needs you before the copy can be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get syncContinueOnline => 'Continue online';

  @override
  String syncLimitDays(int days) {
    return 'You have worked offline for $days days. Connect once so we can send your work and check your account.';
  }

  @override
  String syncPlanEndedTitle(String day) {
    return 'Your plan ended on $day';
  }

  @override
  String get syncPlanEndedBody =>
      'Offline use stops when your plan ends. Connect to the internet so we can sync your work and you can renew on Plan & billing.';

  @override
  String get syncSafeHere => 'Safe on this phone';

  @override
  String get syncSafeHereSub =>
      'Nothing is lost. It all syncs when you connect.';

  @override
  String syncLastSynced(String when) {
    return 'Last synced $when';
  }

  @override
  String get syncNotSyncedYet => 'Not synced on this phone yet';

  @override
  String get syncLimitWhy => 'the offline limit';

  @override
  String get syncOpenWifi => 'Open Wi-Fi settings';

  @override
  String get syncLookUpOnly =>
      'You can still look up orders, deals and stock, but not change them.';

  @override
  String get syncHoldTag => 'Account';

  @override
  String get syncHoldTitle => 'Your account is on hold';

  @override
  String get syncHoldBody =>
      'This phone was signed out and its offline copy deleted. Ask your brand owner, or message Atomshop.';

  @override
  String get syncHoldSafe =>
      'Work you recorded before was sent to the brand. This phone no longer keeps its offline copy.';

  @override
  String get syncHoldWhatsApp => 'Message Atomshop on WhatsApp';

  @override
  String get syncHoldSignIn => 'Sign in with another account';

  @override
  String get syncOnlineTag => 'Online';

  @override
  String syncReadyTitle(String where) {
    return 'Getting $where ready for offline';
  }

  @override
  String get syncReadyBody =>
      'We are copying your brand’s orders, deals and stock to this phone, encrypted. Keep the app open: on Wi-Fi this takes about a minute.';

  @override
  String get syncReadyOrders => 'Orders and payments';

  @override
  String get syncReadyBulk => 'Bulk requests and deals';

  @override
  String get syncReadyProducts => 'Products and prices';

  @override
  String get syncReadyStock => 'Stock and serial numbers';

  @override
  String get syncReadyAtompay => 'AtomPay orders';

  @override
  String get syncReadyPhotos => 'Delivery and receipt photos';

  @override
  String get syncStartNow => 'Start working now';

  @override
  String get syncReadyNote =>
      'Photos finish in the background. Sending quotes and new bulk requests need internet.';

  @override
  String get syncReadyFailed =>
      'The copy stopped part-way. It carries on by itself when there is signal.';

  @override
  String get syncReadyDone => 'Ready. This phone works without signal now.';

  @override
  String get stockTitle => 'Stock';

  @override
  String get stockIn => 'Stock in';

  @override
  String get stockMove => 'Move';

  @override
  String get stockAdjust => 'Adjust';

  @override
  String get stockHistory => 'History';

  @override
  String get stockHistoryTitle => 'Stock history';

  @override
  String get stockListTitle => 'Stock list';

  @override
  String get stockMoveTitle => 'Move stock';

  @override
  String get stockAdjustTitle => 'Adjust stock';

  @override
  String get stockWarehouses => 'Warehouses';

  @override
  String get stockWarehouse => 'Warehouse';

  @override
  String get stockOutlet => 'Outlet';

  @override
  String get stockAllOutlets => 'All outlets';

  @override
  String get stockAll => 'All';

  @override
  String get stockAllProducts => 'All products';

  @override
  String get stockProduct => 'Product';

  @override
  String get stockProductVariant => 'Product and variant';

  @override
  String get stockProductOrSku => 'Product or SKU';

  @override
  String get stockSerialOrImei => 'Serial or IMEI';

  @override
  String get stockSerialOrProduct => 'Serial or product';

  @override
  String get stockTypeNumber => 'Type the number';

  @override
  String get stockScan => 'Scan';

  @override
  String get stockLookUp => 'Look it up';

  @override
  String get stockAdd => 'Add';

  @override
  String get stockEdit => 'Edit';

  @override
  String get stockOpen => 'Open';

  @override
  String get stockDone => 'Done';

  @override
  String get stockChange => 'Change';

  @override
  String get stockRemove => 'Remove';

  @override
  String get stockNote => 'Note';

  @override
  String get stockOptional => '(optional)';

  @override
  String get stockRequired => '(required)';

  @override
  String get stockDate => 'Date';

  @override
  String get stockReason => 'Reason';

  @override
  String get stockPrefix => 'Prefix';

  @override
  String get stockStandard => 'Standard';

  @override
  String stockOutletFilter(String name) {
    return 'Outlet: $name';
  }

  @override
  String stockCategoryFilter(String name) {
    return 'Category: $name';
  }

  @override
  String get stockCategory => 'Category';

  @override
  String get stockNoRecentIn => 'Nothing received in the last 30 days.';

  @override
  String get stockCameraOffTitle => 'The camera is off for Brand Partner';

  @override
  String get stockCameraOffBody =>
      'To scan serials and IMEIs, allow the camera in your phone\'s settings. You can also type the number.';

  @override
  String get stockCameraFailedTitle => 'The camera didn\'t start';

  @override
  String get stockCameraFailedBody =>
      'Close other apps using the camera and try again, or type the number.';

  @override
  String get stockOpenSettings => 'Open settings';

  @override
  String get catVarPickCategory =>
      'Choose a category first. The options follow it: storage for phones, screen size for TVs.';

  @override
  String get catVarOneVersion =>
      'Products in this category come in one version.';

  @override
  String get catVarNoColours =>
      'Atomshop hasn\'t added colours yet. Ask support for the ones you need.';

  @override
  String get catVarNoSizes =>
      'Atomshop hasn\'t added screen sizes yet. Ask support for the ones you need.';

  @override
  String get catVarNoStorage =>
      'Atomshop hasn\'t added storage options yet. Ask support for the ones you need.';

  @override
  String get syncNoTeamPhone => 'No phone signed in yet';

  @override
  String get teamKpiOrders => 'Orders handled this month';

  @override
  String get teamKpiOrdersNote => 'Confirmed or delivered';

  @override
  String teamOrdersMonthN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n orders this month',
      one: '1 order this month',
    );
    return '$_temp0';
  }

  @override
  String teamKpiHandled(String month) {
    return 'Orders handled · $month';
  }

  @override
  String teamKpiHandledNote(int confirmed, int delivered) {
    return '$confirmed confirmed, $delivered delivered';
  }

  @override
  String teamKpiPaid(String month) {
    return 'Payments recorded · $month';
  }

  @override
  String teamKpiPaidNote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String get teamPhonesRow => 'Sign out their phones';

  @override
  String get teamPhonesSub => 'They can sign in again';

  @override
  String teamPhonesTitle(String name) {
    return 'Sign out $name\'s phones?';
  }

  @override
  String get teamPhonesBody =>
      'Every phone they use is signed out. A phone with an offline copy deletes it the next time it goes online, with anything it never sent. Their login stays.';

  @override
  String get teamPhonesButton => 'Sign out phones';

  @override
  String teamPhonesDone(String name) {
    return '$name\'s phones are signed out.';
  }

  @override
  String get teamPhonesNone => 'No phone was signed in.';

  @override
  String get teamBlurbManager =>
      'Everything except outlets, settings and billing';

  @override
  String get teamBlurbOrders =>
      'Orders, payments, AtomPay; sees products and stock';

  @override
  String get teamBlurbBulk => 'Bulk requests, quotes and deals';

  @override
  String get teamBlurbStock => 'Stock in, adjust, move; warehouses';

  @override
  String get teamBlurbMarketing => 'Products and the brand page';

  @override
  String get teamBlurbAccountant => 'Totals, payments, reports and exports';

  @override
  String stockProductFilter(String name) {
    return 'Product: $name';
  }

  @override
  String stockWhenFilter(String period) {
    return 'When: $period';
  }

  @override
  String get stockWhen => 'When';

  @override
  String stockNoMatch(String query) {
    return 'No match for \"$query\"';
  }

  @override
  String get stockNothingHere => 'Nothing here';

  @override
  String get stockNothingYet => 'Nothing yet.';

  @override
  String get stockOther => 'Other';

  @override
  String get stockTrackingImei => 'IMEI';

  @override
  String get stockTrackingSerial => 'serial number';

  @override
  String get stockTrackingAuto => 'auto number';

  @override
  String stockNumberedBy(String what) {
    return 'numbered by $what';
  }

  @override
  String get stockWhTypeFactory => 'Factory store';

  @override
  String get stockWhTypeGodown => 'Godown';

  @override
  String get stockWhTypeStore => 'Outlet store';

  @override
  String get stockSerialTwice => 'Entered twice';

  @override
  String get stockSerialImei15 => 'IMEI should be 15 digits';

  @override
  String get stockSerialCheckDigit => 'Last digit doesn’t match';

  @override
  String get stockSerialLength => 'Should be 3 to 60 characters';

  @override
  String get stockSerialInStock => 'Already in stock';

  @override
  String get stockChooseWarehouse => 'Choose the warehouse';

  @override
  String get stockChooseProduct => 'Choose the product';

  @override
  String get stockInEnterQty => 'Enter how many units arrived';

  @override
  String stockInMax(int max) {
    return 'Add up to $max units at a time';
  }

  @override
  String stockInScanEach(String what) {
    return 'Scan or type each unit’s $what';
  }

  @override
  String stockAutoRange(String first, String last) {
    return '$first to $last';
  }

  @override
  String get stockWhereNone => 'None in stock';

  @override
  String get stockStateOut => 'Out of stock';

  @override
  String get stockStateLow => 'Low';

  @override
  String get stockStateIn => 'In stock';

  @override
  String get stockMoveDelivered => 'Delivered';

  @override
  String get stockMoveMoved => 'Moved';

  @override
  String get stockMoveAdjusted => 'Adjusted';

  @override
  String get stockDayToday => 'Today';

  @override
  String stockDayYesterday(String date) {
    return 'Yesterday · $date';
  }

  @override
  String get stockDayEarlier => 'Earlier';

  @override
  String get stockAdjustChooseUnit => 'Choose the unit to remove';

  @override
  String get stockAdjustEnterImei => 'Enter the IMEI';

  @override
  String get stockAdjustEnterSerial => 'Enter the serial number';

  @override
  String get stockAdjustCheckImei => 'Check the IMEI: 15 digits';

  @override
  String get stockAdjustChooseReason => 'Choose a reason';

  @override
  String get stockAdjustWriteNote => 'Write a note: what happened?';

  @override
  String get stockMoveChooseFrom => 'Choose where it moves from';

  @override
  String get stockMoveChooseTo => 'Choose where it goes';

  @override
  String get stockMoveDifferent => 'Choose a different warehouse';

  @override
  String get stockMoveTickUnits => 'Tick the units to move';

  @override
  String get stockMoveMax => 'Move up to 200 units at a time';

  @override
  String get stockWhNameMissing => 'Give the warehouse a name';

  @override
  String get stockWhNameLong => 'Keep the name to 60 characters';

  @override
  String get stockWhChooseOutlet => 'Choose the outlet';

  @override
  String get stockPrefixRule => 'Use 2 to 6 letters or digits';

  @override
  String get stockOffMessage => 'Inventory isn’t switched on for your brand.';

  @override
  String get stockReadOnlyMessage =>
      'Inventory has ended, so stock can’t be changed. Switch it back on in Plan & billing.';

  @override
  String get stockOffTitle => 'Inventory isn’t on';

  @override
  String get stockOffBody =>
      'Ask Atomshop to switch on the Inventory add-on for your brand.';

  @override
  String get stockNotFoundTitle => 'Not found';

  @override
  String get stockNotFoundBody =>
      'It isn’t in your stock, or it’s in an outlet you don’t work in.';

  @override
  String stockTodayDay(String date) {
    return 'Today, $date';
  }

  @override
  String stockWarehousesN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warehouses',
      one: '1 warehouse',
    );
    return '$_temp0';
  }

  @override
  String stockScopeAll(String warehouses) {
    return 'All outlets · $warehouses';
  }

  @override
  String stockScopeNamed(String name, String warehouses) {
    return '$name · $warehouses';
  }

  @override
  String get stockTrialTitle => 'Inventory free trial.';

  @override
  String stockTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Inventory free trial: $_temp0 left.';
  }

  @override
  String get stockTrialOwner => 'Keep it on from Plan & billing.';

  @override
  String get stockTrialStaff => 'Your brand’s owner can keep it on.';

  @override
  String get stockPlanBilling => 'Plan & billing';

  @override
  String get stockReadOnlyTitle =>
      'Inventory has ended, so stock is read-only.';

  @override
  String get stockReadOnlyBody => 'You can still see it.';

  @override
  String get stockSwitchBackOn => 'Switch it back on';

  @override
  String get stockViewByProduct => 'By product';

  @override
  String get stockHeld => 'Held';

  @override
  String stockViewHeldN(int count) {
    return 'Held · $count';
  }

  @override
  String get stockViewSerial => 'Find a serial';

  @override
  String stockChipAll(int n) {
    return 'All $n';
  }

  @override
  String stockChipLow(int n) {
    return 'Low $n';
  }

  @override
  String stockChipOut(int n) {
    return 'Out $n';
  }

  @override
  String get stockEmptyTitle => 'No stock yet';

  @override
  String get stockEmptyBody =>
      'Stock in what arrives from the factory and it shows here.';

  @override
  String get stockEmptyLow => 'No variant is running low.';

  @override
  String get stockEmptyOut => 'No variant is out of stock.';

  @override
  String stockSeeAll(int total) {
    return 'See all $total products';
  }

  @override
  String get stockAvailableNote =>
      'Available = in stock minus units held for confirmed orders and bulk deals. When it reaches 0 the product shows \"Out of stock\" on atomshop.pk.';

  @override
  String get stockScanSerial => 'Scan a serial';

  @override
  String get stockAvailableToSell => 'Available to sell';

  @override
  String stockOfUnits(int units, int products) {
    String _temp0 = intl.Intl.pluralLogic(
      products,
      locale: localeName,
      other: '$products products',
      one: '1 product',
    );
    return 'of $units units in stock · $_temp0';
  }

  @override
  String get stockFullList => 'Full list';

  @override
  String get stockHeldForOrders => 'Held for orders';

  @override
  String get stockLiveOn => 'Live on atomshop.pk';

  @override
  String stockLiveOf(int live, int listed) {
    return '$live of $listed';
  }

  @override
  String get stockLowOrOut => 'Low or out';

  @override
  String stockLowOutValue(int total, int out) {
    return '$total · $out out';
  }

  @override
  String stockOutAlert(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count variants are out of stock',
      one: '1 variant is out of stock',
    );
    return '$_temp0';
  }

  @override
  String get stockOutAlertBody => 'Customers can’t order them on atomshop.pk';

  @override
  String stockVariantSemantics(String title, int count) {
    return '$title, $count available';
  }

  @override
  String stockLevelSemantics(int available, int held, int onHand) {
    return '$available available, $held held, $onHand in stock';
  }

  @override
  String get stockAvailableWord => 'available';

  @override
  String stockHeldN(int count) {
    return '$count held';
  }

  @override
  String get stockHeldEmptyTitle => 'Nothing is held';

  @override
  String get stockHeldEmptyBody =>
      'Units held for confirmed orders and bulk deals show here.';

  @override
  String stockBulkDealN(String id) {
    return 'Bulk deal #$id';
  }

  @override
  String stockCashOrderN(String id) {
    return 'Cash order #$id';
  }

  @override
  String stockFromWh(String warehouse) {
    return 'from $warehouse';
  }

  @override
  String stockSince(String when) {
    return 'since $when';
  }

  @override
  String get stockSinceToday => 'today';

  @override
  String get stockSinceYesterday => 'yesterday';

  @override
  String get stockRemoved => 'Removed';

  @override
  String get stockNotInYourStock => 'This number isn’t in your stock.';

  @override
  String get stockWhere => 'Where';

  @override
  String get stockCameIn => 'Came in';

  @override
  String get stockHeldFor => 'Held for';

  @override
  String get stockWhy => 'Why';

  @override
  String get stockOpenOrder => 'Open the order';

  @override
  String get stockOpenDeal => 'Open the deal';

  @override
  String get stockOpenProduct => 'Open product';

  @override
  String get stockFoundAddBack => 'Found it: add it back';

  @override
  String get stockStockItIn => 'Stock it in';

  @override
  String get stockFoundUnit => 'Found a unit';

  @override
  String get stockEditProduct => 'Edit product';

  @override
  String get stockLive => 'Live';

  @override
  String get stockOrdersAndDeals => 'Orders and bulk deals';

  @override
  String get stockAvailable => 'Available';

  @override
  String get stockCanSellNow => 'Can be sold now';

  @override
  String get stockDelivered90 => 'Delivered in 90 days';

  @override
  String get stockVariants => 'Variants';

  @override
  String get stockColVariant => 'Variant';

  @override
  String get stockColAvail => 'Avail.';

  @override
  String get stockByWarehouse => 'By outlet and warehouse';

  @override
  String get stockSellsOnline => 'sells online';

  @override
  String get stockNotOnline => 'not online';

  @override
  String stockSegInStock(int count) {
    return 'In stock · $count';
  }

  @override
  String stockSegDelivered(int count) {
    return 'Delivered · $count';
  }

  @override
  String get stockNothingDelivered => 'Nothing delivered yet.';

  @override
  String get stockNoUnits => 'No units in stock.';

  @override
  String get stockRecentChanges => 'Recent stock changes';

  @override
  String get stockNoChanges => 'No changes yet.';

  @override
  String get stockOnAtomshop => 'On atomshop.pk';

  @override
  String get stockShowsAs => 'Shows as';

  @override
  String get stockNotListed => 'Not listed';

  @override
  String get stockCountsFrom => 'Counts from';

  @override
  String get stockOnlineWarehouses => 'Warehouses that sell online';

  @override
  String get stockAvailableOnline => 'Available online';

  @override
  String get stockDetails => 'Details';

  @override
  String get stockPrNumber => 'PR number';

  @override
  String get stockUnitsNumberedBy => 'Units numbered by';

  @override
  String get stockOnWebsite => 'On the website';

  @override
  String stockUnitBulkDeal(String id) {
    return 'bulk deal #$id';
  }

  @override
  String stockUnitOrder(String id) {
    return 'order #$id';
  }

  @override
  String stockUnitCameIn(String date) {
    return 'came in $date';
  }

  @override
  String get stockNumberingSaved => 'Numbering saved.';

  @override
  String get stockNumImeiHint => 'Phones and tablets: the 15-digit number';

  @override
  String get stockNumSerial => 'Serial number';

  @override
  String get stockNumSerialHint => 'The number on the box or the back label';

  @override
  String get stockNumAuto => 'Numbered for me';

  @override
  String get stockNumAutoHint => 'We give each unit a number with your prefix';

  @override
  String get stockNumTitle => 'How units are numbered';

  @override
  String get stockPrefixNote => 'up to 6 letters';

  @override
  String stockPrefixHint(String prefix) {
    return 'Units become $prefix-0001, $prefix-0002…';
  }

  @override
  String get stockSaveNumbering => 'Save numbering';

  @override
  String get stockScanNotImei => 'That isn’t an IMEI: 15 digits (dial *#06#).';

  @override
  String get stockScanLength => 'Should be 3 to 60 characters.';

  @override
  String get stockScanHintImei => 'Point at the IMEI barcode on the box.';

  @override
  String get stockScanHintSerial => 'Point at the serial number’s barcode.';

  @override
  String get stockScanTitle => 'Scan a serial or IMEI';

  @override
  String get stockTypeInstead => 'Type it instead';

  @override
  String stockScannedN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scanned',
      one: '1 scanned',
    );
    return '$_temp0';
  }

  @override
  String get stockScanPoint =>
      'Point the camera at the serial or IMEI barcode.';

  @override
  String get stockScanAnother => 'Scan another';

  @override
  String get stockUnitToRemove => 'Unit to remove';

  @override
  String get stockScanTheUnit => 'Scan the unit';

  @override
  String stockNotInStockHere(String serial) {
    return '$serial isn’t in stock in your warehouses.';
  }

  @override
  String stockTakenOut(String serial) {
    return '$serial taken out of stock.';
  }

  @override
  String get stockUnitAddedBack => 'Unit added back to stock.';

  @override
  String stockAddedBack(String serial) {
    return '$serial added back to stock.';
  }

  @override
  String get stockRemoveUnit => 'Remove a unit';

  @override
  String get stockChooseUnit => 'Choose the unit';

  @override
  String get stockAutoNote =>
      'This product is numbered for you: the unit gets the next number.';

  @override
  String get stockWhatHappened => 'What happened?';

  @override
  String get stockRemoveOne => 'Remove 1 unit';

  @override
  String get stockAddUnit => 'Add the unit';

  @override
  String get stockPeriod30 => 'Last 30 days';

  @override
  String get stockPeriodMonth => 'This month';

  @override
  String get stockPeriod90 => 'Last 90 days';

  @override
  String get stockPeriodAll => 'All time';

  @override
  String get stockSearchHistory => 'Search history';

  @override
  String get stockHistoryHint => 'Product, serial or reference';

  @override
  String get stockNothingPeriod => 'Nothing in this period';

  @override
  String get stockRunningLow => 'Running low';

  @override
  String get stockFindStock => 'Find stock';

  @override
  String get stockFindHint => 'Product, PR number or SKU';

  @override
  String get stockNoMatchBody => 'Try the product’s name, PR number or SKU.';

  @override
  String get stockNoVariant => 'No variant in this list.';

  @override
  String get stockListNote =>
      'Numbers are what you can sell now: in stock minus units held for orders and bulk deals.';

  @override
  String get stockNotLive => 'Not live';

  @override
  String get stockScanEachBox => 'Scan each box’s serial';

  @override
  String stockAddedUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count units to stock.',
      one: 'Added 1 unit to stock.',
    );
    return '$_temp0';
  }

  @override
  String get stockImeis => 'IMEIs';

  @override
  String get stockSerials => 'Serials';

  @override
  String get stockWhereArrived => 'Where it arrived';

  @override
  String get stockSellsOnAtomshop => 'sells on atomshop.pk';

  @override
  String get stockNotOnAtomshop => 'not on atomshop.pk';

  @override
  String get stockReceivedOn => 'Received on';

  @override
  String get stockReference => 'Reference';

  @override
  String get stockRefPlaceholder => 'e.g. FDN-2304';

  @override
  String get stockRefHint => 'Factory delivery note or reference.';

  @override
  String get stockWhatArrived => 'What arrived';

  @override
  String get stockHowMany => 'How many arrived';

  @override
  String stockNumberedAs(String numbers) {
    return 'They’ll be numbered $numbers.';
  }

  @override
  String get stockNextNumber =>
      'Each unit gets the next number with your prefix.';

  @override
  String stockLinesN(String what, int count) {
    return '$what · $count';
  }

  @override
  String get stockTypeMore => 'Or type or paste more';

  @override
  String get stockOnePerLine => 'One per line';

  @override
  String get stockPasteHint =>
      'Type or paste them, one per line. Duplicates are left out.';

  @override
  String get stockNotePlaceholder => 'e.g. Second truck from the factory';

  @override
  String get stockSummary => 'Summary';

  @override
  String get stockInto => 'Into';

  @override
  String get stockUnits => 'Units';

  @override
  String get stockAddToStock => 'Add to stock';

  @override
  String get stockAddAnother => 'Add and receive another';

  @override
  String get stockScanNext => 'Scan the next serial';

  @override
  String get stockScanStrip =>
      'Point at each box’s serial.\nIt adds them one by one.';

  @override
  String get stockRecentIn => 'Recent stock in';

  @override
  String get stockScanToMove => 'Scan the units to move';

  @override
  String stockNotInStockN(int count) {
    return '$count not in stock';
  }

  @override
  String stockElsewhereN(int count) {
    return '$count in another warehouse';
  }

  @override
  String stockMovedUnits(int count, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count units to $to.',
      one: 'Moved 1 unit to $to.',
    );
    return '$_temp0';
  }

  @override
  String get stockFrom => 'From';

  @override
  String get stockTo => 'To';

  @override
  String stockUnitsN(int count) {
    return '$count units';
  }

  @override
  String get stockMoveFrom => 'Move from';

  @override
  String get stockMoveTo => 'Move to';

  @override
  String get stockSwap => 'Swap';

  @override
  String stockTickedN(int count) {
    return '$count ticked';
  }

  @override
  String get stockNoUnitsHere => 'No units in stock here.';

  @override
  String get stockScanInstead => 'Scan units instead';

  @override
  String get stockMovedOn => 'Moved on';

  @override
  String get stockMovePlaceholder => 'Truck, driver…';

  @override
  String stockMoveN(int count) {
    return 'Move $count units';
  }

  @override
  String stockMoveNTo(int count, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count units to $to',
      one: 'Move 1 unit to $to',
    );
    return '$_temp0';
  }

  @override
  String get stockHeldCantMove =>
      'Held units can’t move. They stay with their order.';

  @override
  String get stockWhReadOnly =>
      'Inventory has ended, so warehouses can’t be changed.';

  @override
  String get stockNoWarehouses => 'No warehouses yet';

  @override
  String get stockNoWarehousesBody =>
      'Each outlet gets a store warehouse made for it.';

  @override
  String get stockArchived => 'Archived';

  @override
  String stockArchivedUnits(int count) {
    return 'Archived · $count units';
  }

  @override
  String get stockBringBack => 'Bring back';

  @override
  String get stockDefault => 'Default';

  @override
  String get stockSellsOnAtomshopTag => 'Sells on atomshop.pk';

  @override
  String get stockNotOnAtomshopTag => 'Not on atomshop.pk';

  @override
  String stockInChargeOf(String name) {
    return 'in charge: $name';
  }

  @override
  String get stockNobodyYet => 'nobody yet';

  @override
  String stockArchiveTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String get stockArchiveBody =>
      'It leaves the lists. Move its stock out first.';

  @override
  String get stockArchive => 'Archive';

  @override
  String stockWhArchived(String name) {
    return '$name archived.';
  }

  @override
  String stockWhSaved(String name) {
    return '$name saved.';
  }

  @override
  String get stockAddWarehouse => 'Add a warehouse';

  @override
  String get stockEditWarehouse => 'Edit warehouse';

  @override
  String get stockName => 'Name';

  @override
  String get stockType => 'Type';

  @override
  String get stockInCharge => 'In charge';

  @override
  String get stockNobody => 'Nobody';

  @override
  String get stockOwner => 'Owner';

  @override
  String get stockAddress => 'Address';

  @override
  String get stockSellsOnlineSub => 'Its units count as available online';

  @override
  String get stockDefaultOutlet => 'Default for this outlet';

  @override
  String get stockDefaultSub => 'Stock in and orders use it first';

  @override
  String syncCopyOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String syncCopyProducts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String syncCopyUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units',
      one: '1 unit',
    );
    return '$_temp0';
  }

  @override
  String syncCopyBulk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bulk requests',
      one: '1 bulk request',
    );
    return '$_temp0';
  }

  @override
  String syncCopyMb(int count) {
    return '$count MB';
  }

  @override
  String syncUpdateBold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes are safe on this phone',
      one: '1 change is safe on this phone',
    );
    return '$_temp0';
  }

  @override
  String syncUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units',
      one: '1 unit',
    );
    return '$_temp0';
  }

  @override
  String get syncEntryVerification => 'Verification';

  @override
  String get syncEntryOrder => 'order';

  @override
  String syncEntryOrderNo(String id) {
    return 'order #$id';
  }

  @override
  String syncEntryReceivedBy(String name) {
    return 'received by $name';
  }

  @override
  String get syncEntryCancelled => 'Cancelled';

  @override
  String syncEntryPayment(String amount) {
    return 'Payment $amount';
  }

  @override
  String get syncEntryHandedOver => 'Handed over';

  @override
  String syncEntryAtompay(String order) {
    return 'AtomPay $order';
  }

  @override
  String get syncEntryDelivery => 'Delivery';

  @override
  String syncEntryDeal(String number) {
    return 'deal $number';
  }

  @override
  String syncEntryRequest(String id) {
    return 'request #$id';
  }

  @override
  String syncEntryStockIn(String qty) {
    return 'Stock in · $qty';
  }

  @override
  String syncEntrySerials(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serials',
      one: '1 serial',
    );
    return '$_temp0';
  }

  @override
  String get syncEntryStockOut => 'Stock out';

  @override
  String get syncEntryBackIn => 'Back into stock';

  @override
  String syncEntryUnit(String id) {
    return 'unit #$id';
  }

  @override
  String syncEntryMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count units',
      one: 'Moved 1 unit',
    );
    return '$_temp0';
  }

  @override
  String syncEntryTo(String name) {
    return 'to $name';
  }

  @override
  String syncLimitAgo(int days, String why) {
    return '$days days ago, $why';
  }

  @override
  String get syncYourBrand => 'your brand';

  @override
  String get ordersStagePending => 'Pending';

  @override
  String get ordersStageConfirming => 'Confirming';

  @override
  String get ordersStageProcessing => 'Processing';

  @override
  String get ordersStageDelivered => 'Delivered';

  @override
  String get ordersStageCompleted => 'Completed';

  @override
  String get ordersStageCancelled => 'Cancelled';

  @override
  String get ordersPayUnpaid => 'Unpaid';

  @override
  String get ordersPayPart => 'Part paid';

  @override
  String get ordersPayPaid => 'Paid';

  @override
  String get ordersPayNotNeeded => 'Not needed';

  @override
  String get ordersCancelUnreachable => 'Customer can’t be reached';

  @override
  String get ordersCancelChangedMind => 'Customer changed their mind';

  @override
  String get ordersCancelOutOfStock => 'Out of stock';

  @override
  String get ordersCancelNoDelivery => 'We don’t deliver there';

  @override
  String get ordersMethodCod => 'Cash on delivery';

  @override
  String get ordersMethodBank => 'Bank transfer';

  @override
  String get ordersMethodJazzcash => 'JazzCash';

  @override
  String get ordersMethodEasypaisa => 'Easypaisa';

  @override
  String get ordersMethodCash => 'Cash';

  @override
  String get ordersMethodCheque => 'Cheque';

  @override
  String get ordersPayNothingLeft => 'Nothing is left to pay.';

  @override
  String get ordersPayEnterAmount => 'Enter an amount';

  @override
  String get ordersPayTooMuch => 'More than what is left to pay.';

  @override
  String get ordersDeliverScanFirst => 'Scan the serial first';

  @override
  String get ordersSayWhoReceived => 'Say who received it';

  @override
  String get ordersDeliverEnterCash => 'Enter the cash collected';

  @override
  String get ordersDeliverTooMuch => 'More than what is left to pay';

  @override
  String get ordersPickHowPaid => 'Pick how they paid';

  @override
  String get ordersTheCustomer => 'the customer';

  @override
  String get ordersCallCustomer => 'Call the customer';

  @override
  String ordersNextCallBody(String name) {
    return 'Call $name to confirm the order, the colour and the address. Start confirming so the team knows you are on it.';
  }

  @override
  String get ordersStartConfirming => 'Start confirming';

  @override
  String get ordersConfirmOrder => 'Confirm order';

  @override
  String get ordersNextConfirmBodyHeld =>
      'Spoke to the customer? Confirm the order and one unit is held for it.';

  @override
  String get ordersNextConfirmBody =>
      'Spoke to the customer? Confirm the order so it can go out.';

  @override
  String get ordersMarkDelivered => 'Mark delivered';

  @override
  String get ordersNextDeliverBody =>
      'Note who received it, the serial and a proof photo. Cash collected on delivery is recorded too.';

  @override
  String get ordersRecordPayment => 'Record payment';

  @override
  String ordersNextPayBody(String amount) {
    return '$amount is still to collect. Complete the order once it is paid in full.';
  }

  @override
  String get ordersComplete => 'Complete';

  @override
  String get ordersNextCompleteBody =>
      'Delivered and paid in full. Complete the order to close it.';

  @override
  String get ordersStepNew => 'New order';

  @override
  String ordersDayTime(String day, String time) {
    return '$day, $time';
  }

  @override
  String get ordersYou => 'you';

  @override
  String get ordersSubHeldOnWay => 'Unit held, on its way';

  @override
  String get ordersSubOnWay => 'On its way';

  @override
  String get ordersSubSerialProof => 'Serial and proof';

  @override
  String get ordersPaidInFull => 'Paid in full';

  @override
  String ordersSubPlaced(String when) {
    return 'Placed $when';
  }

  @override
  String ordersSubCalled(String when) {
    return 'Called $when';
  }

  @override
  String ordersSubUnitHeld(String day) {
    return 'Unit held · $day';
  }

  @override
  String ordersSubConfirmed(String when) {
    return 'Confirmed $when';
  }

  @override
  String ordersSubReceivedBy(String name) {
    return 'Received by $name';
  }

  @override
  String ordersSubDelivered(String day) {
    return 'Delivered $day';
  }

  @override
  String ordersSubCompleted(String day) {
    return 'Completed $day';
  }

  @override
  String ordersEvMovedTo(String to) {
    return 'Moved to $to';
  }

  @override
  String ordersEvMovedFromTo(String from, String to) {
    return 'Moved from $from to $to';
  }

  @override
  String get ordersPlacedOnline => 'Order placed on atomshop.pk';

  @override
  String get ordersEvPlaced => 'Order placed';

  @override
  String get ordersEvStarted => 'Started confirming';

  @override
  String get ordersEvConfirmedHeld =>
      'Confirmed, moved to Processing, 1 unit held';

  @override
  String get ordersEvConfirmed => 'Confirmed, moved to Processing';

  @override
  String ordersEvDeliveredTo(String name) {
    return 'Delivered to $name';
  }

  @override
  String ordersEvCollected(String amount) {
    return '$amount collected';
  }

  @override
  String get ordersEvCompleted => 'Completed, paid in full';

  @override
  String ordersEvCancelledWhy(String why) {
    return 'Cancelled: $why';
  }

  @override
  String ordersEvPayment(String amount, String method) {
    return 'Payment $amount by $method';
  }

  @override
  String ordersRef(String ref) {
    return 'ref $ref';
  }

  @override
  String ordersRecordedBy(String name) {
    return 'recorded by $name';
  }

  @override
  String ordersReceiptPaidFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paid in full · $count payments',
      one: 'Paid in full · 1 payment',
    );
    return '$_temp0';
  }

  @override
  String get ordersReceiptNotPaid => 'Not paid yet';

  @override
  String ordersReceiptPartLeft(String amount) {
    return 'Part paid · $amount left';
  }

  @override
  String get ordersCashReceipt => 'Cash receipt';

  @override
  String ordersOrderNumber(String number) {
    return 'Order $number';
  }

  @override
  String get ordersCustomer => 'Customer';

  @override
  String get ordersItem => 'Item';

  @override
  String get ordersSerial => 'Serial';

  @override
  String get ordersLeftToPay => 'Left to pay';

  @override
  String get ordersSoldOn => 'Sold on atomshop.pk';

  @override
  String ordersReceiptMsgHead(String brand, String number) {
    return '$brand: cash receipt $number';
  }

  @override
  String ordersSerialValue(String serial) {
    return 'Serial $serial';
  }

  @override
  String ordersTotalValue(String amount) {
    return 'Total $amount';
  }

  @override
  String ordersQty(int qty) {
    return 'Qty $qty';
  }

  @override
  String get atompayStepApproving => 'Atomshop approving';

  @override
  String get atompayStepSeller => 'Finding a seller';

  @override
  String get atompayHandOver => 'Hand over';

  @override
  String get atompayHandedOver => 'Handed over';

  @override
  String get atompayStepPaid => 'Paid to you';

  @override
  String get atompayStepCancelled => 'Not approved';

  @override
  String get bulkStatusNew => 'New';

  @override
  String get bulkStatusChangeAsked => 'Change asked';

  @override
  String get bulkStatusQuoted => 'Quoted';

  @override
  String get bulkStatusDeclined => 'Declined';

  @override
  String get bulkStatusAccepted => 'Accepted';

  @override
  String get bulkStatusContacted => 'Contacted';

  @override
  String get bulkStatusWon => 'Won';

  @override
  String get bulkStatusLost => 'Lost';

  @override
  String get bulkStatusBackToNew => 'Back to new';

  @override
  String get bulkDaysToday => 'today';

  @override
  String get bulkDaysTomorrow => 'tomorrow';

  @override
  String bulkDaysLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String bulkDaysCount(int days) {
    return '$days days';
  }

  @override
  String get bulkActReply => 'Reply';

  @override
  String get bulkActSendQuote => 'Send quote';

  @override
  String get bulkActFollowUp => 'Follow up';

  @override
  String get bulkActOpenDeal => 'Open deal';

  @override
  String get bulkActView => 'View';

  @override
  String get bulkLostReasonNeeded => 'Choose why it was lost.';

  @override
  String get bulkQpNoLines => 'Add at least one line.';

  @override
  String bulkQpMaxLines(String max) {
    return 'A quote can have up to $max lines.';
  }

  @override
  String bulkQpLineProduct(int n) {
    return 'Line $n: choose a product.';
  }

  @override
  String bulkQpLineQty(int n, String max) {
    return 'Line $n: enter a quantity from 1 to $max.';
  }

  @override
  String bulkQpLinePrice(int n) {
    return 'Line $n: enter the unit price.';
  }

  @override
  String bulkQpLinePriceHigh(int n) {
    return 'Line $n: the unit price is too high.';
  }

  @override
  String bulkQpLineDiscount(int n) {
    return 'Line $n: the discount is 0 to 100%.';
  }

  @override
  String get bulkQpDelivery => 'Enter a delivery charge up to Rs 5,000,000.';

  @override
  String get bulkQpValidNeeded => 'Choose until when the quote is valid.';

  @override
  String get bulkQpValidPast => 'Valid until is today or later.';

  @override
  String get bulkQpAdvance => 'The advance is 0 to 100%.';

  @override
  String get bulkQpNotes => 'Notes are up to 500 letters.';

  @override
  String get bulkQpTooLarge =>
      'This quote is too large. Split it into smaller deals.';

  @override
  String bulkSerialCount(String title, String serials, int qty) {
    return '$title: $serials serials for $qty units. Enter one per unit, or none.';
  }

  @override
  String bulkSerialTwice(String title) {
    return '$title: a serial is listed twice.';
  }

  @override
  String get bulkDeliverWhoNeeded => 'Enter who received the units.';

  @override
  String get bulkDeliverWhoLong => 'Received by is up to 100 letters.';

  @override
  String get bulkDeliverNoteLong => 'The note is up to 500 letters.';

  @override
  String get bulkPayAmountNeeded => 'Enter the amount received.';

  @override
  String bulkPayOverBalance(String amount) {
    return 'More than the balance of $amount';
  }

  @override
  String get bulkPayAdvance => 'Advance';

  @override
  String get bulkPayHalf => 'Half';

  @override
  String get bulkPayFull => 'Full balance';

  @override
  String get bulkMethodBank => 'Bank transfer';

  @override
  String get bulkMethodCash => 'Cash';

  @override
  String get bulkMethodCheque => 'Cheque';

  @override
  String get bulkTermsEach => 'Before each delivery';

  @override
  String get bulkTermsLast => 'Before the last delivery';

  @override
  String get bulkDealOpen => 'Open';

  @override
  String get bulkDealDelivering => 'Delivering';

  @override
  String get bulkDealDelivered => 'Delivered';

  @override
  String get bulkDealPaid => 'Paid';

  @override
  String get bulkDealClosed => 'Closed';

  @override
  String get bulkQuoteDraft => 'Draft';

  @override
  String get bulkQuoteSuperseded => 'Superseded';

  @override
  String get bulkQuoteExpired => 'Expired';

  @override
  String get bulkQuoteSent => 'Sent';

  @override
  String bulkWhenToday(String time) {
    return 'Today $time';
  }

  @override
  String bulkWhenYesterday(String time) {
    return 'Yesterday $time';
  }

  @override
  String get bulkAgoNow => 'just now';

  @override
  String bulkAgoMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String bulkAgoHours(int hours) {
    return '$hours h ago';
  }

  @override
  String get bulkAgoYesterday => 'yesterday';

  @override
  String bulkStepOf(int reached, int total, String label) {
    return 'Step $reached of $total: $label';
  }

  @override
  String get bulkVerifiedSeller => 'Verified seller';

  @override
  String get bulkNeededBy => 'Needed by';

  @override
  String bulkNeedByDate(String lead, String date) {
    return '$lead $date';
  }

  @override
  String get bulkCall => 'Call';

  @override
  String get bulkWhatsApp => 'WhatsApp';

  @override
  String get bulkNotFoundBody =>
      'It may have been removed, or it belongs to another outlet.';

  @override
  String get bulkFree => 'Free';

  @override
  String get bulkPickHint => 'Pick a request or deal to see it here';

  @override
  String get bulkTitle => 'Bulk deals';

  @override
  String get bulkAskAtom => 'Ask Atom';

  @override
  String get bulkSearch => 'Search';

  @override
  String bulkTabBadge(String label, int badge) {
    return '$label, $badge new';
  }

  @override
  String get bulkTabSellers => 'Seller requests';

  @override
  String get bulkTabWebsite => 'Website';

  @override
  String get bulkTabDeals => 'Deals';

  @override
  String get bulkKpiNew => 'New requests';

  @override
  String get bulkKpiNewNote => 'Waiting for your reply';

  @override
  String get bulkKpiQuotesOut => 'Quotes out';

  @override
  String bulkKpiQuotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quotes',
      one: '1 quote',
    );
    return '$_temp0';
  }

  @override
  String bulkKpiExpireSoon(int count) {
    return '$count expire this week';
  }

  @override
  String get bulkKpiWon => 'Won this month';

  @override
  String bulkKpiDeals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deals',
      one: '1 deal',
    );
    return '$_temp0';
  }

  @override
  String bulkKpiWinRate(String rate) {
    return 'win rate $rate%';
  }

  @override
  String get bulkKpiCollect => 'Still to collect';

  @override
  String bulkKpiOpenDeals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'On $count open deals',
      one: 'On 1 open deal',
    );
    return '$_temp0';
  }

  @override
  String bulkKpiChangeAsked(int count) {
    return '$count asked for a change';
  }

  @override
  String get bulkKpiOpenNow => 'Open now';

  @override
  String get bulkSellersNote =>
      'Verified Atomshop sellers asking you for stock for their shops. They answer your quote in their app; the seller pays you directly. Quote before their \"needed by\" date.';

  @override
  String get bulkSellersNoteBold =>
      'Verified Atomshop sellers asking you for stock';

  @override
  String bulkChangeAskedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sellers asked for a change to your quote. See Quoted.',
      one: 'A seller asked for a change to your quote. See Quoted.',
    );
    return '$_temp0';
  }

  @override
  String get bulkEmptySellersNew => 'No new seller requests';

  @override
  String get bulkEmptyAccepted => 'No accepted quotes yet';

  @override
  String get bulkEmptyDeclined => 'Nothing declined';

  @override
  String get bulkEmptyHere => 'Nothing here';

  @override
  String get bulkEmptySellersBody =>
      'When an Atomshop seller asks you for stock, it shows here.';

  @override
  String get bulkSellersFooter =>
      'A seller can have up to 10 open requests. Atomshop\'s commission on seller deals is shown on the request before you send a quote.';

  @override
  String bulkValidUntil(String date) {
    return 'valid until $date';
  }

  @override
  String bulkHopingFor(String price) {
    return 'Hoping for $price a unit';
  }

  @override
  String bulkYourPrice(String price) {
    return 'your price $price';
  }

  @override
  String bulkSellerSaid(String reason) {
    return 'Seller said: $reason';
  }

  @override
  String get bulkActSendNewQuote => 'Send new quote';

  @override
  String get bulkOpen => 'Open';

  @override
  String get bulkTypedTag => 'Not in your catalogue · typed by the seller';

  @override
  String get bulkEmptyWebNew => 'No new enquiries';

  @override
  String get bulkEmptyWebBody =>
      'They appear here the moment a buyer asks for a quote.';

  @override
  String get bulkWebFooter =>
      'Website buyers asking atomshop.pk for a bulk price. Reply fast: the first brand to call usually wins.';

  @override
  String get bulkDealStatus => 'Deal status';

  @override
  String get bulkAny => 'Any';

  @override
  String bulkStatusFilter(String status) {
    return 'Status: $status';
  }

  @override
  String get bulkEmptyDeals => 'No deals yet';

  @override
  String get bulkEmptyDealsHere => 'No deals here';

  @override
  String get bulkEmptyDealsBody =>
      'A deal opens when a buyer or a seller says yes to your quote.';

  @override
  String bulkWonOn(String date) {
    return 'Won $date';
  }

  @override
  String get bulkSellerTag => 'Seller';

  @override
  String bulkUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units',
      one: '1 unit',
    );
    return '$_temp0';
  }

  @override
  String bulkDeliveredOf(int done, int units) {
    return 'Delivered $done of $units';
  }

  @override
  String bulkPaidAmount(String amount) {
    return 'Paid $amount';
  }

  @override
  String bulkPercentPaid(int pct) {
    return '$pct percent paid';
  }

  @override
  String bulkAmountDue(String amount) {
    return '$amount due';
  }

  @override
  String get bulkPaidInFull => 'Paid in full';

  @override
  String get bulkDeliver => 'Deliver';

  @override
  String get bulkRecordPayment => 'Record payment';

  @override
  String get acctBeingChecked => 'Being checked';

  @override
  String get acctReadOnly => 'Read-only';

  @override
  String get acctLate => 'Late';

  @override
  String get acctBillWaiting => 'Bill waiting';

  @override
  String get acctNoPlanYet => 'No plan yet';

  @override
  String get acctFreeTrial => 'Free trial';

  @override
  String get acctPaid => 'Paid';

  @override
  String acctFreeUntil(String day) {
    return 'Free until $day';
  }

  @override
  String acctFreeTrialUntil(String day) {
    return 'Free trial until $day';
  }

  @override
  String acctPaidUntilDay(String day) {
    return 'Paid until $day';
  }

  @override
  String get acctBasicPackage => 'Basic package';

  @override
  String get acctMultiOutlet => 'Multi-outlet';

  @override
  String get acctSingleOutlet => 'Single outlet';

  @override
  String acctOutletCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outlets',
      one: '1 outlet',
    );
    return '$_temp0';
  }

  @override
  String get acctEndsToday => 'Ends today';

  @override
  String acctDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get acctFree => 'Free';

  @override
  String acctFreeTrialLeft(String left) {
    return 'Free trial · $left';
  }

  @override
  String acctTrialStops(String day) {
    return 'Trial stops $day';
  }

  @override
  String get acctOn => 'On';

  @override
  String get acctOff => 'Off';

  @override
  String get acctEnded => 'Ended';

  @override
  String acctSwitchedOffUntil(String day) {
    return 'Switched off · works until $day';
  }

  @override
  String get acctBill => 'Bill';

  @override
  String acctRenewal(String month) {
    return '$month renewal';
  }

  @override
  String get acctCancelled => 'Cancelled';

  @override
  String get acctPartPaid => 'Part paid';

  @override
  String get acctToPay => 'To pay';

  @override
  String get acctReceived => 'Received';

  @override
  String get acctNotFound => 'Not found';

  @override
  String get acctReversed => 'Reversed';

  @override
  String get acctBank => 'Bank';

  @override
  String get acctJazzCash => 'JazzCash';

  @override
  String get acctEasypaisa => 'Easypaisa';

  @override
  String get acctCash => 'Cash';

  @override
  String get acctCheque => 'Cheque';

  @override
  String get acctPayNoMethod => 'Choose how you paid';

  @override
  String get acctPayNoAmount => 'Type the amount you paid';

  @override
  String get acctPayTooLarge => 'That amount is too large';

  @override
  String get acctPayNoDay => 'Choose the day you paid';

  @override
  String get acctPayFutureDay => 'The day you paid can\'t be in the future';

  @override
  String get acctPayRefTooLong =>
      'The transaction ID is too long (100 characters at most)';

  @override
  String get acctPayNoScreenshot => 'Add the payment screenshot';

  @override
  String get acctOneYear => '1 year';

  @override
  String acctMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get acctMonthly => 'Monthly';

  @override
  String get acctYearly => 'Yearly';

  @override
  String acctEveryMonths(int count) {
    return 'Every $count months';
  }

  @override
  String get acctShopNeedOnePay => 'Keep at least one way for customers to pay';

  @override
  String get acctShopNeedBankName =>
      'Enter the bank name, or switch bank transfer off';

  @override
  String get acctShopNeedBankTitle =>
      'Enter the account title, or switch bank transfer off';

  @override
  String get acctShopNeedIban => 'Enter the IBAN, or switch bank transfer off';

  @override
  String get acctShopBadIban =>
      'An IBAN looks like PK36 MEZN 0002 4501 0123 4567';

  @override
  String get acctShopNeedWallet => 'Enter a JazzCash or Easypaisa number';

  @override
  String get acctShopBadMobile => 'A mobile number looks like 0300 1234567';

  @override
  String get acctShopPickHours => 'Pick 2, 4, 8 or 24 hours';

  @override
  String get acctShopLowStockRange => 'Between 0 and 100 units';

  @override
  String get acctShopNoteTooLong => 'Up to 200 characters';

  @override
  String get acctShopPickMinutes => 'Pick 15 or 30 minutes';

  @override
  String get acctPeriodToday => 'Today';

  @override
  String get acctPeriodMonth => 'This month';

  @override
  String get acctPeriodYear => 'This year';

  @override
  String get acctPeriodAll => 'All time';

  @override
  String get acctPeriodCustom => 'Choose dates';

  @override
  String get acctTotal => 'Total';

  @override
  String acctPdfFooterMade(String when) {
    return 'Atombrand · Made $when';
  }

  @override
  String get acctFeatInventory1 =>
      'Stock in, adjust and move units between warehouses';

  @override
  String get acctFeatInventory2 => 'Orders hold a unit while you confirm them';

  @override
  String get acctFeatInventory3 =>
      'Out-of-stock products show as such on atomshop.pk';

  @override
  String get acctFeatTeam1 =>
      'Order handler, Bulk sales, Stock keeper, Marketing, Accountant';

  @override
  String get acctFeatTeam2 => 'Each person sees only their outlets';

  @override
  String get acctFeatTeam3 => 'Switch anyone off in a tap';

  @override
  String get acctFeatAskAtom1 => 'Which orders wait to be confirmed';

  @override
  String get acctFeatAskAtom2 => 'Which quotes run out this week';

  @override
  String get acctFeatAskAtom3 => 'What is running low';

  @override
  String get acctFeatAlerts1 =>
      'A new order or bulk request the moment it arrives';

  @override
  String get acctFeatAlerts2 => 'AtomPay units to hand over';

  @override
  String get acctFeatAlerts3 => 'Quiet 10 PM to 8 AM';

  @override
  String get acctFeatOffline1 =>
      'Orders, stock and payments work with no signal';

  @override
  String get acctFeatOffline2 =>
      'Changes wait on the phone and send when you are back';

  @override
  String get acctFeatOffline3 => 'A copy of your records, locked with your PIN';

  @override
  String acctAddonTrialStarted(String name) {
    return '$name is on: free trial started';
  }

  @override
  String acctAddonIsOff(String name) {
    return '$name is off';
  }

  @override
  String acctAddonStopsAtEnd(String name) {
    return '$name stops at the end of the period';
  }

  @override
  String acctBillReady(String number) {
    return 'Bill $number is ready';
  }

  @override
  String acctAddonIsOn(String name) {
    return '$name is on';
  }

  @override
  String get acctAddonNotSold => 'This add-on isn\'t sold to brands';

  @override
  String acctAddonTryTitle(int count) {
    return 'Try it free for $count days';
  }

  @override
  String get acctAddonTrySub =>
      'Then it is added to your bill, unless you switch it off during the trial.';

  @override
  String get acctAddonTryCta => 'Try free';

  @override
  String get acctAddonPayTitle => 'Switch on and pay now';

  @override
  String get acctAddonPaySub =>
      'A bill for the rest of this period, then it renews with your plan.';

  @override
  String get acctSwitchOn => 'Switch on';

  @override
  String get acctAddonKeepOn => 'Keep it on';

  @override
  String get acctAddonCarriesOn => 'It carries on with your plan.';

  @override
  String acctAddonWasStopping(String day) {
    return 'It was going to stop on $day. Keep it and it renews with your plan.';
  }

  @override
  String get acctAddonOffTitle => 'Switch it off';

  @override
  String get acctAddonOffTrial => 'The free trial stops now.';

  @override
  String get acctAddonOffLegacy =>
      'It stops now; switching it on again later starts a bill.';

  @override
  String get acctAddonOffPeriodEnd =>
      'It works until the period ends, then it isn\'t renewed.';

  @override
  String acctAddonOffUntil(String day) {
    return 'It works until $day, then it isn\'t renewed.';
  }

  @override
  String get acctSwitchOff => 'Switch off';

  @override
  String acctAddonFreeUntilDot(String day) {
    return 'Free until $day.';
  }

  @override
  String get acctAddonAfterLegacy =>
      'After that it joins your bill, or you can switch it off.';

  @override
  String get acctAddonEnded =>
      'It ended: you can still see what is there, but not change it.';

  @override
  String get acctPlanOn => 'Your plan is on.';

  @override
  String acctBillReadyDot(String number) {
    return 'Bill $number is ready.';
  }

  @override
  String get acctRenewTitle => 'Renew or change your plan';

  @override
  String get acctHowLong => 'How long';

  @override
  String get acctAddons => 'Add-ons';

  @override
  String get acctYourBill => 'Your bill';

  @override
  String get acctChangePeriod => 'Change the period or add-ons';

  @override
  String get acctGetBill => 'Get my bill';

  @override
  String acctGetBillTotal(String total) {
    return 'Get my bill · $total';
  }

  @override
  String acctNotSoldFor(String period) {
    return 'Not sold for $period';
  }

  @override
  String acctPriceFor(String price, String period) {
    return '$price for $period';
  }

  @override
  String get acctSpecialPrice => 'Special price';

  @override
  String get acctYourCredit => 'Your credit';

  @override
  String get acctDailyTitle => 'Daily summary';

  @override
  String get acctDailySend => 'Send me a daily summary';

  @override
  String get acctDailySendSub => 'On WhatsApp and in the app, at 9:00 am';

  @override
  String get acctDailyTellsAbout => 'It tells you about';

  @override
  String get acctDailyConfirm => 'Orders to confirm';

  @override
  String get acctDailyConfirmSub => 'New orders still waiting, oldest first';

  @override
  String get acctDailyQuotes => 'Quotes running out';

  @override
  String get acctDailyQuotesSub => 'Sent quotes that end within 2 days';

  @override
  String get acctDailyHandOverSub => 'Units Atomshop gave to a seller';

  @override
  String get acctDailyLow => 'Running low';

  @override
  String get acctDailyLowSub => 'Products at or under your low-stock number';

  @override
  String get acctDailyYouSee => 'You see';

  @override
  String acctDailySample(String name, String brand) {
    return 'Good morning, $name. $brand today: 3 orders to confirm (oldest 6 hours), 1 quote runs out tomorrow, 1 AtomPay unit to hand over.';
  }

  @override
  String get acctDailyThere => 'there';

  @override
  String get acctDailyYourBrand => 'Your brand';

  @override
  String get acctDailyNothing => 'Nothing to report? No message that day.';

  @override
  String get acctDailySoon => 'Daily summary is coming soon';

  @override
  String get acctDailySoonBody =>
      'One message each morning with the orders to confirm, quotes running out and units to hand over.';

  @override
  String get acctPaidOn => 'Paid on';

  @override
  String get acctPaymentSent =>
      'Payment sent. It shows as Being checked until Atomshop finds it.';

  @override
  String get acctIvePaid => 'I\'ve paid';

  @override
  String get acctSendPayment => 'Send payment';

  @override
  String acctWalletNumber(String wallet) {
    return '$wallet number';
  }

  @override
  String get acctAccountTitle => 'Account title';

  @override
  String get acctIban => 'IBAN';

  @override
  String get acctHowToPay => 'How to pay Atomshop';

  @override
  String get acctAskForAccount => 'Ask Atomshop for the account to pay into.';

  @override
  String get acctAmount => 'Amount';

  @override
  String get acctNotForOneBill => 'Not for one bill';

  @override
  String get acctWhichBill => 'Which bill?';

  @override
  String get acctTransactionId => 'Transaction ID';

  @override
  String get acctOptional => 'optional';

  @override
  String get acctTransactionIdHint => 'From your bank or wallet message';

  @override
  String get acctPayCheckedNote =>
      'Your payment shows as Being checked until Atomshop finds it. You keep using everything meanwhile.';

  @override
  String get acctScreenshotAdded => 'Screenshot added · change';

  @override
  String get acctAddonsFollow => 'add-ons follow the same period';

  @override
  String acctPayAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get acctPlan => 'Plan';

  @override
  String get acctNoneYet => 'None yet';

  @override
  String get acctPaidUntil => 'Paid until';

  @override
  String get acctAmountDue => 'Amount due';

  @override
  String get acctNothingToPay => 'Nothing to pay';

  @override
  String acctOpenBills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open bills',
      one: '1 open bill',
    );
    return '$_temp0';
  }

  @override
  String get acctCredit => 'Credit';

  @override
  String acctSpecialPricePct(String pct) {
    return '$pct special price';
  }

  @override
  String get acctNoSpecialPrice => 'No special price';

  @override
  String acctDueOn(String day) {
    return 'due $day';
  }

  @override
  String get acctPay => 'Pay';

  @override
  String acctHowLongLine(String periods) {
    return 'How long: $periods';
  }

  @override
  String get acctRenewSub => 'Pick add-ons, see the total, get my bill';

  @override
  String get acctYourPayments => 'Your payments';

  @override
  String get acctReceipt => 'Receipt';

  @override
  String get acctBills => 'Bills';

  @override
  String get acctPdf => 'PDF';

  @override
  String get acctPricesNote =>
      'Prices come from Atomshop\'s price list. Switching an add-on off keeps it until the period ends.';

  @override
  String acctPeriodsOr(String list, String last) {
    return '$list or $last months';
  }

  @override
  String acctCopyLabel(String label) {
    return 'Copy $label';
  }

  @override
  String acctCopied(String label) {
    return '$label copied';
  }

  @override
  String get acctPdfFailed =>
      'Couldn\'t make the PDF on this phone. Try again.';

  @override
  String get acctDownloadsOnPortal =>
      'Downloads are on the brand portal for now.';

  @override
  String get acctReport => 'Report';

  @override
  String get acctReportMissing => 'This report isn\'t there for your brand';

  @override
  String get acctExcel => 'Excel';

  @override
  String get acctExcelOnline => 'Excel · online';

  @override
  String accountReportOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
      zero: 'No orders',
    );
    return '$_temp0';
  }

  @override
  String accountReportStillDue(String amount) {
    return '$amount still due';
  }

  @override
  String accountReportUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units',
      one: '1 unit',
      zero: 'No units',
    );
    return '$_temp0';
  }

  @override
  String accountReportDeals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deals',
      one: '1 deal',
      zero: 'No deals',
    );
    return '$_temp0';
  }

  @override
  String get accountReportNoneToday => 'None today';

  @override
  String accountReportMethodIs(String method) {
    return 'Method: $method';
  }

  @override
  String get accountReportMethodAny => 'Any';

  @override
  String get accountReportWhichMethod => 'Which method?';

  @override
  String get accountNoPaymentsYet => 'No payments yet';

  @override
  String get accountNoBillsYet => 'No bills yet';

  @override
  String acctOutletIs(String outlet) {
    return 'Outlet: $outlet';
  }

  @override
  String get acctNothingThisPeriod => 'Nothing for this period';

  @override
  String get acctTryAnotherPeriod => 'Try another period.';

  @override
  String acctMadeAt(String when) {
    return 'Made $when';
  }

  @override
  String acctDateRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String acctSalesPeriod(String period) {
    return 'Sales · $period';
  }

  @override
  String get acctCashOrders => 'Cash orders';

  @override
  String get acctPaymentsReceived => 'Payments received';

  @override
  String get acctAtompayPaid => 'AtomPay, paid to you';

  @override
  String get acctBulkWon => 'Bulk deals won';

  @override
  String get acctLast6Months => 'Last 6 months';

  @override
  String get acctNoReports => 'No reports for your role';

  @override
  String get acctNoReportsBody => 'Ask the owner if you need one.';

  @override
  String get acctReportsOffline =>
      'Offline: reports need internet. Pull down to try again when you are back.';

  @override
  String get acctReportsCanExport =>
      'Open any report, then share it as a PDF on WhatsApp or download Excel.';

  @override
  String get acctReportsNoExport =>
      'Your role can open reports but not download them.';

  @override
  String get acctOutlet => 'Outlet';

  @override
  String get acctWhichOutlet => 'Which outlet?';

  @override
  String acctMonthSemantics(String month, String cash, String received) {
    return '$month: cash orders $cash, received $received';
  }

  @override
  String get acctShopSaved => 'Shop settings saved';

  @override
  String get acctShopHowPaid => 'How customers pay you';

  @override
  String get acctShopCod => 'Cash on delivery';

  @override
  String get acctShopCodSub => 'Collected when the unit is handed over';

  @override
  String get acctShopBank => 'Bank transfer before dispatch';

  @override
  String get acctShopBankSub => 'Shown to customers at checkout';

  @override
  String get acctShopWallet => 'JazzCash or Easypaisa';

  @override
  String get acctShopWalletSub => 'Paid to your number before dispatch';

  @override
  String get acctBankName => 'Bank name';

  @override
  String get acctShopCashAlways =>
      'Cash is always allowed when you record a payment.';

  @override
  String get acctShopOrdersPortal => 'Orders and the portal';

  @override
  String get acctShopConfirmWithin => 'Confirm new orders within';

  @override
  String acctHours(int count) {
    return '$count hours';
  }

  @override
  String get acctShopConfirmNote =>
      'Later than this, the task on Home turns red.';

  @override
  String get acctShopIdle => 'Sign out when idle for';

  @override
  String acctMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get acctShopIdleNote => 'For the brand portal on the web.';

  @override
  String get acctShopLowAt => 'Running low at';

  @override
  String get acctShopLowAtNote => '0–100 units';

  @override
  String get acctShopAtomLanguage => 'Atom language';

  @override
  String get acctShopAtomAnswersIn => 'Atom answers in';

  @override
  String get acctShopReceiptNote => 'Receipt note';

  @override
  String get acctShopReceiptNoteLimit => 'up to 200 characters';

  @override
  String get acctShopReceiptHint =>
      '7-day replacement on factory faults. Keep this receipt.';

  @override
  String get acctLangEnglish => 'English';

  @override
  String get acctLangRomanUrdu => 'Roman Urdu';

  @override
  String get acctLangAuto => 'Auto';

  @override
  String get askAtomName => 'Atom';

  @override
  String get askAtomStatus => 'Knows your brand · answers in seconds';

  @override
  String get askAtomStatusOffline => 'Needs internet to answer';

  @override
  String get askAtomNoticed => 'Atom noticed';

  @override
  String get askAtomAsk => 'Ask';

  @override
  String get askAtomRecent => 'Recent';

  @override
  String get askAtomHowFix => 'How to fix it';

  @override
  String get askAtomConfirm => 'Confirm';

  @override
  String get askAtomAskAtomshop => 'Ask Atomshop';

  @override
  String get askAtomHelpfulQ => 'Helpful?';

  @override
  String get askAtomHelpful => 'Helpful';

  @override
  String get askAtomNotHelpful => 'Not helpful';

  @override
  String get askAtomThanks => 'Thanks for telling us.';

  @override
  String get askAtomLanguageNote =>
      'Atom answers the way you write: English, Roman Urdu or اردو.';

  @override
  String get askAtomHint => 'Ask, or tap the mic';

  @override
  String get askAtomHintOffline => 'Atom needs internet';

  @override
  String get askAtomSend => 'Send';

  @override
  String get askAtomWhatsAppUrgent => 'Urgent? WhatsApp Atomshop';

  @override
  String askAtomSentTo(String code) {
    return 'Sent to Atomshop support as $code. Their reply comes to your notifications.';
  }

  @override
  String get askAtomMorning => 'Good morning';

  @override
  String get askAtomAfternoon => 'Good afternoon';

  @override
  String get askAtomEvening => 'Good evening';

  @override
  String askAtomHello(String part) {
    return '$part. What do you need?';
  }

  @override
  String askAtomHelloName(String part, String name) {
    return '$part, $name. What do you need?';
  }

  @override
  String get askAtomQOrders => 'Which orders are waiting to be confirmed?';

  @override
  String get askAtomQQuotes => 'Which quotes run out this week?';

  @override
  String get askAtomQLow => 'What is running low?';

  @override
  String get askAtomQSales => 'Sales this month';

  @override
  String get askAtomQRequests => 'Which seller requests are new?';

  @override
  String get askAtomQAtompay => 'Is mahine kitni AtomPay sales hui?';

  @override
  String get askAtomShowThem => 'Show them';

  @override
  String get askAtomMic => 'Speak your question';

  @override
  String get askAtomMicStop => 'Stop listening';

  @override
  String get askAtomListening => 'Listening…';

  @override
  String get askAtomMicDenied =>
      'Atom can\'t hear you: the microphone is off for Brand Partner. Allow it in your phone\'s settings, or type your question.';

  @override
  String get askAtomMicUnavailable =>
      'Voice isn\'t available on this phone. Type your question instead.';

  @override
  String get applyTypeManufacturer => 'Manufacturer';

  @override
  String get applyTypeDistributor => 'Official distributor';

  @override
  String get applyTypeImporter => 'Authorised importer';

  @override
  String get applyTypeOther => 'Other';

  @override
  String get commonBeingBuilt => 'This screen is being built.';

  @override
  String syncPaidNow(String amount) {
    return 'Paid on the server now: $amount.';
  }

  @override
  String syncWhenToday(String time) {
    return '$time today';
  }

  @override
  String bulkQuoteLine(String name, String amount) {
    return 'Quote $name · $amount';
  }

  @override
  String bulkQuoteLineColon(String name, String amount) {
    return 'Quote: $name · $amount';
  }

  @override
  String bulkNeedBySoon(String lead, String day, String rest) {
    return '$lead $day · $rest';
  }

  @override
  String syncPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get syncThisWarehouse => 'this warehouse';

  @override
  String teamKpiMembersNote(int n) {
    return '$n active';
  }

  @override
  String teamKpiRolesNote(int ready, int own) {
    return '$ready ready-made, $own yours';
  }

  @override
  String teamAddedTitle(String name) {
    return '$name is on your team';
  }

  @override
  String teamPasswordHow(String first) {
    return '$first signs in with their mobile number and this password, then chooses their own. If it gets lost, reset it from their page.';
  }

  @override
  String teamAddedNote(String aRole) {
    return 'The app link goes with the WhatsApp message. Their phone gets only what $aRole may see.';
  }

  @override
  String teamAddedNoteOffline(String aRole) {
    return 'The app link goes with the WhatsApp message. Their phone gets only what $aRole may see, and can work offline on it.';
  }

  @override
  String teamArticleA(String role) {
    return 'a $role';
  }

  @override
  String teamArticleAn(String role) {
    return 'an $role';
  }

  @override
  String teamWhatsAppMessage(
    String first,
    String brand,
    String username,
    String password,
    String appLink,
  ) {
    return 'Assalam o Alaikum $first, you are on the $brand team on Atombrand. Sign in with your mobile number $username and this temporary password: $password\nYou will choose your own password after signing in.\nApp: $appLink';
  }

  @override
  String teamWhatsAppWeb(String webLink) {
    return 'Web: $webLink';
  }

  @override
  String teamResetTitle(String first) {
    return 'Reset $first’s password?';
  }

  @override
  String teamOffTitle(String first) {
    return 'Switch $first off?';
  }

  @override
  String teamOnTitle(String first) {
    return 'Switch $first on?';
  }

  @override
  String teamOffDone(String first) {
    return '$first is switched off';
  }

  @override
  String teamPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String teamPeopleAllOff(String people) {
    return '$people (switched off)';
  }

  @override
  String teamPeopleSomeOff(String people, int off) {
    return '$people, $off switched off';
  }

  @override
  String teamRoleTitle(String name) {
    return 'Role · $name';
  }

  @override
  String teamDeleteRoleTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get teamTitle => 'Team & roles';

  @override
  String get teamAddMember => 'Add team member';

  @override
  String get teamAdd => 'Add';

  @override
  String get teamPeople => 'People';

  @override
  String get teamRoles => 'Roles';

  @override
  String get teamRolesAndPermissions => 'Roles and permissions';

  @override
  String get teamKpiMembers => 'Team members';

  @override
  String get teamKpiToday => 'Signed in today';

  @override
  String get teamKpiTodayNote => 'App and portal';

  @override
  String get teamKpiWaiting => 'Waiting to sign in';

  @override
  String get teamKpiWaitingNote => 'Still on the temporary password';

  @override
  String get teamKpiRoles => 'Roles';

  @override
  String get teamFilterActive => 'Active';

  @override
  String get teamFilterOff => 'Switched off';

  @override
  String get teamFilterAll => 'All';

  @override
  String get teamOwner => 'Owner';

  @override
  String get teamActiveNow => 'Active now';

  @override
  String get teamEmptyTitle => 'No team members yet';

  @override
  String get teamEmptyBody =>
      'Add the people who help you: each signs in with their own mobile number and sees only what their role allows.';

  @override
  String get teamEmptyOff => 'Nobody is switched off';

  @override
  String get teamFootOnline =>
      'Team members sign in with their mobile number and see only their outlets.';

  @override
  String get teamFootOffline =>
      'Offline: you can see your team, but adding or changing people needs internet.';

  @override
  String get teamNoRole => 'No role';

  @override
  String get teamEditMember => 'Change team member';

  @override
  String get teamFullName => 'Full name';

  @override
  String get teamMobile => 'Mobile number';

  @override
  String get teamEmailOptional => 'Email (optional)';

  @override
  String get teamMobileHint => 'They sign in with this mobile number.';

  @override
  String get teamMobileFixed =>
      'The mobile number is their username: it can’t change.';

  @override
  String get teamRole => 'Role';

  @override
  String get teamWorksIn => 'Works in';

  @override
  String get teamEveryOutlet => 'Every outlet';

  @override
  String get teamSomeOutlets => 'Only some outlets';

  @override
  String get teamEveryOutletHint => 'Orders, stock and deals of every outlet.';

  @override
  String get teamSomeOutletsHint => 'Only the outlets you tick.';

  @override
  String get teamAllOutlets => 'All outlets';

  @override
  String get teamPickOutlets => 'Outlets they work in';

  @override
  String get teamSearchOutlets => 'Search outlets';

  @override
  String get teamSave => 'Save changes';

  @override
  String get teamNoChanges => 'No changes yet';

  @override
  String get teamNeedsInternet => 'Needs internet';

  @override
  String get teamSaved => 'Saved';

  @override
  String get teamLoginTitle => 'Login for Brand Partner';

  @override
  String get teamShownOnce => 'Shown once';

  @override
  String get teamUsername => 'Username';

  @override
  String get teamCopy => 'Copy';

  @override
  String get teamCopied => 'Copied';

  @override
  String get teamPasswordCopied => 'Password copied';

  @override
  String get teamSendWhatsApp => 'Send on WhatsApp';

  @override
  String get teamDone => 'Done';

  @override
  String get teamAddedGoneTitle => 'The password was shown once';

  @override
  String get teamAddedGoneBody =>
      'If they didn’t get it, open their page and reset the password: that makes a new one.';

  @override
  String get teamMemberTitle => 'Team member';

  @override
  String get teamEdit => 'Edit';

  @override
  String get teamLoginAndAccess => 'Login and access';

  @override
  String get teamLastActive => 'Last active';

  @override
  String get teamPassword => 'Password';

  @override
  String get teamTheirOwn => 'Their own';

  @override
  String get teamTemporary => 'Temporary: not changed yet';

  @override
  String get teamEmail => 'Email';

  @override
  String get teamAdded => 'Added';

  @override
  String get teamResetRow => 'Reset password';

  @override
  String get teamResetSub => 'Gives a new temporary one and signs them out';

  @override
  String get teamOffRow => 'Switch off';

  @override
  String get teamOffSub => 'Can’t sign in; their work stays';

  @override
  String get teamOnRow => 'Switch on';

  @override
  String get teamOnSub => 'Can sign in again with a new temporary password';

  @override
  String get teamResetBody =>
      'They are signed out on every phone and get a new temporary password to sign in with.';

  @override
  String get teamResetButton => 'Reset password';

  @override
  String get teamOffBody =>
      'They are signed out everywhere and can’t sign in. Orders and payments they handled stay.';

  @override
  String get teamOnBody => 'They get a new temporary password to sign in with.';

  @override
  String get teamNeedInternetFoot => 'These need internet.';

  @override
  String get teamNotYoursToChange =>
      'You can see this person, but only the owner can change them.';

  @override
  String get teamMemberGone => 'This person isn’t on your team any more';

  @override
  String get teamNewRole => 'New role';

  @override
  String get teamYours => 'Yours';

  @override
  String get teamReadyMade => 'Ready-made';

  @override
  String get teamOwnerRole => 'Owner';

  @override
  String get teamOwnerRoleSum =>
      'Everything, including outlets, shop settings, roles and the team.';

  @override
  String get teamReadyNote =>
      'Ready-made roles can’t be edited. Copy one to make your own.';

  @override
  String get teamNoOwnRoles =>
      'Make a role of your own, or copy a ready-made one.';

  @override
  String get teamCompare => 'Compare roles';

  @override
  String get teamCompareHint => 'Pick two roles to see what each can do.';

  @override
  String get teamFirstRole => 'First role';

  @override
  String get teamSecondRole => 'Second role';

  @override
  String get teamDelete => 'Delete';

  @override
  String get teamRoleName => 'Role name';

  @override
  String get teamDescription => 'Description';

  @override
  String get teamDescriptionHint => 'What this role is for (optional)';

  @override
  String get teamAll => 'All';

  @override
  String get teamSaveRole => 'Save role';

  @override
  String get teamNeedRoleName => 'Give the role a name';

  @override
  String get teamNeedPermission => 'Turn on at least one permission';

  @override
  String get teamRoleSaved => 'Role saved';

  @override
  String get teamDeleteRoleBody =>
      'Nobody can be given this role after it is deleted.';

  @override
  String get teamDeleteRole => 'Delete role';

  @override
  String get teamRoleDeleted => 'Role deleted';

  @override
  String get teamRoleGone => 'This role isn’t there any more';

  @override
  String get teamNoGroups => 'The permissions couldn’t be read. Try again.';

  @override
  String get teamOwnerOnlyRoles => 'Only the owner can make or change roles.';

  @override
  String get teamHomeTotalsSub => 'Sales and payments on Home';

  @override
  String get outletsTitle => 'Outlets';

  @override
  String get outletsAddOutlet => 'Add outlet';

  @override
  String get outletsMain => 'Main';

  @override
  String get outletsCashSales => 'Cash sales';

  @override
  String get outletsOrders => 'Orders';

  @override
  String get outletsPayments => 'Payments';

  @override
  String get outletsBulkWon => 'Bulk won';

  @override
  String get outletsInStock => 'In stock';

  @override
  String get outletsAvgOrder => 'Average order';

  @override
  String get outletsAskMulti =>
      'This is a single-outlet account. Atomshop can make it multi-outlet so you can add outlets.';

  @override
  String get outletsAskWhatsApp => 'Ask Atomshop on WhatsApp';

  @override
  String get outletsEmpty => 'No outlets yet';

  @override
  String get outletsEditOutlet => 'Change outlet';

  @override
  String get outletsName => 'Outlet name';

  @override
  String get outletsPhone => 'Phone';

  @override
  String get outletsCity => 'City';

  @override
  String get outletsChooseCity => 'Choose the city';

  @override
  String get outletsSearchCities => 'Search cities';

  @override
  String get outletsOpenedOn => 'Opened on';

  @override
  String get outletsToday => 'Today';

  @override
  String get outletsWhoRunsIt => 'Who runs it?';

  @override
  String get outletsNobody => 'Nobody yet';

  @override
  String get outletsManagerHint =>
      'They become Outlet manager of this outlet only.';

  @override
  String get outletsAddress => 'Address';

  @override
  String get outletsCitiesServes => 'Cities it serves';

  @override
  String get outletsOneOutletPerCity => 'one outlet per city';

  @override
  String get outletsAllCities => 'All cities';

  @override
  String get outletsCitiesHint =>
      'None picked: it serves the city it is in. A city served by another outlet is taken.';

  @override
  String get outletsAccount => 'Account';

  @override
  String get outletsMultiOutlet => 'Multi-outlet';

  @override
  String get outletsOutletsUsed => 'Outlets used';

  @override
  String get outletsAfterSaving => 'After saving';

  @override
  String get outletsSaveOutlet => 'Save outlet';

  @override
  String get outletsSaveChanges => 'Save changes';

  @override
  String get outletsNoChanges => 'No changes yet';

  @override
  String get outletsNeedsInternet => 'Needs internet';

  @override
  String get outletsSaved => 'Saved';

  @override
  String get outletsCitiesFailed => 'The cities couldn’t be loaded.';

  @override
  String get outletsKpiSales => 'Cash sales this month';

  @override
  String get outletsKpiOrders => 'Orders';

  @override
  String get outletsKpiPayments => 'Payments received';

  @override
  String get outletsKpiOpen => 'Open orders';

  @override
  String get outletsKpiOpenNote => 'Not yet delivered';

  @override
  String get outletsOrdersThisMonth => 'Orders this month';

  @override
  String get outletsNoOrders => 'No orders for this outlet yet.';

  @override
  String get outletsStaff => 'Staff';

  @override
  String get outletsStock => 'Stock';

  @override
  String get outletsContact => 'Contact';

  @override
  String get outletsBulkDeals => 'Bulk deals';

  @override
  String get outletsStatus => 'Status';

  @override
  String get outletsPauseBody =>
      'New orders from its cities go to the main outlet, and its staff are signed out until you open it again.';

  @override
  String get outletsCloseBody =>
      'It is kept for its history. Its cities move to the main outlet and it can’t take orders.';

  @override
  String get outletsOpenBody => 'It takes new orders for its cities again.';

  @override
  String get outletsOutletGone => 'This outlet isn’t there any more';

  @override
  String get outletsClosedNoEdit =>
      'A closed outlet can’t be changed. Reopen it first.';

  @override
  String get teamChipOrders => 'Orders';

  @override
  String get teamChipPayments => 'Payments';

  @override
  String get teamChipAtompay => 'AtomPay';

  @override
  String get teamChipBulk => 'Bulk deals';

  @override
  String get teamChipQuotes => 'Quotes';

  @override
  String get teamChipProducts => 'Products';

  @override
  String get teamChipPage => 'Brand page';

  @override
  String get teamChipSeeStock => 'See stock';

  @override
  String get teamChipStockChanges => 'Stock changes';

  @override
  String get teamChipReports => 'Reports';

  @override
  String get teamChipExports => 'Exports';

  @override
  String get teamChipAddTeam => 'Add team';

  @override
  String get teamCopyTail => 'copy';

  @override
  String teamCopyTailN(int n) {
    return 'copy $n';
  }

  @override
  String get teamSeenOff => 'Switched off · can\'t sign in';

  @override
  String teamSeenOffOn(String day) {
    return 'Switched off $day · can\'t sign in';
  }

  @override
  String get teamSeenTemporary => 'Temporary: not signed in yet';

  @override
  String get teamSeenNever => 'Not signed in yet';

  @override
  String teamSeenAt(String time) {
    return 'Active $time';
  }

  @override
  String get teamSeenYesterday => 'Last active yesterday';

  @override
  String teamSeenOn(String day) {
    return 'Last active $day';
  }

  @override
  String get teamNameEmpty => 'Enter their full name.';

  @override
  String get teamNameLong => 'Keep the name under 80 letters.';

  @override
  String get teamNameLetters => 'Use letters and spaces only.';

  @override
  String get teamMobileEmpty => 'Enter their mobile number.';

  @override
  String get teamMobileBad => 'Enter a mobile number like 0300 1234567.';

  @override
  String get teamEmailBad => 'Check the email.';

  @override
  String get teamBlockName => 'Enter their name';

  @override
  String get teamBlockNameBad => 'Check the name';

  @override
  String get teamBlockMobile => 'Enter their mobile number';

  @override
  String get teamBlockMobileBad => 'Check the mobile number';

  @override
  String get teamBlockEmail => 'Check the email';

  @override
  String get teamBlockRole => 'Choose a role';

  @override
  String get teamBlockScope => 'Choose where they work';

  @override
  String get teamBlockOutlet => 'Pick at least one outlet';

  @override
  String get homeGoodMorning => 'Good morning';

  @override
  String get homeGoodAfternoon => 'Good afternoon';

  @override
  String get homeGoodEvening => 'Good evening';

  @override
  String get homePeriodYear => 'This year';

  @override
  String get homePeriodAll => 'All time';

  @override
  String get homePeriodMonth => 'This month';

  @override
  String get homeBulkNew => 'New';

  @override
  String get homeBulkContacted => 'Contacted';

  @override
  String get homeBulkQuoted => 'Quoted';

  @override
  String get homeBulkWon => 'Won';

  @override
  String get homeBulkLost => 'Lost';

  @override
  String get homeBulkDelivering => 'Delivering';

  @override
  String get homeBannerRestrictedTitle => 'Atomshop paused changes';

  @override
  String get homeBannerRestrictedBody =>
      'You can still see everything. Ask Atomshop support what to do next.';

  @override
  String get homeBannerReadOnlyTitle => 'Your account is read-only';

  @override
  String homeBannerReadOnlyLate(int days) {
    return 'Your bill is $days days late. Pay it and everything opens again at once.';
  }

  @override
  String get homeBannerReadOnlyBody =>
      'Pay the open bill and everything opens again at once.';

  @override
  String homeBannerLateDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Your bill is $days days late',
      one: 'Your bill is 1 day late',
    );
    return '$_temp0';
  }

  @override
  String get homeBannerLate => 'Your bill is late';

  @override
  String get homeBannerLateBody =>
      'Pay it to keep making changes. After 15 days the account becomes read-only until it is paid.';

  @override
  String get homeBannerMessage => 'Message from Atomshop';

  @override
  String get homeBannerBillReady => 'Your bill is ready';

  @override
  String homeBannerMonthBill(String month) {
    return '$month bill is ready';
  }

  @override
  String homeBannerDue(String date) {
    return 'due $date';
  }

  @override
  String homeTrialEndsToday(String name) {
    return '$name trial ends today';
  }

  @override
  String homeTrialEndsTomorrow(String name) {
    return '$name trial ends tomorrow';
  }

  @override
  String homeTrialEndsIn(String name, int days) {
    return '$name trial ends in $days days';
  }

  @override
  String homeTrialRenew(String day) {
    return 'It stays on and is added to your next bill, unless you switch it off before $day.';
  }

  @override
  String homeTrialOff(String day) {
    return 'It switches off on $day unless you keep it.';
  }

  @override
  String get homeStepPinTitle => 'Set your PIN and fingerprint';

  @override
  String get homeStepPinSub => 'Open the app fast, even offline';

  @override
  String get homeStepProductsTitle => 'Add your products';

  @override
  String homeStepProductsSub(int count) {
    return 'At least $count; Atomshop reviews each one before it goes live';
  }

  @override
  String get homeStepPageTitle => 'Set up your brand page';

  @override
  String get homeStepPageSub => 'Logo, banner, your story and contacts';

  @override
  String get homeStepPayTitle => 'Choose how customers pay you';

  @override
  String get homeStepPaySub =>
      'Cash on delivery, bank transfer, JazzCash or Easypaisa';

  @override
  String get homeStepTeamTitle => 'Add your team';

  @override
  String get homeStepTeamSub =>
      'Order handlers and stock keepers, each with their own sign-in';

  @override
  String homePipelineLabel(String steps) {
    return 'Orders by status: $steps';
  }

  @override
  String get homeTeamMember => 'Team member';

  @override
  String homeMonthSoFar(String month) {
    return '$month so far';
  }

  @override
  String homeChartBarLabel(String month, String sales, String paid) {
    return '$month: cash sales $sales, payments $paid';
  }

  @override
  String homeWhenToday(String time) {
    return 'today $time';
  }

  @override
  String get homeYesterday => 'yesterday';

  @override
  String get homeOutletsLoadError =>
      'This month\'s figures could not be loaded.';

  @override
  String get homeSearchOffline =>
      'No signal. Try again when you are back online.';

  @override
  String get homeSellerRequest => 'Seller request';

  @override
  String get homeWebsite => 'Website';

  @override
  String homeOrdersNote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String get ordersNoSignal => 'No signal. Check your internet and try again.';

  @override
  String get ordersSomethingWrong => 'Something went wrong. Please try again.';

  @override
  String get ordersNextStepEyebrow => 'NEXT STEP';

  @override
  String get ordersHistory => 'History';

  @override
  String get ordersCall => 'Call';

  @override
  String get ordersWhatsApp => 'WhatsApp';

  @override
  String get ordersPhotoAdded => 'Photo added · tap to change';

  @override
  String get ordersScanSerial => 'Scan the serial';

  @override
  String get ordersCashOrders => 'Cash orders';

  @override
  String get ordersAtompayOrders => 'AtomPay orders';

  @override
  String get ordersTitle => 'Orders';

  @override
  String get ordersAskAtom => 'Ask Atom';

  @override
  String get ordersSearch => 'Search orders';

  @override
  String get ordersNoRoleTitle => 'Orders are not in your role';

  @override
  String get ordersNoRoleBody => 'Ask the owner if you need to see orders.';

  @override
  String get ordersPayment => 'Payment';

  @override
  String get ordersAnyPayment => 'Any payment';

  @override
  String get ordersOutlet => 'Outlet';

  @override
  String get ordersAllOutlets => 'All outlets';

  @override
  String get ordersAll => 'All';

  @override
  String ordersPaymentFilter(String value) {
    return 'Payment: $value';
  }

  @override
  String ordersOutletFilter(String value) {
    return 'Outlet: $value';
  }

  @override
  String get ordersProductName => 'Product name';

  @override
  String get ordersNoMatch => 'No orders match these filters.';

  @override
  String get ordersClearFilters => 'Clear filters';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyBody =>
      'Orders for your products on atomshop.pk show here the moment they are placed.';

  @override
  String get ordersPickOne => 'Pick an order to see it here';

  @override
  String get ordersConfirm => 'Confirm';

  @override
  String get ordersTakePayment => 'Take payment';

  @override
  String get ordersReceipt => 'Receipt';

  @override
  String get ordersNotFound => 'Order not found';

  @override
  String get ordersNotFoundBody =>
      'It may be in another outlet, or no longer yours to see.';

  @override
  String ordersNowStage(String stage) {
    return 'Order is now $stage.';
  }

  @override
  String ordersFor(String name) {
    return 'For $name';
  }

  @override
  String ordersPlacedOn(String day) {
    return 'placed $day on atomshop.pk';
  }

  @override
  String ordersCashOrderNumber(String number) {
    return 'Cash order $number';
  }

  @override
  String get ordersOrderValue => 'Order value';

  @override
  String get ordersToCollect => 'To collect';

  @override
  String get ordersFromCopy =>
      'Shown from this phone. The customer\'s full details come back with a signal.';

  @override
  String get ordersCancelledDot => 'Cancelled.';

  @override
  String ordersCancelledOn(String day) {
    return 'Cancelled on $day:';
  }

  @override
  String get ordersNoRefund => 'Nothing was paid, so no refund is needed.';

  @override
  String get ordersCompletedDot => 'Completed.';

  @override
  String get ordersCompletedReceipt =>
      'Delivered and paid in full. The receipt is ready to share.';

  @override
  String get ordersCompletedBody => 'Delivered and paid in full.';

  @override
  String get ordersAlsoBought => 'Also bought from you';

  @override
  String get ordersMoveTitle => 'Move to another outlet';

  @override
  String ordersCompleteStillToPay(String amount) {
    return 'Complete · $amount still to pay';
  }

  @override
  String get ordersStatus => 'Status';

  @override
  String get ordersTapStep => 'Tap a step to preview it';

  @override
  String get ordersArrived => 'The order arrived from atomshop.pk.';

  @override
  String get ordersWhatOrdered => 'What was ordered';

  @override
  String get ordersTotal => 'Total';

  @override
  String get ordersDue => 'Due';

  @override
  String get ordersPaidSoFar => 'Paid so far';

  @override
  String get ordersReceiptPhoto => 'Receipt photo';

  @override
  String get ordersVerified => 'Verified';

  @override
  String get ordersName => 'Name';

  @override
  String get ordersCustomerSince => 'Customer since';

  @override
  String get ordersPhone => 'Phone';

  @override
  String get ordersEmail => 'Email';

  @override
  String get ordersAddress => 'Address';

  @override
  String get ordersCity => 'City';

  @override
  String get ordersDelivery => 'Delivery';

  @override
  String get ordersStepNotOpen => 'This step isn\'t open';

  @override
  String ordersGateIsNow(String stage) {
    return 'The order is $stage now.';
  }

  @override
  String get ordersOpenOrder => 'Open the order';

  @override
  String get ordersDeliverNotOpen => 'This order can\'t be marked delivered';

  @override
  String get ordersDeliverySaved => 'Delivery saved.';

  @override
  String get ordersMarkAsDelivered => 'Mark as delivered';

  @override
  String get ordersScanReadHeld =>
      'Read. It is checked against the held unit when you save.';

  @override
  String get ordersScanPoint => 'Point at the serial barcode on the box';

  @override
  String get ordersHeldUnit => 'The unit held for this order';

  @override
  String get ordersChange => 'Change';

  @override
  String get ordersSerialOptional => 'Serial or IMEI (optional)';

  @override
  String get ordersTypeFromBox => 'Type it from the box';

  @override
  String get ordersSerialHint => 'Kept on the order and the receipt.';

  @override
  String get ordersReceivedBy => 'Received by';

  @override
  String ordersFirstCustomer(String name) {
    return '$name (customer)';
  }

  @override
  String get ordersSomeoneElse => 'Someone else';

  @override
  String get ordersNameRelation => 'Name and relation';

  @override
  String get ordersNameRelationHint => 'e.g. Ahmed Javed, husband';

  @override
  String get ordersCashCollected => 'Cash collected (Rs)';

  @override
  String ordersCashCollectedHint(String amount) {
    return 'Up to $amount left to pay. Leave 0 if nothing was paid at the door.';
  }

  @override
  String get ordersPaidBy => 'Paid by';

  @override
  String get ordersProof => 'Proof of delivery';

  @override
  String get ordersTakePhoto => 'Take a photo';

  @override
  String get ordersSaveDelivery => 'Save delivery';

  @override
  String get ordersNothingToRecord => 'Nothing to record on this order';

  @override
  String get ordersPaymentDate => 'Payment date';

  @override
  String ordersPaymentSaved(String amount) {
    return 'Payment of $amount saved.';
  }

  @override
  String ordersPaymentSavedHere(String amount) {
    return 'Payment of $amount saved on this phone';
  }

  @override
  String get ordersTheReceipt => 'The receipt comes once the server has it.';

  @override
  String get ordersRecordSellerPayment => 'Record seller\'s payment';

  @override
  String get ordersRecordAPayment => 'Record a payment';

  @override
  String ordersAtompayNumber(String id) {
    return 'AtomPay #A-$id';
  }

  @override
  String get ordersCashPrice => 'Cash price';

  @override
  String get ordersLeftToReceive => 'Left to receive';

  @override
  String get ordersAmount => 'Amount';

  @override
  String ordersAllAmount(String amount) {
    return 'All $amount';
  }

  @override
  String get ordersHalf => 'Half';

  @override
  String get ordersHowPaid => 'How did they pay?';

  @override
  String get ordersNoFutureDate => 'Can\'t be a future date.';

  @override
  String ordersPaymentDateSem(String day) {
    return 'Payment date, $day';
  }

  @override
  String ordersTodayDay(String day) {
    return 'Today, $day';
  }

  @override
  String get ordersReference => 'Reference';

  @override
  String get ordersOptional => '(optional)';

  @override
  String get ordersReferenceHint => 'Transaction ID or cheque number';

  @override
  String get ordersReceiptPhotoHint => 'Photo of the receipt or transfer';

  @override
  String get ordersSavePayment => 'Save payment';

  @override
  String ordersEnterUpTo(String amount) {
    return 'Enter an amount up to $amount';
  }

  @override
  String get ordersSerialLength => 'A serial is 3 to 60 characters.';

  @override
  String get ordersScanCamera => 'Scan with the camera';

  @override
  String get ordersTypeIt => 'Type it';

  @override
  String get ordersSerialOrImei => 'Serial or IMEI';

  @override
  String get ordersUseSerial => 'Use this serial';

  @override
  String get ordersScanHelp =>
      'Point at the serial barcode on the box. No barcode? Tap the keyboard to type it.';

  @override
  String get ordersCancelledToast => 'Order cancelled.';

  @override
  String get ordersCancelTitle => 'Cancel this order';

  @override
  String get ordersCancelWhy => 'Why? Pick all that apply';

  @override
  String get ordersCancelNote => 'Anything else (optional)';

  @override
  String get ordersCancelNoteHint =>
      'What happened? The customer doesn\'t see this note.';

  @override
  String get ordersCancelWarnHeld =>
      'The unit held for this order goes back to available in your stock. A cancelled order can\'t be reopened.';

  @override
  String get ordersCancelWarn => 'A cancelled order can\'t be reopened.';

  @override
  String get ordersCancelWarnBold => 'available';

  @override
  String get ordersKeepOrder => 'Keep order';

  @override
  String get ordersCancelOrder => 'Cancel order';

  @override
  String get ordersPickReason => 'Pick a reason';

  @override
  String get ordersMovedToast => 'Order moved.';

  @override
  String ordersNowAt(String name) {
    return 'now at $name';
  }

  @override
  String ordersWhereNowSem(String name) {
    return '$name, where it is now';
  }

  @override
  String get ordersWhereNow => 'where it is now';

  @override
  String get ordersMoveNoteHeld =>
      'The new outlet\'s team sees it straight away, and the held unit is freed so they can hold one of theirs. Finished orders can\'t move.';

  @override
  String get ordersMoveNote =>
      'The new outlet\'s team sees it straight away. Finished orders can\'t move.';

  @override
  String get ordersMoveOrder => 'Move order';

  @override
  String get ordersCantMove => 'This order can\'t move';

  @override
  String get ordersCantCancel => 'This order can\'t be cancelled';

  @override
  String ordersItIsNow(String stage) {
    return 'It is $stage now.';
  }

  @override
  String get ordersPdfFailed =>
      'Couldn\'t make the PDF on this phone. Try again.';

  @override
  String get ordersPdf => 'PDF';

  @override
  String get ordersPrint => 'Print';

  @override
  String get ordersReceiptNoteFrom =>
      'The note at the bottom comes from Shop settings · Receipt note.';

  @override
  String get atompayTheSeller => 'the seller';

  @override
  String get atompayTheSellerCap => 'The seller';

  @override
  String get atompayNoticeApproving =>
      'Atomshop is checking the customer. Nothing to do yet: you hear from us when it is approved.';

  @override
  String get atompayNoticeSeller =>
      'Approved. Atomshop is still finding a seller near the customer. Keep one unit ready.';

  @override
  String atompayNoticeSellerAt(String outlet) {
    return 'Approved. Atomshop is still finding a seller near the customer. Keep one unit ready at $outlet.';
  }

  @override
  String atompayNoticeHandover(String seller) {
    return 'Atomshop gave this order to $seller. Hand the unit over to them; they pay you the cash price.';
  }

  @override
  String atompayNoticeHanded(String seller) {
    return 'Handed to $seller. Record their payment when it reaches you.';
  }

  @override
  String atompayNoticeHandedOn(String seller, String day) {
    return 'Handed to $seller on $day. Record their payment when it reaches you.';
  }

  @override
  String atompayNoticePaid(String seller) {
    return '$seller paid you in full. This cash sale is done.';
  }

  @override
  String get atompayNoticeCancelled =>
      'Atomshop did not approve this order. Nothing to hand over, and any held unit is free again.';

  @override
  String atompayEvSerial(String serial) {
    return 'serial $serial';
  }

  @override
  String atompayEvTo(String name) {
    return 'to $name';
  }

  @override
  String get atompayEvSaleDone => 'Cash sale completed';

  @override
  String get atompayEvNotApproved => 'Atomshop did not approve the order';

  @override
  String get atompayEvChecking => 'Atomshop is checking the customer';

  @override
  String get atompayEvApproved => 'Atomshop approved the order';

  @override
  String atompayEvPaid(String seller, String amount, String method) {
    return '$seller paid $amount by $method';
  }

  @override
  String get atompaySaleCompleted => 'Sale to the seller completed.';

  @override
  String get atompayHandOverUnit => 'Hand over the unit';

  @override
  String get atompayHandOverBody =>
      'Note the serial, who received it and a photo of the hand-over.';

  @override
  String atompayPayBody(String amount, String seller) {
    return '$amount to receive from $seller. Complete the order once it is paid.';
  }

  @override
  String get atompayCompleteSale => 'Complete the sale';

  @override
  String get atompayCompleteBody =>
      'The seller paid in full. Complete the order to close this cash sale.';

  @override
  String get atompayStApproved => 'Atomshop approved';

  @override
  String get atompayApproved => 'Approved';

  @override
  String get atompayStSeller => 'Seller given';

  @override
  String get atompayYourStep => 'Your step';

  @override
  String get atompayStDone => 'Cash sale done';

  @override
  String get atompaySellerPaysYou => 'Seller pays you';

  @override
  String get atompayFromCopy =>
      'Shown from this phone. The seller\'s details come back with a signal.';

  @override
  String get atompayYourStepEyebrow => 'YOUR STEP';

  @override
  String get atompaySteps => 'Steps';

  @override
  String get atompayPaymentToYou => 'Payment to you';

  @override
  String get atompaySeller => 'Seller';

  @override
  String get atompayShop => 'Shop';

  @override
  String get atompayArea => 'Area';

  @override
  String get atompayContact => 'Contact';

  @override
  String get atompayHandOverCard => 'Hand-over';

  @override
  String get atompayNotYet => 'Not yet';

  @override
  String get atompayHandTo => 'Hand to';

  @override
  String get atompaySellerNotGiven => 'Seller not given yet';

  @override
  String atompayOrderNumber(String number) {
    return 'AtomPay order $number';
  }

  @override
  String atompayPlacedOn(String day) {
    return 'Placed $day on atomshop.pk';
  }

  @override
  String get atompayOnceSeller => 'Once a seller is given';

  @override
  String get atompayCustomerPays => 'Customer pays';

  @override
  String atompayMonthly(int months, String amount) {
    return '$months × $amount';
  }

  @override
  String atompayMonths(int months) {
    return '$months months';
  }

  @override
  String get atompayNoMarkup => 'No advance, 0% markup';

  @override
  String get atompayNothingToHand => 'Nothing to hand over';

  @override
  String atompayAtStepNow(String step) {
    return 'This order is at \"$step\" now.';
  }

  @override
  String get atompayHandoverSaved => 'Hand-over saved. The seller is told.';

  @override
  String get atompayScanRead => 'Read. Serial filled in below.';

  @override
  String get atompaySerialHint => 'Scan or type it from the box';

  @override
  String get atompayReceivedHint =>
      'Required. The person from the seller\'s shop who took the unit.';

  @override
  String get atompayNote => 'Note';

  @override
  String get atompayNoteHint =>
      'e.g. Sealed box, remote and wall bracket included';

  @override
  String get atompayPhoto => 'Photo';

  @override
  String get atompayPhotoHint => 'Photo of the hand-over';

  @override
  String get atompaySaveHandover => 'Save hand-over';

  @override
  String get atompayNoMatch => 'No AtomPay orders match these filters.';

  @override
  String get atompayEmptyTitle => 'No AtomPay orders yet';

  @override
  String get atompayEmptyBody =>
      'Switch AtomPay on for a product and orders paid in 3 months show here.';

  @override
  String get atompayIntro =>
      'The customer pays in 3 months, no advance, 0% markup. Atomshop approves the order and gives it to a seller. For you it is a cash sale to that seller: hand the unit over, the seller pays you.';

  @override
  String get atompayIntroBold => '3 months, no advance, 0% markup';

  @override
  String get atompayNotGiven => 'Not given yet';

  @override
  String get atompayView => 'View';

  @override
  String get bulkScanTooShort => 'That is too short for a serial.';

  @override
  String bulkScanAlready(String serial) {
    return '$serial is already on this delivery.';
  }

  @override
  String get bulkScanTypeIt => 'Type it';

  @override
  String get bulkScanSerial => 'Serial';

  @override
  String get bulkScanAdd => 'Add';

  @override
  String bulkScanCount(int done, int max) {
    return '$done of $max scanned';
  }

  @override
  String get bulkScanDone => 'Done';

  @override
  String get bulkChooseStatus => 'Choose a status.';

  @override
  String get bulkRequestDeclined => 'Request declined';

  @override
  String get bulkStatusSaved => 'Status saved';

  @override
  String get bulkDeclineTitle => 'Decline this request';

  @override
  String get bulkUpdateStatus => 'Update status';

  @override
  String get bulkWhyDeclining => 'Why are you declining?';

  @override
  String get bulkWhyLost => 'Why was it lost?';

  @override
  String get bulkChooseReason => 'Choose a reason';

  @override
  String get bulkReason => 'Reason';

  @override
  String get bulkDeclineNote =>
      'The seller is told in their app. A request you decline can\'t be quoted again.';

  @override
  String get bulkContactedHint =>
      'Use Contacted after you have spoken to them. Quoted is set when you send a quote, and Won when you make a deal.';

  @override
  String get bulkNote => 'Note';

  @override
  String get bulkOptional => 'optional';

  @override
  String get bulkNoteSellerHint => 'A word for the seller';

  @override
  String get bulkNoteBuyerHint => 'What did they say?';

  @override
  String get bulkDeclineRequest => 'Decline request';

  @override
  String get bulkWonNeedQuote =>
      'Send a quote first: a deal is made from the quote they accepted.';

  @override
  String bulkDealMade(String number) {
    return 'Deal $number made';
  }

  @override
  String bulkDealMadeShort(String number, String items) {
    return 'Deal $number made. Short in stock: $items';
  }

  @override
  String get bulkSaidYes => 'They said yes';

  @override
  String bulkAlreadyDeal(String number) {
    return 'This request is already deal $number.';
  }

  @override
  String get bulkWonNeedQuoteBusiness =>
      'Send a quote first: a deal is made from the quote the business accepted.';

  @override
  String get bulkAcceptedQuote => 'Accepted quote';

  @override
  String bulkSentWhen(String when) {
    return 'Sent $when';
  }

  @override
  String bulkAdvancePct(int pct) {
    return '$pct% advance';
  }

  @override
  String get bulkDeliverFrom => 'Deliver from';

  @override
  String get bulkWonInfo =>
      'The request becomes Won and a deal opens with these lines.';

  @override
  String bulkWonInfoAdvance(int pct) {
    return ' Take the $pct% advance before the first delivery.';
  }

  @override
  String bulkOpenDealNumber(String number) {
    return 'Open deal $number';
  }

  @override
  String get bulkMarkWon => 'Mark won and make a deal';

  @override
  String get bulkSendAQuote => 'Send a quote';

  @override
  String get bulkValidUntilLabel => 'Valid until';

  @override
  String bulkSavedAsDraft(String name) {
    return 'Saved as a draft ($name)';
  }

  @override
  String bulkQuoteSentToast(String name) {
    return 'Quote $name sent';
  }

  @override
  String get bulkDraftSaved => 'Draft saved';

  @override
  String bulkDraftLine(String name, String total) {
    return 'Draft $name · $total, not sent yet';
  }

  @override
  String get bulkActFinishQuote => 'Finish quote';

  @override
  String bulkDraftSavedName(String name) {
    return 'Draft saved ($name)';
  }

  @override
  String bulkQuoteFor(String who) {
    return 'Quote · $who';
  }

  @override
  String get bulkTheyAskedFor => 'They asked for ';

  @override
  String bulkHopingForTail(String price) {
    return ', hoping for $price a unit';
  }

  @override
  String bulkChangingDraft(String rev) {
    return '. You are changing draft rev $rev.';
  }

  @override
  String bulkSendingMakesRev(String rev, String old) {
    return '. Sending makes rev $rev; rev $old is marked superseded.';
  }

  @override
  String get bulkTypedNote =>
      'The seller typed what they need. Quote it with the closest product from your catalogue.';

  @override
  String get bulkLinesHeader => 'LINES';

  @override
  String bulkUpTo(String max) {
    return 'Up to $max';
  }

  @override
  String get bulkAddLine => 'Add a line';

  @override
  String get bulkTermsHeader => 'TERMS';

  @override
  String get bulkDeliveryCharge => 'Delivery charge';

  @override
  String get bulkNone => 'None';

  @override
  String get bulkBalance => 'Balance';

  @override
  String get bulkNotes => 'Notes';

  @override
  String get bulkNotesNote => 'optional, up to 500';

  @override
  String get bulkNotesHint =>
      'Delivery lots, warranty, anything the buyer should know';

  @override
  String get bulkPreviewPdf => 'Preview or download PDF';

  @override
  String get bulkGettingPdf => 'Getting the PDF…';

  @override
  String get bulkPdfDraftNote =>
      'The PDF saves this quote as a draft first; nothing is sent.';

  @override
  String get bulkProductVariant => 'Product and variant';

  @override
  String get bulkChooseProduct => 'Choose a product';

  @override
  String get bulkSearchProducts => 'Search your products';

  @override
  String bulkRemoveLine(int n) {
    return 'Remove line $n';
  }

  @override
  String get bulkColour => 'Colour';

  @override
  String get bulkQty => 'Qty';

  @override
  String get bulkDiscountPct => 'Discount %';

  @override
  String get bulkUnitPrice => 'Unit price';

  @override
  String get bulkLineTotal => 'Line total';

  @override
  String get bulkLess => 'Less';

  @override
  String get bulkMore => 'More';

  @override
  String get bulkQuoteTotal => 'Quote total';

  @override
  String bulkUnitsSubtotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units · subtotal',
      one: '1 unit · subtotal',
    );
    return '$_temp0';
  }

  @override
  String get bulkDiscountDelivery => 'Discount · Delivery';

  @override
  String get bulkAdvanceNone => 'Advance (none)';

  @override
  String bulkAdvanceRow(int pct) {
    return 'Advance $pct%';
  }

  @override
  String get bulkSaveDraft => 'Save as draft';

  @override
  String get bulkSaveSendWhatsApp => 'Save and send on WhatsApp';

  @override
  String get bulkDeal => 'Deal';

  @override
  String bulkFromOutlet(String outlet) {
    return 'from $outlet';
  }

  @override
  String bulkDealNumber(String number) {
    return 'Deal $number';
  }

  @override
  String bulkWonDate(String date) {
    return 'won $date';
  }

  @override
  String get bulkAtomshopSeller => 'Atomshop seller';

  @override
  String get bulkStepOpenAdvance => 'Open\nAdvance paid';

  @override
  String bulkStepDeliveringOf(int done, int units) {
    return 'Delivering\n$done of $units';
  }

  @override
  String get bulkInvoice => 'Invoice';

  @override
  String get bulkDeliverUnits => 'Deliver units';

  @override
  String get bulkDealValue => 'Deal value';

  @override
  String bulkDeliveryAmount(String amount) {
    return '$amount delivery';
  }

  @override
  String get bulkFreeDelivery => 'free delivery';

  @override
  String bulkDoneOf(int done, int units) {
    return '$done of $units';
  }

  @override
  String bulkDeliveriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deliveries',
      one: '1 delivery',
    );
    return '$_temp0';
  }

  @override
  String bulkPctOfDeal(int pct) {
    return '$pct% of the deal';
  }

  @override
  String get bulkBalanceDue => 'Balance due';

  @override
  String bulkAdvanceBeforeFirst(String amount) {
    return 'Advance $amount before the first delivery';
  }

  @override
  String get bulkTakeBeforeNext => 'Take payment before the next delivery';

  @override
  String get bulkDueBeforeLast => 'Due before the last delivery';

  @override
  String get bulkTerms => 'Terms';

  @override
  String bulkAdvancePaidPct(int pct) {
    return '$pct% · paid';
  }

  @override
  String bulkAdvanceToTake(int pct, String amount) {
    return '$pct% · $amount to take';
  }

  @override
  String get bulkDelivery => 'Delivery';

  @override
  String get bulkInParts => 'In parts';

  @override
  String get bulkFromQuote => 'From quote';

  @override
  String get bulkItems => 'Items';

  @override
  String get bulkProduct => 'Product';

  @override
  String get bulkOrdered => 'Ordered';

  @override
  String get bulkLeft => 'Left';

  @override
  String get bulkAmount => 'Amount';

  @override
  String bulkNDelivered(int count) {
    return '$count delivered';
  }

  @override
  String get bulkTotal => 'Total';

  @override
  String bulkSerialOne(String serial) {
    return 'Serial $serial';
  }

  @override
  String bulkSerialsList(String serials) {
    return 'Serials $serials';
  }

  @override
  String bulkSerialsRange(String first, String last) {
    return 'Serials $first to $last';
  }

  @override
  String get bulkDeliveries => 'Deliveries';

  @override
  String bulkReceivedByName(String name) {
    return 'received by $name';
  }

  @override
  String get bulkWaitingSeller => 'Waiting for the seller to confirm';

  @override
  String bulkSellerConfirmed(String date) {
    return 'Seller confirmed $date · in their stock';
  }

  @override
  String get bulkSignedNote => 'Signed note';

  @override
  String get bulkSellerConfirmsNote =>
      'The seller confirms each delivery note in their app; the units go into their stock with your serials.';

  @override
  String get bulkPayments => 'Payments';

  @override
  String get bulkNoPayment => 'No payment yet.';

  @override
  String get bulkPayment => 'Payment';

  @override
  String bulkRef(String ref) {
    return 'ref $ref';
  }

  @override
  String get bulkReceipt => 'Receipt';

  @override
  String get bulkBusiness => 'Business';

  @override
  String get bulkShop => 'Shop';

  @override
  String bulkShopVerified(String name) {
    return '$name ✓ Verified';
  }

  @override
  String get bulkBranch => 'Branch';

  @override
  String get bulkSellerCode => 'Seller code';

  @override
  String get bulkContact => 'Contact';

  @override
  String bulkWebsiteBuyer(String name) {
    return '$name · Website buyer';
  }

  @override
  String get bulkPhone => 'Phone';

  @override
  String get bulkCommission => 'Atomshop commission';

  @override
  String get bulkFromSellerRequest => 'From seller request';

  @override
  String get bulkFromBulkRequest => 'From bulk request';

  @override
  String bulkHistDelivered(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delivered $count units ($number)',
      one: 'Delivered 1 unit ($number)',
    );
    return '$_temp0';
  }

  @override
  String bulkHistPayment(String kind, String amount) {
    return '$kind $amount';
  }

  @override
  String bulkHistBy(String method) {
    return 'by $method';
  }

  @override
  String get bulkDealMadeEvent => 'Deal made';

  @override
  String bulkWonFromQuote(String quote) {
    return 'Won from quote $quote';
  }

  @override
  String get bulkHistory => 'History';

  @override
  String get bulkPhotoAdded => 'Photo added';

  @override
  String get bulkRemovePhoto => 'Remove the photo';

  @override
  String get bulkGallery => 'Gallery';

  @override
  String get bulkSerialsFull => 'There is a serial for every unit already.';

  @override
  String bulkScanTitle(String title) {
    return 'Scan $title';
  }

  @override
  String get bulkDeliveredOn => 'Delivered on';

  @override
  String bulkDeliverySaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delivery of $count units saved',
      one: 'Delivery of 1 unit saved',
    );
    return '$_temp0';
  }

  @override
  String bulkRuleAdvance(String advance, String paid) {
    return 'Take the advance of $advance before the first delivery. Paid so far: $paid.';
  }

  @override
  String get bulkAdvancePaidPrefix => 'Advance paid. ';

  @override
  String bulkRuleEach(String amount) {
    return 'Balance is due before each delivery: payments so far cover $amount more.';
  }

  @override
  String get bulkRuleLast => 'The balance is due before the last delivery.';

  @override
  String bulkBlockPayUnits(String amount) {
    return 'This delivery is worth more than what has been paid. Record a payment of at least $amount first.';
  }

  @override
  String bulkBlockBalance(String amount) {
    return 'This delivery completes the deal: the balance of $amount must be paid first. Bulk deals have no credit.';
  }

  @override
  String bulkBlockTooMany(String title, int left) {
    return '$title: only $left left to deliver.';
  }

  @override
  String get bulkReasonPick => 'Choose how many units go out.';

  @override
  String get bulkReasonAdvance => 'The advance comes first.';

  @override
  String get bulkReasonPay => 'Record a payment first.';

  @override
  String get bulkReasonTooMany => 'More than is left.';

  @override
  String bulkDeliverTitle(String number) {
    return 'Deliver units · $number';
  }

  @override
  String get bulkRecordAPayment => 'Record a payment';

  @override
  String get bulkGoesOutHeader => 'WHAT GOES OUT NOW';

  @override
  String get bulkAllDelivered => 'Everything on this deal is delivered.';

  @override
  String get bulkReceivedBy => 'Received by';

  @override
  String get bulkReceivedByHint => 'Name, and who they are';

  @override
  String bulkTodayDate(String date) {
    return 'Today, $date';
  }

  @override
  String get bulkDeliverNoteHint => 'e.g. Second lot, by our van';

  @override
  String get bulkSignedDeliveryNote => 'Signed delivery note';

  @override
  String get bulkTakePhoto => 'Take a photo';

  @override
  String get bulkLastNeedsBalance =>
      'The last delivery needs the full balance paid first.';

  @override
  String bulkSaveDelivery(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save delivery · $count units',
      one: 'Save delivery · 1 unit',
    );
    return '$_temp0';
  }

  @override
  String bulkLeftOf(int left, int qty) {
    return '$left left of $qty';
  }

  @override
  String get bulkSerials => 'Serials';

  @override
  String get bulkOnePerLine => 'one per line';

  @override
  String get bulkOptionalCap => 'Optional';

  @override
  String get bulkSerialsHint => 'One per unit, or none';

  @override
  String bulkScanSerialsFor(String title) {
    return 'Scan serials for $title';
  }

  @override
  String get bulkFewer => 'Fewer';

  @override
  String get bulkPaymentDate => 'Payment date';

  @override
  String bulkPaymentSaved(String amount) {
    return 'Payment of $amount saved';
  }

  @override
  String bulkRecordPaymentTitle(String number) {
    return 'Record payment · $number';
  }

  @override
  String get bulkDealPaidFull => 'This deal is paid in full.';

  @override
  String bulkWhoBalance(String who, String amount) {
    return '$who · balance $amount';
  }

  @override
  String get bulkHowPaid => 'How did they pay?';

  @override
  String get bulkReference => 'Reference';

  @override
  String get bulkSlipPhoto => 'Add a photo of the slip';

  @override
  String get bulkSavePayment => 'Save payment';

  @override
  String get bulkSellerRequest => 'Seller request';

  @override
  String get bulkBulkRequest => 'Bulk request';

  @override
  String bulkSellerRequestWhen(String when) {
    return 'Seller request · $when';
  }

  @override
  String get bulkStepAsked => 'Asked';

  @override
  String get bulkStepSellerAnswers => 'Seller answers';

  @override
  String get bulkNoQuoteSeller =>
      'No quote yet. A quote can carry a lower unit price, a discount, a delivery charge, the advance and how the balance is paid.';

  @override
  String get bulkDecline => 'Decline';

  @override
  String get bulkSendANewQuote => 'Send a new quote';

  @override
  String get bulkReplySoon => 'Reply soon.';

  @override
  String bulkNeededByLate(String day, String rest) {
    return 'Needed by $day: $rest.';
  }

  @override
  String bulkNeededByLeft(String day, String rest) {
    return 'Needed by $day: $rest left.';
  }

  @override
  String bulkNeededByWhen(String day, String rest) {
    return 'Needed by $day: $rest.';
  }

  @override
  String get bulkAskOthers =>
      'The seller can ask other brands too. Send your quote today.';

  @override
  String get bulkChangeAskedTitle => 'The seller asked for a change';

  @override
  String bulkOnQuote(String name) {
    return 'On quote $name. ';
  }

  @override
  String get bulkSendRevisionNote =>
      'Send a new revision: the old one is replaced and the seller is told.';

  @override
  String bulkValidUntilSentence(String date) {
    return 'Valid until $date.';
  }

  @override
  String bulkQuoteExpiredLead(String name) {
    return 'Quote $name has expired.';
  }

  @override
  String get bulkKeepSeller => 'Send a new revision to keep the seller.';

  @override
  String bulkQuoteWithSellerLead(String name) {
    return 'Quote $name is with the seller.';
  }

  @override
  String get bulkQuoteWithSellerBody =>
      'They accept, ask for a change or decline it in their Atom Seller app.';

  @override
  String get bulkTurnedDownDot => 'The seller turned your quote down.';

  @override
  String get bulkTurnedDownColon => 'The seller turned your quote down:';

  @override
  String get bulkRequestClosed => 'The request is closed.';

  @override
  String get bulkStillQuote =>
      'You can still send a new quote while the request is open.';

  @override
  String get bulkYouDeclined => 'You declined this request.';

  @override
  String bulkReasonSentence(String reason) {
    return 'Reason: $reason.';
  }

  @override
  String get bulkAcceptedDot => 'Accepted.';

  @override
  String bulkAcceptedDeal(String number) {
    return 'Accepted: deal $number is open.';
  }

  @override
  String bulkCode(String code) {
    return 'Code $code';
  }

  @override
  String get bulkOnAtomshopSince => 'On Atomshop since';

  @override
  String get bulkBoughtFromYou => 'Bought from you';

  @override
  String get bulkNotYet => 'Not yet';

  @override
  String get bulkPaidOnTime => 'Paid on time';

  @override
  String get bulkOtherOpen => 'Other open requests';

  @override
  String get bulkWhatTheyNeed => 'What they need';

  @override
  String get bulkFromCatalogue => 'From your catalogue';

  @override
  String get bulkHopesToPay => 'Seller hopes to pay';

  @override
  String get bulkAUnit => 'a unit';

  @override
  String get bulkCashPrice => 'Your cash price';

  @override
  String get bulkSamePrice => 'the same as their price';

  @override
  String bulkAbovePrice(int pct) {
    return '$pct% above their price';
  }

  @override
  String bulkBelowPrice(int pct) {
    return '$pct% below their price';
  }

  @override
  String get bulkDeliverTo => 'Deliver to';

  @override
  String get bulkAtYourPrice => 'At your price';

  @override
  String get bulkSellersNoteLabel => 'Seller\'s note';

  @override
  String get bulkQuotesSent => 'Quotes sent';

  @override
  String bulkQuoteSemantics(String name, String amount, String label) {
    return '$name, $amount, $label. Share the PDF';
  }

  @override
  String bulkSentDate(String date) {
    return 'Sent $date';
  }

  @override
  String get bulkCommissionFixed =>
      'The commission was fixed when the deal opened: see the deal.';

  @override
  String get bulkCommissionInfo =>
      'If Atomshop sets a rate on seller deals, it is shown here before you send a quote and fixed when the deal opens. It is added to your monthly bill, never taken from the seller\'s payment.';

  @override
  String get bulkOnThisRequest => 'On this request';

  @override
  String get bulkTheSeller => 'The seller';

  @override
  String get bulkYou => 'You';

  @override
  String bulkBulkRequestWhen(String when) {
    return 'Bulk request · $when';
  }

  @override
  String get bulkStepDeliveredPaid => 'Delivered and paid';

  @override
  String get bulkStatusButton => 'Status';

  @override
  String bulkQuoteReady(String name) {
    return 'Quote $name is ready.';
  }

  @override
  String get bulkOpenWhatsApp => 'Open WhatsApp';

  @override
  String get bulkDownloadPdf => 'Download PDF';

  @override
  String get bulkWonDot => 'Won.';

  @override
  String bulkWonDeal(String number) {
    return 'Won: deal $number.';
  }

  @override
  String get bulkLostDot => 'Lost.';

  @override
  String bulkLostReason(String reason) {
    return 'Lost: $reason.';
  }

  @override
  String get bulkTheRequest => 'The request';

  @override
  String get bulkQuantity => 'Quantity';

  @override
  String get bulkAtListPrice => 'At list price';

  @override
  String get bulkPriceHope => 'Price they hope for';

  @override
  String bulkPriceAUnit(String price) {
    return '$price a unit';
  }

  @override
  String get bulkLostBecause => 'Lost because';

  @override
  String get bulkNewRevision => 'New revision';

  @override
  String get bulkSaidYesQ => 'They said yes?';

  @override
  String get bulkMarkWonNote =>
      'Mark the request won. It becomes a deal you deliver and collect on.';

  @override
  String get bulkConversation => 'Conversation history';

  @override
  String get bulkContactStanding => 'Contact and standing';

  @override
  String get bulkName => 'Name';

  @override
  String get bulkEmail => 'Email';

  @override
  String get bulkVerified => 'Verified';

  @override
  String get bulkAccount => 'Account';

  @override
  String get bulkGuest => 'Guest, no Atomshop account';

  @override
  String bulkOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String get bulkOtherRequests => 'Other requests';

  @override
  String get bulkNewQuoteRevision => 'New quote revision';

  @override
  String get bulkAll => 'All';

  @override
  String bulkReceivedFilter(String when) {
    return 'Received: $when';
  }

  @override
  String get bulkReceivedTitle => 'Received';

  @override
  String get bulkAnyTime => 'Any time';

  @override
  String get bulkRangeToday => 'Today';

  @override
  String get bulkRangeWeek => 'Last 7 days';

  @override
  String get bulkRangeDays30 => 'Last 30 days';

  @override
  String get bulkRangeThisMonth => 'This month';

  @override
  String get bulkRangePick => 'Pick dates';

  @override
  String bulkRangeDates(String from, String to) {
    return '$from – $to';
  }

  @override
  String get bulkEmptyReceived => 'No requests received then';

  @override
  String get bulkEmptyReceivedBody => 'Try another time, or Any time.';

  @override
  String get bulkLoadErrorTitle => 'That didn\'t load';

  @override
  String get bulkLoadErrorBody =>
      'Atomshop couldn\'t load this just now. Nothing was changed.';

  @override
  String get bulkNoDelivery => 'No delivery yet.';

  @override
  String get bulkFromRequest => 'From request';

  @override
  String get bulkAddress => 'Address';

  @override
  String get bulkCommissionNoneInfo =>
      'Seller deals carry no commission for your brand today. If Atomshop sets a rate, it is shown here before you send a quote and fixed when the deal opens; it is added to your monthly bill, never taken from the seller\'s payment.';

  @override
  String get bulkReceivedFromAtomshop => 'Request received from Atomshop';

  @override
  String get bulkAddPhotoTitle => 'Add a photo';

  @override
  String get teamSemYes => 'yes';

  @override
  String get teamSemNo => 'no';

  @override
  String outletsHeroLabel(String period) {
    return 'Cash sales, all outlets · $period';
  }

  @override
  String outletsUsedOf(int used, int limit) {
    return '$used of $limit outlets';
  }

  @override
  String outletsHeroMeta(int delivered, String paid, int outlets) {
    String _temp0 = intl.Intl.pluralLogic(
      outlets,
      locale: localeName,
      other:
          'Delivered $delivered · Payments received $paid · $outlets outlets',
      one: 'Delivered $delivered · Payments received $paid · 1 outlet',
    );
    return '$_temp0';
  }

  @override
  String outletsUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units',
      one: '1 unit',
    );
    return '$_temp0';
  }

  @override
  String outletsOfSales(int pct) {
    return '$pct% of sales';
  }

  @override
  String outletsAskMore(int limit) {
    return 'Need more than $limit outlets? Ask Atomshop on WhatsApp';
  }

  @override
  String outletsFull(int limit) {
    return 'You have used all $limit outlets on your account. Ask Atomshop for more.';
  }

  @override
  String outletsWaAskMore(String brand) {
    return 'Assalam o Alaikum, I would like more outlets for $brand on Atombrand.';
  }

  @override
  String outletsWaAskMulti(String brand) {
    return 'Assalam o Alaikum, I would like to make $brand a multi-outlet account on Atombrand.';
  }

  @override
  String outletsUsedLine(int used, int limit) {
    return 'Outlets used: $used of $limit';
  }

  @override
  String outletsTakenBy(String city, String outlet) {
    return '$city · $outlet';
  }

  @override
  String outletsTakenAria(String city, String outlet) {
    return '$city, served by $outlet';
  }

  @override
  String outletsOfLimit(int used, int limit) {
    return '$used of $limit';
  }

  @override
  String outletsOpenedDay(String day) {
    return 'opened $day';
  }

  @override
  String outletsRunBy(String name) {
    return 'run by $name';
  }

  @override
  String outletsKpiSalesNote(int delivered) {
    return '$delivered delivered';
  }

  @override
  String outletsKpiOrdersNote(int toConfirm) {
    return '$toConfirm to confirm';
  }

  @override
  String outletsKpiDue(String rs) {
    return '$rs still due';
  }

  @override
  String outletsStaffHere(int own) {
    return '$own here';
  }

  @override
  String outletsStaffAll(int own, int all) {
    return '$own here · $all work in every outlet';
  }

  @override
  String outletsStatusDone(String name, String status) {
    return '$name is $status';
  }

  @override
  String outletsPauseTitle(String name) {
    return 'Pause $name?';
  }

  @override
  String outletsCloseTitle(String name) {
    return 'Close $name?';
  }

  @override
  String outletsOpenTitle(String name) {
    return 'Open $name again?';
  }

  @override
  String get outletsStatusOpen => 'Open';

  @override
  String get outletsStatusPaused => 'Paused';

  @override
  String get outletsStatusClosed => 'Closed';

  @override
  String get outletsPeriodMonth => 'This month';

  @override
  String get outletsPeriodLast => 'Last month';

  @override
  String get outletsPeriodYear => 'This year';

  @override
  String get outletsCardPaused => 'Paused · no new orders';

  @override
  String get outletsCardClosed => 'Closed · history only';

  @override
  String outletsStaffCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count staff',
      one: '1 staff',
    );
    return '$_temp0';
  }

  @override
  String get outletsItsCities => 'its cities';

  @override
  String outletsAnd(String a, String b) {
    return '$a and $b';
  }

  @override
  String get outletsPlanMainNote =>
      'The main outlet can’t be paused or closed: orders from cities no other outlet serves go to it.';

  @override
  String get outletsPlanMainButton => 'Main outlet';

  @override
  String outletsPlanOpenNote(String where) {
    return 'Open: takes new orders for $where.';
  }

  @override
  String get outletsKeepOpen => 'Keep it open';

  @override
  String get outletsReopen => 'Reopen outlet';

  @override
  String get outletsOpenAgain => 'Open it again';

  @override
  String outletsPlanPausedNote(String where) {
    return 'Paused: new orders for $where go to the main outlet and its staff can’t sign in.';
  }

  @override
  String outletsPlanPausingNote(String where) {
    return 'Pausing stops new orders for $where and signs its staff out. Orders already placed carry on.';
  }

  @override
  String get outletsKeepPaused => 'Keep it paused';

  @override
  String get outletsPause => 'Pause';

  @override
  String get outletsPlanClosedNote =>
      'Closed: kept for its history. Reopen it to change it or take orders again.';

  @override
  String outletsWhyOrders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders are still open',
      one: '1 order is still open',
    );
    return '$_temp0';
  }

  @override
  String outletsWhyUnits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count units are still in stock',
      one: '1 unit is still in stock',
    );
    return '$_temp0';
  }

  @override
  String get outletsPlanCloseNote =>
      'Closing needs no open orders, no running bulk deals and zero stock. Its cities move to the main outlet.';

  @override
  String outletsPlanCantCloseNote(String why) {
    return 'Can’t close yet: $why. Deliver, cancel or move them first, or pause the outlet instead.';
  }

  @override
  String get outletsCloseOutlet => 'Close outlet';

  @override
  String get outletsCantClose => 'Can’t close yet';

  @override
  String get outletsPhoneEmpty => 'Enter the outlet’s phone number.';

  @override
  String get outletsPhoneBad =>
      'Enter a phone number, e.g. 0300 1234567 or 042 35761234.';

  @override
  String get outletsBlockName => 'Give the outlet a name';

  @override
  String get outletsBlockNameLong => 'Keep the name to 40 letters';

  @override
  String get outletsBlockPhone => 'Enter the phone number';

  @override
  String get outletsBlockPhoneBad => 'Check the phone number';

  @override
  String get outletsBlockAddress => 'Enter the address';

  @override
  String get outletsBlockAddressLong => 'Shorten the address';

  @override
  String get outletsOpenIt => 'Open it';

  @override
  String get outletsEdit => 'Edit';

  @override
  String get outletsOrderPending => 'Pending';

  @override
  String get outletsOrderConfirming => 'Confirming';

  @override
  String get outletsOrderProcessing => 'Processing';

  @override
  String get outletsOrderDelivered => 'Delivered';

  @override
  String get outletsOrderCompleted => 'Completed';

  @override
  String get outletsOrderInstalments => 'Instalments';

  @override
  String get outletsOrderCancelled => 'Cancelled';

  @override
  String get outletsMyBrand => 'my brand';

  @override
  String get teamSemOn => 'on';

  @override
  String get teamSemOff => 'off';

  @override
  String get ordersClearSearch => 'Clear search';

  @override
  String get ordersSearchPlaceholder =>
      'Order number, customer, phone or product';

  @override
  String get atompaySearchPlaceholder => 'Order number or product';

  @override
  String get ordersPlacedTitle => 'Placed';

  @override
  String ordersPlacedFilter(String when) {
    return 'Placed: $when';
  }

  @override
  String get ordersLoadErrorTitle => 'That didn\'t load';

  @override
  String get ordersLoadErrorBody =>
      'Atomshop couldn\'t load this just now. Nothing was changed.';

  @override
  String ordersErrorRef(String ref) {
    return 'Ref $ref';
  }

  @override
  String get ordersSaveErrorBody =>
      'That didn\'t save. Nothing was changed; try again.';

  @override
  String get ordersDeliveryFree => 'Free';

  @override
  String get ordersNotVerified => 'Not verified';

  @override
  String get ordersNotGiven => 'Not given';

  @override
  String get ordersDeliveredBy => 'Delivered by';
}
