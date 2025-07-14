@echo off
echo === Fix Gradle Version Issues ===
echo.

echo 1. Cleaning Flutter project...
flutter clean

echo.
echo 2. Cleaning Gradle cache...
cd android
call gradlew.bat clean
cd ..

echo.
echo 3. Removing Gradle cache directories...
if exist "%USERPROFILE%\.gradle\caches" (
    echo Removing user Gradle cache...
    rmdir /s /q "%USERPROFILE%\.gradle\caches"
)

if exist "android\.gradle" (
    echo Removing project Gradle cache...
    rmdir /s /q "android\.gradle"
)

echo.
echo 4. Getting Flutter dependencies...
flutter pub get

echo.
echo 5. Generating launcher icons...
dart run flutter_launcher_icons:main

echo.
echo 6. Ready to build! Try: flutter run
echo.
pause
