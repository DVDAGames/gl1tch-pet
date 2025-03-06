extends Area2D

enum PetState {
	IDLE,
	THINKING,
	SLEEPING,
	ASLEEP,
	WAKING
}

enum MenuStates {
	TOGGLE,
	CHAT,
	SETTINGS,
	QUIT
}

func print_state(state: PetState) -> void:
	match state:
		PetState.IDLE:
			print("IDLE")
		PetState.THINKING:
			print("THINKING")
		PetState.SLEEPING:
			print("SLEEPING")
		PetState.ASLEEP:
			print("ASLEEP")
		PetState.WAKING:
			print("WAKING")
		_:
			pass

@export var player_size: Vector2i = Vector2i(32, 32)
@export var sprite: AnimatedSprite2D
@export var collider: CollisionShape2D
@export var control: Control
@export var sub_window: Window
@export var menu: PopupMenu

@onready var _MainWindow: Window = get_window()

var STATE: PetState = PetState.ASLEEP

var last_position = _MainWindow
var is_booting_up = true
var can_drag = false
var is_dragging = false
var sprite_size: Vector2i = Vector2i.ZERO
var is_interacting: bool = false
var last_cursor: int
var screen: int
var screen_rect: Rect2
var current_animation: String
var is_menu_active = false


func _ready():
	setup()

	print('PET _ready')
	print_state(STATE)

	sprite_size = player_size * Vector2i($Sprite.scale)

	sub_window.size = screen_rect.size
	sub_window.position = get_offset_rect().position
	sub_window.visible = false
	sub_window.hide()

	build_menu()
	
	global_position = Vector2i(_MainWindow.get_visible_rect().end) - sprite_size


func _physics_process(_delta: float) -> void:
	if !is_booting_up:
		if Input.is_action_just_released("ui_right_click") and is_interacting:
			print("Right Click")
			if !is_menu_active:
				is_menu_active = true
				menu.position = get_global_mouse_position()
				menu.show()
			else:
				menu.hide()
				is_menu_active = false

		
		if Input.is_action_just_released("ui_click") and is_interacting:
			if !is_dragging:
				print_state(STATE)
				match STATE:
					PetState.IDLE:
						go_to_sleep()

					PetState.ASLEEP:
						wake_up()
					
					_:
						pass
			else:
				is_dragging = false
				sprite.play()

		if Input.is_action_just_pressed("ui_move") and is_interacting:
			is_dragging = true
			last_cursor = DisplayServer.cursor_get_shape()
			
		if Input.is_action_just_released("ui_move"):
			is_dragging = false
			is_interacting = false


func _process(_delta):
	set_passthrough() #Lets you click through the character	
	
	if is_booting_up and STATE == PetState.ASLEEP:
		sprite.play("wake_up");
	
	# TODO: set cursor
	if is_mouse_over_control():
		if !is_interacting:
			print("mouse_over")
			is_interacting = true
			
	else:
		if is_interacting:
			print("mouse_out")
			is_interacting = false

	if is_dragging:
		var mouse_pos = get_global_mouse_position()
		var rect = _MainWindow.get_visible_rect()

		if rect.has_point(mouse_pos):
			sprite.pause()
			position = mouse_pos
		else:
			sprite.play()


func _draw() -> void:
	if OS.is_debug_build():
		draw_rect(get_offset_rect(), Color.CORAL, false, 2)
		draw_rect(sub_window.get_visible_rect(), Color.CHARTREUSE, false, 2)
		draw_rect(_MainWindow.get_visible_rect(), Color.FIREBRICK, false, 2)


func setup() -> void:
	print("SETUP")
	screen = DisplayServer.get_primary_screen()
	DisplayServer.window_set_current_screen(screen) #selects screen
	get_tree().get_root().set_transparent_background(true) 
	
	Engine.max_fps = 60
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)	

	screen_rect = DisplayServer.screen_get_usable_rect(screen)
	
	_MainWindow.position = to_global(get_viewport_rect().position)

	_MainWindow.position = screen_rect.position
	_MainWindow.size = screen_rect.size
	
	
func build_menu() -> void:
	menu.add_item("Sleep", MenuStates.TOGGLE)
	menu.add_item("Chat", MenuStates.CHAT)
	menu.add_item("Settings", MenuStates.SETTINGS)
	menu.add_item("Quit", MenuStates.QUIT)


func get_global_offset_rect() -> Rect2:
	var rect_start = global_position - Vector2(sprite_size / 2)
	
	return Rect2(rect_start, sprite_size)


func get_offset_rect() -> Rect2:
	var rect_start = sprite.position - Vector2(sprite_size / 2)
	
	return Rect2(rect_start, sprite_size)


func is_mouse_over_control():
	var mouse_pos = get_global_mouse_position()
	var sprite_rect = get_global_offset_rect()
	
	return sprite_rect.has_point(mouse_pos)


func get_bounding_box(rect: Rect2) -> PackedVector2Array:
	var box: PackedVector2Array = [
		rect.position,
		Vector2(rect.position.x + rect.size.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.position.y + rect.size.y),
	]

	return box


#Sets the coordinates for hitbox, then sets everything outside of that hitbox as non clickable
func set_passthrough():
	DisplayServer.window_set_mouse_passthrough(get_bounding_box(get_global_offset_rect()))


func go_to_sleep() -> void:
	print_state(STATE)
	menu.set_item_disabled(0, true)
	STATE = PetState.SLEEPING
	sprite.play("play_dead")
	print_state(STATE)


func wake_up() -> void:
	print(STATE)
	menu.set_item_disabled(0, true)
	STATE = PetState.WAKING
	sprite.play("wake_up")
	print_state(STATE)


func _on_sprite_animation_changed() -> void:
	current_animation = sprite.animation
	print("animation: ", current_animation)


func _on_sprite_animation_finished() -> void:
	print_state(STATE)
	
	if is_booting_up:
		STATE = PetState.WAKING
		is_booting_up = false;

	match STATE:
		PetState.SLEEPING:
			menu.set_item_text(0, "Wake Up")
			menu.set_item_disabled(0, false)

			STATE = PetState.ASLEEP
			sprite.play("sleep_idle")
			print_state(STATE)
		
		PetState.WAKING:
			menu.set_item_text(0, "Sleep")
			menu.set_item_disabled(0, false)

			STATE = PetState.IDLE
			sprite.play("idle")
			print_state(STATE)
		_:
			pass
	

func _on_popup_menu_popup_hide() -> void:
	menu.hide();
	is_menu_active = false


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		0:
			match STATE:
				PetState.IDLE:
					go_to_sleep()
				PetState.ASLEEP:
					wake_up()
				_:
					pass
		1:
			print("CHAT")
		_:
			pass


func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		MenuStates.TOGGLE:
			match STATE:
				PetState.IDLE:
					go_to_sleep()
				PetState.ASLEEP:
					wake_up()
				_:
					pass
		MenuStates.CHAT:
			print("CHAT")
		MenuStates.SETTINGS:
			print("SETTINGS")
			
		MenuStates.QUIT:
			print("QUIT")
			get_tree().quit()
		_:
			pass
