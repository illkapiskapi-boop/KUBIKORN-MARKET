KUBIKORN_MARKET — НАТИВНЫЕ ANDROID + iOS, БЕЗ FLUTTER

В проекте два независимых нативных клиента:
- Android: Kotlin + Android WebView.
- iPhone/iPad: Swift + WKWebView.
- Общий интерфейс магазина: папка web/ (HTML/CSS/JavaScript).
- Общий сервер: Node.js API в папке server/.

ДВА ОСНОВНЫХ BAT-ФАЙЛА:

1) build-apk.bat
   Собирает Android APK на Windows. Нужны JDK 17–23 (рекомендуется JDK 21), Android SDK Platform 35,
   Build-Tools 35.0.0 и интернет для первой загрузки Gradle.
   Результат: build-output\KUBIKORN_MARKET-debug.apk

2) build-ipa.bat
   Windows не умеет запускать Xcode. BAT запускает GitHub Actions на облачном Mac,
   а затем скачивает неподписанный IPA. Нужны GitHub CLI (gh), gh auth login,
   репозиторий с загруженным проектом и .github/workflows/ios-unsigned.yml.
   Результат: build-output\ios\KUBIKORN_MARKET-Unsigned.ipa
   Это неподписанный IPA; для установки на iPhone его необходимо подписать Apple.

СЕРВЕР:
1) Скопируйте server/.env.example в server/.env.
2) Укажите ADMIN_EMAIL, ADMIN_PASSWORD (минимум 14 символов), JWT_SECRET (минимум 32 символа)
   и PUBLIC_BASE_URL (публичный HTTPS-адрес).
3) Запустите server/setup-server.bat, чтобы заполнить .env.
4) Запустите server/start-server.bat.
5) В приложении откройте Ustawienia и укажите HTTPS URL API.

Администратор создаёт учётные записи продавцов. У продавцов нет открытой регистрации.
Новые объявления отправляются на модерацию. Кнопка Kup показывает официальный контакт магазина,
если он задан администратором. Платежей внутри приложения нет.

ВНИМАНИЕ: примерные товары видны только в демонстрационном режиме без настроенного API.
Не публикуйте server/.env, пароли, JWT, сертификаты и приватные профили подписи.


## Исправление APK Builder 1.1.2

Исправлен разбор версии Java в Windows CMD. Прежний `FOR /F` пытался трактовать строку версии Java как имя файла и мог вызывать `Непредвиденное появление: ..`. Новый BAT безопасно извлекает номер версии без этого `FOR /F`.
