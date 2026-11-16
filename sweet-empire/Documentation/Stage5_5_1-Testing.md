# Stage 5.5.1 / Phase 2A — Python test harness

Дата: 2026-11-15. Baseline: `c591c30b867d357ebbdc39d4b4e7838dbf6203aa`, ветка `main`.

## Область работ

Исполняемая инфраструктура перенесена на Python 3, только стандартная библиотека.
PowerShell Execution Policy не изменялась и не обходилась. Три исходных `.ps1`,
`suites.json`, `cases.json` и README fixtures сохранены без изменений для сравнения.
Игровые скрипты, сцены, ресурсы и существующие suites не менялись.
Godot, камера, IPC и Python-worker жестов в Phase 2A не запускались.

Созданы:

- `tools/testing/run_godot_tests.py` — Windows runner.
- `tools/testing/test_godot_result.py` — классификатор результата завершённого процесса.
- `tools/testing/test_runner.py` — статические проверки и 29 синтетических тестов.
- `Documentation/Stage5_5_1-Testing.md` — этот отчёт.

## Контракт результата

PASS требует exit code типа int со значением 0, отсутствия тайм-аута и ошибки
запуска, трёх читаемых свежих файлов stdout/stderr/Godot log, непустого Godot log,
ровно одного корректного RESULT в stdout, failed == 0 и passed > 0.
Для `checks=N failed=M` passed вычисляется как N-M.

В Godot log разрешена одна идентичная копия stdout RESULT: это зеркало одного
события, а не второй результат. Другой маркер, несовпадение, дубликат, RESULT на
stderr или некорректные числа дают FAIL. Пустой stderr допустим; отсутствующий — нет.

Проверяется весь вывод после завершения, включая строки после RESULT. Ошибки
SCRIPT ERROR / Parse Error / Compile Error / ERROR / FATAL, ошибки загрузки,
признаки crash и отдельные сообщения FAIL дают FAIL с причинами и строками.
Обычное WARNING не является ошибкой. Исключений для ошибок движка нет.
Нераспознанный формат результата отклоняется. Ошибки чтения, декодирования и
конфигурации также не допускают PASS.

Каждый запуск получает новый UUID-каталог `.local/testing/python/<uuid>/`.
stdout/stderr создаются эксклюзивно; Godot получает новый абсолютный log path.
Старые каталоги не читаются. Время изменения каждого файла должно быть не раньше
начала запуска. `result.json` и `summary.json` содержат причины, exit code,
тайм-аут, команду, путь артефактов и результат классификации.

## Запуск и ограничения режимов

Разрешён только ранее найденный путь, зафиксированный в коде:

`C:\Users\timoxa\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

Произвольного параметра exe нет. `subprocess.Popen` получает список аргументов с
`shell=False`. PATH не меняется. Внешние утилиты для перечисления процессов не
запускаются: используется Windows API через ctypes. Наличие любого Godot-процесса
блокирует запуск. Между Python runners действует Windows byte-range lock.
Suites выполняются последовательно, лимит каждого — 300 секунд из manifest.
При тайм-ауте останавливается только созданный этим запуском Godot. Если он не
завершился, дальнейшие suites не запускаются.

По умолчанию выбран headless. GPU требует одновременно `--mode gpu` и конкретный
`--suite`. IPC и camera запрещены в Python runner независимо от enabled в manifest;
параметров для их включения нет. Следовательно, существующая camera-запись
`stage55_render_qa` остаётся в исходном manifest, но не может быть выбрана.

### Headless: 13 suites

- `run_tests`
- `stage15_visual_tests`
- `stage2_tests`
- `stage3_tests`
- `stage3_campaign_sim`
- `stage4_tests`
- `stage4_campaign_sim`
- `stage5_tests`
- `stage5_campaign_sim`
- `stage55_economy_tests`
- `stage55_demand_tests`
- `stage55_input_tests`
- `stage55_progression_tests`

GPU: доступен только `stage5_render_qa` по явному выбору. `render_check`,
`stage15_visual_qa`, `stage2_render_qa`, `stage3_render_qa`, `stage4_render_qa`
заблокированы исходным manifest: отсутствует RESULT с числом выполненных проверок.
`stage55_ipc_tests` и `stage55_render_qa` не запускаются.

## Выполненные проверки

Команды из каталога `sweet-empire`, без Godot:

```text
python -B tools/testing/test_runner.py --static-only
python -B tools/testing/test_runner.py
```

Обе завершились с настоящим exit code 0. Python найден через Get-Command:
`C:\Users\timoxa\AppData\Local\Programs\Python\Python314\python.exe`.

Статически проверены AST и компиляция трёх Python-файлов без исполнения runner,
параметры shell, 21 запись manifest, пути suites, наличие маркеров, запреты
IPC/camera, неизвестных/повторных suites и GPU без явного выбора.
Набор headless проверен на прямые вызовы запуска внешнего процесса в suites;
это не является полным анализом всех косвенных вызовов игрового кода.

29/29 синтетических тестов пройдены: 4 ожидаемых PASS, 25 ожидаемых FAIL;
failures=0, errors=0. Проверены syntax/dependency compile/runtime/resource errors,
ошибка после RESULT, дубликаты, отсутствие/неверный RESULT, exit != 0/null,
тайм-аут, старый/пустой/отсутствующий log, отсутствующие stdout/stderr, launch
failure, пустые/проваленные проверки, зеркальный/несовпадающий log и предупреждение.

Артефакты:
`.local/testing/classifier-python/400d155b49c54090bd425ac01c81b18a/summary.json`.
Для каждого случая сохранён `result.json` с причинами. Fixtures — текстовые файлы
в новом каталоге внутри проекта; намеренно сломанных `.gd` нет. Для отсутствующих
артефактов файл просто не создаётся; существующие файлы не удаляются.
Хеши scripts/scenes/assets/tests, трёх `.ps1` и suites.json до/после совпали.

## Phase 2B — только после отдельного разрешения

Следующие команды подготовлены, но НЕ выполнены. Закрыть редактор и все Godot.
Из `sweet-empire`:

```text
python -B tools/testing/run_godot_tests.py --suite stage55_economy_tests
python -B tools/testing/run_godot_tests.py
python -B tools/testing/run_godot_tests.py --mode gpu --suite stage5_render_qa
```

Первая команда проверяет один suite; вторая — все 13 headless; третья требует
отдельно разрешённой GPU-проверки. Для просмотра списка без запуска движка:

```text
python -B tools/testing/run_godot_tests.py --list
```

В Phase 2B нужно проверить фактические сообщения Godot, код завершения, запись
журналов, тайм-аут и остановку процесса на изолированном временном Godot-проекте.
Синтетические tests Phase 2A не доказывают это взаимодействие. Отдельный import
и smoke сцен ещё не автоматизированы: suites не заменяют полную проверку импорта.

## Риски и границы подтверждения

- Windows API инвентаризации, byte-range lock и subprocess lifecycle реализованы,
  но с реальным Godot пока не проверены.
- Внешний ручной запуск Godot между проверкой процессов и Popen нельзя полностью
  исключить: пользователь не должен открывать редактор во время runner.
- Строгие regex/UTF-8/mtime могут вызвать консервативный FAIL из-за формата вывода,
  округления timestamp, ошибок окружения или локализации. Это не повод разрешать PASS.
- Диагностика через логи не доказывает отсутствие ошибок, которые движок вообще
  не сообщил. Все новые реальные форматы ошибок потребуют отрицательных регрессий.
- Текущие игровые suites могут не соответствовать Stage 5.5; их успешность не заявлена.
- GPU suite сохраняет скриншоты в Documentation: это его существующее поведение.
- Manifest и код считаются доверенными файлами проекта, не защитой от их подмены.
- Python runner не является обходом PowerShell policy; `.ps1` не исполнялись.

Phase 2A завершена в части Python-классификатора. Phase 2B не начата.

## Phase 2B — изолированная интеграция, 2026-11-15

Статус: **BLOCKED после неуспешного self-test; импорт и игровой suite не запускались**.
Предыдущие разделы описывают исторический результат Phase 2A.

HEAD до/после: `c591c30b867d357ebbdc39d4b4e7838dbf6203aa`.
Tracked-изменений нет. Изменены только `tools/testing/run_godot_tests.py` и этот
отчёт. Исходные версии сохранены внутри проекта:
`.local/testing/backups/e45cebf0fad047c89dcea9638cb26594/`.
Отдельная пользовательская резервная копия в Documents не затрагивалась.

Добавлен `--self-test`, несовместимый с --suite/--list/GPU. Шесть фиксированных
fixtures создаются в отдельных минимальных проектах нового UUID-каталога внутри
`.local/testing/python/`. Произвольные параметры проекта, exe или script не добавлены.
Обычный запуск suites сохраняет PROJECT и прежние параметры. Внутренний параметр
fixture_project ограничен разрешённым подкаталогом и не доступен через CLI.
Все fixtures используют общий run_one, headless, тайм-аут 10 секунд, общую блокировку
и классификатор; каталоги сохраняются. Проверяется ожидаемый статус и конкретная
причина. Launch failure, отсутствие/старость артефактов и тайм-аут не считаются
успешным отрицательным тестом. Runtime fixtures дополнительно требуют exit 0.

Повторная статическая проверка и 29/29 искусственных случаев: exit 0,
failures=0, errors=0, watched_files_unchanged=true.
Артефакты: `.local/testing/classifier-python/21ed2a07c4ac4c068ec13ed570d472b9/`.

Выполнена команда:

```text
python -B tools/testing/run_godot_tests.py --self-test
```

Настоящий exit code runner: **1**. Все запуски последовательны, без повышения прав.
Версия через согласованный console exe --version: **4.7.2.stable.official.ed1daf0bf**.

| Fixture | Exit Godot | Классификация | Проверка ожидания / причина |
|---|---:|---|---|
| success | 0 | FAIL | Не выполнено: корректный RESULT с 1 passed, 0 failed, но ERROR certificate store |
| syntax | 1 | FAIL | Подтверждено: SCRIPT ERROR: Parse Error: Expected parameter name; Failed to load script |
| runtime | 0 | FAIL | Подтверждено: SCRIPT ERROR: Invalid call, missing_method в Nil, несмотря на успешный RESULT |
| after_result | 0 | FAIL | Подтверждено: тот же runtime diagnostic после RESULT |
| missing_result | 0 | FAIL | Подтверждено: Expected exactly one stdout RESULT |
| nonzero_exit | 7 | FAIL | Подтверждено: Invalid/nonzero exit code: 7 |

Кроме syntax, все fixtures также сообщили
`ERROR: Failed to read the root certificate store.` в stderr и Godot log.
Эта ошибка не исключалась и не маскировалась. Поэтому подтверждены 5/6 ожиданий,
но self-test целиком НЕ пройден. Runtime/after_result воспроизвели важный случай:
exit 0 и успешный RESULT при настоящей ошибке GDScript, которую runner отклонил.

Полные артефакты:
`.local/testing/python/70434a7dc245463088692c1f3c247336/`:

- `version.stdout.log`, `version.stderr.log` — версия;
- `self-test-summary.json` — шесть результатов с verified и required_reason;
- `<fixture>/stdout.log`, `stderr.log`, `godot.log`, `result.json`;
- `project_<fixture>/` — минимальные проекты и намеренно ошибочные GDScript,
  исключительно в игнорируемой `.local/`, вне обычных игровых каталогов.

Импорт проекта: **NOT RUN / BLOCKED prerequisite**.
Один headless suite: **NOT RUN / BLOCKED prerequisite**.
Не утверждается ни успешность, ни ошибка компиляции игрового проекта.
Камера, Python-worker, IPC/GPU suites не запускались. Системные настройки,
PowerShell Execution Policy и Git-история не менялись. Все Godot-процессы завершились.

### Рекомендации Phase 2C

Отдельно согласовать диагностику доступа Godot к Windows root certificate store
в текущей среде. Не отключать безопасность Windows и не добавлять широкое
исключение ERROR ради прохождения self-test. После устранения причины штатным
способом повторить только --self-test; затем, если 6/6 ожиданий подтверждены,
выполнить headless import и один разрешённый suite. Изменения игровых исходников
по-прежнему требуют отдельного разрешения.

## Продолжение по master task SWEET EMPIRE 1.0

Пользователь отдельно разрешил стабилизацию игры и реализацию сохранений.
Добавлены SaveStore/GamePersistence, безопасные загрузчики, Windows job ownership,
изолированные APPDATA/LOCALAPPDATA для тестов, три новые headless suites и три
реальных boot с сохранением/покупкой до Continue. Allowlist остаётся явным;
IPC/camera не включены. Актуальные результаты и список файлов:
[Release1_0-Status.md](Release1_0-Status.md). Версия — 1.0.0-dev.1, не release-ready.
