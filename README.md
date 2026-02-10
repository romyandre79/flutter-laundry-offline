## Tentang Aplikasi

**Kreatif Laundry** adalah aplikasi kasir Kreatif Laundry modern yang dirancang khusus untuk UMKM Indonesia. Aplikasi ini berjalan **100% offline** - tidak memerlukan koneksi internet untuk beroperasi. Semua data tersimpan aman di perangkat lokal.

### Fitur Utama

- **Full Offline Mode** - Aplikasi berjalan tanpa internet
- **Manajemen Order** - Buat, edit, dan kelola pesanan Kreatif Laundry
- **Manajemen Pelanggan** - Database pelanggan lengkap
- **Paket Layanan** - Kelola berbagai jenis layanan Kreatif Laundry
- **Laporan Penjualan** - Analisa pendapatan harian, mingguan, bulanan
- **Multi User** - Support Owner dan Kasir dengan hak akses berbeda
- **Cetak Struk** - Dukungan printer thermal Bluetooth (58mm/80mm)
- **Export Data** - Export laporan ke Excel
- **Share WhatsApp** - Kirim struk ke pelanggan via WhatsApp

---

## Tech Stack

| Technology | Version | Description |
|------------|---------|-------------|
| **Flutter** | 3.10.1+ | Cross-platform UI Framework |
| **Dart** | 3.0.0+ | Programming Language |
| **flutter_bloc** | 9.1.1 | State Management (BLoC/Cubit Pattern) |
| **sqflite** | 2.4.2 | SQLite Local Database |
| **shared_preferences** | 2.5.4 | Key-Value Storage untuk Session |
| **google_fonts** | 7.0.2 | Custom Typography (Poppins) |
| **fl_chart** | 1.1.1 | Charts & Grafik Laporan |
| **print_bluetooth_thermal** | 1.1.9 | Thermal Printer Bluetooth |
| **excel** | 4.0.6 | Export Laporan ke Excel |
| **share_plus** | 12.0.1 | Share ke WhatsApp & Apps |
| **url_launcher** | 6.3.2 | Buka URL External |
| **intl** | 0.20.2 | Format Tanggal & Mata Uang |
| **permission_handler** | 12.0.1 | Handle Permissions Android/iOS |
| **uuid** | 4.5.2 | Generate Unique ID |
| **crypto** | 3.0.6 | Enkripsi Password |
| **equatable** | 2.0.8 | Object Comparison untuk BLoC |
| **path_provider** | 2.1.5 | Akses File System |
| **esc_pos_utils_plus** | 2.0.3 | ESC/POS Commands untuk Printer |

---

## Arsitektur Aplikasi

```
lib/
├── core/
│   ├── constants/       # App constants & configurations
│   ├── services/        # Business services (printer, whatsapp, export)
│   ├── theme/           # Design system (colors, typography, spacing)
│   └── utils/           # Utility functions (formatters, validators)
├── data/
│   ├── database/        # SQLite database helper & migrations
│   ├── models/          # Data models (Order, Customer, Service, dll)
│   └── repositories/    # Data repositories (CRUD operations)
├── logic/
│   └── cubits/          # BLoC/Cubit state management
│       ├── auth/        # Authentication state
│       ├── order/       # Order management state
│       ├── customer/    # Customer management state
│       ├── service/     # Service management state
│       └── report/      # Reporting state
├── presentation/
│   ├── screens/         # UI screens
│   │   ├── auth/        # Login screen
│   │   ├── dashboard/   # Dashboard & statistics
│   │   ├── orders/      # Order list & form
│   │   ├── customers/   # Customer list & form
│   │   ├── services/    # Service list & form
│   │   ├── reports/     # Reports & analytics
│   │   ├── settings/    # App settings
│   │   └── onboarding/  # Onboarding slides
│   └── widgets/         # Reusable widgets
└── main.dart            # App entry point
```

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.10.1
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Android SDK (untuk Android build)
- Xcode (untuk iOS build, macOS only)
- Java 17 (untuk Android build)

## Build APK

### Debug APK (untuk testing)
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (untuk distribusi)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APK per ABI (ukuran lebih kecil)
```bash
flutter build apk --release --split-per-abi
```
Output:
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (~15MB) - untuk device ARM 32-bit
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~16MB) - untuk device ARM 64-bit (recommended)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (~16MB) - untuk emulator

### App Bundle (untuk Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Signing APK untuk Release

### 1. Generate Keystore
```bash
keytool -genkey -v -keystore ~/Kreatif Laundry-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias Kreatif Laundry
```

### 2. Buat file `android/key.properties`
```properties
storePassword=<password-anda>
keyPassword=<password-anda>
keyAlias=Kreatif Laundry
storeFile=/Users/<username>/Kreatif Laundry-release-key.jks
```

> **PENTING:** Tambahkan `key.properties` ke `.gitignore` agar tidak ter-commit!

### 3. Update `android/app/build.gradle.kts`
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 4. Build Signed APK
```bash
flutter build apk --release
```

---

## Distribusi APK

### Opsi 1: Distribusi Langsung (Direct APK)

1. Build APK release dengan signing
2. Transfer file APK ke device via:
   - Kirim via WhatsApp/Telegram
   - Upload ke Google Drive/Dropbox
   - Transfer via kabel USB
3. Install APK di device (aktifkan "Install from Unknown Sources")

### Opsi 2: Google Play Store

1. **Buat akun Google Play Console** ($25 one-time fee)
   - https://play.google.com/console

2. **Siapkan assets**
   - App icon: 512x512 PNG
   - Feature graphic: 1024x500 PNG
   - Screenshots: minimal 2 (phone), opsional tablet
   - Short description (80 karakter)
   - Full description (4000 karakter)

3. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

4. **Upload ke Play Console**
   - Create app > Upload AAB
   - Isi store listing, content rating, pricing
   - Submit for review

5. **Timeline**
   - Review pertama: 1-7 hari
   - Update selanjutnya: 1-3 hari

### Opsi 3: Alternative App Stores

| Store | Pros | Cons |
|-------|------|------|
| **APKPure** | No review, instant publish | Less trusted |
| **Huawei AppGallery** | Free, large China market | Review required |
| **Samsung Galaxy Store** | Pre-installed Samsung | Review required |
| **Amazon Appstore** | Free, Fire devices | Review required |

### Opsi 4: Firebase App Distribution (Testing)

1. **Setup Firebase**
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init
   ```

2. **Distribute APK**
   ```bash
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app YOUR_FIREBASE_APP_ID \
     --groups "testers"
   ```

---

## Build iOS

### Debug
```bash
flutter build ios --debug
```

### Release
```bash
flutter build ios --release
```

### Archive untuk App Store
```bash
flutter build ipa
```

Output: `build/ios/ipa/flutter_Kreatif Laundry_offline_app.ipa`

### Submit ke App Store

1. Buka Xcode > Open `ios/Runner.xcworkspace`
2. Product > Archive
3. Distribute App > App Store Connect
4. Upload

---

## Configuration

### Package Name
Current: `com.prismadataabadi.Kreatif Laundryoffline`

Untuk mengubah package name:
```bash
flutter pub run change_app_package_name:main com.yourcompany.yourapp
```

### App Icon
Logo: `assets/icons/logoKreatif Laundry.png`

Regenerate icons:
```bash
flutter pub run flutter_launcher_icons
```

### App Name
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String appName = 'Kreatif Laundry';
```

Dan `android/app/src/main/AndroidManifest.xml`:
```xml
android:label="Kreatif Laundry"
```

---

## Default Credentials

| Role | Username | Password |
|------|----------|----------|
| Owner | `owner` | `admin123` |

> **Note:** Segera ubah password setelah login pertama kali!

---

## Design System

### Colors (Purple/Violet Theme)
```dart
Primary: #7B2D8E (Violet)
Primary Light: #9B4DB0
Primary Dark: #5A1D6B
Background: #FAF7FB
Surface: #FFFFFF
Error: #E53935
Success: #43A047
Warning: #FB8C00
```

### Typography (Poppins)
| Style | Size | Weight |
|-------|------|--------|
| Display Large | 32sp | Bold |
| Title Large | 24sp | SemiBold |
| Title Medium | 18sp | SemiBold |
| Body Large | 16sp | Regular |
| Body Medium | 14sp | Regular |
| Body Small | 12sp | Regular |
| Label | 10sp | Medium |

### Spacing
```dart
xs: 4dp
sm: 8dp
md: 12dp
lg: 16dp
xl: 24dp
xxl: 32dp
```

---

## Troubleshooting

### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "SDK location not found"
Buat file `android/local.properties`:
```properties
sdk.dir=/Users/<username>/Library/Android/sdk
```

### Error: "Printer not connecting"
1. Pastikan Bluetooth enabled
2. Pair printer di Settings Bluetooth device
3. Restart aplikasi

### Error: "Permission denied"
Tambahkan permissions di AndroidManifest.xml (sudah ada di project):
```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

