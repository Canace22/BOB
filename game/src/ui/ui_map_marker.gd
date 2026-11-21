class_name WhaleMapMarker
extends Button

enum Kind { CURRENT, VISITED, UNKNOWN }
const PAPER := Color("f9d58d")
const SEA := Color("a9e1d6")
const SILVER := Color("bdcdd0")
const CAMP: Texture2D = preload("res://art/ui/shell.svg")

var kind: Kind = Kind.UNKNOWN
var camp: bool
var inspected: bool

func configure(room: Dictionary, regional: bool) -> void:
	name = "Room_" + str(room.id)
	kind = Kind.CURRENT if room.current else (Kind.VISITED if room.visited else Kind.UNKNOWN)
	camp = regional and room.visited and room.camp
	accessibility_name = "%s · %s · %s" % [CampaignWorld.region_name(room.id), room.name, WhaleUICampaignData.visit_label(room)]
	accessibility_description = room.route_kind
	custom_minimum_size = Vector2(36, 36)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, empty)

func _draw() -> void:
	var center := size * 0.5
	if inspected and kind != Kind.CURRENT:
		draw_arc(center, 13, 0, TAU, 40, WhaleUIStyle.INK, 4, true)
		draw_arc(center, 13, 0, TAU, 40, WhaleUIStyle.BONE, 1.5, true)
	draw_symbol(self, center, kind)
	if camp:
		draw_texture_rect(CAMP, Rect2(center + Vector2(9, -19), Vector2(15, 15)), false)

static func draw_symbol(canvas: CanvasItem, center: Vector2, state: Kind, scale_factor: float = 1.0) -> void:
	var ink := WhaleUIStyle.INK
	if state == Kind.CURRENT:
		canvas.draw_circle(center, 15 * scale_factor, ink, true, -1, true)
		canvas.draw_arc(center, 14 * scale_factor, 0, TAU, 48, PAPER, 1.8 * scale_factor, true)
		var diamond := PackedVector2Array()
		for offset: Vector2 in [Vector2(0,-10), Vector2(8,0), Vector2(0,10), Vector2(-8,0)]:
			diamond.append(center + offset * scale_factor)
		canvas.draw_colored_polygon(diamond, PAPER)
	else:
		canvas.draw_circle(center, 8 * scale_factor, ink, true, -1, true)
		if state == Kind.VISITED:
			canvas.draw_circle(center, 6 * scale_factor, SEA, true, -1, true)
		else:
			canvas.draw_arc(center, 5.5 * scale_factor, 0, TAU, 32, SILVER, 1.7 * scale_factor, true)
