@echo off
setlocal
echo === Treasure of Temple Flutter setup ===
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter SDK not found in PATH.
  echo Install from https://docs.flutter.dev/get-started/install/windows
  echo Then re-run this script inside p8_Treasure_of_Temple_flutter
  exit /b 1
)
flutter create --project-name treasure_of_temple --org com.treasure.temple .
flutter pub get
echo Done. Run: flutter run
