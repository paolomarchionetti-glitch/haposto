@echo off
rem HAPOSTO STEP 7 bootstrap script.
rem Generate the official wrapper once with Gradle 9.5.0: gradle wrapper --gradle-version 9.5.0
where gradle >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  gradle %*
  exit /b %ERRORLEVEL%
)
echo Gradle executable not found and the standard Gradle wrapper JAR is not included.
echo Install/use Gradle 9.5.0 once, then run: gradle wrapper --gradle-version 9.5.0
exit /b 1
