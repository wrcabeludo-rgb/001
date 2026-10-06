class_name BossBar
extends Control
## The boss's name and a long health bar at the top of the screen.

const BAR_SIZE := Vector2(900, 22)
const FILL_COLOR := Color(0.55, 0.95, 0.3)

var _name: Label
var _fill: ColorRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2((1920 - BAR_SIZE.x) / 2.0, 40)
	_name = Label.new()
	_name.size = Vector2(BAR_SIZE.x, 40)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", 30)
	_name.add_theme_color_override("font_color", FILL_COLOR)
	add_child(_name)
	add_child(Harm.box(Vector2(-4, 44), BAR_SIZE + Vector2(8, 8), Color(0, 0, 0, 0.7)))
	_fill = Harm.box(Vector2(0, 48), BAR_SIZE, FILL_COLOR)
	add_child(_fill)
	visible = false


## Shows the first living boss in the scene, or hides the bar.
func refresh() -> void:
	var boss: SludgeBoss = null
	for node in get_tree().get_nodes_in_group("bosses"):
		if node is SludgeBoss and not node.is_queued_for_deletion() and node.is_alive():
			boss = node
			break
	visible = boss != null
	if boss == null:
		return
	_name.text = boss.display_name()
	_fill.size.x = BAR_SIZE.x * boss.health.ratio()
