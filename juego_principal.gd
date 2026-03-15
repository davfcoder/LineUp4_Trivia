extends Node2D

# ====== REFERENCIAS A LOS NODOS ======
@onready var pantalla_pregunta = $CapaUI/PantallaPregunta
@onready var texto_pregunta = $CapaUI/PantallaPregunta/TextoPregunta
@onready var contenedor_botones = $CapaUI/PantallaPregunta/ContenedorBotones
@onready var texto_reloj = $CapaUI/PantallaPregunta/TextoReloj
@onready var temporizador = $Temporizador
@onready var tablero_visual = $TableroVisual
@onready var capa_ui = $CapaUI

var ficha_escena = preload("res://ficha.tscn")

# ====== CONFIGURACIÓN DEL TABLERO ======
const COLUMNAS = 7
const FILAS = 6
const TAMANO_CELDA = 70
const ESPACIO = 5

var tablero_x = 311
var tablero_y = 145

var color_fondo_tablero = Color(0.0, 0.2, 0.7)
var color_celda_vacia = Color(0.9, 0.9, 0.95)
var color_celda_congelada = Color(0.5, 0.85, 1.0)
var color_fondo_pantalla = Color(0.08, 0.08, 0.14)
var color_seleccionable = Color(1.0, 0.4, 0.4, 0.5)

var matriz_tablero = []
var fichas_visuales = []

# ====== VARIABLES DEL JUEGO ======
var turno_actual = 1
var pregunta_actual = {}
var fase_juego = "PREGUNTA"  # PREGUNTA, LANZAMIENTO, BOMBA_SELECCION, ANIMANDO, FIN
var juego_terminado = false

var racha_j1 = 0
var racha_j2 = 0

# ====== FICHAS ESPECIALES ======
var bombas_j1 = 0
var bombas_j2 = 0
var hielos_j1 = 0
var hielos_j2 = 0

var poder_seleccionado = "NINGUNO"
var columnas_congeladas_info = []

# Resaltado de fichas destruibles
var fichas_resaltadas = []

# Referencias UI
var panel_poderes = null
var label_inventario_j1 = null
var label_inventario_j2 = null
var boton_bomba = null
var boton_hielo = null
var boton_normal = null
var boton_cancelar = null
var label_poder_activo = null
var label_turno = null
var label_notificacion = null
var boton_reiniciar = null

# ====== BASE DE DATOS DE PREGUNTAS ======
var preguntas_base = [
	{"pregunta": "What does 'CAT' mean in Spanish?", "opciones": ["Perro", "Gato", "Ratón", "Pájaro"], "correcta": 1},
	{"pregunta": "Choose: 'She ___ to school yesterday'", "opciones": ["go", "goes", "went", "going"], "correcta": 2},
	{"pregunta": "What's the opposite of 'HOT'?", "opciones": ["Warm", "Cold", "Cool", "Frozen"], "correcta": 1},
	{"pregunta": "How do you say 'ROJO' in English?", "opciones": ["Blue", "Yellow", "Red", "Green"], "correcta": 2},
	{"pregunta": "Complete: 'I ___ from Mexico'", "opciones": ["is", "are", "am", "be"], "correcta": 2},
	{"pregunta": "Which word is a verb?", "opciones": ["Beautiful", "Quickly", "Run", "Table"], "correcta": 2},
	{"pregunta": "Translate: 'The book is on the table'", "opciones": ["El libro está en la mesa", "El libro son en mesa", "La mesa tiene libro", "Libro está mesa"], "correcta": 0},
	{"pregunta": "Plural of 'Mouse'?", "opciones": ["Mouses", "Mice", "Meese", "Mouse"], "correcta": 1},
	{"pregunta": "What is the synonym of 'Happy'?", "opciones": ["Sad", "Angry", "Glad", "Tired"], "correcta": 2},
	{"pregunta": "I haven't seen him ___ 2010.", "opciones": ["since", "for", "in", "at"], "correcta": 0},
	{"pregunta": "What does 'DOG' mean?", "opciones": ["Gato", "Perro", "Pez", "Ave"], "correcta": 1},
	{"pregunta": "'She is ___ than her sister'", "opciones": ["tall", "taller", "tallest", "more tall"], "correcta": 1},
	{"pregunta": "What color is the sky?", "opciones": ["Red", "Green", "Blue", "Yellow"], "correcta": 2},
	{"pregunta": "Past tense of 'Eat'?", "opciones": ["Eated", "Ate", "Eaten", "Eating"], "correcta": 1},
	{"pregunta": "'They ___ playing soccer now'", "opciones": ["is", "am", "are", "be"], "correcta": 2},
	{"pregunta": "What does 'HOUSE' mean?", "opciones": ["Carro", "Casa", "Calle", "Ciudad"], "correcta": 1},
	{"pregunta": "Choose: 'He ___ breakfast every morning'", "opciones": ["have", "has", "having", "had"], "correcta": 1},
	{"pregunta": "What's the opposite of 'BIG'?", "opciones": ["Large", "Huge", "Small", "Tall"], "correcta": 2},
	{"pregunta": "Translate: 'HERMANO'", "opciones": ["Sister", "Brother", "Father", "Mother"], "correcta": 1},
	{"pregunta": "'We ___ to the park tomorrow'", "opciones": ["go", "goes", "will go", "going"], "correcta": 2}
]

var preguntas_activas = []

# ====== FUNCIONES DE POSICIÓN ======
func celda_pos_x(columna):
	return tablero_x + ESPACIO + columna * (TAMANO_CELDA + ESPACIO)

func celda_pos_y(fila):
	return tablero_y + ESPACIO + fila * (TAMANO_CELDA + ESPACIO)

# ====== INICIO ======
func _ready():
	preguntas_activas = preguntas_base.duplicate(true)
	crear_matriz_tablero()
	crear_matriz_fichas_visuales()
	dibujar_tablero()
	crear_interfaz_poderes()
	crear_notificacion()
	conectar_botones_trivia()
	
	if not temporizador.timeout.is_connected(_on_tiempo_agotado):
		temporizador.timeout.connect(_on_tiempo_agotado)
	
	iniciar_turno()

func crear_matriz_tablero():
	matriz_tablero = []
	for x in range(COLUMNAS):
		var columna = []
		for y in range(FILAS):
			columna.append(0)
		matriz_tablero.append(columna)

func crear_matriz_fichas_visuales():
	fichas_visuales = []
	for x in range(COLUMNAS):
		var columna = []
		for y in range(FILAS):
			columna.append(null)
		fichas_visuales.append(columna)

# ====== DIBUJAR TABLERO ======
func dibujar_tablero():
	var fondo_pantalla = ColorRect.new()
	fondo_pantalla.name = "FondoPantalla"
	fondo_pantalla.size = Vector2(1152, 648)
	fondo_pantalla.color = color_fondo_pantalla
	fondo_pantalla.z_index = -10
	tablero_visual.add_child(fondo_pantalla)
	
	var ancho_tablero = COLUMNAS * (TAMANO_CELDA + ESPACIO) + ESPACIO
	var alto_tablero = FILAS * (TAMANO_CELDA + ESPACIO) + ESPACIO
	
	var fondo_tablero = ColorRect.new()
	fondo_tablero.name = "FondoTablero"
	fondo_tablero.size = Vector2(ancho_tablero, alto_tablero)
	fondo_tablero.position = Vector2(tablero_x, tablero_y)
	fondo_tablero.color = color_fondo_tablero
	tablero_visual.add_child(fondo_tablero)
	
	for x in range(COLUMNAS):
		for y in range(FILAS):
			var celda = ColorRect.new()
			celda.name = "Celda_" + str(x) + "_" + str(y)
			celda.size = Vector2(TAMANO_CELDA, TAMANO_CELDA)
			celda.position = Vector2(celda_pos_x(x), celda_pos_y(y))
			celda.color = color_celda_vacia
			tablero_visual.add_child(celda)
	
	for x in range(COLUMNAS):
		var flecha = Label.new()
		flecha.name = "Flecha_" + str(x)
		flecha.text = "▼"
		flecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flecha.position = Vector2(celda_pos_x(x) + 22, tablero_y - 25)
		flecha.add_theme_font_size_override("font_size", 20)
		flecha.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		tablero_visual.add_child(flecha)
	
	label_inventario_j1 = Label.new()
	label_inventario_j1.position = Vector2(15, 160)
	label_inventario_j1.size = Vector2(280, 80)
	label_inventario_j1.add_theme_font_size_override("font_size", 14)
	label_inventario_j1.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	tablero_visual.add_child(label_inventario_j1)
	
	label_inventario_j2 = Label.new()
	label_inventario_j2.position = Vector2(15, 270)
	label_inventario_j2.size = Vector2(280, 80)
	label_inventario_j2.add_theme_font_size_override("font_size", 14)
	label_inventario_j2.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	tablero_visual.add_child(label_inventario_j2)
	
	label_turno = Label.new()
	label_turno.name = "EtiquetaTurno"
	label_turno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_turno.position = Vector2(tablero_x, tablero_y + alto_tablero + 8)
	label_turno.size = Vector2(ancho_tablero, 30)
	label_turno.add_theme_font_size_override("font_size", 18)
	label_turno.add_theme_color_override("font_color", Color(1, 1, 1))
	tablero_visual.add_child(label_turno)

# ====== NOTIFICACIÓN DE PODER ======
func crear_notificacion():
	label_notificacion = Label.new()
	label_notificacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_notificacion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_notificacion.position = Vector2(326, 70)
	label_notificacion.size = Vector2(500, 40)
	label_notificacion.add_theme_font_size_override("font_size", 22)
	label_notificacion.add_theme_color_override("font_color", Color(1, 1, 0))
	label_notificacion.modulate.a = 0
	capa_ui.add_child(label_notificacion)

func mostrar_notificacion(texto):
	label_notificacion.text = texto
	var tween = create_tween()
	# Aparecer
	tween.tween_property(label_notificacion, "modulate:a", 1.0, 0.3)
	# Esperar
	tween.tween_interval(2.0)
	# Desaparecer
	tween.tween_property(label_notificacion, "modulate:a", 0.0, 0.5)

# ====== INTERFAZ DE PODERES ======
func crear_interfaz_poderes():
	panel_poderes = Panel.new()
	panel_poderes.position = Vector2(220, 5)
	panel_poderes.size = Vector2(720, 50)
	
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.15, 0.15, 0.25, 0.95)
	estilo.border_width_bottom = 2
	estilo.border_width_top = 2
	estilo.border_width_left = 2
	estilo.border_width_right = 2
	estilo.border_color = Color(0.4, 0.5, 0.8)
	estilo.corner_radius_top_left = 10
	estilo.corner_radius_top_right = 10
	estilo.corner_radius_bottom_left = 10
	estilo.corner_radius_bottom_right = 10
	panel_poderes.add_theme_stylebox_override("panel", estilo)
	capa_ui.add_child(panel_poderes)
	
	var boton_ancho = 130
	var boton_alto = 32
	var margen_y = 9
	var inicio_x = 8
	var separacion = 8
	
	boton_normal = Button.new()
	boton_normal.text = "[1] 🎯 Normal"
	boton_normal.position = Vector2(inicio_x, margen_y)
	boton_normal.size = Vector2(boton_ancho, boton_alto)
	boton_normal.pressed.connect(_on_seleccionar_normal)
	panel_poderes.add_child(boton_normal)
	
	boton_bomba = Button.new()
	boton_bomba.text = "[2] 💣 Bomba"
	boton_bomba.position = Vector2(inicio_x + (boton_ancho + separacion), margen_y)
	boton_bomba.size = Vector2(boton_ancho, boton_alto)
	boton_bomba.pressed.connect(_on_seleccionar_bomba)
	panel_poderes.add_child(boton_bomba)
	
	boton_hielo = Button.new()
	boton_hielo.text = "[3] ❄️ Hielo"
	boton_hielo.position = Vector2(inicio_x + (boton_ancho + separacion) * 2, margen_y)
	boton_hielo.size = Vector2(boton_ancho, boton_alto)
	boton_hielo.pressed.connect(_on_seleccionar_hielo)
	panel_poderes.add_child(boton_hielo)
	
	boton_cancelar = Button.new()
	boton_cancelar.text = "[Esc] Cancelar"
	boton_cancelar.position = Vector2(inicio_x + (boton_ancho + separacion) * 3, margen_y)
	boton_cancelar.size = Vector2(boton_ancho, boton_alto)
	boton_cancelar.pressed.connect(_on_cancelar_poder)
	boton_cancelar.hide()
	panel_poderes.add_child(boton_cancelar)
	
	label_poder_activo = Label.new()
	label_poder_activo.position = Vector2(inicio_x + (boton_ancho + separacion) * 4 + 10, margen_y + 5)
	label_poder_activo.size = Vector2(180, 30)
	label_poder_activo.add_theme_font_size_override("font_size", 15)
	label_poder_activo.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	panel_poderes.add_child(label_poder_activo)
	
	# Botón de reiniciar (oculto hasta que termine el juego)
	boton_reiniciar = Button.new()
	boton_reiniciar.text = "🔄 Jugar de Nuevo"
	boton_reiniciar.position = Vector2(440, 550)
	boton_reiniciar.size = Vector2(250, 50)
	boton_reiniciar.add_theme_font_size_override("font_size", 30)
	
	var estilo_reiniciar = StyleBoxFlat.new()
	estilo_reiniciar.bg_color = Color(0.1, 0.6, 0.2)  # Verde fuerte
	boton_reiniciar.add_theme_stylebox_override("normal", estilo_reiniciar)
	var estilo_hover = StyleBoxFlat.new()
	estilo_hover.bg_color = Color(0.15, 0.75, 0.3)  # Verde más brillante
	boton_reiniciar.pressed.connect(_on_reiniciar)
	boton_reiniciar.add_theme_stylebox_override("hover", estilo_hover)
	
	var estilo_pressed = StyleBoxFlat.new()
	estilo_pressed.bg_color = Color(0.05, 0.4, 0.15)  # Verde oscuro
	boton_reiniciar.add_theme_stylebox_override("pressed", estilo_pressed)
	
	boton_reiniciar.hide()
	capa_ui.add_child(boton_reiniciar)
	
	panel_poderes.hide()
	actualizar_inventario()

func actualizar_inventario():
	label_inventario_j1.text = "🔴 JUGADOR 1\n💣 Bombas: " + str(bombas_j1) + "\n❄️ Hielos: " + str(hielos_j1)
	label_inventario_j2.text = "🟡 JUGADOR 2\n💣 Bombas: " + str(bombas_j2) + "\n❄️ Hielos: " + str(hielos_j2)

func mostrar_botones_poder():
	panel_poderes.show()
	boton_cancelar.hide()
	label_poder_activo.show()
	
	if turno_actual == 1:
		boton_bomba.disabled = bombas_j1 <= 0
		boton_hielo.disabled = hielos_j1 <= 0
	else:
		boton_bomba.disabled = bombas_j2 <= 0
		boton_hielo.disabled = hielos_j2 <= 0
	
	poder_seleccionado = "NINGUNO"
	label_poder_activo.text = "Modo: Normal 🎯"
	label_poder_activo.add_theme_color_override("font_color", Color(0.5, 1, 0.5))

func ocultar_botones_poder():
	panel_poderes.hide()
	limpiar_resaltado()

func _on_seleccionar_normal():
	poder_seleccionado = "NINGUNO"
	label_poder_activo.text = "Modo: Normal 🎯"
	label_poder_activo.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	boton_cancelar.hide()
	label_poder_activo.show()
	limpiar_resaltado()

func _on_seleccionar_bomba():
	poder_seleccionado = "BOMBA"
	label_poder_activo.text = "Poder: 💣 BOMBA"
	label_poder_activo.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
	boton_cancelar.show()
	label_poder_activo.show()  # Ahora se muestra junto con Cancelar
	resaltar_fichas_enemigas()

func _on_seleccionar_hielo():
	poder_seleccionado = "HIELO"
	label_poder_activo.text = "Poder: ❄️ HIELO"
	label_poder_activo.add_theme_color_override("font_color", Color(0.3, 0.8, 1))
	boton_cancelar.show()
	label_poder_activo.show()  # Ahora se muestra junto con Cancelar
	limpiar_resaltado()

func _on_cancelar_poder():
	_on_seleccionar_normal()

# ====== RESALTAR FICHAS ENEMIGAS (para bomba) ======
func resaltar_fichas_enemigas():
	limpiar_resaltado()
	var enemigo = 2 if turno_actual == 1 else 1
	
	for x in range(COLUMNAS):
		# No resaltar fichas en columnas congeladas
		if esta_columna_congelada(x):
			continue
		
		for y in range(FILAS):
			if matriz_tablero[x][y] == enemigo:
				var resaltado = ColorRect.new()
				resaltado.name = "Resaltado_" + str(x) + "_" + str(y)
				resaltado.size = Vector2(TAMANO_CELDA, TAMANO_CELDA)
				resaltado.position = Vector2(celda_pos_x(x), celda_pos_y(y))
				resaltado.color = color_seleccionable
				resaltado.z_index = 5
				tablero_visual.add_child(resaltado)
				fichas_resaltadas.append(resaltado)

func limpiar_resaltado():
	for r in fichas_resaltadas:
		if is_instance_valid(r):
			r.queue_free()
	fichas_resaltadas.clear()

# ====== RELOJ VISUAL ======
func _process(_delta):
	if fase_juego == "PREGUNTA" and temporizador.time_left > 0:
		texto_reloj.text = str(int(temporizador.time_left))

# ====== DETECTAR CLICS Y TECLAS ======
func _input(event):
	if juego_terminado:
		return
	
	# Atajos de teclado
	if fase_juego == "LANZAMIENTO" and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_seleccionar_normal()
			KEY_2:
				var tiene = bombas_j1 if turno_actual == 1 else bombas_j2
				if tiene > 0:
					_on_seleccionar_bomba()
			KEY_3:
				var tiene = hielos_j1 if turno_actual == 1 else hielos_j2
				if tiene > 0:
					_on_seleccionar_hielo()
			KEY_ESCAPE:
				_on_cancelar_poder()
	
	# Clics
	if fase_juego != "LANZAMIENTO":
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mx = event.position.x
		var my = event.position.y
		
		# Ignorar zona de botones de poder
		if my < 60:
			return
		
		var ancho_tablero = COLUMNAS * (TAMANO_CELDA + ESPACIO) + ESPACIO
		var alto_tablero = FILAS * (TAMANO_CELDA + ESPACIO) + ESPACIO
		
		if mx >= tablero_x and mx <= tablero_x + ancho_tablero:
			if my >= tablero_y and my <= tablero_y + alto_tablero:
				var columna = int((mx - tablero_x - ESPACIO) / (TAMANO_CELDA + ESPACIO))
				var fila = int((my - tablero_y - ESPACIO) / (TAMANO_CELDA + ESPACIO))
				columna = clamp(columna, 0, COLUMNAS - 1)
				fila = clamp(fila, 0, FILAS - 1)
				
				ejecutar_accion(columna, fila)

func ejecutar_accion(columna, fila):
	match poder_seleccionado:
		"NINGUNO":
			if esta_columna_congelada(columna):
				print("¡Columna congelada!")
				return
			lanzar_ficha(columna)
		"BOMBA":
			usar_bomba(columna, fila)
		"HIELO":
			if esta_columna_congelada(columna):
				print("¡Ya está congelada!")
				return
			usar_hielo(columna)

func esta_columna_congelada(columna):
	for info in columnas_congeladas_info:
		if info["columna"] == columna:
			return true
	return false

# ====== CONECTAR BOTONES TRIVIA ======
func conectar_botones_trivia():
	var botones = contenedor_botones.get_children()
	for i in range(botones.size()):
		botones[i].pressed.connect(_on_boton_trivia_presionado.bind(i))

# ====== TURNOS ======
func iniciar_turno():
	if juego_terminado:
		return
	
	verificar_descongelamiento()
	
	fase_juego = "PREGUNTA"
	pantalla_pregunta.show()
	ocultar_botones_poder()
	
	if label_turno:
		var color_txt = "🔴 ROJO" if turno_actual == 1 else "🟡 AMARILLO"
		label_turno.text = "Turno: Jugador " + str(turno_actual) + " " + color_txt
	
	mostrar_pregunta_aleatoria()

func verificar_descongelamiento():
	var columnas_a_quitar = []
	
	for info in columnas_congeladas_info:
		if info["puesto_por"] == turno_actual:
			columnas_a_quitar.append(info)
	
	for info in columnas_a_quitar:
		var col = info["columna"]
		
		for fila in range(FILAS):
			var celda = tablero_visual.get_node_or_null("Celda_" + str(col) + "_" + str(fila))
			if celda and matriz_tablero[col][fila] == 0:
				celda.color = color_celda_vacia
		
		var flecha = tablero_visual.get_node_or_null("Flecha_" + str(col))
		if flecha:
			flecha.text = "▼"
			flecha.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
		
		columnas_congeladas_info.erase(info)

func mostrar_pregunta_aleatoria():
	if preguntas_activas.size() == 0:
		preguntas_activas = preguntas_base.duplicate(true)
	
	var indice = randi() % preguntas_activas.size()
	pregunta_actual = preguntas_activas[indice]
	preguntas_activas.remove_at(indice)
	
	var icono = "🔴" if turno_actual == 1 else "🟡"
	texto_pregunta.text = icono + " Jugador " + str(turno_actual) + ": " + pregunta_actual["pregunta"]
	
	var botones = contenedor_botones.get_children()
	for i in range(4):
		botones[i].text = pregunta_actual["opciones"][i]
		botones[i].show()
	
	temporizador.start(15.0)

# ====== RESPUESTAS ======
func _on_boton_trivia_presionado(indice_boton):
	if fase_juego != "PREGUNTA":
		return
	temporizador.stop()
	
	if indice_boton == pregunta_actual["correcta"]:
		manejar_acierto()
	else:
		manejar_fallo()

func _on_tiempo_agotado():
	if fase_juego != "PREGUNTA":
		return
	
	# Romper racha
	if turno_actual == 1:
		racha_j1 = 0
	else:
		racha_j2 = 0
	
	# Mostrar mensaje de tiempo agotado
	texto_pregunta.text = "⏰ ¡TIEMPO AGOTADO!\n\n Inténtalo más rápido la próxima vez"
	texto_reloj.text = "⌛"
	
	for boton in contenedor_botones.get_children():
		boton.hide()
	
	var boton_continuar = Button.new()
	boton_continuar.name = "BotonContinuar"
	boton_continuar.text = "Continuar ➡️"
	boton_continuar.position = Vector2(300, 320)
	boton_continuar.size = Vector2(200, 50)
	boton_continuar.add_theme_font_size_override("font_size", 18)
	boton_continuar.pressed.connect(_on_continuar_despues_error.bind(boton_continuar))
	pantalla_pregunta.add_child(boton_continuar)

func manejar_acierto():
	fase_juego = "LANZAMIENTO"
	pantalla_pregunta.hide()
	mostrar_botones_poder()
	
	if turno_actual == 1:
		racha_j1 += 1
		if racha_j1 >= 2:
			otorgar_poder_aleatorio(1)
			racha_j1 = 0
	else:
		racha_j2 += 1
		if racha_j2 >= 2:
			otorgar_poder_aleatorio(2)
			racha_j2 = 0
	
	actualizar_inventario()

func otorgar_poder_aleatorio(jugador):
	var poder = ["BOMBA", "HIELO"].pick_random()
	
	if jugador == 1:
		if poder == "BOMBA":
			bombas_j1 += 1
		else:
			hielos_j1 += 1
	else:
		if poder == "BOMBA":
			bombas_j2 += 1
		else:
			hielos_j2 += 1
	
	# Notificación visual
	var icono_poder = "💣 BOMBA" if poder == "BOMBA" else "❄️ HIELO"
	var icono_jugador = "🔴" if jugador == 1 else "🟡"
	mostrar_notificacion(icono_jugador + " ¡Jugador " + str(jugador) + " ganó " + icono_poder + "!")
	
	mostrar_botones_poder()

func manejar_fallo():
	if turno_actual == 1:
		racha_j1 = 0
	else:
		racha_j2 = 0
	
	# Mostrar mensaje de error
	mostrar_mensaje_error()

func mostrar_mensaje_error():
	# Cambiar el texto de la pregunta para mostrar el error
	var respuesta_correcta = pregunta_actual["opciones"][pregunta_actual["correcta"]]
	texto_pregunta.text = "❌ ¡INCORRECTO!\n\nLa respuesta correcta era: " + respuesta_correcta
	texto_reloj.text = "😔"
	
	# Ocultar los botones de respuesta
	for boton in contenedor_botones.get_children():
		boton.hide()
	
	# Crear botón de continuar
	var boton_continuar = Button.new()
	boton_continuar.name = "BotonContinuar"
	boton_continuar.text = "Continuar ➡️"
	boton_continuar.position = Vector2(300, 320)
	boton_continuar.size = Vector2(200, 50)
	boton_continuar.add_theme_font_size_override("font_size", 18)
	boton_continuar.pressed.connect(_on_continuar_despues_error.bind(boton_continuar))
	pantalla_pregunta.add_child(boton_continuar)

func _on_continuar_despues_error(boton):
	# Eliminar el botón de continuar
	boton.queue_free()
	
	# Cambiar turno
	cambiar_turno()

# ====== LANZAR FICHA NORMAL ======
func lanzar_ficha(columna):
	var fila = buscar_fila_disponible(columna)
	
	if fila == -1:
		print("¡Columna llena!")
		return
	
	fase_juego = "ANIMANDO"
	matriz_tablero[columna][fila] = turno_actual
	
	var nueva_ficha = ficha_escena.instantiate()
	nueva_ficha.position = Vector2(celda_pos_x(columna), tablero_y - TAMANO_CELDA)
	nueva_ficha.size = Vector2(TAMANO_CELDA, TAMANO_CELDA)
	nueva_ficha.configurar(turno_actual)
	tablero_visual.add_child(nueva_ficha)
	
	fichas_visuales[columna][fila] = nueva_ficha
	
	var destino_y = celda_pos_y(fila)
	nueva_ficha.animar_caida(destino_y)
	
	ocultar_botones_poder()
	
	await get_tree().create_timer(0.6).timeout
	
	if verificar_victoria(columna, fila, turno_actual):
		juego_terminado = true
		fase_juego = "FIN"
		mostrar_victoria()
		return
	
	if tablero_lleno():
		juego_terminado = true
		fase_juego = "FIN"
		mostrar_empate()
		return
	
	cambiar_turno()

# ====== USAR BOMBA (seleccionar ficha específica) ======
func usar_bomba(columna, fila):
	var enemigo = 2 if turno_actual == 1 else 1
	
	# Verificar si la columna está congelada
	if esta_columna_congelada(columna):
		print("¡Esa columna está congelada! No puedes destruir fichas ahí.")
		mostrar_notificacion("❄️ ¡Columna congelada! No puedes usar bomba ahí")
		return
	
	# Verificar que la celda seleccionada tiene ficha enemiga
	if matriz_tablero[columna][fila] != enemigo:
		print("¡Selecciona una ficha del oponente! (resaltadas en rojo)")
		return
	
	fase_juego = "ANIMANDO"
	
	# Destruir la ficha seleccionada
	matriz_tablero[columna][fila] = 0
	
	if fichas_visuales[columna][fila] != null:
		var ficha = fichas_visuales[columna][fila]
		crear_explosion(ficha.position + Vector2(TAMANO_CELDA / 2, TAMANO_CELDA / 2))
		ficha.queue_free()
		fichas_visuales[columna][fila] = null
	
	# Descontar bomba
	if turno_actual == 1:
		bombas_j1 -= 1
	else:
		bombas_j2 -= 1
	
	limpiar_resaltado()
	actualizar_inventario()
	ocultar_botones_poder()
	
	# Esperar y aplicar gravedad
	await get_tree().create_timer(0.3).timeout
	await aplicar_gravedad(columna)
	
	# Verificar si la gravedad creó un 4 en línea
	await get_tree().create_timer(0.3).timeout
	if verificar_victoria_completa():
		return
	
	cambiar_turno()

# ====== GRAVEDAD: hacer caer fichas después de destruir una ======
func aplicar_gravedad(columna):
	# Recorrer desde abajo hacia arriba
	var hubo_cambio = true
	
	while hubo_cambio:
		hubo_cambio = false
		
		# Desde la penúltima fila hacia arriba
		for y in range(FILAS - 2, -1, -1):
			# Si esta celda tiene ficha y la de abajo está vacía
			if matriz_tablero[columna][y] != 0 and matriz_tablero[columna][y + 1] == 0:
				# Mover en la matriz
				matriz_tablero[columna][y + 1] = matriz_tablero[columna][y]
				matriz_tablero[columna][y] = 0
				
				# Mover visualmente
				var ficha = fichas_visuales[columna][y]
				fichas_visuales[columna][y + 1] = ficha
				fichas_visuales[columna][y] = null
				
				if ficha != null:
					var destino_y = celda_pos_y(y + 1)
					var tween = create_tween()
					tween.tween_property(ficha, "position:y", destino_y, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				
				hubo_cambio = true
		
		if hubo_cambio:
			await get_tree().create_timer(0.25).timeout

func verificar_victoria_completa():
	# Revisar TODAS las fichas del jugador actual para ver si alguna forma 4 en línea
	for x in range(COLUMNAS):
		for y in range(FILAS):
			if matriz_tablero[x][y] == turno_actual:
				if verificar_victoria(x, y, turno_actual):
					juego_terminado = true
					fase_juego = "FIN"
					print("¡¡¡JUGADOR ", turno_actual, " GANA POR GRAVEDAD!!!")
					mostrar_victoria()
					return true
	return false
	
func crear_explosion(centro):
	for i in range(12):
		var particula = ColorRect.new()
		particula.size = Vector2(12, 12)
		particula.position = centro
		var colores = [Color(1, 0.3, 0), Color(1, 0.7, 0), Color(1, 1, 0), Color(1, 0, 0)]
		particula.color = colores[randi() % colores.size()]
		tablero_visual.add_child(particula)
		
		var tween = create_tween()
		var dir = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		tween.tween_property(particula, "position", centro + dir, 0.5)
		tween.parallel().tween_property(particula, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particula.queue_free)

# ====== USAR HIELO ======
func usar_hielo(columna):
	if esta_columna_congelada(columna):
		print("¡Ya está congelada!")
		return
	
	columnas_congeladas_info.append({
		"columna": columna,
		"puesto_por": turno_actual
	})
	
	if turno_actual == 1:
		hielos_j1 -= 1
	else:
		hielos_j2 -= 1
	
	for fila in range(FILAS):
		var celda = tablero_visual.get_node_or_null("Celda_" + str(columna) + "_" + str(fila))
		if celda and matriz_tablero[columna][fila] == 0:
			celda.color = color_celda_congelada
	
	var flecha = tablero_visual.get_node_or_null("Flecha_" + str(columna))
	if flecha:
		flecha.text = "❄️"
		flecha.add_theme_color_override("font_color", Color(0.3, 0.8, 1))
	
	actualizar_inventario()
	
	# Volver a modo normal para lanzar ficha
	poder_seleccionado = "NINGUNO"
	boton_cancelar.hide()
	label_poder_activo.show()
	label_poder_activo.text = "Ahora lanza tu ficha 🎯"
	label_poder_activo.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	boton_hielo.disabled = true
	boton_bomba.disabled = true

# ====== BUSCAR FILA ======
func buscar_fila_disponible(columna):
	for y in range(FILAS - 1, -1, -1):
		if matriz_tablero[columna][y] == 0:
			return y
	return -1

# ====== VERIFICAR VICTORIA ======
func verificar_victoria(columna, fila, jugador):
	var direcciones = [
		[Vector2i(1, 0), Vector2i(-1, 0)],
		[Vector2i(0, 1), Vector2i(0, -1)],
		[Vector2i(1, 1), Vector2i(-1, -1)],
		[Vector2i(1, -1), Vector2i(-1, 1)]
	]
	for dir in direcciones:
		var conteo = 1
		conteo += contar_dir(columna, fila, dir[0].x, dir[0].y, jugador)
		conteo += contar_dir(columna, fila, dir[1].x, dir[1].y, jugador)
		if conteo >= 4:
			return true
	return false

func contar_dir(col, fil, dx, dy, jugador):
	var conteo = 0
	var x = col + dx
	var y = fil + dy
	while x >= 0 and x < COLUMNAS and y >= 0 and y < FILAS:
		if matriz_tablero[x][y] == jugador:
			conteo += 1
			x += dx
			y += dy
		else:
			break
	return conteo

func tablero_lleno():
	for x in range(COLUMNAS):
		if matriz_tablero[x][0] == 0:
			return false
	return true

# ====== RESULTADOS ======
func mostrar_victoria():
	texto_pregunta.text = "🏆 ¡JUGADOR " + str(turno_actual) + " GANA! 🏆"
	texto_reloj.text = "🎉"
	for boton in contenedor_botones.get_children():
		boton.hide()
	pantalla_pregunta.show()
	boton_reiniciar.show()

func mostrar_empate():
	texto_pregunta.text = "🤝 ¡EMPATE! 🤝"
	texto_reloj.text = ""
	for boton in contenedor_botones.get_children():
		boton.hide()
	pantalla_pregunta.show()
	boton_reiniciar.show()

# ====== REINICIAR JUEGO ======
func _on_reiniciar():
	# Limpiar todo
	boton_reiniciar.hide()
	juego_terminado = false
	turno_actual = 1
	racha_j1 = 0
	racha_j2 = 0
	bombas_j1 = 0
	bombas_j2 = 0
	hielos_j1 = 0
	hielos_j2 = 0
	poder_seleccionado = "NINGUNO"
	columnas_congeladas_info.clear()
	fichas_resaltadas.clear()
	preguntas_activas = preguntas_base.duplicate(true)
	
	# Eliminar todas las fichas visuales del tablero
	for x in range(COLUMNAS):
		for y in range(FILAS):
			if fichas_visuales[x][y] != null:
				fichas_visuales[x][y].queue_free()
	
	# Reiniciar matrices
	crear_matriz_tablero()
	crear_matriz_fichas_visuales()
	
	# Restaurar colores de celdas
	for x in range(COLUMNAS):
		for y in range(FILAS):
			var celda = tablero_visual.get_node_or_null("Celda_" + str(x) + "_" + str(y))
			if celda:
				celda.color = color_celda_vacia
		var flecha = tablero_visual.get_node_or_null("Flecha_" + str(x))
		if flecha:
			flecha.text = "▼"
			flecha.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	
	actualizar_inventario()
	iniciar_turno()

func cambiar_turno():
	turno_actual = 2 if turno_actual == 1 else 1
	iniciar_turno()
