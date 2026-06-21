import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('uz')
  ];

  /// No description provided for @errorDefault.
  ///
  /// In uz, this message translates to:
  /// **'⚠️ Xatolik, qayta urinib ko\'ring'**
  String get errorDefault;

  /// No description provided for @errorOk.
  ///
  /// In uz, this message translates to:
  /// **'OK'**
  String get errorOk;

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get save;

  /// No description provided for @continueBtn.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueBtn;

  /// No description provided for @hideText.
  ///
  /// In uz, this message translates to:
  /// **'Yashirish'**
  String get hideText;

  /// No description provided for @showText.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rsatish'**
  String get showText;

  /// No description provided for @errorGeneric.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi'**
  String get errorGeneric;

  /// No description provided for @confirm.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In uz, this message translates to:
  /// **'Ha'**
  String get yes;

  /// No description provided for @deleteBtn.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish'**
  String get deleteBtn;

  /// No description provided for @closeBtn.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get closeBtn;

  /// No description provided for @openStatus.
  ///
  /// In uz, this message translates to:
  /// **'Ochiq'**
  String get openStatus;

  /// No description provided for @closedStatus.
  ///
  /// In uz, this message translates to:
  /// **'Yopiq'**
  String get closedStatus;

  /// No description provided for @enterHint.
  ///
  /// In uz, this message translates to:
  /// **'Kiriting'**
  String get enterHint;

  /// No description provided for @enterNumber.
  ///
  /// In uz, this message translates to:
  /// **'Raqam kiriting'**
  String get enterNumber;

  /// No description provided for @fieldRequired.
  ///
  /// In uz, this message translates to:
  /// **'Maydonni to\'ldiring'**
  String get fieldRequired;

  /// No description provided for @roleOwner.
  ///
  /// In uz, this message translates to:
  /// **'Ferma egasi'**
  String get roleOwner;

  /// No description provided for @roleVet.
  ///
  /// In uz, this message translates to:
  /// **'Veterinar'**
  String get roleVet;

  /// No description provided for @roleFarmer.
  ///
  /// In uz, this message translates to:
  /// **'Fermer'**
  String get roleFarmer;

  /// No description provided for @roleCoowner.
  ///
  /// In uz, this message translates to:
  /// **'Hamegasi'**
  String get roleCoowner;

  /// No description provided for @roleVetDesc.
  ///
  /// In uz, this message translates to:
  /// **'Kasalliklar tashxisi, rasmiy davolanish qarorlari'**
  String get roleVetDesc;

  /// No description provided for @roleFarmerDesc.
  ///
  /// In uz, this message translates to:
  /// **'Hayvonlarni ro\'yxatga oladi, ma\'lumotlar kiritadi'**
  String get roleFarmerDesc;

  /// No description provided for @roleCoownerDesc.
  ///
  /// In uz, this message translates to:
  /// **'Egasi bilan bir xil huquqlar, a\'zolarni tasdiqlash'**
  String get roleCoownerDesc;

  /// No description provided for @speciesSigir.
  ///
  /// In uz, this message translates to:
  /// **'Sigir'**
  String get speciesSigir;

  /// No description provided for @speciesQoy.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'y'**
  String get speciesQoy;

  /// No description provided for @speciesEchki.
  ///
  /// In uz, this message translates to:
  /// **'Echki'**
  String get speciesEchki;

  /// No description provided for @speciesOt.
  ///
  /// In uz, this message translates to:
  /// **'Ot'**
  String get speciesOt;

  /// No description provided for @speciesChochqa.
  ///
  /// In uz, this message translates to:
  /// **'Cho\'chqa'**
  String get speciesChochqa;

  /// No description provided for @speciesBoshqa.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa'**
  String get speciesBoshqa;

  /// No description provided for @speciesSigirPlural.
  ///
  /// In uz, this message translates to:
  /// **'Mollar'**
  String get speciesSigirPlural;

  /// No description provided for @speciesQoyPlural.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'ylar'**
  String get speciesQoyPlural;

  /// No description provided for @speciesEchkiPlural.
  ///
  /// In uz, this message translates to:
  /// **'Echkilar'**
  String get speciesEchkiPlural;

  /// No description provided for @speciesOtPlural.
  ///
  /// In uz, this message translates to:
  /// **'Otlar'**
  String get speciesOtPlural;

  /// No description provided for @speciesAll.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get speciesAll;

  /// No description provided for @statusSoglom.
  ///
  /// In uz, this message translates to:
  /// **'Sog\'lom'**
  String get statusSoglom;

  /// No description provided for @statusDavolanmoqda.
  ///
  /// In uz, this message translates to:
  /// **'Davolanmoqda'**
  String get statusDavolanmoqda;

  /// No description provided for @statusKritik.
  ///
  /// In uz, this message translates to:
  /// **'Kritik'**
  String get statusKritik;

  /// No description provided for @statusKuzatuvda.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvda'**
  String get statusKuzatuvda;

  /// No description provided for @statusSotildi.
  ///
  /// In uz, this message translates to:
  /// **'Sotildi'**
  String get statusSotildi;

  /// No description provided for @statusOldi.
  ///
  /// In uz, this message translates to:
  /// **'O\'ldi'**
  String get statusOldi;

  /// No description provided for @severityRoutine.
  ///
  /// In uz, this message translates to:
  /// **'Oddiy'**
  String get severityRoutine;

  /// No description provided for @severityUrgent.
  ///
  /// In uz, this message translates to:
  /// **'Shoshilinch'**
  String get severityUrgent;

  /// No description provided for @severityEmergency.
  ///
  /// In uz, this message translates to:
  /// **'🚨 Favqulodda'**
  String get severityEmergency;

  /// No description provided for @googleSignInTitle.
  ///
  /// In uz, this message translates to:
  /// **'AgriVet'**
  String get googleSignInTitle;

  /// No description provided for @googleSignInSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ferma hayvonlarini boshqarish\nva AI veterinar yordamchi'**
  String get googleSignInSubtitle;

  /// No description provided for @googleSignInBtn.
  ///
  /// In uz, this message translates to:
  /// **'Google orqali kirish'**
  String get googleSignInBtn;

  /// No description provided for @googleSignInLoading.
  ///
  /// In uz, this message translates to:
  /// **'Kirish...'**
  String get googleSignInLoading;

  /// No description provided for @googleSignInError.
  ///
  /// In uz, this message translates to:
  /// **'Kirish amalga oshmadi. Qayta urinib ko\'ring.'**
  String get googleSignInError;

  /// No description provided for @googleSignInOrDivider.
  ///
  /// In uz, this message translates to:
  /// **'yoki'**
  String get googleSignInOrDivider;

  /// No description provided for @googleSignInViaPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqam orqali kirish'**
  String get googleSignInViaPhone;

  /// No description provided for @phoneAuthTitle.
  ///
  /// In uz, this message translates to:
  /// **'Telefon orqali kirish'**
  String get phoneAuthTitle;

  /// No description provided for @phoneAuthSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'SMS orqali tasdiqlash kodi yuboramiz'**
  String get phoneAuthSubtitle;

  /// No description provided for @phoneEnterNumber.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamingiz'**
  String get phoneEnterNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In uz, this message translates to:
  /// **'XX XXX XX XX'**
  String get phoneNumberHint;

  /// No description provided for @phoneSendCode.
  ///
  /// In uz, this message translates to:
  /// **'SMS kod yuborish'**
  String get phoneSendCode;

  /// No description provided for @phoneInvalidNumber.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamni to\'g\'ri kiriting'**
  String get phoneInvalidNumber;

  /// No description provided for @phoneTooManyRequests.
  ///
  /// In uz, this message translates to:
  /// **'Juda ko\'p urinish. Keyinroq urinib ko\'ring.'**
  String get phoneTooManyRequests;

  /// No description provided for @phoneError.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi. Qayta urinib ko\'ring.'**
  String get phoneError;

  /// No description provided for @phoneOtpTitle.
  ///
  /// In uz, this message translates to:
  /// **'SMS kodni kiriting'**
  String get phoneOtpTitle;

  /// No description provided for @phoneOtpSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'{phone} raqamiga kod yuborildi'**
  String phoneOtpSubtitle(String phone);

  /// No description provided for @phoneOtpHint.
  ///
  /// In uz, this message translates to:
  /// **'------'**
  String get phoneOtpHint;

  /// No description provided for @phoneOtpVerify.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get phoneOtpVerify;

  /// No description provided for @phoneOtpResend.
  ///
  /// In uz, this message translates to:
  /// **'Qayta yuborish'**
  String get phoneOtpResend;

  /// No description provided for @phoneOtpResendIn.
  ///
  /// In uz, this message translates to:
  /// **'{sec} soniyada qayta yuborish'**
  String phoneOtpResendIn(int sec);

  /// No description provided for @phoneOtpError.
  ///
  /// In uz, this message translates to:
  /// **'Kod noto\'g\'ri yoki muddati o\'tgan'**
  String get phoneOtpError;

  /// No description provided for @phoneOtpAutoVerified.
  ///
  /// In uz, this message translates to:
  /// **'Avtomatik tasdiqlandi'**
  String get phoneOtpAutoVerified;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ferma hayvonlarini boshqarish\nva AI veterinar yordamchi'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeFeatureAnimals.
  ///
  /// In uz, this message translates to:
  /// **'Hayvonlarni ro\'yxatga oling'**
  String get welcomeFeatureAnimals;

  /// No description provided for @welcomeFeatureAi.
  ///
  /// In uz, this message translates to:
  /// **'AI veterinar yordamchi'**
  String get welcomeFeatureAi;

  /// No description provided for @welcomeFeatureHistory.
  ///
  /// In uz, this message translates to:
  /// **'Emlash va kasallik tarixi'**
  String get welcomeFeatureHistory;

  /// No description provided for @welcomeFeatureSheets.
  ///
  /// In uz, this message translates to:
  /// **'Google Sheets sinxronizatsiya'**
  String get welcomeFeatureSheets;

  /// No description provided for @welcomeNewFarm.
  ///
  /// In uz, this message translates to:
  /// **'Yangi ferma ochish'**
  String get welcomeNewFarm;

  /// No description provided for @welcomeJoinFarm.
  ///
  /// In uz, this message translates to:
  /// **'Mavjud fermaga qo\'shilish'**
  String get welcomeJoinFarm;

  /// No description provided for @setupTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi ferma'**
  String get setupTitle;

  /// No description provided for @setupHeading.
  ///
  /// In uz, this message translates to:
  /// **'Fermangizni sozlash'**
  String get setupHeading;

  /// No description provided for @setupSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Barcha maydonlar to\'ldirilishi shart'**
  String get setupSubtitle;

  /// No description provided for @setupOwnerName.
  ///
  /// In uz, this message translates to:
  /// **'Ism-familiya'**
  String get setupOwnerName;

  /// No description provided for @setupOwnerNameHint.
  ///
  /// In uz, this message translates to:
  /// **'Ismingizni kiriting'**
  String get setupOwnerNameHint;

  /// No description provided for @setupFarmName.
  ///
  /// In uz, this message translates to:
  /// **'Ferma nomi'**
  String get setupFarmName;

  /// No description provided for @setupLocation.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get setupLocation;

  /// No description provided for @setupLocationHint.
  ///
  /// In uz, this message translates to:
  /// **'Tuman, viloyat'**
  String get setupLocationHint;

  /// No description provided for @setupEmail.
  ///
  /// In uz, this message translates to:
  /// **'Email (ixtiyoriy)'**
  String get setupEmail;

  /// No description provided for @setupPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get setupPhone;

  /// No description provided for @joinTitle.
  ///
  /// In uz, this message translates to:
  /// **'Fermaga qo\'shilish'**
  String get joinTitle;

  /// No description provided for @joinCodeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Farm kodi'**
  String get joinCodeTitle;

  /// No description provided for @joinCodeSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ferma egasidan farm kodini oling (AGVET-XXXXXX)'**
  String get joinCodeSubtitle;

  /// No description provided for @joinCodeCheck.
  ///
  /// In uz, this message translates to:
  /// **'Kodni tekshirish'**
  String get joinCodeCheck;

  /// No description provided for @joinCodeNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Farm kodi topilmadi. Tekshirib ko\'ring.'**
  String get joinCodeNotFound;

  /// No description provided for @joinPhoneRequired.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamini to\'liq kiriting'**
  String get joinPhoneRequired;

  /// No description provided for @joinRoleTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rolingizni tanlang'**
  String get joinRoleTitle;

  /// No description provided for @joinRoleSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'\"{farmName}\" fermasiga qo\'shilasiz'**
  String joinRoleSubtitle(String farmName);

  /// No description provided for @joinApprovalNote.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shilish so\'rovi ferma egasiga yuboriladi va tasdiqlashni kutadi.'**
  String get joinApprovalNote;

  /// No description provided for @joinDetailsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Shaxsiy ma\'lumotlar'**
  String get joinDetailsTitle;

  /// No description provided for @joinDetailsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'\"{farmName}\" — {role} rolida'**
  String joinDetailsSubtitle(String farmName, String role);

  /// No description provided for @joinNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'Ism-familiya'**
  String get joinNameLabel;

  /// No description provided for @joinNameHint.
  ///
  /// In uz, this message translates to:
  /// **'Ismingizni kiriting'**
  String get joinNameHint;

  /// No description provided for @joinNameRequired.
  ///
  /// In uz, this message translates to:
  /// **'Ismingizni kiriting'**
  String get joinNameRequired;

  /// No description provided for @joinLocationLabel.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get joinLocationLabel;

  /// No description provided for @joinLocationRequired.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni kiriting'**
  String get joinLocationRequired;

  /// No description provided for @joinEmailLabel.
  ///
  /// In uz, this message translates to:
  /// **'Email (ixtiyoriy)'**
  String get joinEmailLabel;

  /// No description provided for @joinPhoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get joinPhoneLabel;

  /// No description provided for @joinSubmit.
  ///
  /// In uz, this message translates to:
  /// **'So\'rov yuborish'**
  String get joinSubmit;

  /// No description provided for @pinSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'PIN kodingizni kiriting'**
  String get pinSubtitle;

  /// No description provided for @pinGreeting.
  ///
  /// In uz, this message translates to:
  /// **'Salom, {name}!'**
  String pinGreeting(String name);

  /// No description provided for @pinWrongMany.
  ///
  /// In uz, this message translates to:
  /// **'Juda ko\'p urinish. Egaliga xabar yuboring.'**
  String get pinWrongMany;

  /// No description provided for @pinWrong.
  ///
  /// In uz, this message translates to:
  /// **'Noto\'g\'ri PIN. Qaytadan urinib ko\'ring.'**
  String get pinWrong;

  /// No description provided for @pinSetupTitle.
  ///
  /// In uz, this message translates to:
  /// **'PIN kod o\'rnatish'**
  String get pinSetupTitle;

  /// No description provided for @pinSetupGreeting.
  ///
  /// In uz, this message translates to:
  /// **'Salom, {name}!\nKirishni himoya qilish uchun 4 xonali PIN kod o\'rnating.'**
  String pinSetupGreeting(String name);

  /// No description provided for @pinSetupEnter.
  ///
  /// In uz, this message translates to:
  /// **'PIN kodni kiriting'**
  String get pinSetupEnter;

  /// No description provided for @pinSetupConfirm.
  ///
  /// In uz, this message translates to:
  /// **'PIN kodni tasdiqlang'**
  String get pinSetupConfirm;

  /// No description provided for @pinSetupSave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash va kirish'**
  String get pinSetupSave;

  /// No description provided for @pinSetupReminder.
  ///
  /// In uz, this message translates to:
  /// **'PIN kodni eslab qoling — tizimga kirish uchun kerak bo\'ladi'**
  String get pinSetupReminder;

  /// No description provided for @pinSetupError4digits.
  ///
  /// In uz, this message translates to:
  /// **'PIN 4 ta raqamdan iborat bo\'lishi kerak'**
  String get pinSetupError4digits;

  /// No description provided for @pinSetupErrorMatch.
  ///
  /// In uz, this message translates to:
  /// **'PIN kodlar mos kelmadi'**
  String get pinSetupErrorMatch;

  /// No description provided for @changePinTitle.
  ///
  /// In uz, this message translates to:
  /// **'PIN kodni o\'zgartirish'**
  String get changePinTitle;

  /// No description provided for @changePinNote.
  ///
  /// In uz, this message translates to:
  /// **'Avval joriy PIN kodingizni, keyin yangi PIN kodingizni kiriting.'**
  String get changePinNote;

  /// No description provided for @changePinCurrentLabel.
  ///
  /// In uz, this message translates to:
  /// **'Joriy PIN kod'**
  String get changePinCurrentLabel;

  /// No description provided for @changePinNewLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yangi PIN kod'**
  String get changePinNewLabel;

  /// No description provided for @changePinConfirmLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yangi PIN kodni tasdiqlang'**
  String get changePinConfirmLabel;

  /// No description provided for @changePinSuccess.
  ///
  /// In uz, this message translates to:
  /// **'✅ PIN kod muvaffaqiyatli o\'zgartirildi'**
  String get changePinSuccess;

  /// No description provided for @changePinErrorCurrent4.
  ///
  /// In uz, this message translates to:
  /// **'Joriy PIN 4 ta raqamdan iborat'**
  String get changePinErrorCurrent4;

  /// No description provided for @changePinError4digits.
  ///
  /// In uz, this message translates to:
  /// **'Yangi PIN 4 ta raqamdan iborat bo\'lishi kerak'**
  String get changePinError4digits;

  /// No description provided for @changePinErrorMatch.
  ///
  /// In uz, this message translates to:
  /// **'Yangi PIN kodlar mos kelmadi'**
  String get changePinErrorMatch;

  /// No description provided for @changePinErrorSame.
  ///
  /// In uz, this message translates to:
  /// **'Yangi PIN joriy PIN bilan bir xil bo\'lishi mumkin emas'**
  String get changePinErrorSame;

  /// No description provided for @changePinErrorWrong.
  ///
  /// In uz, this message translates to:
  /// **'Joriy PIN noto\'g\'ri. Qaytadan kiriting.'**
  String get changePinErrorWrong;

  /// No description provided for @changePinErrorTooMany.
  ///
  /// In uz, this message translates to:
  /// **'Juda ko\'p noto\'g\'ri urinish. Ilovadan chiqib qayta kiring.'**
  String get changePinErrorTooMany;

  /// No description provided for @homeGreeting.
  ///
  /// In uz, this message translates to:
  /// **'Salom, {name}! 👋'**
  String homeGreeting(String name);

  /// No description provided for @homeLock.
  ///
  /// In uz, this message translates to:
  /// **'Qulflash'**
  String get homeLock;

  /// No description provided for @homeOpenCasesAlert.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta ochiq kasallik holati'**
  String homeOpenCasesAlert(int count);

  /// No description provided for @homeDueSoonAlert.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta emlash muddati yaqinlashmoqda'**
  String homeDueSoonAlert(int count);

  /// No description provided for @homeTotalAnimals.
  ///
  /// In uz, this message translates to:
  /// **'Jami hayvon'**
  String get homeTotalAnimals;

  /// No description provided for @homeTodayMilk.
  ///
  /// In uz, this message translates to:
  /// **'Jami sut'**
  String get homeTodayMilk;

  /// No description provided for @homeAnimalsSection.
  ///
  /// In uz, this message translates to:
  /// **'Hayvonlar'**
  String get homeAnimalsSection;

  /// No description provided for @homeQuickActions.
  ///
  /// In uz, this message translates to:
  /// **'Tezkor amallar'**
  String get homeQuickActions;

  /// No description provided for @homeNavHome.
  ///
  /// In uz, this message translates to:
  /// **'Bosh'**
  String get homeNavHome;

  /// No description provided for @homeNavAnimals.
  ///
  /// In uz, this message translates to:
  /// **'Hayvonlar'**
  String get homeNavAnimals;

  /// No description provided for @homeNavHealth.
  ///
  /// In uz, this message translates to:
  /// **'Kasallik'**
  String get homeNavHealth;

  /// No description provided for @homeNavFarm.
  ///
  /// In uz, this message translates to:
  /// **'Ferma'**
  String get homeNavFarm;

  /// No description provided for @homeActionHealth.
  ///
  /// In uz, this message translates to:
  /// **'Kasallik holati'**
  String get homeActionHealth;

  /// No description provided for @homeActionHealthSub.
  ///
  /// In uz, this message translates to:
  /// **'Belgilarni kiriting, AI tashxis qo\'yadi'**
  String get homeActionHealthSub;

  /// No description provided for @homeActionVacc.
  ///
  /// In uz, this message translates to:
  /// **'Emlash'**
  String get homeActionVacc;

  /// No description provided for @homeActionVaccSub.
  ///
  /// In uz, this message translates to:
  /// **'Emlash qo\'shing'**
  String get homeActionVaccSub;

  /// No description provided for @homeActionMilk.
  ///
  /// In uz, this message translates to:
  /// **'Sut'**
  String get homeActionMilk;

  /// No description provided for @homeActionMilkSub.
  ///
  /// In uz, this message translates to:
  /// **'Sutni ro\'yxatga oling'**
  String get homeActionMilkSub;

  /// No description provided for @homeActionWeight.
  ///
  /// In uz, this message translates to:
  /// **'Vazn'**
  String get homeActionWeight;

  /// No description provided for @homeActionWeightSub.
  ///
  /// In uz, this message translates to:
  /// **'Vazn o\'lchovi'**
  String get homeActionWeightSub;

  /// No description provided for @homeActionReport.
  ///
  /// In uz, this message translates to:
  /// **'Hisobot'**
  String get homeActionReport;

  /// No description provided for @homeActionReportSub.
  ///
  /// In uz, this message translates to:
  /// **'Ferma hisobotini ko\'ring'**
  String get homeActionReportSub;

  /// No description provided for @homeAnimalCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta'**
  String homeAnimalCount(int count);

  /// No description provided for @farmTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ferma'**
  String get farmTitle;

  /// No description provided for @farmNoData.
  ///
  /// In uz, this message translates to:
  /// **'Ferma ma\'lumoti topilmadi'**
  String get farmNoData;

  /// No description provided for @farmSheets.
  ///
  /// In uz, this message translates to:
  /// **'Google Sheets'**
  String get farmSheets;

  /// No description provided for @farmSheetsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ferma ma\'lumotlarini ko\'ring'**
  String get farmSheetsSubtitle;

  /// No description provided for @farmChangePin.
  ///
  /// In uz, this message translates to:
  /// **'PIN kodni o\'zgartirish'**
  String get farmChangePin;

  /// No description provided for @farmLock.
  ///
  /// In uz, this message translates to:
  /// **'Qulflash'**
  String get farmLock;

  /// No description provided for @farmLogout.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get farmLogout;

  /// No description provided for @farmLogoutConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Hisobdan chiqmoqchimisiz?'**
  String get farmLogoutConfirm;

  /// No description provided for @farmOwnerLabel.
  ///
  /// In uz, this message translates to:
  /// **'Egasi'**
  String get farmOwnerLabel;

  /// No description provided for @farmEmailLabel.
  ///
  /// In uz, this message translates to:
  /// **'Email'**
  String get farmEmailLabel;

  /// No description provided for @farmYouLabel.
  ///
  /// In uz, this message translates to:
  /// **'Siz'**
  String get farmYouLabel;

  /// No description provided for @farmRoleLabel.
  ///
  /// In uz, this message translates to:
  /// **'Rol'**
  String get farmRoleLabel;

  /// No description provided for @farmCodeCopied.
  ///
  /// In uz, this message translates to:
  /// **'Farm kodi nusxalandi'**
  String get farmCodeCopied;

  /// No description provided for @farmLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get farmLanguage;

  /// No description provided for @farmLanguageUz.
  ///
  /// In uz, this message translates to:
  /// **'🇺🇿 O\'zbek'**
  String get farmLanguageUz;

  /// No description provided for @farmLanguageRu.
  ///
  /// In uz, this message translates to:
  /// **'🇷🇺 Русский'**
  String get farmLanguageRu;

  /// No description provided for @settingsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settingsTitle;

  /// No description provided for @settingsFarmSection.
  ///
  /// In uz, this message translates to:
  /// **'Ferma ma\'lumoti'**
  String get settingsFarmSection;

  /// No description provided for @settingsAccountSection.
  ///
  /// In uz, this message translates to:
  /// **'Sizning hisobingiz'**
  String get settingsAccountSection;

  /// No description provided for @settingsSecuritySection.
  ///
  /// In uz, this message translates to:
  /// **'Xavfsizlik'**
  String get settingsSecuritySection;

  /// No description provided for @settingsFarmName.
  ///
  /// In uz, this message translates to:
  /// **'Ferma nomi'**
  String get settingsFarmName;

  /// No description provided for @settingsFarmCode.
  ///
  /// In uz, this message translates to:
  /// **'Ferma kodi'**
  String get settingsFarmCode;

  /// No description provided for @settingsLocation.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get settingsLocation;

  /// No description provided for @settingsPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon'**
  String get settingsPhone;

  /// No description provided for @settingsLogoutStep2Title.
  ///
  /// In uz, this message translates to:
  /// **'Ishonchingiz komilmi?'**
  String get settingsLogoutStep2Title;

  /// No description provided for @settingsLogoutStep2Body.
  ///
  /// In uz, this message translates to:
  /// **'Tizimdan chiqib ketasiz. Qayta kirish uchun PIN kod kerak bo\'ladi.'**
  String get settingsLogoutStep2Body;

  /// No description provided for @settingsLogoutFinal.
  ///
  /// In uz, this message translates to:
  /// **'Ha, chiqish'**
  String get settingsLogoutFinal;

  /// No description provided for @animalsAllTitle.
  ///
  /// In uz, this message translates to:
  /// **'🐾 Barcha hayvonlar'**
  String get animalsAllTitle;

  /// No description provided for @animalsSearch.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish (ism, quloq raqami...)'**
  String get animalsSearch;

  /// No description provided for @animalsAdd.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon qo\'shish'**
  String get animalsAdd;

  /// No description provided for @animalsEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon yo\'q'**
  String get animalsEmpty;

  /// No description provided for @animalsEmptySpecies.
  ///
  /// In uz, this message translates to:
  /// **'{species} yo\'q'**
  String animalsEmptySpecies(String species);

  /// No description provided for @animalsAddNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi hayvon qo\'shing'**
  String get animalsAddNew;

  /// No description provided for @addAnimalTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon qo\'shish'**
  String get addAnimalTitle;

  /// No description provided for @addAnimalSpeciesSection.
  ///
  /// In uz, this message translates to:
  /// **'Tur'**
  String get addAnimalSpeciesSection;

  /// No description provided for @addAnimalBasicSection.
  ///
  /// In uz, this message translates to:
  /// **'Asosiy ma\'lumot'**
  String get addAnimalBasicSection;

  /// No description provided for @addAnimalEarTag.
  ///
  /// In uz, this message translates to:
  /// **'Quloq raqami *'**
  String get addAnimalEarTag;

  /// No description provided for @addAnimalEarTagRequired.
  ///
  /// In uz, this message translates to:
  /// **'Quloq raqamini kiriting'**
  String get addAnimalEarTagRequired;

  /// No description provided for @addAnimalName.
  ///
  /// In uz, this message translates to:
  /// **'Nomi (ixtiyoriy)'**
  String get addAnimalName;

  /// No description provided for @addAnimalSex.
  ///
  /// In uz, this message translates to:
  /// **'Jins'**
  String get addAnimalSex;

  /// No description provided for @addAnimalSexMale.
  ///
  /// In uz, this message translates to:
  /// **'♂ Erkak'**
  String get addAnimalSexMale;

  /// No description provided for @addAnimalSexFemale.
  ///
  /// In uz, this message translates to:
  /// **'♀ Urdona'**
  String get addAnimalSexFemale;

  /// No description provided for @addAnimalSexUnknown.
  ///
  /// In uz, this message translates to:
  /// **'Noma\'lum'**
  String get addAnimalSexUnknown;

  /// No description provided for @addAnimalDob.
  ///
  /// In uz, this message translates to:
  /// **'Tug\'ilgan sana'**
  String get addAnimalDob;

  /// No description provided for @addAnimalDetailsSection.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shimcha ma\'lumot'**
  String get addAnimalDetailsSection;

  /// No description provided for @addAnimalBreed.
  ///
  /// In uz, this message translates to:
  /// **'Zoti'**
  String get addAnimalBreed;

  /// No description provided for @addAnimalColor.
  ///
  /// In uz, this message translates to:
  /// **'Rangi'**
  String get addAnimalColor;

  /// No description provided for @addAnimalOrigin.
  ///
  /// In uz, this message translates to:
  /// **'Kelib chiqishi (tuman, viloyat)'**
  String get addAnimalOrigin;

  /// No description provided for @addAnimalParentsSection.
  ///
  /// In uz, this message translates to:
  /// **'Ota-ona (ixtiyoriy)'**
  String get addAnimalParentsSection;

  /// No description provided for @addAnimalMother.
  ///
  /// In uz, this message translates to:
  /// **'Onasining quloq raqami'**
  String get addAnimalMother;

  /// No description provided for @addAnimalFather.
  ///
  /// In uz, this message translates to:
  /// **'Otasining quloq raqami'**
  String get addAnimalFather;

  /// No description provided for @healthTitle.
  ///
  /// In uz, this message translates to:
  /// **'🏥 Kasallik holatlari'**
  String get healthTitle;

  /// No description provided for @healthOpen.
  ///
  /// In uz, this message translates to:
  /// **'Ochiq'**
  String get healthOpen;

  /// No description provided for @healthSevere.
  ///
  /// In uz, this message translates to:
  /// **'Jiddiy'**
  String get healthSevere;

  /// No description provided for @healthClosed.
  ///
  /// In uz, this message translates to:
  /// **'Yopiq'**
  String get healthClosed;

  /// No description provided for @healthEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Kasallik holati yo\'q 🎉'**
  String get healthEmpty;

  /// No description provided for @healthAddBtn.
  ///
  /// In uz, this message translates to:
  /// **'Holat qo\'shish'**
  String get healthAddBtn;

  /// No description provided for @healthAddTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kasallik holati qo\'shish'**
  String get healthAddTitle;

  /// No description provided for @healthAnimalHint.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon tanlang'**
  String get healthAnimalHint;

  /// No description provided for @healthAnimalLabel.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon'**
  String get healthAnimalLabel;

  /// No description provided for @healthAnimalRequired.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon tanlang'**
  String get healthAnimalRequired;

  /// No description provided for @healthSymptomsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Belgilar'**
  String get healthSymptomsLabel;

  /// No description provided for @healthSymptomsRequired.
  ///
  /// In uz, this message translates to:
  /// **'Belgilarni kiriting'**
  String get healthSymptomsRequired;

  /// No description provided for @healthSeverityLabel.
  ///
  /// In uz, this message translates to:
  /// **'Jiddiylik'**
  String get healthSeverityLabel;

  /// No description provided for @healthClose.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get healthClose;

  /// No description provided for @healthAiLabel.
  ///
  /// In uz, this message translates to:
  /// **'🤖 AI tashxisi:'**
  String get healthAiLabel;

  /// No description provided for @healthConfidence.
  ///
  /// In uz, this message translates to:
  /// **'Ishonch: {pct}%'**
  String healthConfidence(int pct);

  /// No description provided for @animalNotFoundTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon topilmadi'**
  String get animalNotFoundTitle;

  /// No description provided for @animalNotFoundBody.
  ///
  /// In uz, this message translates to:
  /// **'Bu hayvon topilmadi'**
  String get animalNotFoundBody;

  /// No description provided for @animalTabInfo.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumot'**
  String get animalTabInfo;

  /// No description provided for @animalTabHealth.
  ///
  /// In uz, this message translates to:
  /// **'Kasallik'**
  String get animalTabHealth;

  /// No description provided for @animalTabVacc.
  ///
  /// In uz, this message translates to:
  /// **'Emlash'**
  String get animalTabVacc;

  /// No description provided for @animalTabWeight.
  ///
  /// In uz, this message translates to:
  /// **'Vazn'**
  String get animalTabWeight;

  /// No description provided for @animalMenuHealth.
  ///
  /// In uz, this message translates to:
  /// **'🏥 Kasallik qo\'shish'**
  String get animalMenuHealth;

  /// No description provided for @animalMenuVacc.
  ///
  /// In uz, this message translates to:
  /// **'💉 Emlash qo\'shish'**
  String get animalMenuVacc;

  /// No description provided for @animalMenuWeight.
  ///
  /// In uz, this message translates to:
  /// **'⚖️ Vazn qo\'shish'**
  String get animalMenuWeight;

  /// No description provided for @animalMenuSold.
  ///
  /// In uz, this message translates to:
  /// **'✅ Sotildi'**
  String get animalMenuSold;

  /// No description provided for @animalMenuDead.
  ///
  /// In uz, this message translates to:
  /// **'💀 O\'ldi'**
  String get animalMenuDead;

  /// No description provided for @animalMenuDelete.
  ///
  /// In uz, this message translates to:
  /// **'🗑️ O\'chirish'**
  String get animalMenuDelete;

  /// No description provided for @animalFabHealth.
  ///
  /// In uz, this message translates to:
  /// **'Kasallik'**
  String get animalFabHealth;

  /// No description provided for @animalFabVacc.
  ///
  /// In uz, this message translates to:
  /// **'Emlash'**
  String get animalFabVacc;

  /// No description provided for @animalFabWeight.
  ///
  /// In uz, this message translates to:
  /// **'Vazn'**
  String get animalFabWeight;

  /// No description provided for @animalConfirmSold.
  ///
  /// In uz, this message translates to:
  /// **'Sotildi deb belgilansinmi?'**
  String get animalConfirmSold;

  /// No description provided for @animalConfirmDead.
  ///
  /// In uz, this message translates to:
  /// **'O\'ldi deb belgilansinmi?'**
  String get animalConfirmDead;

  /// No description provided for @animalConfirmDelete.
  ///
  /// In uz, this message translates to:
  /// **'{name} o\'chirilsinmi?'**
  String animalConfirmDelete(String name);

  /// No description provided for @animalInfoSpecies.
  ///
  /// In uz, this message translates to:
  /// **'Tur'**
  String get animalInfoSpecies;

  /// No description provided for @animalInfoBreed.
  ///
  /// In uz, this message translates to:
  /// **'Zot'**
  String get animalInfoBreed;

  /// No description provided for @animalInfoSex.
  ///
  /// In uz, this message translates to:
  /// **'Jins'**
  String get animalInfoSex;

  /// No description provided for @animalInfoAge.
  ///
  /// In uz, this message translates to:
  /// **'Yoshi'**
  String get animalInfoAge;

  /// No description provided for @animalInfoAgeValue.
  ///
  /// In uz, this message translates to:
  /// **'{count} yosh'**
  String animalInfoAgeValue(int count);

  /// No description provided for @animalInfoColor.
  ///
  /// In uz, this message translates to:
  /// **'Rang'**
  String get animalInfoColor;

  /// No description provided for @animalInfoOrigin.
  ///
  /// In uz, this message translates to:
  /// **'Kelib chiqishi'**
  String get animalInfoOrigin;

  /// No description provided for @animalInfoMother.
  ///
  /// In uz, this message translates to:
  /// **'Onasi'**
  String get animalInfoMother;

  /// No description provided for @animalInfoFather.
  ///
  /// In uz, this message translates to:
  /// **'Otasi'**
  String get animalInfoFather;

  /// No description provided for @animalInfoPregnancy.
  ///
  /// In uz, this message translates to:
  /// **'Homiladorlik'**
  String get animalInfoPregnancy;

  /// No description provided for @animalPregnant.
  ///
  /// In uz, this message translates to:
  /// **'🤰 Homilador ({date})'**
  String animalPregnant(String date);

  /// No description provided for @animalCalved.
  ///
  /// In uz, this message translates to:
  /// **'✅ Bola tug\'ildi'**
  String get animalCalved;

  /// No description provided for @animalHealthEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Kasallik holati yo\'q'**
  String get animalHealthEmpty;

  /// No description provided for @animalVaccEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Emlash tarixi yo\'q'**
  String get animalVaccEmpty;

  /// No description provided for @animalWeightEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Vazn o\'lchovi yo\'q'**
  String get animalWeightEmpty;

  /// No description provided for @animalVaccDate.
  ///
  /// In uz, this message translates to:
  /// **'Sana: {date}'**
  String animalVaccDate(String date);

  /// No description provided for @animalVaccNextLabel.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi:'**
  String get animalVaccNextLabel;

  /// No description provided for @animalHealthSymptomsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Belgilar:'**
  String get animalHealthSymptomsLabel;

  /// No description provided for @animalHealthAiLabel.
  ///
  /// In uz, this message translates to:
  /// **'AI tashxisi:'**
  String get animalHealthAiLabel;

  /// No description provided for @animalHealthConfidence.
  ///
  /// In uz, this message translates to:
  /// **'Ishonch: {pct}%'**
  String animalHealthConfidence(int pct);

  /// No description provided for @milkTitle.
  ///
  /// In uz, this message translates to:
  /// **'🥛 Sut'**
  String get milkTitle;

  /// No description provided for @milkTodayLabel.
  ///
  /// In uz, this message translates to:
  /// **'Bugungi sut'**
  String get milkTodayLabel;

  /// No description provided for @milkMorning.
  ///
  /// In uz, this message translates to:
  /// **'🌅 Ertalab'**
  String get milkMorning;

  /// No description provided for @milkEvening.
  ///
  /// In uz, this message translates to:
  /// **'🌙 Kechqurun'**
  String get milkEvening;

  /// No description provided for @milkRecent.
  ///
  /// In uz, this message translates to:
  /// **'So\'nggi yozuvlar'**
  String get milkRecent;

  /// No description provided for @milkEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Sut yozuvi yo\'q'**
  String get milkEmpty;

  /// No description provided for @milkAmountLabel.
  ///
  /// In uz, this message translates to:
  /// **'Miqdor (litr)'**
  String get milkAmountLabel;

  /// No description provided for @milkMorningTitle.
  ///
  /// In uz, this message translates to:
  /// **'🌅 Ertalab sut'**
  String get milkMorningTitle;

  /// No description provided for @milkEveningTitle.
  ///
  /// In uz, this message translates to:
  /// **'🌙 Kechqurun sut'**
  String get milkEveningTitle;

  /// No description provided for @vaccTitle.
  ///
  /// In uz, this message translates to:
  /// **'💉 Emlash'**
  String get vaccTitle;

  /// No description provided for @vaccDueSoon.
  ///
  /// In uz, this message translates to:
  /// **'⚠️ Yaqinlashgan emlashlar ({count})'**
  String vaccDueSoon(int count);

  /// No description provided for @vaccAll.
  ///
  /// In uz, this message translates to:
  /// **'Barcha emlashlar ({count})'**
  String vaccAll(int count);

  /// No description provided for @vaccEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Emlash yozuvi yo\'q'**
  String get vaccEmpty;

  /// No description provided for @vaccAddBtn.
  ///
  /// In uz, this message translates to:
  /// **'Emlash qo\'shish'**
  String get vaccAddBtn;

  /// No description provided for @vaccAddTitle.
  ///
  /// In uz, this message translates to:
  /// **'Emlash qo\'shish'**
  String get vaccAddTitle;

  /// No description provided for @vaccAnimalHint.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon tanlang'**
  String get vaccAnimalHint;

  /// No description provided for @vaccAnimalLabel.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon'**
  String get vaccAnimalLabel;

  /// No description provided for @vaccAnimalRequired.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon tanlang'**
  String get vaccAnimalRequired;

  /// No description provided for @vaccNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'Vaksina nomi'**
  String get vaccNameLabel;

  /// No description provided for @vaccNextDueBtn.
  ///
  /// In uz, this message translates to:
  /// **'Keyingisi'**
  String get vaccNextDueBtn;

  /// No description provided for @vaccDateLabel.
  ///
  /// In uz, this message translates to:
  /// **'Sana: {date}'**
  String vaccDateLabel(String date);

  /// No description provided for @vaccNextLabel.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi:'**
  String get vaccNextLabel;

  /// No description provided for @weightTitle.
  ///
  /// In uz, this message translates to:
  /// **'⚖️ Vazn'**
  String get weightTitle;

  /// No description provided for @weightEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Vazn o\'lchovi yo\'q'**
  String get weightEmpty;

  /// No description provided for @weightAddBtn.
  ///
  /// In uz, this message translates to:
  /// **'Vazn qo\'shish'**
  String get weightAddBtn;

  /// No description provided for @weightAddTitle.
  ///
  /// In uz, this message translates to:
  /// **'Vazn qo\'shish'**
  String get weightAddTitle;

  /// No description provided for @weightAnimalHint.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon tanlang'**
  String get weightAnimalHint;

  /// No description provided for @weightAnimalLabel.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon'**
  String get weightAnimalLabel;

  /// No description provided for @weightAnimalRequired.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon tanlang'**
  String get weightAnimalRequired;

  /// No description provided for @weightLabel.
  ///
  /// In uz, this message translates to:
  /// **'Vazn'**
  String get weightLabel;

  /// No description provided for @reportTitle.
  ///
  /// In uz, this message translates to:
  /// **'📊 Hisobot'**
  String get reportTitle;

  /// No description provided for @report7Days.
  ///
  /// In uz, this message translates to:
  /// **'7 kun'**
  String get report7Days;

  /// No description provided for @report30Days.
  ///
  /// In uz, this message translates to:
  /// **'30 kun'**
  String get report30Days;

  /// No description provided for @report1Year.
  ///
  /// In uz, this message translates to:
  /// **'1 yil'**
  String get report1Year;

  /// No description provided for @reportOverview.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy ko\'rsatkichlar ({days} kun)'**
  String reportOverview(int days);

  /// No description provided for @reportTotalAnimals.
  ///
  /// In uz, this message translates to:
  /// **'Jami hayvon'**
  String get reportTotalAnimals;

  /// No description provided for @reportHealthy.
  ///
  /// In uz, this message translates to:
  /// **'Sog\'lom'**
  String get reportHealthy;

  /// No description provided for @reportTreatment.
  ///
  /// In uz, this message translates to:
  /// **'Davolanmoqda'**
  String get reportTreatment;

  /// No description provided for @reportCritical.
  ///
  /// In uz, this message translates to:
  /// **'Kritik'**
  String get reportCritical;

  /// No description provided for @reportTeam.
  ///
  /// In uz, this message translates to:
  /// **'Jamoat a\'zolari'**
  String get reportTeam;

  /// No description provided for @reportBirths.
  ///
  /// In uz, this message translates to:
  /// **'Tug\'ilishlar'**
  String get reportBirths;

  /// No description provided for @reportVaccDue.
  ///
  /// In uz, this message translates to:
  /// **'Yaqin emlashlar'**
  String get reportVaccDue;

  /// No description provided for @reportSpeciesBreakdown.
  ///
  /// In uz, this message translates to:
  /// **'Tur bo\'yicha taqsimot'**
  String get reportSpeciesBreakdown;

  /// No description provided for @reportAnimalStatus.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon holati'**
  String get reportAnimalStatus;

  /// No description provided for @reportHealthStats.
  ///
  /// In uz, this message translates to:
  /// **'Kasallik holatlari'**
  String get reportHealthStats;

  /// No description provided for @reportOpenCases.
  ///
  /// In uz, this message translates to:
  /// **'Ochiq holatlar'**
  String get reportOpenCases;

  /// No description provided for @reportClosedCases.
  ///
  /// In uz, this message translates to:
  /// **'Yopiq holatlar'**
  String get reportClosedCases;

  /// No description provided for @reportMilkStats.
  ///
  /// In uz, this message translates to:
  /// **'Sut ishlab chiqarish'**
  String get reportMilkStats;

  /// No description provided for @reportTotalMilk.
  ///
  /// In uz, this message translates to:
  /// **'Jami sut ({days} kun)'**
  String reportTotalMilk(int days);

  /// No description provided for @reportAvgMilk.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha kunlik'**
  String get reportAvgMilk;

  /// No description provided for @reportHealthBySpecies.
  ///
  /// In uz, this message translates to:
  /// **'Tur bo\'yicha sog\'lik holati'**
  String get reportHealthBySpecies;

  /// No description provided for @reportLegendHealthy.
  ///
  /// In uz, this message translates to:
  /// **'Sog\'lom'**
  String get reportLegendHealthy;

  /// No description provided for @reportLegendTreatment.
  ///
  /// In uz, this message translates to:
  /// **'Davolanmoqda'**
  String get reportLegendTreatment;

  /// No description provided for @reportLegendObserved.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvda'**
  String get reportLegendObserved;

  /// No description provided for @reportLegendCritical.
  ///
  /// In uz, this message translates to:
  /// **'Kritik'**
  String get reportLegendCritical;

  /// No description provided for @menuLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get menuLanguage;

  /// No description provided for @menuLangUz.
  ///
  /// In uz, this message translates to:
  /// **'O\'zbekcha'**
  String get menuLangUz;

  /// No description provided for @menuLangRu.
  ///
  /// In uz, this message translates to:
  /// **'Русский'**
  String get menuLangRu;

  /// No description provided for @menuEditProfile.
  ///
  /// In uz, this message translates to:
  /// **'Ferma ma\'lumotlari'**
  String get menuEditProfile;

  /// No description provided for @menuLogout.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get menuLogout;

  /// No description provided for @menuLogoutConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Hisobdan chiqmoqchimisiz?'**
  String get menuLogoutConfirm;

  /// No description provided for @menuChangeAccount.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntni almashtirish'**
  String get menuChangeAccount;

  /// No description provided for @menuChangeAccountConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Joriy akkauntdan chiqib, boshqa akkaunt bilan kirasizmi?'**
  String get menuChangeAccountConfirm;

  /// No description provided for @farmPickerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Fermani tanlang'**
  String get farmPickerTitle;

  /// No description provided for @farmPickerSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntingizga ulangan fermalar'**
  String get farmPickerSubtitle;

  /// No description provided for @farmPickerNewFarm.
  ///
  /// In uz, this message translates to:
  /// **'Yangi ferma qo\'shish'**
  String get farmPickerNewFarm;

  /// No description provided for @bulkVaccTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ommaviy emlash'**
  String get bulkVaccTitle;

  /// No description provided for @bulkVaccSelectAll.
  ///
  /// In uz, this message translates to:
  /// **'Barchasini tanlash'**
  String get bulkVaccSelectAll;

  /// No description provided for @bulkVaccDeselectAll.
  ///
  /// In uz, this message translates to:
  /// **'Tanlovni bekor qilish'**
  String get bulkVaccDeselectAll;

  /// No description provided for @bulkVaccInvert.
  ///
  /// In uz, this message translates to:
  /// **'Teskari tanlash'**
  String get bulkVaccInvert;

  /// No description provided for @bulkVaccSelected.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta tanlandi'**
  String bulkVaccSelected(int count);

  /// No description provided for @bulkVaccSaveBtn.
  ///
  /// In uz, this message translates to:
  /// **'Emlash qo\'shish'**
  String get bulkVaccSaveBtn;

  /// No description provided for @bulkVaccFormTitle.
  ///
  /// In uz, this message translates to:
  /// **'Emlash ma\'lumotlari'**
  String get bulkVaccFormTitle;

  /// No description provided for @bulkVaccVaccineName.
  ///
  /// In uz, this message translates to:
  /// **'Vaksina nomi'**
  String get bulkVaccVaccineName;

  /// No description provided for @bulkVaccDate.
  ///
  /// In uz, this message translates to:
  /// **'Emlash sanasi'**
  String get bulkVaccDate;

  /// No description provided for @bulkVaccNextDue.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi sana (ixtiyoriy)'**
  String get bulkVaccNextDue;

  /// No description provided for @bulkVaccSuccess.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta hayvon emlantirildi'**
  String bulkVaccSuccess(int count);

  /// No description provided for @bulkVaccNoneSelected.
  ///
  /// In uz, this message translates to:
  /// **'Kamida 1 ta hayvon tanlang'**
  String get bulkVaccNoneSelected;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sonya — AI Veterinar'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'15 yil tajribali Farg\'ona vodiysi veterinari'**
  String get aiAssistantSubtitle;

  /// No description provided for @aiInputHint.
  ///
  /// In uz, this message translates to:
  /// **'Hayvon haqida yozing...'**
  String get aiInputHint;

  /// No description provided for @aiRecording.
  ///
  /// In uz, this message translates to:
  /// **'Yozilmoqda... (qo\'lni oling)'**
  String get aiRecording;

  /// No description provided for @aiEmergency.
  ///
  /// In uz, this message translates to:
  /// **'FAVQULODDA HOLAT'**
  String get aiEmergency;

  /// No description provided for @aiFirstAid.
  ///
  /// In uz, this message translates to:
  /// **'Darhol choralar:'**
  String get aiFirstAid;

  /// No description provided for @aiFollowUp.
  ///
  /// In uz, this message translates to:
  /// **'{days} kundan so\'ng tekshirish'**
  String aiFollowUp(int days);

  /// No description provided for @aiListenBtn.
  ///
  /// In uz, this message translates to:
  /// **'Eshitish'**
  String get aiListenBtn;

  /// No description provided for @aiStopBtn.
  ///
  /// In uz, this message translates to:
  /// **'To\'xtatish'**
  String get aiStopBtn;

  /// No description provided for @aiMicPermission.
  ///
  /// In uz, this message translates to:
  /// **'Mikrofon ruxsati kerak'**
  String get aiMicPermission;

  /// No description provided for @aiCallVet.
  ///
  /// In uz, this message translates to:
  /// **'Veterinar chaqirish'**
  String get aiCallVet;

  /// No description provided for @aiOnline.
  ///
  /// In uz, this message translates to:
  /// **'Online'**
  String get aiOnline;

  /// No description provided for @aiExperience.
  ///
  /// In uz, this message translates to:
  /// **'AI Veterinar · 15 yil tajriba'**
  String get aiExperience;
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
      <String>['ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
