# KUBIKORN_MARKET — natywna wersja Android + iOS

**To wydanie nie używa Fluttera.** Android jest aplikacją natywną Kotlin + Android WebView, a iOS jest aplikacją Swift + WKWebView. Interfejs sklepu jest wspólny (`web/`) i osadzony lokalnie w obu aplikacjach. Katalog, logowanie, zdjęcia i moderacja łączą się ze wspólnym API Node.js.

## Funkcje aplikacji

- Polski interfejs z ciemnym, fioletowym motywem KUBIKORN_MARKET.
- Publiczny katalog, wyszukiwarka i kategorie: Odzież, Elektronika, Obuwie, Perfumy, Akcesoria.
- Oferty zawierają nazwę, opis, kategorię, cenę w PLN, sprzedawcę i maksymalnie 4 zdjęcia.
- Ulubione są zapisywane lokalnie na urządzeniu.
- Logowanie administratora i zaproszonych sprzedawców; publiczna rejestracja sprzedawców nie istnieje.
- Administrator tworzy konta sprzedawców, dezaktywuje je, moderuje ogłoszenia i konfiguruje oficjalny kontakt sklepu.
- Nowe ogłoszenia są domyślnie oczekujące na zatwierdzenie administratora.
- Przycisk „Kup” otwiera oficjalny kontakt sklepu, jeśli administrator go skonfigurował. Aplikacja nie pobiera płatności i nie obsługuje kart.
- Wybór zdjęć działa przez systemowy selektor plików Android/iOS.

## Struktura projektu — bez Fluttera

```text
KUBIKORN_MARKET/
├── android/                         # natywny klient Kotlin + Gradle
│   └── app/src/main/assets/www/     # wspólny interfejs sklepu
├── ios/                             # natywny klient Swift + Xcode
│   └── KUBIKORN_MARKET.xcodeproj/
├── web/                             # HTML, CSS, JavaScript
├── server/                          # API Node.js + baza JSON MVP
├── .github/workflows/ios-unsigned.yml
├── build-apk.bat                    # Windows -> Android APK
├── build-ipa.bat                    # Windows -> GitHub Actions/macOS -> IPA
└── README.md
```

## 1. Budowanie APK na Windows

Wymagania:
- JDK 17–23 (JDK 21 jest zalecany; Gradle 8.10.2 nie jest przeznaczony do uruchamiania na JDK 25).
- Android SDK Platform 35.
- Android SDK Build-Tools 35.0.0.
- Połączenie z internetem podczas pierwszego uruchomienia — skrypt pobierze Gradle 8.10.2 do `%USERPROFILE%\.kubikorn-tools`.

Kroki:
1. Otwórz Android Studio → SDK Manager i zainstaluj Android 15 / API 35 oraz Build-Tools 35.0.0.
2. Rozpakuj projekt do zwykłego folderu na dysku Windows.
3. Uruchom `build-apk.bat`.
4. Debug APK pojawi się jako `build-output/KUBIKORN_MARKET-debug.apk`.

To APK jest podpisane debugowym kluczem Android Gradle i służy do testów. Do dystrybucji produkcyjnej należy skonfigurować własny, prywatny klucz release i budować wariant `release`. Nie publikuj klucza ani hasła w repozytorium.

## 2. Budowanie iOS IPA z Windows

Windows nie uruchamia Xcode lokalnie. `build-ipa.bat` używa GitHub CLI do uruchomienia workflow na macOS.

Wymagania:
- konto GitHub i GitHub CLI (`gh`),
- `gh auth login`,
- projekt przesłany do repozytorium GitHub, w tym ukryty katalog `.github/workflows/ios-unsigned.yml`,
- uprawnienie do uruchamiania GitHub Actions w tym repozytorium.

Kroki:
1. Utwórz repozytorium, np. `KUBIKORN-MARKET`, i wypchnij do gałęzi `main` **zawartość** tego folderu (w tym `.github`).
2. Uruchom `build-ipa.bat`.
3. Podaj `owner/repository` i gałąź `main`.
4. Skrypt uruchomi Xcode na GitHub-hosted macOS, poczeka na wynik i pobierze artefakt do `build-output/ios/`.

Wynik to **niepodpisany IPA** dla prawdziwego iPhone'a, a nie aplikacja symulatora. Nie można go zainstalować bez podpisu Apple i odpowiedniego profilu. Do instalacji na własnym urządzeniu potrzebna jest poprawna podpisana dystrybucja (np. Personal Team przez Xcode lub własny profil provisioning). Ten projekt nie zawiera certyfikatów ani kluczy.

## 3. Uruchomienie API i konfiguracja administratora

Wymagania: Node.js 22 lub nowszy.

1. Otwórz `server/.env.example`, skopiuj go jako `server/.env`.
2. Ustaw `ADMIN_EMAIL` oraz `ADMIN_PASSWORD` (unikalne hasło o długości co najmniej 14 znaków).
3. Ustaw `JWT_SECRET` na losowy sekret o długości co najmniej 32 znaków. Wygeneruj go poleceniem:

   ```cmd
   node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
   ```

4. Ustaw `PUBLIC_BASE_URL` na publiczny adres HTTPS API.
5. W folderze `server` uruchom `npm install`, a następnie `npm start` (albo skorzystaj z `server/setup-server.bat` i `server/start-server.bat`).
6. Sprawdź `https://twoj-adres-api/health`; oczekiwana odpowiedź to JSON z `ok: true`.
7. W aplikacji otwórz **Ustawienia** i wpisz ten sam adres API HTTPS.

Administrator jest tworzony automatycznie przy pierwszym uruchomieniu serwera z ustawionym `ADMIN_EMAIL` i `ADMIN_PASSWORD`. Konta sprzedawców tworzy wyłącznie administrator w panelu aplikacji.

## 4. Kontakt sklepu i bezpieczeństwo

- Linki Telegram/WhatsApp są domyślnie puste i może je ustawić administrator w panelu. Wpisuj tylko oficjalne kanały sklepu; nie umieszczaj prywatnych numerów ani prywatnych kont w publicznym repozytorium.
- Nie umieszczaj w GitHub `server/.env`, haseł, JWT_SECRET, certyfikatów ani provisioning profiles.
- Do publicznego uruchomienia wymagane są HTTPS, kopie zapasowe, moderacja ogłoszeń i regulamin sklepu.
- Serwer zapisuje dane w jednym pliku `server/data/db.json`. To prototyp dla pojedynczej instancji, nie docelowa baza dużego sklepu. Przed szerszym wdrożeniem zastąp go PostgreSQL i przenieś zdjęcia do trwałego object storage.

## 5. Ograniczenia wersji 1.1.0

- Nie ma płatności w aplikacji, zamówień ani śledzenia dostawy.
- Nie ma publicznej rejestracji kupujących ani sprzedawców.
- Token sesji i ulubione są przechowywane w lokalnym magazynie WebView; przed publicznym wdrożeniem warto przenieść token do Android Keystore / iOS Keychain.
- Domyślny ekran demonstracyjny pokazuje wyraźnie oznaczone przykładowe produkty, dopóki nie zostanie skonfigurowany prawdziwy adres API.
- Do publikacji w Google Play lub App Store potrzebne są dodatkowe czynności, polityka prywatności, konta wydawcy i podpisy platform.


## Исправление сборщиков 1.1.1

- `build-apk.bat` открывает отдельное постоянное окно CMD и сохраняет лог в `build-output/apk-build.log`.
- `build-ipa.bat` проверяет workflow через `gh workflow view ... --yaml` (этот флаг обязателен, если указан `--ref`) и запускает GitHub Actions на macOS.
- iOS workflow находится в `.github/workflows/ios-unsigned.yml`.


## APK Builder 1.1.2 — poprawka Windows CMD

W `build-apk.bat` poprawiono odczyt numeru wersji JDK. Poprzedni skrypt próbował parsować wersję Java przez `FOR /F` jako nazwę pliku, co w niektórych instalacjach Windows kończyło się komunikatem `Непредвиденное появление: ..`. Nowy skrypt wyciąga numer główny przez bezpieczne podstawienie podciągu, a następnie wykonuje standardową kontrolę JDK.
