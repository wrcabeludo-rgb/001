class_name SecretArea
extends Node2D
## A hidden room: tiles that look exactly like a wall but can be walked
## through. When a hero steps in, the false wall turns see-through and the
## secret counts as found.

signal found(area: SecretArea)

## Same colour as the level's walls, so the false wall does not stand out.
var color := Level.COLOR_WALL
var secret_id := ""
## Optional textured look per cell (the level's wall or ground material).
var cell_materials: Array = []
var is_found := false

var _cells: Array[Rect2] = []
var _cover: Node2D


## `cells` are the tiles of the false wall, in level coordinates.
func setup(p_secret_id: String, cells: Array[Rect2]) -> void:
	secret_id = p_secret_id
	_cells = cells


func _ready() -> void:
	z_index = 5
	_cover = Node2D.new()
	add_child(_cover)
	for i in _cells.size():
		var box := Harm.box(_cells[i].position, _cells[i].size, color)
		if i < cell_materials.size() and cell_materials[i] != null:
			box.color = Color.WHITE
			box.material = cell_materials[i]
		_cover.add_child(box)


func _physics_process(delta: float) -> void:
	var inside := _hero_inside()
	var target := 0.25 if inside or is_found else 1.0
	_cover.modulate.a = move_toward(_cover.modulate.a, target, delta * 3.0)
	if inside and not is_found:
		is_found = true
		found.emit(self)


func _hero_inside() -> bool:
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or not hero.is_alive():
			continue
		var body := Rect2(hero.global_position - Player.SIZE / 2.0, Player.SIZE)
		for cell in _cells:
			if body.intersects(cell):
				return true
	return false
