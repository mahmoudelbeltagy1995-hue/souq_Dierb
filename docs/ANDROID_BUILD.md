# Android Build

المطلوب Flutter يتضمن Dart 3.10 أو أحدث متوافق، Android SDK 36، وJava 17.

```bash
cp .env.example .env
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
dart run flutter_native_splash:create --path=splash.yaml
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
flutter build apk --debug -t lib/main_development.dart --flavor development
flutter build apk --release -t lib/main_production.dart --flavor production
flutter build appbundle --release -t lib/main_production.dart --flavor production
```

Application ID هو `com.souqderb.app`، ونسخة development تضيف `.dev`. لا يوجد مفتاح توقيع في Git؛ اضبط keystore وخصائصه في بيئة CI/الجهاز قبل release فعلي للنشر.

المسارات المتوقعة بعد نجاح البناء:

- `build/app/outputs/flutter-apk/app-development-debug.apk`
- `build/app/outputs/flutter-apk/app-production-release.apk`
- `build/app/outputs/bundle/productionRelease/app-production-release.aab`
