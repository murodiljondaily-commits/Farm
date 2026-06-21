// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get errorDefault => '⚠️ Ошибка, попробуйте снова';

  @override
  String get errorOk => 'OK';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get continueBtn => 'Продолжить';

  @override
  String get hideText => 'Скрыть';

  @override
  String get showText => 'Показать';

  @override
  String get errorGeneric => 'Произошла ошибка';

  @override
  String get confirm => 'Подтверждение';

  @override
  String get yes => 'Да';

  @override
  String get deleteBtn => 'Удалить';

  @override
  String get closeBtn => 'Закрыть';

  @override
  String get openStatus => 'Открыт';

  @override
  String get closedStatus => 'Закрыт';

  @override
  String get enterHint => 'Введите';

  @override
  String get enterNumber => 'Введите число';

  @override
  String get fieldRequired => 'Заполните поле';

  @override
  String get roleOwner => 'Владелец фермы';

  @override
  String get roleVet => 'Ветеринар';

  @override
  String get roleFarmer => 'Фермер';

  @override
  String get roleCoowner => 'Совладелец';

  @override
  String get roleVetDesc =>
      'Диагностика болезней, официальные решения о лечении';

  @override
  String get roleFarmerDesc => 'Регистрирует животных, вводит данные';

  @override
  String get roleCoownerDesc =>
      'Те же права, что у владельца, подтверждение участников';

  @override
  String get speciesSigir => 'Корова';

  @override
  String get speciesQoy => 'Овца';

  @override
  String get speciesEchki => 'Коза';

  @override
  String get speciesOt => 'Лошадь';

  @override
  String get speciesChochqa => 'Свинья';

  @override
  String get speciesBoshqa => 'Другое';

  @override
  String get speciesSigirPlural => 'Коровы';

  @override
  String get speciesQoyPlural => 'Овцы';

  @override
  String get speciesEchkiPlural => 'Козы';

  @override
  String get speciesOtPlural => 'Лошади';

  @override
  String get speciesAll => 'Все';

  @override
  String get statusSoglom => 'Здоров';

  @override
  String get statusDavolanmoqda => 'На лечении';

  @override
  String get statusKritik => 'Критический';

  @override
  String get statusKuzatuvda => 'Под наблюдением';

  @override
  String get statusSotildi => 'Продан';

  @override
  String get statusOldi => 'Погиб';

  @override
  String get severityRoutine => 'Обычный';

  @override
  String get severityUrgent => 'Срочный';

  @override
  String get severityEmergency => '🚨 Экстренный';

  @override
  String get googleSignInTitle => 'AgriVet';

  @override
  String get googleSignInSubtitle =>
      'Управление животными фермы\nи ИИ-помощник ветеринара';

  @override
  String get googleSignInBtn => 'Войти через Google';

  @override
  String get googleSignInLoading => 'Вход...';

  @override
  String get googleSignInError => 'Вход не выполнен. Попробуйте снова.';

  @override
  String get googleSignInOrDivider => 'или';

  @override
  String get googleSignInViaPhone => 'Войти по номеру телефона';

  @override
  String get phoneAuthTitle => 'Вход по телефону';

  @override
  String get phoneAuthSubtitle => 'Отправим код подтверждения по SMS';

  @override
  String get phoneEnterNumber => 'Ваш номер телефона';

  @override
  String get phoneNumberHint => 'XX XXX XX XX';

  @override
  String get phoneSendCode => 'Отправить SMS код';

  @override
  String get phoneInvalidNumber => 'Введите корректный номер телефона';

  @override
  String get phoneTooManyRequests => 'Слишком много попыток. Попробуйте позже.';

  @override
  String get phoneError => 'Произошла ошибка. Попробуйте снова.';

  @override
  String get phoneOtpTitle => 'Введите SMS код';

  @override
  String phoneOtpSubtitle(String phone) {
    return 'Код отправлен на $phone';
  }

  @override
  String get phoneOtpHint => '------';

  @override
  String get phoneOtpVerify => 'Подтвердить';

  @override
  String get phoneOtpResend => 'Отправить снова';

  @override
  String phoneOtpResendIn(int sec) {
    return 'Отправить снова через $sec сек';
  }

  @override
  String get phoneOtpError => 'Неверный код или истёк срок действия';

  @override
  String get phoneOtpAutoVerified => 'Автоматически подтверждено';

  @override
  String get welcomeSubtitle =>
      'Управление животными фермы\nи ИИ-помощник ветеринара';

  @override
  String get welcomeFeatureAnimals => 'Регистрируйте животных';

  @override
  String get welcomeFeatureAi => 'ИИ-помощник ветеринара';

  @override
  String get welcomeFeatureHistory => 'История вакцинации и болезней';

  @override
  String get welcomeFeatureSheets => 'Синхронизация с Google Таблицами';

  @override
  String get welcomeNewFarm => 'Создать новую ферму';

  @override
  String get welcomeJoinFarm => 'Присоединиться к ферме';

  @override
  String get setupTitle => 'Новая ферма';

  @override
  String get setupHeading => 'Настройка вашей фермы';

  @override
  String get setupSubtitle => 'Все поля обязательны для заполнения';

  @override
  String get setupOwnerName => 'Имя и фамилия';

  @override
  String get setupOwnerNameHint => 'Введите ваше имя';

  @override
  String get setupFarmName => 'Название фермы';

  @override
  String get setupLocation => 'Адрес';

  @override
  String get setupLocationHint => 'Район, область';

  @override
  String get setupEmail => 'Email (необязательно)';

  @override
  String get setupPhone => 'Номер телефона';

  @override
  String get joinTitle => 'Присоединиться к ферме';

  @override
  String get joinCodeTitle => 'Код фермы';

  @override
  String get joinCodeSubtitle =>
      'Получите код фермы у владельца (AGVET-XXXXXX)';

  @override
  String get joinCodeCheck => 'Проверить код';

  @override
  String get joinCodeNotFound => 'Код фермы не найден. Проверьте и повторите.';

  @override
  String get joinPhoneRequired => 'Введите полный номер телефона';

  @override
  String get joinRoleTitle => 'Выберите вашу роль';

  @override
  String joinRoleSubtitle(String farmName) {
    return 'Присоединяетесь к ферме \"$farmName\"';
  }

  @override
  String get joinApprovalNote =>
      'Запрос на вступление будет отправлен владельцу фермы для подтверждения.';

  @override
  String get joinDetailsTitle => 'Личные данные';

  @override
  String joinDetailsSubtitle(String farmName, String role) {
    return '\"$farmName\" — роль $role';
  }

  @override
  String get joinNameLabel => 'Имя и фамилия';

  @override
  String get joinNameHint => 'Введите ваше имя';

  @override
  String get joinNameRequired => 'Введите ваше имя';

  @override
  String get joinLocationLabel => 'Адрес';

  @override
  String get joinLocationRequired => 'Введите адрес';

  @override
  String get joinEmailLabel => 'Email (необязательно)';

  @override
  String get joinPhoneLabel => 'Номер телефона';

  @override
  String get joinSubmit => 'Отправить запрос';

  @override
  String get pinSubtitle => 'Введите PIN-код';

  @override
  String pinGreeting(String name) {
    return 'Привет, $name!';
  }

  @override
  String get pinWrongMany => 'Слишком много попыток. Сообщите владельцу.';

  @override
  String get pinWrong => 'Неверный PIN. Попробуйте снова.';

  @override
  String get pinSetupTitle => 'Установка PIN-кода';

  @override
  String pinSetupGreeting(String name) {
    return 'Привет, $name!\nУстановите 4-значный PIN-код для защиты входа.';
  }

  @override
  String get pinSetupEnter => 'Введите PIN-код';

  @override
  String get pinSetupConfirm => 'Подтвердите PIN-код';

  @override
  String get pinSetupSave => 'Сохранить и войти';

  @override
  String get pinSetupReminder =>
      'Запомните PIN-код — он нужен для входа в систему';

  @override
  String get pinSetupError4digits => 'PIN-код должен состоять из 4 цифр';

  @override
  String get pinSetupErrorMatch => 'PIN-коды не совпадают';

  @override
  String get changePinTitle => 'Изменить PIN-код';

  @override
  String get changePinNote => 'Сначала введите текущий PIN-код, затем новый.';

  @override
  String get changePinCurrentLabel => 'Текущий PIN-код';

  @override
  String get changePinNewLabel => 'Новый PIN-код';

  @override
  String get changePinConfirmLabel => 'Подтвердите новый PIN-код';

  @override
  String get changePinSuccess => '✅ PIN-код успешно изменён';

  @override
  String get changePinErrorCurrent4 => 'Текущий PIN должен состоять из 4 цифр';

  @override
  String get changePinError4digits => 'Новый PIN должен состоять из 4 цифр';

  @override
  String get changePinErrorMatch => 'Новые PIN-коды не совпадают';

  @override
  String get changePinErrorSame => 'Новый PIN не может совпадать с текущим';

  @override
  String get changePinErrorWrong => 'Неверный текущий PIN. Попробуйте снова.';

  @override
  String get changePinErrorTooMany =>
      'Слишком много неверных попыток. Выйдите и войдите снова.';

  @override
  String homeGreeting(String name) {
    return 'Привет, $name! 👋';
  }

  @override
  String get homeLock => 'Заблокировать';

  @override
  String homeOpenCasesAlert(int count) {
    return '$count открытых случаев болезни';
  }

  @override
  String homeDueSoonAlert(int count) {
    return '$count вакцинаций истекает скоро';
  }

  @override
  String get homeTotalAnimals => 'Всего животных';

  @override
  String get homeTodayMilk => 'Всё молоко';

  @override
  String get homeAnimalsSection => 'Животные';

  @override
  String get homeQuickActions => 'Быстрые действия';

  @override
  String get homeNavHome => 'Главная';

  @override
  String get homeNavAnimals => 'Животные';

  @override
  String get homeNavHealth => 'Здоровье';

  @override
  String get homeNavFarm => 'Ферма';

  @override
  String get homeActionHealth => 'Случай болезни';

  @override
  String get homeActionHealthSub => 'Введите симптомы, ИИ поставит диагноз';

  @override
  String get homeActionVacc => 'Вакцинация';

  @override
  String get homeActionVaccSub => 'Добавить вакцинацию';

  @override
  String get homeActionMilk => 'Молоко';

  @override
  String get homeActionMilkSub => 'Записать надой';

  @override
  String get homeActionWeight => 'Вес';

  @override
  String get homeActionWeightSub => 'Замер веса';

  @override
  String get homeActionReport => 'Отчёт';

  @override
  String get homeActionReportSub => 'Посмотреть отчёт фермы';

  @override
  String homeAnimalCount(int count) {
    return '$count шт.';
  }

  @override
  String get farmTitle => 'Ферма';

  @override
  String get farmNoData => 'Данные фермы не найдены';

  @override
  String get farmSheets => 'Google Таблицы';

  @override
  String get farmSheetsSubtitle => 'Просмотр данных фермы';

  @override
  String get farmChangePin => 'Изменить PIN-код';

  @override
  String get farmLock => 'Заблокировать';

  @override
  String get farmLogout => 'Выйти';

  @override
  String get farmLogoutConfirm => 'Вы хотите выйти из аккаунта?';

  @override
  String get farmOwnerLabel => 'Владелец';

  @override
  String get farmEmailLabel => 'Email';

  @override
  String get farmYouLabel => 'Вы';

  @override
  String get farmRoleLabel => 'Роль';

  @override
  String get farmCodeCopied => 'Код фермы скопирован';

  @override
  String get farmLanguage => 'Язык';

  @override
  String get farmLanguageUz => '🇺🇿 O\'zbek';

  @override
  String get farmLanguageRu => '🇷🇺 Русский';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsFarmSection => 'Данные фермы';

  @override
  String get settingsAccountSection => 'Ваш аккаунт';

  @override
  String get settingsSecuritySection => 'Безопасность';

  @override
  String get settingsFarmName => 'Название фермы';

  @override
  String get settingsFarmCode => 'Код фермы';

  @override
  String get settingsLocation => 'Адрес';

  @override
  String get settingsPhone => 'Телефон';

  @override
  String get settingsLogoutStep2Title => 'Вы уверены?';

  @override
  String get settingsLogoutStep2Body =>
      'Вы выйдете из системы. Для входа снова потребуется PIN-код.';

  @override
  String get settingsLogoutFinal => 'Да, выйти';

  @override
  String get animalsAllTitle => '🐾 Все животные';

  @override
  String get animalsSearch => 'Поиск (имя, ушная бирка...)';

  @override
  String get animalsAdd => 'Добавить животное';

  @override
  String get animalsEmpty => 'Животных нет';

  @override
  String animalsEmptySpecies(String species) {
    return '$species нет';
  }

  @override
  String get animalsAddNew => 'Добавьте новое животное';

  @override
  String get addAnimalTitle => 'Добавить животное';

  @override
  String get addAnimalSpeciesSection => 'Вид';

  @override
  String get addAnimalBasicSection => 'Основная информация';

  @override
  String get addAnimalEarTag => 'Ушная бирка *';

  @override
  String get addAnimalEarTagRequired => 'Введите номер ушной бирки';

  @override
  String get addAnimalName => 'Кличка (необязательно)';

  @override
  String get addAnimalSex => 'Пол';

  @override
  String get addAnimalSexMale => '♂ Самец';

  @override
  String get addAnimalSexFemale => '♀ Самка';

  @override
  String get addAnimalSexUnknown => 'Неизвестно';

  @override
  String get addAnimalDob => 'Дата рождения';

  @override
  String get addAnimalDetailsSection => 'Дополнительная информация';

  @override
  String get addAnimalBreed => 'Порода';

  @override
  String get addAnimalColor => 'Масть';

  @override
  String get addAnimalOrigin => 'Происхождение (район, область)';

  @override
  String get addAnimalParentsSection => 'Родители (необязательно)';

  @override
  String get addAnimalMother => 'Бирка матери';

  @override
  String get addAnimalFather => 'Бирка отца';

  @override
  String get healthTitle => '🏥 Случаи болезней';

  @override
  String get healthOpen => 'Открытые';

  @override
  String get healthSevere => 'Тяжёлые';

  @override
  String get healthClosed => 'Закрытые';

  @override
  String get healthEmpty => 'Случаев болезней нет 🎉';

  @override
  String get healthAddBtn => 'Добавить случай';

  @override
  String get healthAddTitle => 'Добавить случай болезни';

  @override
  String get healthAnimalHint => 'Выберите животное';

  @override
  String get healthAnimalLabel => 'Животное';

  @override
  String get healthAnimalRequired => 'Выберите животное';

  @override
  String get healthSymptomsLabel => 'Симптомы';

  @override
  String get healthSymptomsRequired => 'Введите симптомы';

  @override
  String get healthSeverityLabel => 'Тяжесть';

  @override
  String get healthClose => 'Закрыть';

  @override
  String get healthAiLabel => '🤖 Диагноз ИИ:';

  @override
  String healthConfidence(int pct) {
    return 'Уверенность: $pct%';
  }

  @override
  String get animalNotFoundTitle => 'Животное не найдено';

  @override
  String get animalNotFoundBody => 'Это животное не найдено';

  @override
  String get animalTabInfo => 'Информация';

  @override
  String get animalTabHealth => 'Здоровье';

  @override
  String get animalTabVacc => 'Вакцинация';

  @override
  String get animalTabWeight => 'Вес';

  @override
  String get animalMenuHealth => '🏥 Добавить случай болезни';

  @override
  String get animalMenuVacc => '💉 Добавить вакцинацию';

  @override
  String get animalMenuWeight => '⚖️ Добавить вес';

  @override
  String get animalMenuSold => '✅ Продан';

  @override
  String get animalMenuDead => '💀 Погиб';

  @override
  String get animalMenuDelete => '🗑️ Удалить';

  @override
  String get animalFabHealth => 'Болезнь';

  @override
  String get animalFabVacc => 'Вакцинация';

  @override
  String get animalFabWeight => 'Вес';

  @override
  String get animalConfirmSold => 'Отметить как проданное?';

  @override
  String get animalConfirmDead => 'Отметить как погибшее?';

  @override
  String animalConfirmDelete(String name) {
    return 'Удалить $name?';
  }

  @override
  String get animalInfoSpecies => 'Вид';

  @override
  String get animalInfoBreed => 'Порода';

  @override
  String get animalInfoSex => 'Пол';

  @override
  String get animalInfoAge => 'Возраст';

  @override
  String animalInfoAgeValue(int count) {
    return '$count лет';
  }

  @override
  String get animalInfoColor => 'Масть';

  @override
  String get animalInfoOrigin => 'Происхождение';

  @override
  String get animalInfoMother => 'Мать';

  @override
  String get animalInfoFather => 'Отец';

  @override
  String get animalInfoPregnancy => 'Беременность';

  @override
  String animalPregnant(String date) {
    return '🤰 Беременна ($date)';
  }

  @override
  String get animalCalved => '✅ Отелилась';

  @override
  String get animalHealthEmpty => 'Случаев болезней нет';

  @override
  String get animalVaccEmpty => 'История вакцинации пуста';

  @override
  String get animalWeightEmpty => 'Данных о весе нет';

  @override
  String animalVaccDate(String date) {
    return 'Дата: $date';
  }

  @override
  String get animalVaccNextLabel => 'Следующая:';

  @override
  String get animalHealthSymptomsLabel => 'Симптомы:';

  @override
  String get animalHealthAiLabel => 'Диагноз ИИ:';

  @override
  String animalHealthConfidence(int pct) {
    return 'Уверенность: $pct%';
  }

  @override
  String get milkTitle => '🥛 Молоко';

  @override
  String get milkTodayLabel => 'Молоко сегодня';

  @override
  String get milkMorning => '🌅 Утром';

  @override
  String get milkEvening => '🌙 Вечером';

  @override
  String get milkRecent => 'Последние записи';

  @override
  String get milkEmpty => 'Записей о надое нет';

  @override
  String get milkAmountLabel => 'Количество (литры)';

  @override
  String get milkMorningTitle => '🌅 Утренний надой';

  @override
  String get milkEveningTitle => '🌙 Вечерний надой';

  @override
  String get vaccTitle => '💉 Вакцинация';

  @override
  String vaccDueSoon(int count) {
    return '⚠️ Предстоящие вакцинации ($count)';
  }

  @override
  String vaccAll(int count) {
    return 'Все вакцинации ($count)';
  }

  @override
  String get vaccEmpty => 'Записей о вакцинации нет';

  @override
  String get vaccAddBtn => 'Добавить вакцинацию';

  @override
  String get vaccAddTitle => 'Добавить вакцинацию';

  @override
  String get vaccAnimalHint => 'Выберите животное';

  @override
  String get vaccAnimalLabel => 'Животное';

  @override
  String get vaccAnimalRequired => 'Выберите животное';

  @override
  String get vaccNameLabel => 'Название вакцины';

  @override
  String get vaccNextDueBtn => 'Следующая';

  @override
  String vaccDateLabel(String date) {
    return 'Дата: $date';
  }

  @override
  String get vaccNextLabel => 'Следующая:';

  @override
  String get weightTitle => '⚖️ Вес';

  @override
  String get weightEmpty => 'Данных о весе нет';

  @override
  String get weightAddBtn => 'Добавить вес';

  @override
  String get weightAddTitle => 'Добавить вес';

  @override
  String get weightAnimalHint => 'Выберите животное';

  @override
  String get weightAnimalLabel => 'Животное';

  @override
  String get weightAnimalRequired => 'Выберите животное';

  @override
  String get weightLabel => 'Вес';

  @override
  String get reportTitle => '📊 Отчёт';

  @override
  String get report7Days => '7 дней';

  @override
  String get report30Days => '30 дней';

  @override
  String get report1Year => '1 год';

  @override
  String reportOverview(int days) {
    return 'Общие показатели ($days дней)';
  }

  @override
  String get reportTotalAnimals => 'Всего животных';

  @override
  String get reportHealthy => 'Здоровых';

  @override
  String get reportTreatment => 'На лечении';

  @override
  String get reportCritical => 'Критических';

  @override
  String get reportTeam => 'Членов команды';

  @override
  String get reportBirths => 'Рождений';

  @override
  String get reportVaccDue => 'Предстоящих вакцинаций';

  @override
  String get reportSpeciesBreakdown => 'Распределение по видам';

  @override
  String get reportAnimalStatus => 'Состояние животных';

  @override
  String get reportHealthStats => 'Случаи болезней';

  @override
  String get reportOpenCases => 'Открытые случаи';

  @override
  String get reportClosedCases => 'Закрытые случаи';

  @override
  String get reportMilkStats => 'Производство молока';

  @override
  String reportTotalMilk(int days) {
    return 'Всего молока ($days дней)';
  }

  @override
  String get reportAvgMilk => 'Среднесуточный';

  @override
  String get reportHealthBySpecies => 'Здоровье по видам';

  @override
  String get reportLegendHealthy => 'Здоровых';

  @override
  String get reportLegendTreatment => 'На лечении';

  @override
  String get reportLegendObserved => 'Под наблюдением';

  @override
  String get reportLegendCritical => 'Критических';

  @override
  String get menuLanguage => 'Язык';

  @override
  String get menuLangUz => 'O\'zbekcha';

  @override
  String get menuLangRu => 'Русский';

  @override
  String get menuEditProfile => 'Данные фермы';

  @override
  String get menuLogout => 'Выйти';

  @override
  String get menuLogoutConfirm => 'Выйти из аккаунта?';

  @override
  String get menuChangeAccount => 'Сменить аккаунт';

  @override
  String get menuChangeAccountConfirm => 'Выйти и войти с другим аккаунтом?';

  @override
  String get farmPickerTitle => 'Выберите ферму';

  @override
  String get farmPickerSubtitle => 'Фермы, привязанные к вашему аккаунту';

  @override
  String get farmPickerNewFarm => 'Добавить новую ферму';

  @override
  String get bulkVaccTitle => 'Массовая вакцинация';

  @override
  String get bulkVaccSelectAll => 'Выбрать всех';

  @override
  String get bulkVaccDeselectAll => 'Снять выбор';

  @override
  String get bulkVaccInvert => 'Инвертировать';

  @override
  String bulkVaccSelected(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get bulkVaccSaveBtn => 'Добавить вакцинацию';

  @override
  String get bulkVaccFormTitle => 'Данные вакцинации';

  @override
  String get bulkVaccVaccineName => 'Название вакцины';

  @override
  String get bulkVaccDate => 'Дата вакцинации';

  @override
  String get bulkVaccNextDue => 'Следующая дата (необязательно)';

  @override
  String bulkVaccSuccess(int count) {
    return '$count животных вакцинированы';
  }

  @override
  String get bulkVaccNoneSelected => 'Выберите хотя бы 1 животное';

  @override
  String get aiAssistantTitle => 'Мухлиса — ИИ Ветеринар';

  @override
  String get aiAssistantSubtitle =>
      'Ветеринар из Ферганской долины с 15-летним опытом';

  @override
  String get aiInputHint => 'Напишите о животном...';

  @override
  String get aiRecording => 'Запись... (отпустите)';

  @override
  String get aiEmergency => 'ЭКСТРЕННАЯ СИТУАЦИЯ';

  @override
  String get aiFirstAid => 'Срочные меры:';

  @override
  String aiFollowUp(int days) {
    return 'Проверка через $days дней';
  }

  @override
  String get aiListenBtn => 'Слушать';

  @override
  String get aiStopBtn => 'Стоп';

  @override
  String get aiMicPermission => 'Нужно разрешение микрофона';

  @override
  String get aiCallVet => 'Вызвать ветеринара';

  @override
  String get aiOnline => 'Онлайн';

  @override
  String get aiExperience => 'ИИ Ветеринар · 15 лет опыта';
}
