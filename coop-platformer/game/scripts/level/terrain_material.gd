class_name TerrainMaterial
## A material that fills any rectangle with a seamless texture lined up to the
## world (not to the rectangle), so neighbouring wall pieces join invisibly.

const SHADER_CODE := """
shader_type canvas_item;
uniform sampler2D tex : repeat_enable, filter_linear_mipmap;
uniform float tile_size = 420.0;
uniform vec4 tint : source_color = vec4(1.0);
varying vec2 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	COLOR = texture(tex, world / tile_size) * tint;
}
"""

static var _shader: Shader


static func make(texture: Texture2D, tint: Color, tile_size := 420.0) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("tex", texture)
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("tile_size", tile_size)
	return mat
