class_name Outline
## A coloured rim around a character, so dark heroes and monsters stand out
## from the dark backgrounds. A hero is a puppet of several pictures: they go
## into one CanvasGroup and the rim follows the whole silhouette (no seams at
## the hips). A monster is one sprite: the rim is drawn by its Flash material.

const HERO_WIDTH := 2.0
const ENEMY_WIDTH := 2.5
const ENEMY_COLOR := Color(1.0, 0.3, 0.22, 0.8)

const GROUP_SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 line_color : source_color = vec4(1.0);
uniform float line_width = 2.0;
varying float tint_alpha;
void vertex() {
	tint_alpha = COLOR.a;
}
void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	vec2 step_size = SCREEN_PIXEL_SIZE * line_width;
	float around = 0.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.785398;
		around = max(around, textureLod(screen_texture, SCREEN_UV + vec2(cos(angle), sin(angle)) * step_size, 0.0).a);
	}
	float rim = clamp(around - c.a, 0.0, 1.0) * line_color.a;
	COLOR = vec4(mix(line_color.rgb, c.rgb, c.a), max(c.a, rim) * tint_alpha);
}
"""

static var _group_shader: Shader


## A group whose children are drawn as one picture with a rim of `color`.
static func group(color: Color, width := HERO_WIDTH) -> CanvasGroup:
	if _group_shader == null:
		_group_shader = Shader.new()
		_group_shader.code = GROUP_SHADER
	var canvas_group := CanvasGroup.new()
	# Room around the silhouette for the rim.
	canvas_group.fit_margin = width + 4.0
	var mat := ShaderMaterial.new()
	mat.shader = _group_shader
	mat.set_shader_parameter("line_color", color)
	mat.set_shader_parameter("line_width", width)
	canvas_group.material = mat
	return canvas_group


## A rim around one sprite that uses the Flash material; `width` in texture pixels.
static func on_sprite(sprite: CanvasItem, color: Color, width: float) -> void:
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("outline_color", color)
	mat.set_shader_parameter("outline_width", width)
