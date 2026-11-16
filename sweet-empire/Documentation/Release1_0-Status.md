# SWEET EMPIRE 1.0.0-dev.1 — статус

## Предварительный Windows-пакет после обновления декораций

Экспортированы актуальные исходники в `Builds/Windows/SWEET_EMPIRE.exe` и `.pck`.
Godot export exit 0; предыдущая сборка сохранена в
`.local/release-audit/build-backups/8efe394eac144aa4a8de1e0f1a53da48/`.
Headless запуск экспортированного exe: exit 0, но в журнале присутствует
`ERROR: Failed to read the root certificate store.` Ошибка не подавлялась.
Отдельный запуск копии exe непосредственно из папки пакета также дал exit 0 и
ту же ошибку; журнал `.local/release-audit/package-smoke/godot.log`.

Файлы для тестовой передачи скопированы в `Builds/SWEET_EMPIRE_1.0_Windows/`,
архив — `Builds/SWEET_EMPIRE_1.0_Windows.zip` (40 583 776 байт). ZIP проверен
по CRC и содержит только exe, pck и README. PCK содержит 287 записей; отдельные
исходные .gd/.py/.ps1, тесты, логи, save-файлы и Git в нём не найдены. Три
runtime JSON модели и конфигураций присутствуют. Жестовый worker в пакет не включён.

Запущены актуальные station_lifecycle=39, sophie_layout=45, main_menu_layout=88,
menu_settings=11, stage5=81, persistence_restart=5 assertions с 0 failed и exit 0.
Строгий статус всех suites — FAIL из-за той же engine-ошибки. Логи:
`.local/testing/python/d3caec83678c44a5a5d063e535a792ce/`,
`.local/release-audit/export/` и `.local/release-audit/exported-smoke/`.
GUI, фактическая игра экспортированного exe, FPS, камера, worker, работа на другом
ПК и комплектность лицензионных уведомлений не проверялись. Пакет годится для
предварительного тестирования с этими ограничениями, финальный релиз не готов.

## Дополнение: единый стиль главного меню

Кнопки используют одну локальную тему Button с мятными normal/hover/pressed,
приглушённым disabled и рамкой focus. ShopMenuButton сохраняет прежний класс/API,
но использует ту же кнопку и тему. VBoxContainer размещён в CenterContainer внутри
ScrollContainer с якорями и отступами; при ограниченной высоте кнопки и интервалы
уменьшаются, а прокрутка позволяет добраться до выхода. Другие темы не менялись.

Headless `main_menu_layout_tests`: 88 assertions, 0 failed, Godot exit 0 для
1280×720, 1366×768, 1600×900, 1920×1080, 1024×768 и искусственно уменьшенной
области. Строгий статус FAIL из-за `Failed to read the root certificate store`.
Логи: `.local/testing/python/afb2531e0fd94f8fb267e2d0f42a0046/`.
Связанные menu_settings=11, stage5=81 и run_tests=48 assertions имели 0 failed,
но также получили строгий FAIL из-за той же ошибки. Графическое окно, фактические
fullscreen/windowed режимы и видимые состояния наведения/нажатия не проверялись.
Windows-сборка не переэкспортирована и содержит прежнее меню.

## Дополнение: меню и отдельные настройки

Реализованы «Новая игра», «Продолжить», магазин, отдельный экран настроек и выход.
Новая игра подтверждается при наличии сохранения и архивирует имеющиеся файлы;
отмена не меняет прогресс. Settings.cfg находится в user:// отдельно от save.dat.
Доступны Master/Music/SFX, оконный/полноэкранный режим и три размера окна;
существующих профилей качества графики в проекте нет.

Вероятная причина отображения прогресса разработчика на его компьютере: редактор и
сборка используют одно user:// приложения в Windows-профиле. Реальное сохранение
разработчика не читалось. В каталоге экспортированного
PCK (287 файлов) `save.dat`, `save.previous`, `settings.cfg` и progress/ не найдены.
Чистый тестовый APPDATA содержит отдельные данные; реальное сохранение не менялось.

На изолированных данных menu_settings_tests=11, run_tests=48, stage5_tests=81
assertions passed, 0 failed, Godot exit 0. Три запуска проверили отдельный settings.cfg,
звук/разрешение после перезапуска, продолжение и косметику. Строгий статус всех
запусков FAIL из-за engine certificate store error. Обновлённый Windows exe и PCK
созданы, exe запущен headless с exit 0 и той же ошибкой. Графический UI, физический
fullscreen и пользовательские действия в самом экспортированном exe не проверены;
готовность к релизу не заявляется.

Логи: `.local/testing/python/f1f9f867f4f446ed9b7fd27108e4c773/`,
`.local/testing/python/cd95e2c65c5c429a9b702f76fe0c5aac/`,
`.local/release-audit/export/`, `.local/release-audit/exported-smoke/`.

## Дополнение: экспорт Windows

Установленные пользователем шаблоны 4.7.2.stable Windows x86_64 использованы для
экспорта в `Builds/Windows/SWEET_EMPIRE.exe` и `SWEET_EMPIRE.pck`. Godot export
exit code 0, но журнал содержит `ERROR: Failed to read the root certificate store.`
Это не clean PASS и не готовый релиз.

Экспортированный exe запущен headless на 120 кадров, exit code 0; журнал снова
содержит ту же ошибку. Логи в `.local/release-audit/export/` и `exported-smoke/`.
Headless подтверждает запуск приложения, но не видимый рендер, игру или FPS.

После HUD-изменений runner выполнил sophie_layout (45 assertions), ui_interaction
(4), persistence_restart (5), stage5 (81), все с нулём failed и Godot exit 0.
Каждый suite классифицирован FAIL из-за certificate error. Артефакты:
`.local/testing/python/6d54e3d97e0d4b75989e28ba9c3c0811/`.
Визуальная/ручная проверка интерфейса, игровой процесс экспортированной сборки,
FPS, камера и worker не выполнялись. Следующие разделы — исторический отчёт.

2026-11-15. **Не готово к релизу; Windows RC BLOCKED.**
Git baseline: `c591c30b867d357ebbdc39d4b4e7838dbf6203aa`.
Godot: `4.7.2.stable.official.ed1daf0bf`, согласованный console exe.

## Реализовано

- Дисковые profile/world/settings, продолжение после перезапуска, SHA-256,
  проверенная pending-запись, previous, quarantine повреждённого файла.
- Кампания, экономика, станции/повара, товары, очередь, пешеходы, RNG, аналитика,
  Rush/checkpoint, Endless/repeatable, reward/debit ledger, косметика и настройки.
- Покупка до Continue после перезапуска согласует pending wallet и Rush checkpoint;
  временные кристаллы не расходуются на постоянную косметику.
- Проверка всех вложенных campaign/quest/event/reward/repeatable schemas до мутации.
  Типы счётчиков сверяются с канонической ProgressTracker, не с прошлым load.
- Виртуальные клики в локальных координатах viewport вместо повторного transform.
- Gesture stop/disconnect сбрасывает readiness/PID, отправляет tracking lost и
  статус UI. Weak reference на GameSession устраняет абсолютный get_node при выходе
  из SceneTree. Невалидные и повторные retiring PID исключены.
- Demand telemetry/history ограничены 8192 событиями; общие AI weights вычисляются
  вне внутреннего цикла. Dashboard показывает продажи, расходы и прибыль.
- Windows Job Object назначается suspended console launcher до возобновления;
  тайм-аут завершает только его job и дочерний engine. APPDATA/LOCALAPPDATA тестового
  Godot находятся внутри .local, системное окружение не меняется.
- VERSION, changelog, Windows x64 export preset и инструкция сборки.

Цены, награды, Product ID, коллизии, производственные времена и существующие
механики сохранены. Прежние игровые suites не переписывались.

## Проверки

| Проверка | Статус | Результат |
|---|---|---|
| Python static/manifest/allowlist | PASS | 5 Python-файлов, 24 записи, IPC/camera исключены |
| Искусственный classifier | PASS | 29/29: 4 ожидаемых PASS, 25 ожидаемых FAIL; exit 0 |
| Headless import | FAIL | Godot exit 0, certificate store error; без GDScript/resource ошибок |
| Полная headless регрессия | FAIL | 16 suites, 552 passed assertions, 0 failed, все Godot exit 0; certificate error в каждом |
| Финальный целевой повтор schema | FAIL | stabilization=30, stage3=101, stage5=81 assertions, 0 failed; только certificate error |
| Три boot приложения | FAIL | каждый BOOT_RESULT 1/0, exit 0; общая ошибка сертификатов |
| Реальный self-test | FAIL | 5 отрицательных причин VERIFIED; success отклонён из-за certificate error; exit 1 |
| Job timeout | PASS | 10 секунд, timed_out=true, после завершения Godot не остался |
| Python recognizer | PASS | 6/6 synthetic landmark tests без камеры |
| Offline ML Python | FAIL | 8 tests, 5 errors: неполные pandas/sklearn; exit 1 |
| GPU, визуальная QA, FPS | NOT RUN | Headless не подтверждает рендер и FPS |
| Реальная камера/worker/IPC lifecycle | NOT RUN | Не запускались |
| Windows export | BLOCKED | Шаблонов нет; установка не выполнялась |
| Экспортированный exe без редактора | NOT RUN | Exe не создан |

552 assertions не означают PASS 16 suites. Критические ошибки сохранены, исключений
ERROR нет. Полная таблица: [Release1_0-TestResults.json](Release1_0-TestResults.json).
После последней правки лишь канонической schema повторены три затронутых suites.

Проверены corruption/truncation, семантически несовместимый primary с корректной
SHA, previous fallback, quarantine, int64/Transform3D, расширенный мир между
процессами, Rush/checkpoint, Endless/repeatable, награды и покупки до Continue.
UI проверен в 960×540, 1280×720, 1920×1080: ровно один виртуальный клик.
Реальные boot проверяют автозагрузку GameSession, выбранную форму и покупку
интерьера перед созданием BakeryGame, затем ещё один restart без повторного debit.

## Certificate store

Ошибка воспроизводится в минимальном проекте. Read-only CertOpenStore probe с
CURRENT_USER | OPEN_EXISTING | READONLY успешен, windows_error=0. Сертификаты не
перечислялись и не изменялись. [Исходник Godot OS_Windows](https://github.com/godotengine/godot/blob/master/platform/windows/os_windows.cpp)
показывает CertOpenSystemStoreA в get_system_ca_certificates (upstream master,
не точная верификация исходников бинарного build).
[Microsoft CertOpenStore](https://learn.microsoft.com/en-us/windows/win32/api/wincrypt/nf-wincrypt-certopenstore)
описывает отдельный read-only режим. Различие доступа — направление диагностики,
но точная причина внутри бинарного engine не доказана.

Точечное предложение: проверить upstream-открытие существующего ROOT только для
чтения. Регрессия: startup с read-only доступом, отказ без доступа, неизменность
ROOT и чистые журналы. Доверенный engine build потребует отдельного согласования:
здесь exe не заменён, Windows/TLS/сертификаты/ACL/sandbox не менялись. Ошибка не
добавлялась в allowlist, оснований объявлять clean startup нет.

## Производительность и границы

12000 synthetic telemetry events: retained=8192, около 224 ms в одном запуске.
Полный снимок около 3.55 MB; write + verification + повторное чтение около 385 ms.
Это wall-clock probe, не FPS. Синхронный autosave такого объёма может дать заметную
паузу; до RC нужны GPU-профиль и работа над бюджетом/фоновой записью.
Не подтверждены power-loss, длительная сессия до 16 MiB, вся матрица игровых
состояний и реальное пользовательское оборудование. [Формат](Save-Format.md).

## Журналы (внутри sweet-empire)

- Полная регрессия: `.local/testing/python/f15499aca9bc4dbd8b4fc9b3bd04d197/`.
- Финальный targeted: `.local/testing/python/43dd69015a6541c8bca7fda5c909302b/`.
- Три boot: `.local/testing/python/1d73a30902ae4c98b3439cb1e054d3eb/`.
- Self-test: `.local/testing/python/a1718b50c09f474ba37e40c6536f243d/`.
- Timeout: `.local/testing/python/2433745755134570bcd82fae745b6acb/`.
- Classifier: `.local/testing/classifier-python/c2ab7203061848df888330a067d15705/`.
- Import/ML/read-only probe: `.local/release-audit/`.
- Резервные копии затронутых файлов: `.local/release-audit/backups/`.

## Файлы master task

Изменены:

```text
README.md
project.godot
scripts/analytics/demand_data_collector.gd
scripts/audio/audio_manager.gd
scripts/campaign/achievement_manager.gd
scripts/campaign/campaign_manager.gd
scripts/campaign/campaign_runtime.gd
scripts/campaign/quest_manager.gd
scripts/campaign/repeatable_quest_manager.gd
scripts/campaign/tray_upgrade_manager.gd
scripts/campaign/tutorial_manager.gd
scripts/core/bakery_game.gd
scripts/core/game_session_manager.gd
scripts/economy/economy_system.gd
scripts/input/gesture_bridge.gd
scripts/ui/control_settings.gd
scripts/ui/gameplay_dashboard.gd
scripts/ui/main_menu.gd
tools/testing/run_godot_tests.py
tools/testing/suites.json
tools/testing/test_runner.py
Documentation/Stage5_5_1-Testing.md
```

Созданы (каждому .gd соответствует также созданный Godot .gd.uid):

```text
scripts/core/save_store.gd
scripts/core/game_persistence.gd
tests/stabilization_tests.gd
tests/persistence_restart_tests.gd
tests/ui_interaction_tests.gd
tests/harness_fixtures/boot_session.gd.txt
tools/testing/owned_process.py
tools/testing/test_boot_persistence.py
export_presets.cfg
VERSION
CHANGELOG.md
Documentation/Save-Format.md
Documentation/Windows-Release.md
Documentation/Release1_0-Status.md
Documentation/Release1_0-TestResults.json
```

Диагностические scripts/logs/temporary worlds в .local игнорируются Git. Исходные
.ps1, classifier и cases.json сохранены. Корневые untracked вне sweet-empire не
трогались. Отдельная резервная копия пользователя в Documents не затрагивалась.

## Коммиты и следующие gates

План ручных логических коммитов: (1) runner/jobs/изоляция; (2) atomic loaders и
gesture lifecycle/UI coordinates; (3) сохранения и restart/Rush/Endless/shop tests;
(4) bounded analytics/finance UI; (5) version/export/docs. Git add/commit не выполнялись.

BLOCKED: clean engine startup, export templates, полные offline ML зависимости.
NOT RUN: GPU QA/FPS, реальная камера/worker, export и чистая Windows-машина.
Путь к готовому релизу отсутствует. После снятия ограничений нужно закончить эти
проверки; [инструкция экспорта](Windows-Release.md). Текущие исходники можно открыть
в согласованном Godot через project.godot и F5; это запуск development-версии.
