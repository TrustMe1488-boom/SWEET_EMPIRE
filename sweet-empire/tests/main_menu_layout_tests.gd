extends SceneTree
var passed: int = 0
var failed: int = 0
func check(ok: bool, title: String):
 if ok: passed += 1
 else: failed += 1
 print("MAIN_MENU_LAYOUT ", "PASS: " if ok else "FAIL: ", title)
func _initialize(): run.call_deferred()
func run():
 var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu); current_scene = menu
 await process_frame
 var actions: VBoxContainer = menu.find_child("MenuActions",true,false)
 var scroll: ScrollContainer = menu.find_child("MenuScroll",true,false)
 var title: Label = menu.find_child("MenuTitle",true,false)
 check(actions.get_child_count()==5,"Five menu buttons")
 for resolution in [Vector2i(1280,720),Vector2i(1366,768),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(1024,768)]:
  root.size = resolution
  for i in 4: await process_frame
  var bounds := scroll.get_global_rect()
  var first: Button = actions.get_child(0)
  for button in actions.get_children():
   check(button is Button and bounds.encloses(button.get_global_rect()),"Button inside scroll area %s %s" % [str(resolution),button.name])
   check(is_equal_approx(button.size.y,first.size.y) and is_equal_approx(button.size.x,first.size.x),"Uniform button dimensions %s %s" % [str(resolution),button.name])
   var text_width: float = button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x
   check(text_width < button.size.x - 36,"Text fits button %s %s" % [str(resolution),button.name])
  check(not title.get_global_rect().intersects(actions.get_global_rect()),"Title and buttons do not intersect " + str(resolution))
  check(actions.get_theme_stylebox("normal","Button").bg_color == Color("#b9ddd0") and actions.get_theme_stylebox("hover","Button").bg_color != actions.get_theme_stylebox("pressed","Button").bg_color,"Mint interaction states " + str(resolution))
 scroll.offset_top = menu.size.y - 230
 for i in 5: await process_frame
 var scrollbar := scroll.get_v_scroll_bar()
 check(actions.get_child(0).custom_minimum_size.y==46 and scrollbar.max_value > scrollbar.page,"Compact spacing and scroll fallback for short area")
 scroll.scroll_vertical = int(scrollbar.max_value)
 for i in 3: await process_frame
 var exit_button: Button = menu.find_child("ExitButton",true,false)
 check(scroll.get_global_rect().encloses(exit_button.get_global_rect()),"Scrolling exposes the full exit button")
 menu.queue_free(); await process_frame
 print("MAIN_MENU_LAYOUT_RESULT: %d passed, %d failed" % [passed,failed])
 quit(0 if failed==0 else 1)
