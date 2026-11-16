extends Node
var game: BakeryGame
func _input(event: InputEvent):
 if event.is_action_pressed("pause") and not event.is_echo():
  game.handle_escape()
  get_viewport().set_input_as_handled()

 elif event.is_action_pressed("development") and not event.is_echo():
  game.toggle_management(&"development")
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("personnel") and not event.is_echo():
  game.toggle_management(&"personnel")
  get_viewport().set_input_as_handled()

 elif event.is_action_pressed("journal") and not event.is_echo():
  game.toggle_journal()
  get_viewport().set_input_as_handled()
