class_name Flash
## A material that tints a sprite towards a colour (white flash on a hit,
## yellow blink before an attack) without losing its shape.

const SHADER_CODE := """
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float amount = 0.0;
void fragment() {
	// COLOR already holds the picture (texture times modulate).
	vec4 base = COLOR;
	COLOR = vec4(mix(base.rgb, flash_color.rgb, amount), base.a);
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
