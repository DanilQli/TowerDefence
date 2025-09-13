// flicker_shader.gdshader
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.84, 1.0, 0.0); // основной цвет свечения
uniform float flicker_speed : hint_range(0.1, 10.0) = 4.5;
uniform float brightness_intensity : hint_range(0.0, 1.0) = 0.5;   // интенсивность пульсации яркости
uniform float alpha_intensity : hint_range(0.0, 1.0) = 0.3;         // интенсивность мерцания прозрачности

void fragment() {
	
    // Плавное мерцание от 0 до 1 с использованием синуса
    float t = sin(TIME * flicker_speed) * 0.5 + 0.5; // [0, 1]

    // Смягчаем кривую для более органичного мерцания (ease-in-out)
    t = smoothstep(0.0, 1.0, t);
    
    // Можно добавить немного "дрожания" для живости:
    t += (sin(TIME * 7.0 + 1.0) * 0.1) * brightness_intensity;

    // Модулируем яркость (RGB) и альфу независимо
    vec3 modulated_color = glow_color.rgb * (1.0 + brightness_intensity * t);
    float modulated_alpha = glow_color.a * (1.0 - alpha_intensity * (1.0 - t)); // когда t=1 — альфа максимальна
	
	float glitch = step(0.98, fract(sin(TIME * 0.2) * 12345.0)); // редкие "вспышки"
	modulated_color *= 1.0 + glitch * 0.2;
	modulated_alpha = min(1.0, modulated_alpha + glitch * 0.5);
	
    // Ограничиваем цвет, чтобы не было пересветов (clamp)
    modulated_color = clamp(modulated_color, 0.0, 1.0);

    COLOR = vec4(modulated_color, modulated_alpha);
}