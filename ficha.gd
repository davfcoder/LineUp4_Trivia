extends ColorRect

var jugador = 1

var color_j1 = Color(0.9, 0.1, 0.1)   # Rojo
var color_j2 = Color(1.0, 0.85, 0.0)   # Amarillo

func configurar(num_jugador):
	jugador = num_jugador
	if jugador == 1:
		color = color_j1
	else:
		color = color_j2

func animar_caida(posicion_final_y):
	var tween = create_tween()
	tween.tween_property(self, "position:y", posicion_final_y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
