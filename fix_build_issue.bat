@echo off
echo ===========================================
echo    REPARATION COMPLETE BUILD FLUTTER
echo ===========================================

echo.
echo 1. Arret des processus Flutter et Dart...
taskkill /f /im dart.exe 2>nul
taskkill /f /im flutter.exe 2>nul
taskkill /f /im gradle.exe 2>nul
taskkill /f /im java.exe 2>nul

echo.
echo 2. Attente 3 secondes...
timeout /t 3 /nobreak >nul

echo.
echo 3. Suppression des repertoires build...
if exist "build" rmdir /s /q "build" 2>nul
if exist "android\.gradle" rmdir /s /q "android\.gradle" 2>nul
if exist "android\app\build" rmdir /s /q "android\app\build" 2>nul
if exist "ios\build" rmdir /s /q "ios\build" 2>nul

echo.
echo 4. Nettoyage Flutter...
flutter clean

echo.
echo 5. Suppression du cache Gradle global...
if exist "%USERPROFILE%\.gradle\caches" rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul

echo.
echo 6. Reinstallation des dependances...
flutter pub get

echo.
echo 7. Generation des icones...
dart run flutter_launcher_icons:main

echo.
echo ===========================================
echo    REPARATION TERMINEE
echo ===========================================
echo.
echo Vous pouvez maintenant executer: flutter run
pause
