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
  String get pinSubtitle => 'PIN kodingizni kiriting';

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
  String get farmSheets => 'Google Sheets';

  @override
  String get farmSheetsSubtitle => 'Ferma ma\'lumotlarini ko\'ring';

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
  String get farmLanguage => 'Til';

  @override
  String get farmLanguageUz => '🇺🇿 O\'zbek';

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
  String get healthAiLabel => '🤖 AI tashxisi:';

  @override
  String healthConfidence(int pct) {
    return 'Ishonch: $pct%';
  }

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
  String get aiAssistantTitle => 'Sonya — AI Veterinar';

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
}
