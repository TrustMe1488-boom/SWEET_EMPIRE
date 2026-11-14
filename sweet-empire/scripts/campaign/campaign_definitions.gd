class_name CampaignDefinitions
extends RefCounted
const STAGES = ["small_beginning", "growing_bakery", "sweet_empire"]
const TITLES = ["Маленькое начало", "Растущая кондитерская", "Сладкая империя"]
const QUESTS = [
 {"id":"q1_cookies", "stage":1, "title":"Тёплая партия", "description":"Доставить 15 печений", "metric":"delivered", "product":"COOKIE", "target":15, "coins":30, "gems":0},
 {"id":"q1_guests", "stage":1, "title":"Первые друзья", "description":"Обслужить 10 покупателей", "metric":"served", "target":10, "coins":0, "gems":5},
 {"id":"q1_trips", "stage":1, "title":"Лёгкий шаг", "description":"Выполнить 8 доставок", "metric":"deliveries", "target":8, "coins":40, "gems":0},
 {"id":"q2_coffee", "stage":2, "title":"Кофейная пауза", "description":"Доставить 10 кофе", "metric":"delivered", "product":"COFFEE", "target":10, "coins":60, "gems":0},
 {"id":"q2_cupcakes", "stage":2, "title":"Маленькая радость", "description":"Продать 10 капкейков", "metric":"sold", "product":"CUPCAKE", "target":10, "coins":0, "gems":10},
 {"id":"q2_upgrade", "stage":2, "title":"Работать легче", "description":"Улучшить любую станцию", "metric":"upgrades", "target":1, "coins":80, "gems":0},
 {"id":"q3_cakes", "stage":3, "title":"Праздник каждый день", "description":"Продать 10 тортов", "metric":"sold", "product":"CAKE", "target":10, "coins":0, "gems":15},
 {"id":"q3_trips", "stage":3, "title":"Большой маршрут", "description":"Выполнить 20 доставок", "metric":"deliveries", "target":20, "coins":150, "gems":0},
 {"id":"q3_streak", "stage":3, "title":"Каждому — улыбка", "description":"Обслужить 20 гостей подряд без ухода", "metric":"stage_streak", "target":20, "coins":0, "gems":20}
]
const ACHIEVEMENTS = [
 {"id":"first_sale", "title":"Первая продажа", "gems":5},
 {"id":"twenty_deliveries", "title":"20 доставок", "gems":5},
 {"id":"fifty_guests", "title":"50 обслуженных покупателей", "gems":10},
 {"id":"all_equipment", "title":"Все четыре станции куплены", "gems":10},
 {"id":"five_stars", "title":"Рейтинг 5,0", "gems":15},
 {"id":"campaign_complete", "title":"Сладкая империя", "gems":20}
]
