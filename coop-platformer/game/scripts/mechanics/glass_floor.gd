class_name GlassFloor
extends CrumblingBlock
## A tempered glass floor panel (world 3): it holds, but cracks under a hero's
## feet and shatters a moment later, then is replaced after a few seconds.

const GLASS := Color(0.16, 0.18, 0.26, 0.85)
const SHINE := Color(1.0, 0.18, 0.53, 0.35)

var _cracks: Node2D


func _ready() -> void:
	shake_time = 0.45
	return_time = 3.5
	super._ready()
	_look.material = null
	for child in _look.get_children():
		child.queue_free()
	_look.color = GLASS
	var art := Harm.tiled_prop("glass_floor", Vector2.ZERO, Vector2(size.x, size.y))
	if art != null:
		_look.color = Color.TRANSPARENT
		_look.add_child(art)
	else:
		_look.add_child(Harm.box(Vector2.ZERO, Vector2(size.x, 4), Color(0.6, 0.62, 0.7)))
		_look.add_child(Harm.box(Vector2(8, 10), Vector2(size.x * 0.4, 3), SHINE))
	_cracks = Rubble.Cracks.new()
	_cracks.width = size.x
	_cracks.seed_value = int(position.x * 7.0 + position.y)
	_cracks.position = Vector2(size.x / 2.0, 0)
	_cracks.color = Color(0.85, 0.9, 1.0, 0.9)
	_cracks.visible = false
	_look.add_child(_cracks)


func _physics_process(delta: float) -> void:
	var was := state
	super._physics_process(delta)
	if was == State.SOLID and state == State.SHAKING:
		_cracks.visible = true
		Sound.play("block", 0.1, -4.0, 1.6)
	if was == State.SHAKING and state == State.GONE:
		Sound.play("crumble", 0.1, 0.0, 1.5)
		Fx.burst(get_parent(), global_position, [Color(0.85, 0.9, 1.0, 0.9), Color(1.0, 0.4, 0.75, 0.6),
			Color(0.6, 0.7, 0.9, 0.0)], 22, 320.0, 4.0, 0.7, 1400.0, true)


func reset() -> void:
	super.reset()
	if _cracks != null:
		_cracks.visible = false
