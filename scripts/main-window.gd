extends Window

# TODO: decide if we need to add a top-level window to this

@export var pet: CharacterBody2D

var screen: int

func _ready() -> void:
	print('SCREEN _ready')
