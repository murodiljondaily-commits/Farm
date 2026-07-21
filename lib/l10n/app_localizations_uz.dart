// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get errorDefault => '⚠️ Xatolik, qayta urinib ko\'ring';

  @override
  String get errorOk => 'OK';

  @override
  String get cancel => 'Bekor';

  @override
  String get save => 'Saqlash';

  @override
  String get continueBtn => 'Davom etish';

  @override
  String get hideText => 'Yashirish';

  @override
  String get showText => 'Ko\'rsatish';

  @override
  String get errorGeneric => 'Xatolik yuz berdi';

  @override
  String get confirm => 'Tasdiqlash';

  @override
  String get yes => 'Ha';

  @override
  String get deleteBtn => 'O\'chirish';

  @override
  String get closeBtn => 'Yopish';

  @override
  String get deleteConfirmTitle => 'O\'chirishni tasdiqlang';

  @override
  String get deleteConfirmBody => 'Bu yozuvni o\'chirmoqchimisiz?';

  @override
  String errorWithDetail(String error) {
    return 'Xatolik: $error';
  }

  @override
  String get openStatus => 'Ochiq';

  @override
  String get closedStatus => 'Yopiq';

  @override
  String get enterHint => 'Kiriting';

  @override
  String get enterNumber => 'Raqam kiriting';

  @override
  String get fieldRequired => 'Maydonni to\'ldiring';

  @override
  String get proposedActionDone => 'Bajarildi';

  @override
  String get proposedActionCancelled => 'Bekor qilindi';

  @override
  String get proposedActionDefaultSummary => 'Amalni tasdiqlang';

  @override
  String get proposedActionNeedsConfirm => 'Tasdiqlash kerak';

  @override
  String proposedActionAffectedCount(int count) {
    return '$count ta hayvon';
  }

  @override
  String get proposedActionCancelBtn => 'Bekor qilish';

  @override
  String get proposedActionError => 'Xatolik — qayta urining';

  @override
  String get roleOwner => 'Ferma egasi';

  @override
  String get roleVet => 'Veterinar';

  @override
  String get roleFarmer => 'Fermer';

  @override
  String get roleCoowner => 'Hamegasi';

  @override
  String get roleVetDesc => 'Kasalliklar tashxisi, rasmiy davolanish qarorlari';

  @override
  String get roleFarmerDesc =>
      'Hayvonlarni ro\'yxatga oladi, ma\'lumotlar kiritadi';

  @override
  String get roleCoownerDesc =>
      'Egasi bilan bir xil huquqlar, a\'zolarni tasdiqlash';

  @override
  String get speciesSigir => 'Sigir';

  @override
  String get speciesQoy => 'Qo\'y';

  @override
  String get speciesEchki => 'Echki';

  @override
  String get speciesOt => 'Ot';

  @override
  String get speciesChochqa => 'Cho\'chqa';

  @override
  String get speciesBoshqa => 'Boshqa';

  @override
  String get speciesSigirPlural => 'Mollar';

  @override
  String get speciesQoyPlural => 'Qo\'ylar';

  @override
  String get speciesEchkiPlural => 'Echkilar';

  @override
  String get speciesOtPlural => 'Otlar';

  @override
  String get speciesAll => 'Barchasi';

  @override
  String get speciesYoung => 'Yosh hayvonlar';

  @override
  String get statusSoglom => 'Sog\'lom';

  @override
  String get statusDavolanmoqda => 'Davolanmoqda';

  @override
  String get statusKritik => 'Kritik';

  @override
  String get statusKuzatuvda => 'Kuzatuvda';

  @override
  String get statusSotildi => 'Sotildi';

  @override
  String get statusOldi => 'O\'ldi';

  @override
  String get severityRoutine => 'Oddiy';

  @override
  String get severityUrgent => 'Shoshilinch';

  @override
  String get severityEmergency => '🚨 Favqulodda';

  @override
  String get googleSignInTitle => 'AgriVet';

  @override
  String get googleSignInSubtitle =>
      'Ferma hayvonlarini boshqarish\nva AI veterinar yordamchi';

  @override
  String get googleSignInBtn => 'Google orqali kirish';

  @override
  String get googleSignInLoading => 'Kirish...';

  @override
  String get googleSignInError =>
      'Kirish amalga oshmadi. Qayta urinib ko\'ring.';

  @override
  String get googleSignInOrDivider => 'yoki';

  @override
  String get googleSignInViaPhone => 'Telefon raqam orqali kirish';

  @override
  String get phoneAuthTitle => 'Telefon orqali kirish';

  @override
  String get phoneAuthSubtitle => 'SMS orqali tasdiqlash kodi yuboramiz';

  @override
  String get phoneEnterNumber => 'Telefon raqamingiz';

  @override
  String get phoneNumberHint => 'XX XXX XX XX';

  @override
  String get phoneSendCode => 'SMS kod yuborish';

  @override
  String get phoneInvalidNumber => 'Telefon raqamni to\'g\'ri kiriting';

  @override
  String get phoneFieldEmpty => 'Telefon raqamini kiriting';

  @override
  String get phoneFieldWrongLength => 'Aynan 9 ta raqam kiriting';

  @override
  String get phoneTooManyRequests =>
      'Juda ko\'p urinish. Keyinroq urinib ko\'ring.';

  @override
  String get phoneError => 'Xatolik yuz berdi. Qayta urinib ko\'ring.';

  @override
  String get phoneOtpTitle => 'SMS kodni kiriting';

  @override
  String phoneOtpSubtitle(String phone) {
    return '$phone raqamiga kod yuborildi';
  }

  @override
  String get phoneOtpHint => '------';

  @override
  String get phoneOtpVerify => 'Tasdiqlash';

  @override
  String get phoneOtpResend => 'Qayta yuborish';

  @override
  String phoneOtpResendIn(int sec) {
    return '$sec soniyada qayta yuborish';
  }

  @override
  String get phoneOtpError => 'Kod noto\'g\'ri yoki muddati o\'tgan';

  @override
  String get phoneOtpAutoVerified => 'Avtomatik tasdiqlandi';

  @override
  String get welcomeSubtitle =>
      'Ferma hayvonlarini boshqarish\nva AI veterinar yordamchi';

  @override
  String get welcomeFeatureAnimals => 'Hayvonlarni ro\'yxatga oling';

  @override
  String get welcomeFeatureAi => 'AI veterinar yordamchi';

  @override
  String get welcomeFeatureHistory => 'Emlash va kasallik tarixi';

  @override
  String get welcomeFeatureSheets => 'Google Sheets sinxronizatsiya';

  @override
  String get welcomeNewFarm => 'Yangi ferma ochish';

  @override
  String get welcomeJoinFarm => 'Mavjud fermaga qo\'shilish';

  @override
  String get setupTitle => 'Yangi ferma';

  @override
  String get setupHeading => 'Fermangizni sozlash';

  @override
  String get setupSubtitle => 'Barcha maydonlar to\'ldirilishi shart';

  @override
  String get setupOwnerName => 'Ism-familiya';

  @override
  String get setupOwnerNameHint => 'Ismingizni kiriting';

  @override
  String get setupFarmName => 'Ferma nomi';

  @override
  String get setupLocation => 'Manzil';

  @override
  String get setupLocationHint => 'Tuman, viloyat';

  @override
  String get setupEmail => 'Email (ixtiyoriy)';

  @override
  String get setupPhone => 'Telefon raqami';

  @override
  String get joinTitle => 'Fermaga qo\'shilish';

  @override
  String get joinCodeTitle => 'Farm kodi';

  @override
  String get joinCodeSubtitle =>
      'Ferma egasidan farm kodini oling (AGVET-XXXXXX)';

  @override
  String get joinCodeCheck => 'Kodni tekshirish';

  @override
  String get joinCodeNotFound => 'Farm kodi topilmadi. Tekshirib ko\'ring.';

  @override
  String get joinPhoneRequired => 'Telefon raqamini to\'liq kiriting';

  @override
  String get joinRoleTitle => 'Rolingizni tanlang';

  @override
  String joinRoleSubtitle(String farmName) {
    return '\"$farmName\" fermasiga qo\'shilasiz';
  }

  @override
  String get joinApprovalNote =>
      'Qo\'shilish so\'rovi ferma egasiga yuboriladi va tasdiqlashni kutadi.';

  @override
  String get joinDetailsTitle => 'Shaxsiy ma\'lumotlar';

  @override
  String joinDetailsSubtitle(String farmName, String role) {
    return '\"$farmName\" — $role rolida';
  }

  @override
  String get joinNameLabel => 'Ism-familiya';

  @override
  String get joinNameHint => 'Ismingizni kiriting';

  @override
  String get joinNameRequired => 'Ismingizni kiriting';

  @override
  String get joinLocationLabel => 'Manzil';

  @override
  String get joinLocationRequired => 'Manzilni kiriting';

  @override
  String get joinEmailLabel => 'Email (ixtiyoriy)';

  @override
  String get joinPhoneLabel => 'Telefon raqami';

  @override
  String get joinSubmit => 'So\'rov yuborish';

  @override
  String get setupOfflineWarning =>
      'Ferma yaratildi. Boshqa qurilmalardan qo\'shilish uchun internet kerak.';

  @override
  String get pinSubtitle => 'PIN kodingizni kiriting';

  @override
  String get farmPinGateSubtitle =>
      'Farm sozlamalariga kirish uchun PIN kiriting';

  @override
  String pinGreeting(String name) {
    return 'Salom, $name!';
  }

  @override
  String get pinWrongMany => 'Juda ko\'p urinish. Egaliga xabar yuboring.';

  @override
  String get pinWrong => 'Noto\'g\'ri PIN. Qaytadan urinib ko\'ring.';

  @override
  String get pinSetupTitle => 'PIN kod o\'rnatish';

  @override
  String pinSetupGreeting(String name) {
    return 'Salom, $name!\nKirishni himoya qilish uchun 4 xonali PIN kod o\'rnating.';
  }

  @override
  String get pinSetupEnter => 'PIN kodni kiriting';

  @override
  String get pinSetupConfirm => 'PIN kodni tasdiqlang';

  @override
  String get pinSetupSave => 'Saqlash va kirish';

  @override
  String get pinSetupReminder =>
      'PIN kodni eslab qoling — tizimga kirish uchun kerak bo\'ladi';

  @override
  String get pinSetupError4digits => 'PIN 4 ta raqamdan iborat bo\'lishi kerak';

  @override
  String get pinSetupErrorMatch => 'PIN kodlar mos kelmadi';

  @override
  String get changePinTitle => 'PIN kodni o\'zgartirish';

  @override
  String get changePinNote =>
      'Avval joriy PIN kodingizni, keyin yangi PIN kodingizni kiriting.';

  @override
  String get changePinCurrentLabel => 'Joriy PIN kod';

  @override
  String get changePinNewLabel => 'Yangi PIN kod';

  @override
  String get changePinConfirmLabel => 'Yangi PIN kodni tasdiqlang';

  @override
  String get changePinSuccess => '✅ PIN kod muvaffaqiyatli o\'zgartirildi';

  @override
  String get changePinErrorCurrent4 => 'Joriy PIN 4 ta raqamdan iborat';

  @override
  String get changePinError4digits =>
      'Yangi PIN 4 ta raqamdan iborat bo\'lishi kerak';

  @override
  String get changePinErrorMatch => 'Yangi PIN kodlar mos kelmadi';

  @override
  String get changePinErrorSame =>
      'Yangi PIN joriy PIN bilan bir xil bo\'lishi mumkin emas';

  @override
  String get changePinErrorWrong => 'Joriy PIN noto\'g\'ri. Qaytadan kiriting.';

  @override
  String get changePinErrorTooMany =>
      'Juda ko\'p noto\'g\'ri urinish. Ilovadan chiqib qayta kiring.';

  @override
  String homeGreeting(String name) {
    return 'Salom, $name! 👋';
  }

  @override
  String get homeLock => 'Qulflash';

  @override
  String homeOpenCasesAlert(int count) {
    return '$count ta ochiq kasallik holati';
  }

  @override
  String homeDueSoonAlert(int count) {
    return '$count ta emlash muddati yaqinlashmoqda';
  }

  @override
  String get homeTotalAnimals => 'Jami hayvon';

  @override
  String get homeTodayMilk => 'Jami sut';

  @override
  String get homeTodayPrefix => 'Bugun,';

  @override
  String get homeFarmStatusTitle => 'Farm holati';

  @override
  String get homeTotalAnimalsLabel => 'JAMI HAYVONLAR';

  @override
  String get homeAllTypesLabel => 'Barcha turlar';

  @override
  String get homeHealthyStatLabel => 'SOG\'LOM';

  @override
  String get homeTreatingLabel => 'DAVOLANAYOTGAN';

  @override
  String get homeWarningLabel => 'OGOHLANTIRISH';

  @override
  String get homeAttentionNeeded => 'E\'tibor talab!';

  @override
  String get homeTodayMilkLabel => 'BUGUNGI SUT';

  @override
  String get homeAnimalsSection => 'Hayvonlar';

  @override
  String get homeQuickActions => 'Tezkor amallar';

  @override
  String get homeNavHome => 'Bosh';

  @override
  String get homeNavAnimals => 'Hayvonlar';

  @override
  String get homeNavHealth => 'Kasallik';

  @override
  String get homeNavFarm => 'Ferma';

  @override
  String get homeNavArchive => 'Arxiv';

  @override
  String get homeActionHealth => 'Kasallik holati';

  @override
  String get homeActionHealthSub => 'Belgilarni kiriting, AI tashxis qo\'yadi';

  @override
  String get homeActionVacc => 'Emlash';

  @override
  String get homeActionVaccSub => 'Emlash qo\'shing';

  @override
  String get homeActionMilk => 'Sut';

  @override
  String get homeActionMilkSub => 'Sutni ro\'yxatga oling';

  @override
  String get homeActionWeight => 'Vazn';

  @override
  String get homeActionWeightSub => 'Vazn o\'lchovi';

  @override
  String get homeActionReport => 'Hisobot';

  @override
  String get homeActionReportSub => 'Ferma hisobotini ko\'ring';

  @override
  String homeAnimalCount(int count) {
    return '$count ta';
  }

  @override
  String get farmTitle => 'Ferma';

  @override
  String get farmNoData => 'Ferma ma\'lumoti topilmadi';

  @override
  String get farmChangePin => 'PIN kodni o\'zgartirish';

  @override
  String get farmLock => 'Qulflash';

  @override
  String get farmLogout => 'Chiqish';

  @override
  String get farmLogoutConfirm => 'Hisobdan chiqmoqchimisiz?';

  @override
  String get farmOwnerLabel => 'Egasi';

  @override
  String get farmEmailLabel => 'Email';

  @override
  String get farmYouLabel => 'Siz';

  @override
  String get farmRoleLabel => 'Rol';

  @override
  String get farmCodeCopied => 'Farm kodi nusxalandi';

  @override
  String get farmEditTooltip => 'Tahrirlash';

  @override
  String get farmSectionManagement => 'BOSHQARUV';

  @override
  String get farmSectionSecurityLang => 'XAVFSIZLIK VA TIL';

  @override
  String get farmSectionExport => 'EKSPORT VA XIZMATLAR';

  @override
  String get farmEditSubtitle => 'Nomi, manzili va turi';

  @override
  String get farmExcelExportTitle => 'Excel hisobot';

  @override
  String get farmExcelExportSubtitle => 'Ferma hisobotini yuklab oling';

  @override
  String get farmVersionFooter => 'AgriVet v2.4.0 · Build 2030.A1';

  @override
  String get farmEditSheetTitle => 'Ferma ma\'lumotlari';

  @override
  String get farmNameLabel => 'Ferma nomi';

  @override
  String get farmLocationLabel => 'Joylashuv';

  @override
  String get farmExcelGenerating => 'Hisobot tayyorlanmoqda...';

  @override
  String get farmExcelError => 'Hisobotni yuklab olishda xatolik yuz berdi';

  @override
  String get farmLanguage => 'Til';

  @override
  String get farmLanguageUz => '🇺🇿 O\'zbek';

  @override
  String get farmLanguageUzCyrl => '🇺🇿 Ўзбек';

  @override
  String get farmLanguageRu => '🇷🇺 Русский';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingsFarmSection => 'Ferma ma\'lumoti';

  @override
  String get settingsAccountSection => 'Sizning hisobingiz';

  @override
  String get settingsSecuritySection => 'Xavfsizlik';

  @override
  String get settingsFarmName => 'Ferma nomi';

  @override
  String get settingsFarmCode => 'Ferma kodi';

  @override
  String get settingsLocation => 'Manzil';

  @override
  String get settingsPhone => 'Telefon';

  @override
  String get settingsLogoutStep2Title => 'Ishonchingiz komilmi?';

  @override
  String get settingsLogoutStep2Body =>
      'Tizimdan chiqib ketasiz. Qayta kirish uchun PIN kod kerak bo\'ladi.';

  @override
  String get settingsLogoutFinal => 'Ha, chiqish';

  @override
  String get animalsAllTitle => '🐾 Barcha hayvonlar';

  @override
  String get animalsSearch => 'Qidirish (ism, quloq raqami...)';

  @override
  String get animalsAdd => 'Hayvon qo\'shish';

  @override
  String get animalsEmpty => 'Hayvon yo\'q';

  @override
  String animalsEmptySpecies(String species) {
    return '$species yo\'q';
  }

  @override
  String get animalsAddNew => 'Yangi hayvon qo\'shing';

  @override
  String get archiveTitle => 'Arxiv';

  @override
  String get archiveSubtitle => 'Sotilgan va o\'lgan hayvonlar tarixi';

  @override
  String get archiveFilterAll => 'Hammasi';

  @override
  String get archiveFilterSold => 'Sotilgan';

  @override
  String get archiveFilterDied => 'O\'lgan';

  @override
  String get archiveEmptyTitle => 'Arxiv bo\'sh';

  @override
  String get archiveEmptyBody =>
      'O\'lgan yoki sotilgan hayvonlar bu yerda ko\'rinadi';

  @override
  String get archiveDateLabel => 'Sana:';

  @override
  String get archiveReasonLabel => 'Sabab:';

  @override
  String get archiveDetailsBtn => 'Tafsilotlar';

  @override
  String get addAnimalTitle => 'Hayvon qo\'shish';

  @override
  String get addAnimalSpeciesSection => 'Tur';

  @override
  String get addAnimalBasicSection => 'Asosiy ma\'lumot';

  @override
  String get addAnimalEarTag => 'Quloq raqami *';

  @override
  String get addAnimalEarTagRequired => 'Quloq raqamini kiriting';

  @override
  String get addAnimalName => 'Nomi (ixtiyoriy)';

  @override
  String get addAnimalSex => 'Jins';

  @override
  String get addAnimalSexMale => '♂ Erkak';

  @override
  String get addAnimalSexFemale => '♀ Urdona';

  @override
  String get addAnimalSexUnknown => 'Noma\'lum';

  @override
  String get addAnimalDob => 'Tug\'ilgan sana';

  @override
  String get addAnimalDetailsSection => 'Qo\'shimcha ma\'lumot';

  @override
  String get addAnimalBreed => 'Zoti';

  @override
  String get addAnimalColor => 'Rangi';

  @override
  String get addAnimalOrigin => 'Kelib chiqishi (tuman, viloyat)';

  @override
  String get addAnimalParentsSection => 'Ota-ona (ixtiyoriy)';

  @override
  String get addAnimalMother => 'Onasining quloq raqami';

  @override
  String get addAnimalFather => 'Otasining quloq raqami';

  @override
  String get healthTitle => '🏥 Kasallik holatlari';

  @override
  String get healthOpen => 'Ochiq';

  @override
  String get healthSevere => 'Jiddiy';

  @override
  String get healthClosed => 'Yopiq';

  @override
  String get healthEmpty => 'Kasallik holati yo\'q 🎉';

  @override
  String get healthAddBtn => 'Holat qo\'shish';

  @override
  String get healthAddTitle => 'Kasallik holati qo\'shish';

  @override
  String get healthAnimalHint => 'Hayvon tanlang';

  @override
  String get healthAnimalLabel => 'Hayvon';

  @override
  String get healthAnimalRequired => 'Hayvon tanlang';

  @override
  String get healthSymptomsLabel => 'Belgilar';

  @override
  String get healthSymptomsRequired => 'Belgilarni kiriting';

  @override
  String get healthSeverityLabel => 'Jiddiylik';

  @override
  String get healthClose => 'Yopish';

  @override
  String get healthMarkHealing => 'Davolanmoqda deb belgilash';

  @override
  String get healthViewDetails => 'Batafsil ko\'rish';

  @override
  String get healthAiLabel => '🤖 AI tashxisi:';

  @override
  String healthConfidence(int pct) {
    return 'Ishonch: $pct%';
  }

  @override
  String healthAssignedSnack(String earTag) {
    return '✅ $earTag hayvoniga biriktirildi';
  }

  @override
  String get healthMarkedHealingSnack => 'Davolanmoqda deb belgilandi';

  @override
  String get healthStatOpenLabel => 'OCHIQ HOLATLAR';

  @override
  String get healthStatActive => 'faol';

  @override
  String get healthStatCriticalLabel => 'KRITIK';

  @override
  String get healthStatUrgent => 'shoshilinch';

  @override
  String get healthJournalTitle => 'Sog\'liq jurnali';

  @override
  String get healthFilterAll => 'Hammasi';

  @override
  String get healthFilterCritical => 'Kritik';

  @override
  String get healthCloseSheetTitle => 'Kasallik holatini yopish';

  @override
  String get healthResultLabel => 'Natija';

  @override
  String get healthOutcomeHealed => 'Tuzaldi';

  @override
  String get healthOutcomeWorsened => 'Yomonlashdi';

  @override
  String get healthOutcomeDied => 'O\'ldi';

  @override
  String get healthRecoveryDaysLabel => 'Tiklanish kunlari (ixtiyoriy)';

  @override
  String get healthVetConfirmedLabel => 'Veterinar tasdiqladi';

  @override
  String get healthCaseClosedSnack => 'Holat yopildi';

  @override
  String get healthSaveAndClose => 'Saqlash va yopish';

  @override
  String get healthCaseDeleteBody => 'Bu kasallik yozuvini o\'chirmoqchimisiz?';

  @override
  String get healthCaseSavedSnack => 'Kasallik yozuvi saqlandi';

  @override
  String get healthUnassignedLabel => 'Hayvon tayinlanmagan';

  @override
  String get healthSymptomsSectionLabel => 'ALOMATLAR';

  @override
  String get healthAiDiagnosisLabel => 'SONYA AI TASHXISI';

  @override
  String healthConfidencePercent(int pct) {
    return '$pct% ISHONCH';
  }

  @override
  String healthClosedSummary(String date) {
    return 'Ushbu holat muvaffaqiyatli yakunlangan. Oxirgi ko\'rik: $date.';
  }

  @override
  String get healthAssignHint => 'Hayvonga biriktirish';

  @override
  String get animalNotFoundTitle => 'Hayvon topilmadi';

  @override
  String get animalNotFoundBody => 'Bu hayvon topilmadi';

  @override
  String get animalTabInfo => 'Ma\'lumot';

  @override
  String get animalTabHealth => 'Kasallik';

  @override
  String get animalTabVacc => 'Emlash';

  @override
  String get animalTabWeight => 'Vazn';

  @override
  String get animalMenuHealth => '🏥 Kasallik qo\'shish';

  @override
  String get animalMenuVacc => '💉 Emlash qo\'shish';

  @override
  String get animalMenuWeight => '⚖️ Vazn qo\'shish';

  @override
  String get animalMenuSold => '✅ Sotildi';

  @override
  String get animalMenuDead => '💀 O\'ldi';

  @override
  String get animalMenuDelete => '🗑️ O\'chirish';

  @override
  String get animalFabHealth => 'Kasallik';

  @override
  String get animalFabVacc => 'Emlash';

  @override
  String get animalFabWeight => 'Vazn';

  @override
  String get animalConfirmSold => 'Sotildi deb belgilansinmi?';

  @override
  String get animalConfirmDead => 'O\'ldi deb belgilansinmi?';

  @override
  String animalConfirmDelete(String name) {
    return '$name o\'chirilsinmi?';
  }

  @override
  String get animalInfoSpecies => 'Tur';

  @override
  String get animalInfoBreed => 'Zot';

  @override
  String get animalInfoSex => 'Jins';

  @override
  String get animalInfoAge => 'Yoshi';

  @override
  String animalInfoAgeValue(int count) {
    return '$count yosh';
  }

  @override
  String get animalInfoColor => 'Rang';

  @override
  String get animalInfoOrigin => 'Kelib chiqishi';

  @override
  String get animalInfoMother => 'Onasi';

  @override
  String get animalInfoFather => 'Otasi';

  @override
  String get animalInfoPregnancy => 'Homiladorlik';

  @override
  String animalPregnant(String date) {
    return '🤰 Homilador ($date)';
  }

  @override
  String get animalCalved => '✅ Bola tug\'ildi';

  @override
  String get animalHealthEmpty => 'Kasallik holati yo\'q';

  @override
  String get animalVaccEmpty => 'Emlash tarixi yo\'q';

  @override
  String get animalWeightEmpty => 'Vazn o\'lchovi yo\'q';

  @override
  String animalVaccDate(String date) {
    return 'Sana: $date';
  }

  @override
  String get animalVaccNextLabel => 'Keyingi:';

  @override
  String get animalHealthSymptomsLabel => 'Belgilar:';

  @override
  String get animalHealthAiLabel => 'AI tashxisi:';

  @override
  String animalHealthConfidence(int pct) {
    return 'Ishonch: $pct%';
  }

  @override
  String get animalMenuHealthy => '✅ Sog\'lom qilish';

  @override
  String get animalDeathReasonLabel => 'O\'lim sababi';

  @override
  String get animalDeathReasonRequired => 'Sabab kiritish shart';

  @override
  String get animalSoldReasonLabel => 'Izoh (ixtiyoriy)';

  @override
  String get animalEditSheetTitle => 'Tahrirlash';

  @override
  String get animalNameLabel => 'Ism';

  @override
  String get animalBreedFieldLabel => 'Zoti';

  @override
  String get animalColorFieldLabel => 'Rangi';

  @override
  String get animalMotherFieldLabel => 'Onaning quloq raqami';

  @override
  String get animalFatherFieldLabel => 'Otaning quloq raqami';

  @override
  String get animalPregnancyStatusTitle => 'Homiladorlik holati';

  @override
  String get animalPregnancyNone => 'Yo\'q';

  @override
  String get animalPregnancyPregnant => 'Homilador';

  @override
  String get animalPregnancyUnknown => 'Tekshirilmagan';

  @override
  String get animalPregnancyMonthLabel => 'Homiladorlik oyi:';

  @override
  String animalPregnantWithMonth(int month) {
    return '$month oy homilador 🤰';
  }

  @override
  String get animalPregnantGeneric => 'Homilador 🤰';

  @override
  String animalAgeYearsMonths(int years, int months) {
    return '$years yil $months oy';
  }

  @override
  String animalAgeYears(int years) {
    return '$years yil';
  }

  @override
  String animalAgeMonths(int months) {
    return '$months oy';
  }

  @override
  String get animalStatusPickerTitle => 'Holatni o\'zgartirish';

  @override
  String get milkTitle => '🥛 Sut';

  @override
  String get milkTodayLabel => 'Bugungi sut';

  @override
  String get milkMorning => '🌅 Ertalab';

  @override
  String get milkEvening => '🌙 Kechqurun';

  @override
  String get milkRecent => 'So\'nggi yozuvlar';

  @override
  String get milkEmpty => 'Sut yozuvi yo\'q';

  @override
  String get milkAmountLabel => 'Miqdor (litr)';

  @override
  String get milkMorningTitle => '🌅 Ertalab sut';

  @override
  String get milkEveningTitle => '🌙 Kechqurun sut';

  @override
  String get milkHeroLabel => 'SUT YOZUVI';

  @override
  String get milkHeroTitle => 'Bugungi jami sut';

  @override
  String get milkLitersUnit => 'Litr';

  @override
  String milkYesterday(String liters) {
    return 'Kecha: $liters L';
  }

  @override
  String get milkDuplicateWarning =>
      'Bugun 2 mahal sut allaqachon qo\'shilgan. Yana sut qo\'shmoqchimisiz?';

  @override
  String get milkMorningEntry => 'Ertalabki sut';

  @override
  String get milkEveningEntry => 'Kechqurungi sut';

  @override
  String get milkAnalysisLabel => 'TAHLIL';

  @override
  String get milkTrendRising =>
      'So\'nggi 3 kunda sut unumdorligi barqaror o\'sib bormoqda. Ozuqa tarkibini hozirgi holatda saqlab qolish tavsiya etiladi.';

  @override
  String get milkTrendFalling =>
      'So\'nggi 3 kunda sut unumdorligi pasaymoqda. Ozuqa va suv ta\'minotini tekshirib ko\'ring.';

  @override
  String milkTrendStable(String avg) {
    return 'So\'nggi 3 kunlik o\'rtacha sut hajmi $avg litr. Barqaror holat kuzatilmoqda.';
  }

  @override
  String get vaccTitle => '💉 Emlash';

  @override
  String vaccDueSoon(int count) {
    return '⚠️ Yaqinlashgan emlashlar ($count)';
  }

  @override
  String vaccAll(int count) {
    return 'Barcha emlashlar ($count)';
  }

  @override
  String get vaccEmpty => 'Emlash yozuvi yo\'q';

  @override
  String get vaccAddBtn => 'Emlash qo\'shish';

  @override
  String get vaccAddTitle => 'Emlash qo\'shish';

  @override
  String get vaccAnimalHint => 'Hayvon tanlang';

  @override
  String get vaccAnimalLabel => 'Hayvon';

  @override
  String get vaccAnimalRequired => 'Hayvon tanlang';

  @override
  String get vaccNameLabel => 'Vaksina nomi';

  @override
  String get vaccNextDueBtn => 'Keyingisi';

  @override
  String vaccDateLabel(String date) {
    return 'Sana: $date';
  }

  @override
  String get vaccNextLabel => 'Keyingi:';

  @override
  String get vaccSubtitle =>
      'Chorva mollari sog\'lig\'ini nazorat qilish va boshqarish';

  @override
  String get vaccUpcoming => 'Yaqinlashayotgan\nemlashlar';

  @override
  String vaccUrgentBadge(int count) {
    return '$count TA\nSHOSHILINCH';
  }

  @override
  String get vaccAllRecords => 'Barcha yozuvlar';

  @override
  String get vaccDueOverdue => 'Muddati o\'tgan';

  @override
  String get vaccDueToday => 'Bugun';

  @override
  String get vaccDueTomorrow => 'Ertaga';

  @override
  String vaccDueInDays(int days) {
    return '$days kun qoldi';
  }

  @override
  String get vaccVaccineLabel => 'VAKSINA';

  @override
  String vaccDueDateLabel(String badge) {
    return 'Muddat: $badge';
  }

  @override
  String get vaccStatusDone => 'BAJARILGAN';

  @override
  String get vaccStatusPlanned => 'REJADA';

  @override
  String get vaccSavedSnack => 'Emlash yozuvi saqlandi';

  @override
  String get weightTitle => '⚖️ Vazn';

  @override
  String get weightEmpty => 'Vazn o\'lchovi yo\'q';

  @override
  String get weightAddBtn => 'Vazn qo\'shish';

  @override
  String get weightAddTitle => 'Vazn qo\'shish';

  @override
  String get weightAnimalHint => 'Hayvon tanlang';

  @override
  String get weightAnimalLabel => 'Hayvon';

  @override
  String get weightAnimalRequired => 'Hayvon tanlang';

  @override
  String get weightLabel => 'Vazn';

  @override
  String get weightWeeklyAvg => 'HAFTALIK O\'RTACHA';

  @override
  String get weightChartTitle => 'Vazn grafigi';

  @override
  String get weightChartSubtitle => 'Oxirgi 6 oy';

  @override
  String get weightRecentRecords => 'So\'nggi qaydlar';

  @override
  String get weightSavedSnack => 'Vazn yozuvi saqlandi';

  @override
  String get weightMonthJan => 'Yan';

  @override
  String get weightMonthFeb => 'Fev';

  @override
  String get weightMonthMar => 'Mar';

  @override
  String get weightMonthApr => 'Apr';

  @override
  String get weightMonthMay => 'May';

  @override
  String get weightMonthJun => 'Iyun';

  @override
  String get weightMonthJul => 'Iyul';

  @override
  String get weightMonthAug => 'Avg';

  @override
  String get weightMonthSep => 'Sen';

  @override
  String get weightMonthOct => 'Okt';

  @override
  String get weightMonthNov => 'Noy';

  @override
  String get weightMonthDec => 'Dek';

  @override
  String get reportTitle => '📊 Hisobot';

  @override
  String get report7Days => '7 kun';

  @override
  String get report30Days => '30 kun';

  @override
  String get report1Year => '1 yil';

  @override
  String reportOverview(int days) {
    return 'Umumiy ko\'rsatkichlar ($days kun)';
  }

  @override
  String get reportTotalAnimals => 'Jami hayvon';

  @override
  String get reportHealthy => 'Sog\'lom';

  @override
  String get reportTreatment => 'Davolanmoqda';

  @override
  String get reportCritical => 'Kritik';

  @override
  String get reportTeam => 'Jamoat a\'zolari';

  @override
  String get reportBirths => 'Tug\'ilishlar';

  @override
  String get reportVaccDue => 'Yaqin emlashlar';

  @override
  String get reportSpeciesBreakdown => 'Tur bo\'yicha taqsimot';

  @override
  String get reportAnimalStatus => 'Hayvon holati';

  @override
  String get reportHealthStats => 'Kasallik holatlari';

  @override
  String get reportOpenCases => 'Ochiq holatlar';

  @override
  String get reportClosedCases => 'Yopiq holatlar';

  @override
  String get reportMilkStats => 'Sut ishlab chiqarish';

  @override
  String reportTotalMilk(int days) {
    return 'Jami sut ($days kun)';
  }

  @override
  String get reportAvgMilk => 'O\'rtacha kunlik';

  @override
  String get reportAnalyticsLabel => 'TAHLILIY MA\'LUMOTLAR';

  @override
  String get reportTotalLivestockLabel => 'JAMI CHORVA';

  @override
  String get reportNoData => 'Ma\'lumot yo\'q';

  @override
  String get reportYoungAnimalsTitle => 'Yosh hayvonlar (2 yoshgacha)';

  @override
  String get reportNoYoungAnimals => 'Yosh hayvonlar yo\'q';

  @override
  String get reportBySpeciesLabel => 'Turlar bo\'yicha';

  @override
  String get reportNoAnimals => 'Hayvon yo\'q';

  @override
  String get reportDayMon => 'Du';

  @override
  String get reportDayTue => 'Se';

  @override
  String get reportDayWed => 'Ch';

  @override
  String get reportDayThu => 'Pa';

  @override
  String get reportDayFri => 'Ju';

  @override
  String get reportDaySat => 'Sh';

  @override
  String get reportDaySun => 'Ya';

  @override
  String get reportHealthBySpecies => 'Tur bo\'yicha sog\'lik holati';

  @override
  String get reportLegendHealthy => 'Sog\'lom';

  @override
  String get reportLegendTreatment => 'Davolanmoqda';

  @override
  String get reportLegendObserved => 'Kuzatuvda';

  @override
  String get reportLegendCritical => 'Kritik';

  @override
  String get menuLanguage => 'Til';

  @override
  String get menuLangUz => 'O\'zbekcha';

  @override
  String get menuLangRu => 'Русский';

  @override
  String get menuEditProfile => 'Ferma ma\'lumotlari';

  @override
  String get menuPersonalInfo => 'Shaxsiy ma\'lumotlar';

  @override
  String get menuLogout => 'Chiqish';

  @override
  String get menuLogoutConfirm => 'Hisobdan chiqmoqchimisiz?';

  @override
  String get menuChangeAccount => 'Akkauntni almashtirish';

  @override
  String get menuChangeAccountConfirm =>
      'Joriy akkauntdan chiqib, boshqa akkaunt bilan kirasizmi?';

  @override
  String get farmPickerTitle => 'Fermani tanlang';

  @override
  String get farmPickerSubtitle => 'Akkauntingizga ulangan fermalar';

  @override
  String get farmPickerNewFarm => 'Yangi ferma qo\'shish';

  @override
  String get bulkVaccTitle => 'Ommaviy emlash';

  @override
  String get bulkVaccSelectAll => 'Barchasini tanlash';

  @override
  String get bulkVaccDeselectAll => 'Tanlovni bekor qilish';

  @override
  String get bulkVaccInvert => 'Teskari tanlash';

  @override
  String bulkVaccSelected(int count) {
    return '$count ta tanlandi';
  }

  @override
  String get bulkVaccSaveBtn => 'Emlash qo\'shish';

  @override
  String get bulkVaccFormTitle => 'Emlash ma\'lumotlari';

  @override
  String get bulkVaccVaccineName => 'Vaksina nomi';

  @override
  String get bulkVaccDate => 'Emlash sanasi';

  @override
  String get bulkVaccNextDue => 'Keyingi sana (ixtiyoriy)';

  @override
  String bulkVaccSuccess(int count) {
    return '$count ta hayvon emlantirildi';
  }

  @override
  String get bulkVaccNoneSelected => 'Kamida 1 ta hayvon tanlang';

  @override
  String get aiAssistantTitle => 'Asomiddin — AI Veterinar';

  @override
  String get aiAssistantSubtitle =>
      '15 yil tajribali Farg\'ona vodiysi veterinari';

  @override
  String get aiInputHint => 'Hayvon haqida yozing...';

  @override
  String get aiRecording => 'Yozilmoqda... (qo\'lni oling)';

  @override
  String get aiEmergency => 'FAVQULODDA HOLAT';

  @override
  String get aiFirstAid => 'Darhol choralar:';

  @override
  String aiFollowUp(int days) {
    return '$days kundan so\'ng tekshirish';
  }

  @override
  String get aiListenBtn => 'Eshitish';

  @override
  String get aiStopBtn => 'To\'xtatish';

  @override
  String get aiMicPermission => 'Mikrofon ruxsati kerak';

  @override
  String get aiCallVet => 'Veterinar chaqirish';

  @override
  String get aiOnline => 'Online';

  @override
  String get aiExperience => 'AI Veterinar · 15 yil tajriba';

  @override
  String get aiWelcomeMessage =>
      'Salom! Men Sonya — sizning AI veterinar yordamchingizman. Hayvon holati, kasallik belgilari, emlash yoki vazn haqida menga xabar bering. Ovoz yoki matn bilan murojaat qiling.';

  @override
  String get aiServerError =>
      '⚠️ Server bilan bog\'lanib bo\'lmadi, qayta urinib ko\'ring';

  @override
  String get aiPhotoSavedSnack =>
      '✅ Saqlandi — Salomatlik bo\'limida hayvonga biriktiring';

  @override
  String get aiSavedSnack => 'Saqlandi';

  @override
  String get aiGenericError => 'Xatolik yuz berdi. Qayta urinib ko\'ring.';

  @override
  String get aiSttFailedSnack => '🎤 Ovoz tanilmadi, qayta urinib ko\'ring';

  @override
  String get aiCameraOption => '📷 Kamera';

  @override
  String get aiCameraSubtitle => 'Yangi rasm olish';

  @override
  String get aiGalleryOption => '🖼️ Galereya';

  @override
  String get aiGallerySubtitle => 'Telefondan tanlash';

  @override
  String get aiDeleteConversation => 'Suhbatni o\'chirish';

  @override
  String aiVetContactLabel(String name) {
    return 'Veterinar: $name';
  }

  @override
  String get aiCallVetNow => 'Darhol veterinar chaqiring!';

  @override
  String get aiPhotoAddedHint => 'Rasm qo\'shildi. Matn kiriting va yuboring.';

  @override
  String get aiTranscribing => '🎤 Tahlil qilinmoqda...';

  @override
  String get aiSwipeToLock => '↑ yuqoriga → qulflash';
}

/// The translations for Uzbek, using the Cyrillic script (`uz_Cyrl`).
class AppLocalizationsUzCyrl extends AppLocalizationsUz {
  AppLocalizationsUzCyrl() : super('uz_Cyrl');

  @override
  String get errorDefault => '⚠️ Хатолик, қайта уриниб кўринг';

  @override
  String get errorOk => 'ОК';

  @override
  String get cancel => 'Бекор';

  @override
  String get save => 'Сақлаш';

  @override
  String get continueBtn => 'Давом етиш';

  @override
  String get hideText => 'Яшириш';

  @override
  String get showText => 'Кўрсатиш';

  @override
  String get errorGeneric => 'Хатолик юз берди';

  @override
  String get confirm => 'Тасдиқлаш';

  @override
  String get yes => 'Ҳа';

  @override
  String get deleteBtn => 'Ўчириш';

  @override
  String get closeBtn => 'Ёпиш';

  @override
  String get deleteConfirmTitle => 'Ўчиришни тасдиқланг';

  @override
  String get deleteConfirmBody => 'Бу ёзувни ўчирмоқчимисиз?';

  @override
  String errorWithDetail(String error) {
    return 'Хатолик: $error';
  }

  @override
  String get openStatus => 'Очиқ';

  @override
  String get closedStatus => 'Ёпиқ';

  @override
  String get enterHint => 'Киритинг';

  @override
  String get enterNumber => 'Рақам киритинг';

  @override
  String get fieldRequired => 'Майдонни тўлдиринг';

  @override
  String get proposedActionDone => 'Бажарилди';

  @override
  String get proposedActionCancelled => 'Бекор қилинди';

  @override
  String get proposedActionDefaultSummary => 'Амални тасдиқланг';

  @override
  String get proposedActionNeedsConfirm => 'Тасдиқлаш керак';

  @override
  String proposedActionAffectedCount(int count) {
    return '$count та ҳайвон';
  }

  @override
  String get proposedActionCancelBtn => 'Бекор қилиш';

  @override
  String get proposedActionError => 'Хатолик — қайта урининг';

  @override
  String get roleOwner => 'Ферма егаси';

  @override
  String get roleVet => 'Ветеринар';

  @override
  String get roleFarmer => 'Фермер';

  @override
  String get roleCoowner => 'Ҳамегаси';

  @override
  String get roleVetDesc => 'Касалликлар ташхиси, расмий даволаниш қарорлари';

  @override
  String get roleFarmerDesc =>
      'Ҳайвонларни рўйхатга олади, маълумотлар киритади';

  @override
  String get roleCoownerDesc =>
      'Егаси билан бир хил ҳуқуқлар, аъзоларни тасдиқлаш';

  @override
  String get speciesSigir => 'Сигир';

  @override
  String get speciesQoy => 'Қўй';

  @override
  String get speciesEchki => 'Ечки';

  @override
  String get speciesOt => 'От';

  @override
  String get speciesChochqa => 'Чўчқа';

  @override
  String get speciesBoshqa => 'Бошқа';

  @override
  String get speciesSigirPlural => 'Моллар';

  @override
  String get speciesQoyPlural => 'Қўйлар';

  @override
  String get speciesEchkiPlural => 'Ечкилар';

  @override
  String get speciesOtPlural => 'Отлар';

  @override
  String get speciesAll => 'Барчаси';

  @override
  String get speciesYoung => 'Ёш ҳайвонлар';

  @override
  String get statusSoglom => 'Соғлом';

  @override
  String get statusDavolanmoqda => 'Даволанмоқда';

  @override
  String get statusKritik => 'Критик';

  @override
  String get statusKuzatuvda => 'Кузатувда';

  @override
  String get statusSotildi => 'Сотилди';

  @override
  String get statusOldi => 'Ўлди';

  @override
  String get severityRoutine => 'Оддий';

  @override
  String get severityUrgent => 'Шошилинч';

  @override
  String get severityEmergency => '🚨 Фавқулодда';

  @override
  String get googleSignInTitle => 'АгриВет';

  @override
  String get googleSignInSubtitle =>
      'Ферма ҳайвонларини бошқариш\nва АИ ветеринар ёрдамчи';

  @override
  String get googleSignInBtn => 'Гоогле орқали кириш';

  @override
  String get googleSignInLoading => 'Кириш...';

  @override
  String get googleSignInError => 'Кириш амалга ошмади. Қайта уриниб кўринг.';

  @override
  String get googleSignInOrDivider => 'ёки';

  @override
  String get googleSignInViaPhone => 'Телефон рақам орқали кириш';

  @override
  String get phoneAuthTitle => 'Телефон орқали кириш';

  @override
  String get phoneAuthSubtitle => 'СМС орқали тасдиқлаш коди юборамиз';

  @override
  String get phoneEnterNumber => 'Телефон рақамингиз';

  @override
  String get phoneNumberHint => 'ХХ ХХХ ХХ ХХ';

  @override
  String get phoneSendCode => 'СМС код юбориш';

  @override
  String get phoneInvalidNumber => 'Телефон рақамни тўғри киритинг';

  @override
  String get phoneFieldEmpty => 'Телефон рақамини киритинг';

  @override
  String get phoneFieldWrongLength => 'Айнан 9 та рақам киритинг';

  @override
  String get phoneTooManyRequests => 'Жуда кўп уриниш. Кейинроқ уриниб кўринг.';

  @override
  String get phoneError => 'Хатолик юз берди. Қайта уриниб кўринг.';

  @override
  String get phoneOtpTitle => 'СМС кодни киритинг';

  @override
  String phoneOtpSubtitle(String phone) {
    return '$phone рақамига код юборилди';
  }

  @override
  String get phoneOtpHint => '------';

  @override
  String get phoneOtpVerify => 'Тасдиқлаш';

  @override
  String get phoneOtpResend => 'Қайта юбориш';

  @override
  String phoneOtpResendIn(int sec) {
    return '$sec сонияда қайта юбориш';
  }

  @override
  String get phoneOtpError => 'Код нотўғри ёки муддати ўтган';

  @override
  String get phoneOtpAutoVerified => 'Автоматик тасдиқланди';

  @override
  String get welcomeSubtitle =>
      'Ферма ҳайвонларини бошқариш\nва АИ ветеринар ёрдамчи';

  @override
  String get welcomeFeatureAnimals => 'Ҳайвонларни рўйхатга олинг';

  @override
  String get welcomeFeatureAi => 'АИ ветеринар ёрдамчи';

  @override
  String get welcomeFeatureHistory => 'Емлаш ва касаллик тарихи';

  @override
  String get welcomeFeatureSheets => 'Гоогле Шеетс синхронизатсия';

  @override
  String get welcomeNewFarm => 'Янги ферма очиш';

  @override
  String get welcomeJoinFarm => 'Мавжуд фермага қўшилиш';

  @override
  String get setupTitle => 'Янги ферма';

  @override
  String get setupHeading => 'Фермангизни созлаш';

  @override
  String get setupSubtitle => 'Барча майдонлар тўлдирилиши шарт';

  @override
  String get setupOwnerName => 'Исм-фамилия';

  @override
  String get setupOwnerNameHint => 'Исмингизни киритинг';

  @override
  String get setupFarmName => 'Ферма номи';

  @override
  String get setupLocation => 'Манзил';

  @override
  String get setupLocationHint => 'Туман, вилоят';

  @override
  String get setupEmail => 'Емаил (ихтиёрий)';

  @override
  String get setupPhone => 'Телефон рақами';

  @override
  String get joinTitle => 'Фермага қўшилиш';

  @override
  String get joinCodeTitle => 'Фарм коди';

  @override
  String get joinCodeSubtitle =>
      'Ферма егасидан фарм кодини олинг (АГВЕТ-ХХХХХХ)';

  @override
  String get joinCodeCheck => 'Кодни текшириш';

  @override
  String get joinCodeNotFound => 'Фарм коди топилмади. Текшириб кўринг.';

  @override
  String get joinPhoneRequired => 'Телефон рақамини тўлиқ киритинг';

  @override
  String get joinRoleTitle => 'Ролингизни танланг';

  @override
  String joinRoleSubtitle(String farmName) {
    return '\"$farmName\" фермасига қўшиласиз';
  }

  @override
  String get joinApprovalNote =>
      'Қўшилиш сўрови ферма егасига юборилади ва тасдиқлашни кутади.';

  @override
  String get joinDetailsTitle => 'Шахсий маълумотлар';

  @override
  String joinDetailsSubtitle(String farmName, String role) {
    return '\"$farmName\" — $role ролида';
  }

  @override
  String get joinNameLabel => 'Исм-фамилия';

  @override
  String get joinNameHint => 'Исмингизни киритинг';

  @override
  String get joinNameRequired => 'Исмингизни киритинг';

  @override
  String get joinLocationLabel => 'Манзил';

  @override
  String get joinLocationRequired => 'Манзилни киритинг';

  @override
  String get joinEmailLabel => 'Емаил (ихтиёрий)';

  @override
  String get joinPhoneLabel => 'Телефон рақами';

  @override
  String get joinSubmit => 'Сўров юбориш';

  @override
  String get setupOfflineWarning =>
      'Ферма яратилди. Бошқа қурилмалардан қўшилиш учун интернет керак.';

  @override
  String get pinSubtitle => 'ПИН кодингизни киритинг';

  @override
  String get farmPinGateSubtitle =>
      'Фарм созламаларига кириш учун ПИН киритинг';

  @override
  String pinGreeting(String name) {
    return 'Салом, $name!';
  }

  @override
  String get pinWrongMany => 'Жуда кўп уриниш. Егалига хабар юборинг.';

  @override
  String get pinWrong => 'Нотўғри ПИН. Қайтадан уриниб кўринг.';

  @override
  String get pinSetupTitle => 'ПИН код ўрнатиш';

  @override
  String pinSetupGreeting(String name) {
    return 'Салом, $name!\nКиришни ҳимоя қилиш учун 4 хонали ПИН код ўрнатинг.';
  }

  @override
  String get pinSetupEnter => 'ПИН кодни киритинг';

  @override
  String get pinSetupConfirm => 'ПИН кодни тасдиқланг';

  @override
  String get pinSetupSave => 'Сақлаш ва кириш';

  @override
  String get pinSetupReminder =>
      'ПИН кодни еслаб қолинг — тизимга кириш учун керак бўлади';

  @override
  String get pinSetupError4digits => 'ПИН 4 та рақамдан иборат бўлиши керак';

  @override
  String get pinSetupErrorMatch => 'ПИН кодлар мос келмади';

  @override
  String get changePinTitle => 'ПИН кодни ўзгартириш';

  @override
  String get changePinNote =>
      'Аввал жорий ПИН кодингизни, кейин янги ПИН кодингизни киритинг.';

  @override
  String get changePinCurrentLabel => 'Жорий ПИН код';

  @override
  String get changePinNewLabel => 'Янги ПИН код';

  @override
  String get changePinConfirmLabel => 'Янги ПИН кодни тасдиқланг';

  @override
  String get changePinSuccess => '✅ ПИН код муваффақиятли ўзгартирилди';

  @override
  String get changePinErrorCurrent4 => 'Жорий ПИН 4 та рақамдан иборат';

  @override
  String get changePinError4digits =>
      'Янги ПИН 4 та рақамдан иборат бўлиши керак';

  @override
  String get changePinErrorMatch => 'Янги ПИН кодлар мос келмади';

  @override
  String get changePinErrorSame =>
      'Янги ПИН жорий ПИН билан бир хил бўлиши мумкин емас';

  @override
  String get changePinErrorWrong => 'Жорий ПИН нотўғри. Қайтадан киритинг.';

  @override
  String get changePinErrorTooMany =>
      'Жуда кўп нотўғри уриниш. Иловадан чиқиб қайта киринг.';

  @override
  String homeGreeting(String name) {
    return 'Салом, $name! 👋';
  }

  @override
  String get homeLock => 'Қулфлаш';

  @override
  String homeOpenCasesAlert(int count) {
    return '$count та очиқ касаллик ҳолати';
  }

  @override
  String homeDueSoonAlert(int count) {
    return '$count та емлаш муддати яқинлашмоқда';
  }

  @override
  String get homeTotalAnimals => 'Жами ҳайвон';

  @override
  String get homeTodayMilk => 'Жами сут';

  @override
  String get homeTodayPrefix => 'Бугун,';

  @override
  String get homeFarmStatusTitle => 'Фарм ҳолати';

  @override
  String get homeTotalAnimalsLabel => 'ЖАМИ ҲАЙВОНЛАР';

  @override
  String get homeAllTypesLabel => 'Барча турлар';

  @override
  String get homeHealthyStatLabel => 'СОҒЛОМ';

  @override
  String get homeTreatingLabel => 'ДАВОЛАНАЁТГАН';

  @override
  String get homeWarningLabel => 'ОГОҲЛАНТИРИШ';

  @override
  String get homeAttentionNeeded => 'Еътибор талаб!';

  @override
  String get homeTodayMilkLabel => 'БУГУНГИ СУТ';

  @override
  String get homeAnimalsSection => 'Ҳайвонлар';

  @override
  String get homeQuickActions => 'Тезкор амаллар';

  @override
  String get homeNavHome => 'Бош';

  @override
  String get homeNavAnimals => 'Ҳайвонлар';

  @override
  String get homeNavHealth => 'Касаллик';

  @override
  String get homeNavFarm => 'Ферма';

  @override
  String get homeNavArchive => 'Архив';

  @override
  String get homeActionHealth => 'Касаллик ҳолати';

  @override
  String get homeActionHealthSub => 'Белгиларни киритинг, АИ ташхис қўяди';

  @override
  String get homeActionVacc => 'Емлаш';

  @override
  String get homeActionVaccSub => 'Емлаш қўшинг';

  @override
  String get homeActionMilk => 'Сут';

  @override
  String get homeActionMilkSub => 'Сутни рўйхатга олинг';

  @override
  String get homeActionWeight => 'Вазн';

  @override
  String get homeActionWeightSub => 'Вазн ўлчови';

  @override
  String get homeActionReport => 'Ҳисобот';

  @override
  String get homeActionReportSub => 'Ферма ҳисоботини кўринг';

  @override
  String homeAnimalCount(int count) {
    return '$count та';
  }

  @override
  String get farmTitle => 'Ферма';

  @override
  String get farmNoData => 'Ферма маълумоти топилмади';

  @override
  String get farmChangePin => 'ПИН кодни ўзгартириш';

  @override
  String get farmLock => 'Қулфлаш';

  @override
  String get farmLogout => 'Чиқиш';

  @override
  String get farmLogoutConfirm => 'Ҳисобдан чиқмоқчимисиз?';

  @override
  String get farmOwnerLabel => 'Егаси';

  @override
  String get farmEmailLabel => 'Емаил';

  @override
  String get farmYouLabel => 'Сиз';

  @override
  String get farmRoleLabel => 'Рол';

  @override
  String get farmCodeCopied => 'Фарм коди нусхаланди';

  @override
  String get farmEditTooltip => 'Таҳрирлаш';

  @override
  String get farmSectionManagement => 'БОШҚАРУВ';

  @override
  String get farmSectionSecurityLang => 'ХАВФСИЗЛИК ВА ТИЛ';

  @override
  String get farmSectionExport => 'ЕКСПОРТ ВА ХИЗМАТЛАР';

  @override
  String get farmEditSubtitle => 'Номи, манзили ва тури';

  @override
  String get farmExcelExportTitle => 'Ехcел ҳисобот';

  @override
  String get farmExcelExportSubtitle => 'Ферма ҳисоботини юклаб олинг';

  @override
  String get farmVersionFooter => 'АгриВет в2.4.0 · Буилд 2030.А1';

  @override
  String get farmEditSheetTitle => 'Ферма маълумотлари';

  @override
  String get farmNameLabel => 'Ферма номи';

  @override
  String get farmLocationLabel => 'Жойлашув';

  @override
  String get farmExcelGenerating => 'Ҳисобот тайёрланмоқда...';

  @override
  String get farmExcelError => 'Ҳисоботни юклаб олишда хатолик юз берди';

  @override
  String get farmLanguage => 'Тил';

  @override
  String get farmLanguageUz => '🇺🇿 O\'zbek';

  @override
  String get farmLanguageUzCyrl => '🇺🇿 Ўзбек';

  @override
  String get farmLanguageRu => '🇷🇺 Русский';

  @override
  String get settingsTitle => 'Созламалар';

  @override
  String get settingsFarmSection => 'Ферма маълумоти';

  @override
  String get settingsAccountSection => 'Сизнинг ҳисобингиз';

  @override
  String get settingsSecuritySection => 'Хавфсизлик';

  @override
  String get settingsFarmName => 'Ферма номи';

  @override
  String get settingsFarmCode => 'Ферма коди';

  @override
  String get settingsLocation => 'Манзил';

  @override
  String get settingsPhone => 'Телефон';

  @override
  String get settingsLogoutStep2Title => 'Ишончингиз комилми?';

  @override
  String get settingsLogoutStep2Body =>
      'Тизимдан чиқиб кетасиз. Қайта кириш учун ПИН код керак бўлади.';

  @override
  String get settingsLogoutFinal => 'Ҳа, чиқиш';

  @override
  String get animalsAllTitle => '🐾 Барча ҳайвонлар';

  @override
  String get animalsSearch => 'Қидириш (исм, қулоқ рақами...)';

  @override
  String get animalsAdd => 'Ҳайвон қўшиш';

  @override
  String get animalsEmpty => 'Ҳайвон йўқ';

  @override
  String animalsEmptySpecies(String species) {
    return '$species йўқ';
  }

  @override
  String get animalsAddNew => 'Янги ҳайвон қўшинг';

  @override
  String get archiveTitle => 'Архив';

  @override
  String get archiveSubtitle => 'Сотилган ва ўлган ҳайвонлар тарихи';

  @override
  String get archiveFilterAll => 'Ҳаммаси';

  @override
  String get archiveFilterSold => 'Сотилган';

  @override
  String get archiveFilterDied => 'Ўлган';

  @override
  String get archiveEmptyTitle => 'Архив бўш';

  @override
  String get archiveEmptyBody =>
      'Ўлган ёки сотилган ҳайвонлар бу ерда кўринади';

  @override
  String get archiveDateLabel => 'Сана:';

  @override
  String get archiveReasonLabel => 'Сабаб:';

  @override
  String get archiveDetailsBtn => 'Тафсилотлар';

  @override
  String get addAnimalTitle => 'Ҳайвон қўшиш';

  @override
  String get addAnimalSpeciesSection => 'Тур';

  @override
  String get addAnimalBasicSection => 'Асосий маълумот';

  @override
  String get addAnimalEarTag => 'Қулоқ рақами *';

  @override
  String get addAnimalEarTagRequired => 'Қулоқ рақамини киритинг';

  @override
  String get addAnimalName => 'Номи (ихтиёрий)';

  @override
  String get addAnimalSex => 'Жинс';

  @override
  String get addAnimalSexMale => '♂ Еркак';

  @override
  String get addAnimalSexFemale => '♀ Урдона';

  @override
  String get addAnimalSexUnknown => 'Номаълум';

  @override
  String get addAnimalDob => 'Туғилган сана';

  @override
  String get addAnimalDetailsSection => 'Қўшимча маълумот';

  @override
  String get addAnimalBreed => 'Зоти';

  @override
  String get addAnimalColor => 'Ранги';

  @override
  String get addAnimalOrigin => 'Келиб чиқиши (туман, вилоят)';

  @override
  String get addAnimalParentsSection => 'Ота-она (ихтиёрий)';

  @override
  String get addAnimalMother => 'Онасининг қулоқ рақами';

  @override
  String get addAnimalFather => 'Отасининг қулоқ рақами';

  @override
  String get healthTitle => '🏥 Касаллик ҳолатлари';

  @override
  String get healthOpen => 'Очиқ';

  @override
  String get healthSevere => 'Жиддий';

  @override
  String get healthClosed => 'Ёпиқ';

  @override
  String get healthEmpty => 'Касаллик ҳолати йўқ 🎉';

  @override
  String get healthAddBtn => 'Ҳолат қўшиш';

  @override
  String get healthAddTitle => 'Касаллик ҳолати қўшиш';

  @override
  String get healthAnimalHint => 'Ҳайвон танланг';

  @override
  String get healthAnimalLabel => 'Ҳайвон';

  @override
  String get healthAnimalRequired => 'Ҳайвон танланг';

  @override
  String get healthSymptomsLabel => 'Белгилар';

  @override
  String get healthSymptomsRequired => 'Белгиларни киритинг';

  @override
  String get healthSeverityLabel => 'Жиддийлик';

  @override
  String get healthClose => 'Ёпиш';

  @override
  String get healthMarkHealing => 'Даволанмоқда деб белгилаш';

  @override
  String get healthViewDetails => 'Батафсил кўриш';

  @override
  String get healthAiLabel => '🤖 АИ ташхиси:';

  @override
  String healthConfidence(int pct) {
    return 'Ишонч: $pct%';
  }

  @override
  String healthAssignedSnack(String earTag) {
    return '✅ $earTag ҳайвонига бириктирилди';
  }

  @override
  String get healthMarkedHealingSnack => 'Даволанмоқда деб белгиланди';

  @override
  String get healthStatOpenLabel => 'ОЧИҚ ҲОЛАТЛАР';

  @override
  String get healthStatActive => 'фаол';

  @override
  String get healthStatCriticalLabel => 'КРИТИК';

  @override
  String get healthStatUrgent => 'шошилинч';

  @override
  String get healthJournalTitle => 'Соғлиқ журнали';

  @override
  String get healthFilterAll => 'Ҳаммаси';

  @override
  String get healthFilterCritical => 'Критик';

  @override
  String get healthCloseSheetTitle => 'Касаллик ҳолатини ёпиш';

  @override
  String get healthResultLabel => 'Натижа';

  @override
  String get healthOutcomeHealed => 'Тузалди';

  @override
  String get healthOutcomeWorsened => 'Ёмонлашди';

  @override
  String get healthOutcomeDied => 'Ўлди';

  @override
  String get healthRecoveryDaysLabel => 'Тикланиш кунлари (ихтиёрий)';

  @override
  String get healthVetConfirmedLabel => 'Ветеринар тасдиқлади';

  @override
  String get healthCaseClosedSnack => 'Ҳолат ёпилди';

  @override
  String get healthSaveAndClose => 'Сақлаш ва ёпиш';

  @override
  String get healthCaseDeleteBody => 'Бу касаллик ёзувини ўчирмоқчимисиз?';

  @override
  String get healthCaseSavedSnack => 'Касаллик ёзуви сақланди';

  @override
  String get healthUnassignedLabel => 'Ҳайвон тайинланмаган';

  @override
  String get healthSymptomsSectionLabel => 'АЛОМАТЛАР';

  @override
  String get healthAiDiagnosisLabel => 'СОНЯ АИ ТАШХИСИ';

  @override
  String healthConfidencePercent(int pct) {
    return '$pct% ИШОНЧ';
  }

  @override
  String healthClosedSummary(String date) {
    return 'Ушбу ҳолат муваффақиятли якунланган. Охирги кўрик: $date.';
  }

  @override
  String get healthAssignHint => 'Ҳайвонга бириктириш';

  @override
  String get animalNotFoundTitle => 'Ҳайвон топилмади';

  @override
  String get animalNotFoundBody => 'Бу ҳайвон топилмади';

  @override
  String get animalTabInfo => 'Маълумот';

  @override
  String get animalTabHealth => 'Касаллик';

  @override
  String get animalTabVacc => 'Емлаш';

  @override
  String get animalTabWeight => 'Вазн';

  @override
  String get animalMenuHealth => '🏥 Касаллик қўшиш';

  @override
  String get animalMenuVacc => '💉 Емлаш қўшиш';

  @override
  String get animalMenuWeight => '⚖️ Вазн қўшиш';

  @override
  String get animalMenuSold => '✅ Сотилди';

  @override
  String get animalMenuDead => '💀 Ўлди';

  @override
  String get animalMenuDelete => '🗑️ Ўчириш';

  @override
  String get animalFabHealth => 'Касаллик';

  @override
  String get animalFabVacc => 'Емлаш';

  @override
  String get animalFabWeight => 'Вазн';

  @override
  String get animalConfirmSold => 'Сотилди деб белгилансинми?';

  @override
  String get animalConfirmDead => 'Ўлди деб белгилансинми?';

  @override
  String animalConfirmDelete(String name) {
    return '$name ўчирилсинми?';
  }

  @override
  String get animalInfoSpecies => 'Тур';

  @override
  String get animalInfoBreed => 'Зот';

  @override
  String get animalInfoSex => 'Жинс';

  @override
  String get animalInfoAge => 'Ёши';

  @override
  String animalInfoAgeValue(int count) {
    return '$count ёш';
  }

  @override
  String get animalInfoColor => 'Ранг';

  @override
  String get animalInfoOrigin => 'Келиб чиқиши';

  @override
  String get animalInfoMother => 'Онаси';

  @override
  String get animalInfoFather => 'Отаси';

  @override
  String get animalInfoPregnancy => 'Ҳомиладорлик';

  @override
  String animalPregnant(String date) {
    return '🤰 Ҳомиладор ($date)';
  }

  @override
  String get animalCalved => '✅ Бола туғилди';

  @override
  String get animalHealthEmpty => 'Касаллик ҳолати йўқ';

  @override
  String get animalVaccEmpty => 'Емлаш тарихи йўқ';

  @override
  String get animalWeightEmpty => 'Вазн ўлчови йўқ';

  @override
  String animalVaccDate(String date) {
    return 'Сана: $date';
  }

  @override
  String get animalVaccNextLabel => 'Кейинги:';

  @override
  String get animalHealthSymptomsLabel => 'Белгилар:';

  @override
  String get animalHealthAiLabel => 'АИ ташхиси:';

  @override
  String animalHealthConfidence(int pct) {
    return 'Ишонч: $pct%';
  }

  @override
  String get animalMenuHealthy => '✅ Соғлом қилиш';

  @override
  String get animalDeathReasonLabel => 'Ўлим сабаби';

  @override
  String get animalDeathReasonRequired => 'Сабаб киритиш шарт';

  @override
  String get animalSoldReasonLabel => 'Изоҳ (ихтиёрий)';

  @override
  String get animalEditSheetTitle => 'Таҳрирлаш';

  @override
  String get animalNameLabel => 'Исм';

  @override
  String get animalBreedFieldLabel => 'Зоти';

  @override
  String get animalColorFieldLabel => 'Ранги';

  @override
  String get animalMotherFieldLabel => 'Онанинг қулоқ рақами';

  @override
  String get animalFatherFieldLabel => 'Отанинг қулоқ рақами';

  @override
  String get animalPregnancyStatusTitle => 'Ҳомиладорлик ҳолати';

  @override
  String get animalPregnancyNone => 'Йўқ';

  @override
  String get animalPregnancyPregnant => 'Ҳомиладор';

  @override
  String get animalPregnancyUnknown => 'Текширилмаган';

  @override
  String get animalPregnancyMonthLabel => 'Ҳомиладорлик ойи:';

  @override
  String animalPregnantWithMonth(int month) {
    return '$month ой ҳомиладор 🤰';
  }

  @override
  String get animalPregnantGeneric => 'Ҳомиладор 🤰';

  @override
  String animalAgeYearsMonths(int years, int months) {
    return '$years йил $months ой';
  }

  @override
  String animalAgeYears(int years) {
    return '$years йил';
  }

  @override
  String animalAgeMonths(int months) {
    return '$months ой';
  }

  @override
  String get animalStatusPickerTitle => 'Ҳолатни ўзгартириш';

  @override
  String get milkTitle => '🥛 Сут';

  @override
  String get milkTodayLabel => 'Бугунги сут';

  @override
  String get milkMorning => '🌅 Ерталаб';

  @override
  String get milkEvening => '🌙 Кечқурун';

  @override
  String get milkRecent => 'Сўнгги ёзувлар';

  @override
  String get milkEmpty => 'Сут ёзуви йўқ';

  @override
  String get milkAmountLabel => 'Миқдор (литр)';

  @override
  String get milkMorningTitle => '🌅 Ерталаб сут';

  @override
  String get milkEveningTitle => '🌙 Кечқурун сут';

  @override
  String get milkHeroLabel => 'СУТ ЁЗУВИ';

  @override
  String get milkHeroTitle => 'Бугунги жами сут';

  @override
  String get milkLitersUnit => 'Литр';

  @override
  String milkYesterday(String liters) {
    return 'Кеча: $liters Л';
  }

  @override
  String get milkDuplicateWarning =>
      'Бугун 2 маҳал сут аллақачон қўшилган. Яна сут қўшмоқчимисиз?';

  @override
  String get milkMorningEntry => 'Ерталабки сут';

  @override
  String get milkEveningEntry => 'Кечқурунги сут';

  @override
  String get milkAnalysisLabel => 'ТАҲЛИЛ';

  @override
  String get milkTrendRising =>
      'Сўнгги 3 кунда сут унумдорлиги барқарор ўсиб бормоқда. Озуқа таркибини ҳозирги ҳолатда сақлаб қолиш тавсия етилади.';

  @override
  String get milkTrendFalling =>
      'Сўнгги 3 кунда сут унумдорлиги пасаймоқда. Озуқа ва сув таъминотини текшириб кўринг.';

  @override
  String milkTrendStable(String avg) {
    return 'Сўнгги 3 кунлик ўртача сут ҳажми $avg литр. Барқарор ҳолат кузатилмоқда.';
  }

  @override
  String get vaccTitle => '💉 Емлаш';

  @override
  String vaccDueSoon(int count) {
    return '⚠️ Яқинлашган емлашлар ($count)';
  }

  @override
  String vaccAll(int count) {
    return 'Барча емлашлар ($count)';
  }

  @override
  String get vaccEmpty => 'Емлаш ёзуви йўқ';

  @override
  String get vaccAddBtn => 'Емлаш қўшиш';

  @override
  String get vaccAddTitle => 'Емлаш қўшиш';

  @override
  String get vaccAnimalHint => 'Ҳайвон танланг';

  @override
  String get vaccAnimalLabel => 'Ҳайвон';

  @override
  String get vaccAnimalRequired => 'Ҳайвон танланг';

  @override
  String get vaccNameLabel => 'Ваксина номи';

  @override
  String get vaccNextDueBtn => 'Кейингиси';

  @override
  String vaccDateLabel(String date) {
    return 'Сана: $date';
  }

  @override
  String get vaccNextLabel => 'Кейинги:';

  @override
  String get vaccSubtitle =>
      'Чорва моллари соғлиғини назорат қилиш ва бошқариш';

  @override
  String get vaccUpcoming => 'Яқинлашаётган\nемлашлар';

  @override
  String vaccUrgentBadge(int count) {
    return '$count ТА\nШОШИЛИНЧ';
  }

  @override
  String get vaccAllRecords => 'Барча ёзувлар';

  @override
  String get vaccDueOverdue => 'Муддати ўтган';

  @override
  String get vaccDueToday => 'Бугун';

  @override
  String get vaccDueTomorrow => 'Ертага';

  @override
  String vaccDueInDays(int days) {
    return '$days кун қолди';
  }

  @override
  String get vaccVaccineLabel => 'ВАКСИНА';

  @override
  String vaccDueDateLabel(String badge) {
    return 'Муддат: $badge';
  }

  @override
  String get vaccStatusDone => 'БАЖАРИЛГАН';

  @override
  String get vaccStatusPlanned => 'РЕЖАДА';

  @override
  String get vaccSavedSnack => 'Емлаш ёзуви сақланди';

  @override
  String get weightTitle => '⚖️ Вазн';

  @override
  String get weightEmpty => 'Вазн ўлчови йўқ';

  @override
  String get weightAddBtn => 'Вазн қўшиш';

  @override
  String get weightAddTitle => 'Вазн қўшиш';

  @override
  String get weightAnimalHint => 'Ҳайвон танланг';

  @override
  String get weightAnimalLabel => 'Ҳайвон';

  @override
  String get weightAnimalRequired => 'Ҳайвон танланг';

  @override
  String get weightLabel => 'Вазн';

  @override
  String get weightWeeklyAvg => 'ҲАФТАЛИК ЎРТАЧА';

  @override
  String get weightChartTitle => 'Вазн графиги';

  @override
  String get weightChartSubtitle => 'Охирги 6 ой';

  @override
  String get weightRecentRecords => 'Сўнгги қайдлар';

  @override
  String get weightSavedSnack => 'Вазн ёзуви сақланди';

  @override
  String get weightMonthJan => 'Ян';

  @override
  String get weightMonthFeb => 'Фев';

  @override
  String get weightMonthMar => 'Мар';

  @override
  String get weightMonthApr => 'Апр';

  @override
  String get weightMonthMay => 'Май';

  @override
  String get weightMonthJun => 'Июн';

  @override
  String get weightMonthJul => 'Июл';

  @override
  String get weightMonthAug => 'Авг';

  @override
  String get weightMonthSep => 'Сен';

  @override
  String get weightMonthOct => 'Окт';

  @override
  String get weightMonthNov => 'Ной';

  @override
  String get weightMonthDec => 'Дек';

  @override
  String get reportTitle => '📊 Ҳисобот';

  @override
  String get report7Days => '7 кун';

  @override
  String get report30Days => '30 кун';

  @override
  String get report1Year => '1 йил';

  @override
  String reportOverview(int days) {
    return 'Умумий кўрсаткичлар ($days кун)';
  }

  @override
  String get reportTotalAnimals => 'Жами ҳайвон';

  @override
  String get reportHealthy => 'Соғлом';

  @override
  String get reportTreatment => 'Даволанмоқда';

  @override
  String get reportCritical => 'Критик';

  @override
  String get reportTeam => 'Жамоат аъзолари';

  @override
  String get reportBirths => 'Туғилишлар';

  @override
  String get reportVaccDue => 'Яқин емлашлар';

  @override
  String get reportSpeciesBreakdown => 'Тур бўйича тақсимот';

  @override
  String get reportAnimalStatus => 'Ҳайвон ҳолати';

  @override
  String get reportHealthStats => 'Касаллик ҳолатлари';

  @override
  String get reportOpenCases => 'Очиқ ҳолатлар';

  @override
  String get reportClosedCases => 'Ёпиқ ҳолатлар';

  @override
  String get reportMilkStats => 'Сут ишлаб чиқариш';

  @override
  String reportTotalMilk(int days) {
    return 'Жами сут ($days кун)';
  }

  @override
  String get reportAvgMilk => 'Ўртача кунлик';

  @override
  String get reportAnalyticsLabel => 'ТАҲЛИЛИЙ МАъЛУМОТЛАР';

  @override
  String get reportTotalLivestockLabel => 'ЖАМИ ЧОРВА';

  @override
  String get reportNoData => 'Маълумот йўқ';

  @override
  String get reportYoungAnimalsTitle => 'Ёш ҳайвонлар (2 ёшгача)';

  @override
  String get reportNoYoungAnimals => 'Ёш ҳайвонлар йўқ';

  @override
  String get reportBySpeciesLabel => 'Турлар бўйича';

  @override
  String get reportNoAnimals => 'Ҳайвон йўқ';

  @override
  String get reportDayMon => 'Ду';

  @override
  String get reportDayTue => 'Се';

  @override
  String get reportDayWed => 'Ч';

  @override
  String get reportDayThu => 'Па';

  @override
  String get reportDayFri => 'Жу';

  @override
  String get reportDaySat => 'Ш';

  @override
  String get reportDaySun => 'Я';

  @override
  String get reportHealthBySpecies => 'Тур бўйича соғлик ҳолати';

  @override
  String get reportLegendHealthy => 'Соғлом';

  @override
  String get reportLegendTreatment => 'Даволанмоқда';

  @override
  String get reportLegendObserved => 'Кузатувда';

  @override
  String get reportLegendCritical => 'Критик';

  @override
  String get menuLanguage => 'Тил';

  @override
  String get menuLangUz => 'Ўзбекча';

  @override
  String get menuLangRu => 'Русский';

  @override
  String get menuEditProfile => 'Ферма маълумотлари';

  @override
  String get menuPersonalInfo => 'Шахсий маълумотлар';

  @override
  String get menuLogout => 'Чиқиш';

  @override
  String get menuLogoutConfirm => 'Ҳисобдан чиқмоқчимисиз?';

  @override
  String get menuChangeAccount => 'Аккаунтни алмаштириш';

  @override
  String get menuChangeAccountConfirm =>
      'Жорий аккаунтдан чиқиб, бошқа аккаунт билан кирасизми?';

  @override
  String get farmPickerTitle => 'Фермани танланг';

  @override
  String get farmPickerSubtitle => 'Аккаунтингизга уланган фермалар';

  @override
  String get farmPickerNewFarm => 'Янги ферма қўшиш';

  @override
  String get bulkVaccTitle => 'Оммавий емлаш';

  @override
  String get bulkVaccSelectAll => 'Барчасини танлаш';

  @override
  String get bulkVaccDeselectAll => 'Танловни бекор қилиш';

  @override
  String get bulkVaccInvert => 'Тескари танлаш';

  @override
  String bulkVaccSelected(int count) {
    return '$count та танланди';
  }

  @override
  String get bulkVaccSaveBtn => 'Емлаш қўшиш';

  @override
  String get bulkVaccFormTitle => 'Емлаш маълумотлари';

  @override
  String get bulkVaccVaccineName => 'Ваксина номи';

  @override
  String get bulkVaccDate => 'Емлаш санаси';

  @override
  String get bulkVaccNextDue => 'Кейинги сана (ихтиёрий)';

  @override
  String bulkVaccSuccess(int count) {
    return '$count та ҳайвон емлантирилди';
  }

  @override
  String get bulkVaccNoneSelected => 'Камида 1 та ҳайвон танланг';

  @override
  String get aiAssistantTitle => 'Асомиддин — АИ Ветеринар';

  @override
  String get aiAssistantSubtitle =>
      '15 йил тажрибали Фарғона водийси ветеринари';

  @override
  String get aiInputHint => 'Ҳайвон ҳақида ёзинг...';

  @override
  String get aiRecording => 'Ёзилмоқда... (қўлни олинг)';

  @override
  String get aiEmergency => 'ФАВҚУЛОДДА ҲОЛАТ';

  @override
  String get aiFirstAid => 'Дарҳол чоралар:';

  @override
  String aiFollowUp(int days) {
    return '$days кундан сўнг текшириш';
  }

  @override
  String get aiListenBtn => 'Ешитиш';

  @override
  String get aiStopBtn => 'Тўхтатиш';

  @override
  String get aiMicPermission => 'Микрофон рухсати керак';

  @override
  String get aiCallVet => 'Ветеринар чақириш';

  @override
  String get aiOnline => 'Онлине';

  @override
  String get aiExperience => 'АИ Ветеринар · 15 йил тажриба';

  @override
  String get aiWelcomeMessage =>
      'Салом! Мен Соня — сизнинг АИ ветеринар ёрдамчингизман. Ҳайвон ҳолати, касаллик белгилари, емлаш ёки вазн ҳақида менга хабар беринг. Овоз ёки матн билан мурожаат қилинг.';

  @override
  String get aiServerError =>
      '⚠️ Сервер билан боғланиб бўлмади, қайта уриниб кўринг';

  @override
  String get aiPhotoSavedSnack =>
      '✅ Сақланди — Саломатлик бўлимида ҳайвонга бириктиринг';

  @override
  String get aiSavedSnack => 'Сақланди';

  @override
  String get aiGenericError => 'Хатолик юз берди. Қайта уриниб кўринг.';

  @override
  String get aiSttFailedSnack => '🎤 Овоз танилмади, қайта уриниб кўринг';

  @override
  String get aiCameraOption => '📷 Камера';

  @override
  String get aiCameraSubtitle => 'Янги расм олиш';

  @override
  String get aiGalleryOption => '🖼️ Галерея';

  @override
  String get aiGallerySubtitle => 'Телефондан танлаш';

  @override
  String get aiDeleteConversation => 'Суҳбатни ўчириш';

  @override
  String aiVetContactLabel(String name) {
    return 'Ветеринар: $name';
  }

  @override
  String get aiCallVetNow => 'Дарҳол ветеринар чақиринг!';

  @override
  String get aiPhotoAddedHint => 'Расм қўшилди. Матн киритинг ва юборинг.';

  @override
  String get aiTranscribing => '🎤 Таҳлил қилинмоқда...';

  @override
  String get aiSwipeToLock => '↑ юқорига → қулфлаш';
}
