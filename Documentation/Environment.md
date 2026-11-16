# SWEET EMPIRE — окружение этапа 0B

Дата: 14.11.2026 (Asia/Oral).

- Рабочий каталог: `C:\Users\timoxa\Desktop\SWEET EMPIRE`.
- Godot-проект: `C:\Users\timoxa\Desktop\SWEET EMPIRE\sweet-empire\project.godot`.
- Godot: `4.7.2.stable.official.ed1daf0bf` (реальный запуск `--version`).
- GUI: `C:\Users\timoxa\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`.
- Console: `C:\Users\timoxa\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
- Godot не найден в PATH; используются полные пути.
- Git: 2.56.0.windows.1. Python: 3.14.2 (оба реально запущены).
- Язык проекта: GDScript; renderer: `gl_compatibility`. C#-проект не создаётся.
- Запись, чтение и удаление собственного временного файла в workspace проверены. `git init -b main` выполнен успешно. Права за пределами workspace не изменялись.
- VS Code: рекомендации Godot Tools и Python обновлены; установка расширений и подключение редактора не проверены.

Повторяемая проверка из PowerShell в корне репозитория:

```powershell
$godotExe = 'C:\Users\timoxa\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$env:APPDATA = Join-Path (Get-Location) '.local/AppData'
& $godotExe --headless --path .\sweet-empire --editor --import --quit --log-file (Join-Path (Get-Location) 'Documentation/stage0b-import-absolute.log')
$LASTEXITCODE
& $godotExe --headless --path .\sweet-empire --quit-after 60 --log-file (Join-Path (Get-Location) 'Documentation/stage0b-run-absolute.log')
$LASTEXITCODE
```

Оценивать и код выхода, и содержимое журнала. Результаты текущей проверки — в `Stage0B-Report.md`. Headless не проверяет отображение и работу GPU. Экспорт Windows, обучение ML и игровые тесты не входят в этот этап.

Исторические сведения об окружении сохранены в `History/Before-Stage0B/Environment.md`.