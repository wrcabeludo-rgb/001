class_name Flash
## A material that tints a sprite towards a colour (white flash on a hit,
## yellow blink before an attack) without losing its shape. It can also draw
## a rim around the sprite (Outline.on_sprite).

const SHADER_CODE := """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float amount = 0.0;
uniform vec4 outline_color : source_color = vec4(0.0);
uniform float outline_width = 0.0;
// The sprite's own transparency (COLOR in fragment() already includes the picture).
varying float tint_alpha;
void vertex() {
	tint_alpha = COLOR.a;
}
void fragment() {
	vec4 base = COLOR;
	vec3 rgb = mix(base.rgb, flash_color.rgb, amount);
	// The rim: transparent pixels next to the picture take the rim colour.
	vec2 step_size = TEXTURE_PIXEL_SIZE * outline_width;
	float around = 0.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.785398;
		around = max(around, textureLod(TEXTURE, UV + vec2(cos(angle), sin(angle)) * step_size, 0.0).a);
	}
	float rim = outline_width > 0.0 ? clamp(around - base.a, 0.0, 1.0) * outline_color.a * tint_alpha : 0.0;
	float alpha = max(base.a, rim);
	COLOR = vec4(mix(outline_color.rgb, rgb, base.a / max(alpha, 0.001)), alpha);
}
"""

static var _shader: Shader


static func material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	return mat


static func set_flash(item: CanvasItem, color: Color, amount: float) -> void:
	var mat := item.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("amount", amount)
