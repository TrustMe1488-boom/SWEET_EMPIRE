# Stage 4 — Utility AI и Demand ML: техническая инструкция

Актуальный результат и ограничения: [Stage4-Report.md](Stage4-Report.md).

## Поток данных

`BakeryGame.spawn_customer` → `CustomerUtilityAI` → существующий неизменяемый `CustomerOrder` → существующий FIFO и SaleProcessor.

Создание заказа немедленно записывается в DemandDataCollector. Остальные данные поступают из существующего GameEvents. Collector не влияет на очередь, деньги или рейтинг. Он использует игровой delta и хранит causal-историю. DemandPredictor читает признаки коллектора, исполняет обученную линейную модель и публикует `updated`. Софи читает этот прогноз и отдельно вызывает детерминированный SophieAdvisor.

Никакие экономические операции не привязаны к прогнозам, диалогам или анимациям. Utility AI не использует ML. ML не выбирает заказы.

## Конфигурация Utility AI

`assets/ai/customer_profiles.json` — единый источник продуктов, базового времени, patience, долей типов и весов Python/Godot. Порядок продуктов: COOKIE, COFFEE, CUPCAKE, CAKE.

Score = profile_weight × mode_factor, где mode_factor=1 вне Rush и `1 + 0.15 × 4/BaseTime` в Rush. Вероятность — Score / сумма допустимых Score. Проверяется конечность/неотрицательность. Выбор выполняется существующим RNG спавнера; фиксируйте его seed для повторяемости. Начальные три NORMAL — только вводный порядок, далее доли 50/25/25.

Терпение хранится как base_patience, patience_limit и patience. При начале Rush существующим гостям добавляется base_patience×0.2, limit становится base_patience×1.2. Новый гость Rush начинает с этим limit. Tutorial protection имеет приоритет над таймаутом. Снимок сохраняет эти поля.

## Схема признаков v1

Порядок объявлен в `DemandPredictor.FEATURES` и `Tools/ML/common.py:FEATURES`, проверяется loader:

1. rating, chapter;
2. available_COOKIE, available_COFFEE, available_CUPCAKE, available_CAKE;
3. rush;
4. orders120_COOKIE, orders120_COFFEE, orders120_CUPCAKE, orders120_CAKE;
5. orders30 (общее число), arrival_rate;
6. share_NORMAL, share_IMPATIENT, share_SWEET_TOOTH;
7. session_time;
8. opportunity_COOKIE, opportunity_COFFEE, opportunity_CUPCAKE, opportunity_CAKE.

История `[t-120,t]`, недавнее окно `[t-30,t]`. Будущие записи игнорируются. Arrival_rate=N120/clamp(t,30,120); доли типов делятся на max(1,N120), без истории дают нули. Opportunity = 120/expected_spawn_interval × сумма(type_share × нормализованные utility probabilities). Это известная в момент прогноза модель потенциального потока, не фактические будущие события и не готовый runtime-ответ.

Target `[COOKIE,COFFEE,CUPCAKE,CAKE]` — число **созданных** заказов в `(t,t+120]`, независимо от продажи/ухода. При полном FIFO заказ не создаётся. Будущие покупки, будущие продажи и будущие рейтинги не входят в признаки.

## Runtime JSON v1

`assets/ai/demand_model.json`:

- version, schema_version =1; horizon_seconds=120;
- features в точном порядке, products в точном порядке;
- mean[21], scale[21]>0;
- coefficients[4][21], intercepts[4]; metadata.

Для каждого продукта y=max(0, intercept + sum(coef[j]×(x[j]-mean[j])/scale[j])). Текущая недоступность принудительно обнуляет y. Значения остаются float до UI. Проверка файла происходит один раз при старте; обновление — каждые30 игровых секунд, сразу на development.changed и spawner.mode_changed. Сигнал `updated` доступен другим интерфейсам. Пауза останавливает игровой clock, а не системные часы.

При отсутствии/невалидности файла очищается model, `source="fallback"`. Fallback распределяет ожидаемый поток поровну по доступному ассортименту. UI должен показывать source и не называть fallback машинным обучением.

Включите `assets/ai/*.json` в non-resource include filter при подготовке экспортируемой игры. Python, pkl, датасет и библиотеки не нужны в Windows runtime. Подготовка exe здесь не выполнялась.

## Аналитика и пауза

Основная кампания использует существующий CampaignView: Tab → Аналитика. Новый компактный вход вызывает тот же журнал; во время обучения кнопка скрыта. В песочнице без CampaignRuntime используется простой вариант панели с тем же predictor/advisor. Второй мировой персонаж или второй DialogueController не создаются.

Подробная панель использует существующий `BakeryGame.set_paused` и modal_kind, не независимый PauseManager. Esc закрывает её. SophieAdvisor возвращает одно сообщение, приоритет: первый заказ, нулевой запас, полная станция, прогнозируемый дефицит. Предупреждения маркируются отдельно от ML.

## CSV и реальные данные

Явная кнопка пишет `user://demand-events.csv`. Столбцы: time,event,customer_id,customer_type,product,rating,chapter,available,rush. Временные награды и экспериментальные события неудачного Rush исчезают из коллектора при откате. Журнал хранится в RAM до конца игры, сетевого сбора нет.

`build_real_dataset.py` принимает минимум10 **разных полных игровых сессий**, один CSV на сессию. Пример:

```powershell
python Tools/ML/build_real_dataset.py session01.csv session02.csv session03.csv session04.csv session05.csv session06.csv session07.csv session08.csv session09.csv session10.csv
python Tools/ML/train_model.py --dataset Tools/ML/artifacts/real_dataset.csv
python Tools/ML/evaluate_model.py
python Tools/ML/export_model.py
```

Сохраняйте рабочую JSON-модель перед заменой. Не делите одну исходную сессию на несколько файлов для train/test: это разрушит независимость выборок. Конвертер использует последний известный контекст и только прошлое для признаков; хвост без полного будущего горизонта отбрасывается. Проверка конвертера использует тестовые CSV, настоящие пользовательские сессии пока не собраны.

## Воспроизводимость

Из корня проекта:

```powershell
python -m pip install --target .local/ml-python -r Tools/ML/requirements.txt
python Tools/ML/generate_dataset.py
python Tools/ML/train_model.py
python Tools/ML/evaluate_model.py
python Tools/ML/export_model.py
python Tools/ML/test_pipeline.py
```

Использованы Python3.14.2, numpy2.5.4, pandas3.1.1, scikit-learn1.9.1. Seed20261114. Generator по умолчанию240 сессий, по31 snapshot (0..900 с через30 с), плюс120 секунд будущего для меток. Сессии sid%10<6 train, <8 validation, остальные test. Масштабирование fit только train, alpha выбирается только validation; test используется для окончательного сравнения.

`artifacts/dataset.csv`, `dataset_metadata.json`, `trained.pkl`, `experiments.json`, `metrics.json` — офлайн-артефакты. Pkl читается только Python-инструментами. Результат экспорта — компактный JSON. Model parity: 21 test-vector; feature parity: четыре истории (0,5,150,240 с). Их JSON проверяет GDScript suite.

Godot запускайте по одному экземпляру для проекта. Пример (путь executable адаптируется к установке):

```powershell
$godotPath = 'C:\Users\timoxa\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotPath --headless --path . --editor --import --quit
& $godotPath --headless --path . --script tests/stage4_tests.gd
& $godotPath --headless --path . --script tests/stage4_campaign_sim.gd
& $godotPath --path . --script tests/stage4_render_qa.gd
```

Прежние пять suites также обязательны; результаты перечислены в отчёте. Проверяйте код завершения, RESULT и отсутствие SCRIPT ERROR, а не только успех оболочки. GPU runner сохраняет шесть снимков и `stage4-performance.json`; тестовая подготовка выдаёт деньги только для рендер-сценария. Campaign sim, напротив, проходит от0 без финансирования, с бюджетом времени пути и настоящими продажами.

## Сериализация/откат

Collector и Predictor имеют get_save_data/load_save_data. `BakeryGame.capture_rush_state/restore_rush_state` сохраняют их вместе с customer_type/base_patience, остальными гостями, RNG, инвентарями и экономикой. Никакого автоматического сохранения в файл нет. При неудачном Rush все временные данные восстанавливаются до контрольной точки.

При изменении порядка/смысла признаков увеличивайте schema_version, переобучайте и обновляйте parity fixtures. При изменении типов/весов меняйте общий JSON и повторяйте генерацию/валидацию. Не подменяйте обученные коэффициенты вручную и не оценивайте спрос только по продажам.
