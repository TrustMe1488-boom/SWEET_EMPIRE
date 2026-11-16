# SWEET EMPIRE

Этап 0 — подготовка окружения. Игровая разработка не начата.

**Статус: ТРЕБУЕТ ВМЕШАТЕЛЬСТВА.** Эта папка содержит заготовку структуры и документацию, а не готовый Unity-проект. Unity Hub и Editor не найдены в проверенных местах. `Packages` и `ProjectSettings` ещё не созданы редактором; URP не настроен.

Планируемый проект: `C:\GameDev\SweetEmpire`. Текущая подготовительная папка: `C:\Users\timoxa\Desktop\SWEET EMPIRE`.

## Как подготовить и открыть проект

1. В сессии с доступом к установке программ установить [Unity Hub](https://unity.com/download). Войти в Unity ID и активировать подходящую лицензию штатным способом.
2. В Hub установить актуальный патч Unity 6.3 LTS. Проверить доступное место перед загрузкой. Для сборки IL2CPP добавить Windows Build Support (IL2CPP), C++ tools и Windows SDK при необходимости. Windows Mono обычно входит в Windows Editor.
3. Создать через Hub проект `SweetEmpire`, шаблон **Universal 3D**, путь `C:\GameDev\SweetEmpire`. Если обнаружен существующий проект — сначала согласовать его использование; ничего не перезаписывать.
4. Перенести содержимое этой подготовительной папки в новый проект, сохраняя созданные Unity файлы и существующую документацию. Не заменять совпадающие файлы без просмотра различий.
5. Hub → Projects → Add → выбрать корень проекта → Open. Версия редактора должна соответствовать `ProjectSettings/ProjectVersion.txt`.
6. Edit → Project Settings → Editor → Asset Serialization → **Force Text**; Version Control → **Visible Meta Files**. Проверить URP pipeline asset в Graphics и всех используемых Quality profiles.
7. В VS Code установить официальные расширения `visualstudiotoolsforunity.vstuc`, `ms-dotnettools.csharp`, `ms-dotnettools.csdevkit` и их зависимости. В Unity проверить пакет интеграции Visual Studio Editor и выбрать VS Code в External Tools.
8. Выполнить проверку по `Documentation/Environment.md`. Затем настроить локальный Git и три ветки; первый коммит делать только после проверки состава файлов.

Подробный отчёт: [Environment.md](Documentation/Environment.md). Журнал: [Stage0-Log.md](Documentation/Stage0-Log.md). План будущей разработки: [DevelopmentRoadmap.md](Documentation/DevelopmentRoadmap.md).

Не переходить к этапу 1 без отдельного разрешения пользователя.
