class_name TitleLogo
extends Control
## The game's name: "НЕОН" glows like a neon sign (and flickers like a tired
## one), "ПЕПЕЛ" smoulders — dark ash with glowing embers creeping through it
## and sparks drifting up.

const FONT := preload("res://assets/fonts/RussoOne-Regular.ttf")
const SIZE := 140
const NEON := Color(0.35, 0.95, 1.0)
const EMBER := Color(1.0, 0.45, 0.12)

const EMBER_SHADER := """
shader_type canvas_item;
uniform sampler2D noise : repeat_enable, filter_linear;
void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec2 p = SCREEN_UV * vec2(5.0, 2.5) + vec2(0.0, TIME * 0.05);
	float n = texture(noise, p).r;
	float n2 = texture(noise, p * 2.3 + vec2(TIME * 0.02, 0.0)).r;
	float heat = smoothstep(0.55, 0.9, n * 0.75 + n2 * 0.45 + 0.08 * sin(TIME * 1.3));
	vec3 ash = vec3(0.28, 0.26, 0.26) * (0.75 + 0.5 * n2);
	vec3 ember = mix(vec3(0.85, 0.22, 0.04), vec3(1.0, 0.78, 0.35), heat);
	COLOR = vec4(mix(ash, ember, heat), base.a);
}
"""

var _neon: Label
var _neon_glow: Control
var _ash_glow: Control
var _flicker := 0.0
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1920, 200)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size = size
	row.add_theme_constant_override("separation", 34)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	# НЕОН: a soft wide glow behind, a bright tube in front.
	var neon_box := Control.new()
	neon_box.custom_minimum_size = _word_size("НЕОН", SIZE)
	row.add_child(neon_box)
	_neon_glow = _glow("НЕОН", NEON, [[10, 0.45], [24, 0.2], [44, 0.09], [70, 0.04]])
	neon_box.add_child(_neon_glow)
	_neon = _word("НЕОН", SIZE, Color(0.85, 1.0, 1.0))
	_neon.add_theme_color_override("font_outline_color", NEON)
	_neon.add_theme_constant_override("outline_size", 8)
	neon_box.add_child(_neon)

	var conj := _word("и", 64, Color(0.7, 0.7, 0.75))
	conj.custom_minimum_size = _word_size("и", 64)
	conj.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(conj)

	# ПЕПЕЛ: a low orange glow underneath, the smouldering letters on top.
	var ash_box := Control.new()
	ash_box.custom_minimum_size = _word_size("ПЕПЕЛ", SIZE)
	row.add_child(ash_box)
	_ash_glow = _glow("ПЕПЕЛ", EMBER, [[8, 0.3], [20, 0.14], [38, 0.06]])
	ash_box.add_child(_ash_glow)
	var ash := _word("ПЕПЕЛ", SIZE, Color.WHITE)
	var shader := Shader.new()
	shader.code = EMBER_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var noise := NoiseTexture2D.new()
	noise.seamless = true
	noise.width = 256
	noise.height = 256
	noise.noise = FastNoiseLite.new()
	noise.noise.frequency = 0.02
	mat.set_shader_parameter("noise", noise)
	ash.material = mat
	ash_box.add_child(ash)
	ash_box.add_child(_sparks(ash_box.custom_minimum_size))


func _word(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## A soft halo: the word's outline drawn several times, wider and fainter.
func _glow(text: String, color: Color, rings: Array) -> Control:
	var halo := Control.new()
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ring in rings:
		var label := _word(text, SIZE, Color(color, 0.0))
		label.add_theme_color_override("font_outline_color", Color(color, ring[1]))
		label.add_theme_constant_override("outline_size", ring[0])
		halo.add_child(label)
	return halo


func _word_size(text: String, font_size: int) -> Vector2:
	return FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + Vector2(0, 30)


## Sparks rising from the smouldering word.
func _sparks(area: Vector2) -> CPUParticles2D:
	var sparks := CPUParticles2D.new()
	sparks.position = Vector2(area.x / 2.0, area.y * 0.55)
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(area.x / 2.0, area.y * 0.3)
	sparks.amount = 36
	sparks.lifetime = 2.6
	sparks.preprocess = 2.6
	sparks.direction = Vector2(0, -1)
	sparks.spread = 30.0
	sparks.initial_velocity_min = 20.0
	sparks.initial_velocity_max = 60.0
	sparks.gravity = Vector2(8, -25)
	sparks.scale_amount_min = 1.5
	sparks.scale_amount_max = 3.5
	var colors := Gradient.new()
	colors.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	colors.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	sparks.color_ramp = colors
	return sparks


func _process(delta: float) -> void:
	_time += delta
	# Neon: a steady hum with a rare stutter of a failing tube.
	_flicker -= delta
	var on := 1.0
	if _flicker <= 0.0:
		if randf() < delta * 0.35:
			_flicker = randf_range(0.08, 0.35)
	elif int(_flicker * 30.0) % 2 == 0:
		on = 0.35
	var hum := 0.92 + 0.08 * sin(_time * 7.0)
	_neon.modulate.a = on
	_neon_glow.modulate.a = on * hum
	# Ash: the glow underneath breathes slowly, like coals.
	_ash_glow.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_time * 0.9)) * (0.85 + 0.15 * sin(_time * 3.1))
