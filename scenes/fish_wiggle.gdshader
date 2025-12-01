shader_type canvas_item;

uniform float wiggle_amount = 0.05;
uniform float wiggle_speed = 4.0;
uniform float wiggle_frequency = 2.0;
uniform bool is_wiggling = true;

void fragment() {
	vec2 uv = UV;

	if (is_wiggling) {
		// Create a sine wave based on time and UV position
		float wave = sin((uv.y * wiggle_frequency) + (TIME * wiggle_speed)) * wiggle_amount;
		uv.x += wave;
	}

	COLOR = texture(TEXTURE, uv);
}
