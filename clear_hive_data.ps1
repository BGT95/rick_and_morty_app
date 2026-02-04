# PowerShell скрипт для очистки Hive данных
# Запустите один раз для удаления старых некорректных данных

Write-Host "🔧 Очистка данных Hive..." -ForegroundColor Cyan

# Для Flutter Web (Chrome)
$chromeIndexedDB = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\IndexedDB"
if (Test-Path $chromeIndexedDB) {
    Write-Host "📁 Поиск данных Chrome IndexedDB..." -ForegroundColor Yellow
    Get-ChildItem -Path $chromeIndexedDB -Filter "http_localhost_*" -Directory | ForEach-Object {
        Write-Host "  ❌ Удаление: $($_.FullName)" -ForegroundColor Red
        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Для Flutter Desktop (Windows)
$appData = "$env:APPDATA\rick_and_morty"
if (Test-Path $appData) {
    Write-Host "📁 Найдена папка приложения: $appData" -ForegroundColor Yellow
    Write-Host "  ❌ Удаление данных..." -ForegroundColor Red
    Remove-Item -Path "$appData\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# Проверка временной папки
$tempHive = "$env:TEMP\rick_and_morty"
if (Test-Path $tempHive) {
    Write-Host "📁 Найдена временная папка: $tempHive" -ForegroundColor Yellow
    Write-Host "  ❌ Удаление временных данных..." -ForegroundColor Red
    Remove-Item -Path "$tempHive\*" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "✅ Очистка завершена!" -ForegroundColor Green
Write-Host "💡 Теперь запустите приложение заново:" -ForegroundColor Cyan
Write-Host "   flutter run -d chrome --web-browser-flag=`"--disable-web-security`"" -ForegroundColor White
Write-Host ""
Write-Host "Нажмите любую клавишу для выхода..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
