# Lobotomy Corporation セーブデータ マネージャー
# セーブデータの場所: %USERPROFILE%\AppData\LocalLow\Project_Moon\Lobotomy\

$SaveDir = "$env:USERPROFILE\AppData\LocalLow\Project_Moon\Lobotomy"
$BackupRoot = "$env:USERPROFILE\Documents\LobotomySaves"

function Show-Menu {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Lobotomy Corporation セーブデータ管理" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. 現在のセーブをバックアップする"
    Write-Host "  2. バックアップからセーブを復元する"
    Write-Host "  3. バックアップ一覧を表示する"
    Write-Host "  4. バックアップを削除する"
    Write-Host "  0. 終了"
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Check-SaveDir {
    if (-not (Test-Path $SaveDir)) {
        Write-Host "[エラー] セーブデータフォルダが見つかりません:" -ForegroundColor Red
        Write-Host "  $SaveDir" -ForegroundColor Red
        Write-Host ""
        Write-Host "ゲームを一度起動してからお試しください。" -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Backup-Save {
    if (-not (Check-SaveDir)) { return }

    $files = Get-ChildItem -Path $SaveDir -Filter "*.dat" -ErrorAction SilentlyContinue
    if ($files.Count -eq 0) {
        Write-Host "[警告] バックアップ対象のセーブファイルが見つかりません。" -ForegroundColor Yellow
        return
    }

    Write-Host "バックアップ名を入力してください（例: Day30クリア前）: " -ForegroundColor Green -NoNewline
    $name = Read-Host

    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Host "[エラー] バックアップ名を入力してください。" -ForegroundColor Red
        return
    }

    # ファイル名に使えない文字を除去
    $safeName = $name -replace '[\\/:*?"<>|]', '_'
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolder = "$BackupRoot\${safeName}_${timestamp}"

    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    Copy-Item -Path "$SaveDir\*" -Destination $backupFolder -Recurse -Force

    Write-Host ""
    Write-Host "[成功] バックアップを作成しました！" -ForegroundColor Green
    Write-Host "  名前: $safeName"
    Write-Host "  場所: $backupFolder"
    Write-Host "  ファイル数: $($files.Count) 個"
}

function Restore-Save {
    if (-not (Check-SaveDir)) { return }

    $backups = Get-Backups
    if ($backups.Count -eq 0) {
        Write-Host "[情報] バックアップがありません。先にバックアップを作成してください。" -ForegroundColor Yellow
        return
    }

    Write-Host "復元するバックアップ番号を入力してください: " -ForegroundColor Green -NoNewline
    $input = Read-Host

    if (-not ($input -match '^\d+$')) {
        Write-Host "[エラー] 正しい番号を入力してください。" -ForegroundColor Red
        return
    }

    $index = [int]$input - 1
    if ($index -lt 0 -or $index -ge $backups.Count) {
        Write-Host "[エラー] 番号が範囲外です。" -ForegroundColor Red
        return
    }

    $selected = $backups[$index]
    Write-Host ""
    Write-Host "[警告] 現在のセーブデータは上書きされます！" -ForegroundColor Yellow
    Write-Host "  復元するバックアップ: $($selected.Name)"
    Write-Host "復元しますか？ (y/n): " -ForegroundColor Yellow -NoNewline
    $confirm = Read-Host

    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "キャンセルしました。" -ForegroundColor Gray
        return
    }

    # 現在のセーブを自動バックアップ
    $autoBackup = "$BackupRoot\_自動バックアップ_復元前_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $autoBackup -Force | Out-Null
    Copy-Item -Path "$SaveDir\*" -Destination $autoBackup -Recurse -Force
    Write-Host "(現在のセーブを自動バックアップしました: $autoBackup)" -ForegroundColor Gray

    # セーブフォルダを空にして復元
    Remove-Item -Path "$SaveDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$($selected.FullName)\*" -Destination $SaveDir -Recurse -Force

    Write-Host ""
    Write-Host "[成功] セーブデータを復元しました！" -ForegroundColor Green
    Write-Host "  復元元: $($selected.Name)"
}

function Get-Backups {
    if (-not (Test-Path $BackupRoot)) {
        New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    }
    $backups = Get-ChildItem -Path $BackupRoot -Directory | Sort-Object LastWriteTime -Descending
    return $backups
}

function Show-Backups {
    $backups = Get-Backups
    if ($backups.Count -eq 0) {
        Write-Host "[情報] バックアップがありません。" -ForegroundColor Yellow
        return
    }

    Write-Host "バックアップ一覧:" -ForegroundColor Cyan
    Write-Host ""
    for ($i = 0; $i -lt $backups.Count; $i++) {
        $b = $backups[$i]
        $files = (Get-ChildItem -Path $b.FullName -Filter "*.dat" -ErrorAction SilentlyContinue).Count
        $date = $b.LastWriteTime.ToString("yyyy/MM/dd HH:mm")
        Write-Host ("  {0,2}. [{1}] {2} ({3}ファイル)" -f ($i + 1), $date, $b.Name, $files)
    }
    Write-Host ""
    Write-Host "バックアップ保存先: $BackupRoot" -ForegroundColor Gray
}

function Delete-Backup {
    $backups = Get-Backups
    if ($backups.Count -eq 0) {
        Write-Host "[情報] 削除するバックアップがありません。" -ForegroundColor Yellow
        return
    }

    Show-Backups

    Write-Host "削除するバックアップ番号を入力してください (0でキャンセル): " -ForegroundColor Green -NoNewline
    $input = Read-Host

    if ($input -eq '0') {
        Write-Host "キャンセルしました。" -ForegroundColor Gray
        return
    }

    if (-not ($input -match '^\d+$')) {
        Write-Host "[エラー] 正しい番号を入力してください。" -ForegroundColor Red
        return
    }

    $index = [int]$input - 1
    if ($index -lt 0 -or $index -ge $backups.Count) {
        Write-Host "[エラー] 番号が範囲外です。" -ForegroundColor Red
        return
    }

    $selected = $backups[$index]
    Write-Host "本当に削除しますか？ $($selected.Name) (y/n): " -ForegroundColor Yellow -NoNewline
    $confirm = Read-Host

    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "キャンセルしました。" -ForegroundColor Gray
        return
    }

    Remove-Item -Path $selected.FullName -Recurse -Force
    Write-Host "[成功] 削除しました: $($selected.Name)" -ForegroundColor Green
}

# メインループ
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

while ($true) {
    Show-Menu
    Show-Backups

    Write-Host "番号を入力してください: " -ForegroundColor Green -NoNewline
    $choice = Read-Host

    Write-Host ""

    switch ($choice) {
        '1' { Backup-Save }
        '2' { Restore-Save }
        '3' { Show-Backups }
        '4' { Delete-Backup }
        '0' { Write-Host "終了します。" -ForegroundColor Gray; exit }
        default { Write-Host "[エラー] 0〜4の番号を入力してください。" -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "Enterキーを押して続ける..." -ForegroundColor Gray
    Read-Host | Out-Null
}
