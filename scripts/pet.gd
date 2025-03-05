extends Area2D

enum PetState {
	IDLE,
	THINKING,
	SLEEPING,
	ASLEEP,
	WAKING
}

@export var player_size: Vector2i = Vector2i(32, 32)
@export var sprite: AnimatedSprite2D
@export var collider: CollisionShape2D
@export var control: Control

@onready var _MainWindow: Window = get_window()

var STATE: PetState = PetState.ASLEEP

var last_position = _MainWindow
var is_booting_up = true
var can_drag = false
var is_dragging = false
var sprite_size: Vector2i = Vector2i.ZERO
var is_interacting: bool = false
var last_cursor: int
var screen_rect: Rect2
var screen: int
var current_animation: String


func _ready():
	screen = DisplayServer.get_primary_screen()
	DisplayServer.window_set_current_screen(screen) #selects screen
	get_tree().get_root().set_transparent_background(true) 
	
	Engine.max_fps = 60
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)

	screen_rect = DisplayServer.screen_get_usable_rect(screen)
	
	_MainWindow.current_screen = screen #selects screen 	
	_MainWindow.position = screen_rect.position
	
	_MainWindow.size = screen_rect.size
	
	sprite_size = player_size * Vector2i($Sprite.scale)
	
	last_position = _MainWindow.position
	
	position = Vector2i(screen_rect.size) - sprite_size


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_released("ui_click") and is_interacting:
		match STATE:
			PetState.IDLE:
				sprite.play("play_dead")

			PetState.ASLEEP:
				sprite.play("wake")
			
			_:
				pass

	if Input.is_action_just_pressed("ui_move") and is_interacting:
		is_dragging = true
		last_cursor = DisplayServer.cursor_get_shape()
		
	if Input.is_action_just_released("ui_move"):
		is_dragging = false
		is_interacting = false


func _process(_delta):
	set_passthrough() #Lets you click through the character	
	
	if is_booting_up and STATE == PetState.ASLEEP:
		sprite.play("wake");
	
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

#func _draw() -> void:
	#if OS.is_debug_build():
		#draw_rect(get_offset_rect(), Color.CORAL, false, 2)

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


func _on_sprite_animation_changed() -> void:
	current_animation = sprite.animation
	print(current_animation)


func _on_sprite_animation_finished() -> void:
	print(STATE)
	print(current_animation)
	print(sprite.animation)
	
	if is_booting_up:
		is_booting_up = false;

	match STATE:
		PetState.IDLE:
			print("SLEEPING")
			STATE = PetState.ASLEEP
			if current_animation == "play_dead":
				sprite.play("sleep_idle")
		
		PetState.ASLEEP:
			print("WAKING")
			STATE = PetState.IDLE
			if current_animation == "wake":
				sprite.play("idle")
		_:
			pass
	
