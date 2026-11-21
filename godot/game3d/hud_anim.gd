extends Node
## HudAnim: the one authority over the two A7 HUD clips (CHANGE-BRIEF.md
## "The state machine"). Written by Claude Code.
##
## It is the only code that plays or stops the keycard icon's and the
## pistol rig's AnimationPlayers, and the only code that shows the icon.
## The AnimationPlayers are the only writers of KeycardIcon:frame and of
## Body/Slide/Mag position and rotation. Nothing here writes game state:
## it reads player.reload_changed, player.died and the HUD keycard label's
## visibility (set only by hud.set_keycard()).
##
## Transitions go through the two tables below; a state's "clip" is played
## on entry ("" = stopped at the RESET pose, or hidden for the icon).

const KeycardIconScene := preload("res://game3d/keycard_icon.tscn")
const PistolRigScene := preload("res://game3d/pistol_rig.tscn")

## Pistol rig: state -> {clip, on: {event: next state}}.
const RIG_TABLE := {
	&"HOLD": {"clip": &"", "on": {&"reload_started": &"RELOAD", &"died": &"DEAD"}},
	&"RELOAD": {"clip": &"reload", "on": {&"reload_finished": &"HOLD", &"died": &"DEAD"}},
	&"DEAD": {"clip": &"", "on": {}},
}
## Keycard icon: state -> {clip, on: {event: next state}}.
const KEY_TABLE := {
	&"HIDDEN": {"clip": &"", "on": {&"keycard_acquired": &"SPINNING"}},
	&"SPINNING": {"clip": &"spin", "on": {}},
}
const RIG_START := &"HOLD"
const KEY_START := &"HIDDEN"
const REST_CLIP := &"RESET"

## Where the rig sits: offset from the bottom-right corner of the HUD.
const RIG_OFFSET := Vector2(-150, -110)
## Where the icon sits, relative to the keycard label's top-left.
const ICON_OFFSET := Vector2(124, 11)
const ICON_SCALE := 0.5

var rig_state: StringName = RIG_START
var key_state: StringName = KEY_START
var rig: Node2D
var rig_player: AnimationPlayer
var icon_root: Node2D
var icon: Sprite2D
var icon_player: AnimationPlayer
var _key_label: CanvasItem


## Builds the two rigs inside `hud` and wires HudAnim to `player`.
static func attach(hud: CanvasLayer, player: Node) -> Node:
	var a: Node = (load("res://game3d/hud_anim.gd") as GDScript).new()
	a.name = "HudAnim"
	hud.add_child(a)
	a.setup(hud, player)
	return a


func setup(hud: CanvasLayer, player: Node) -> void:
	var hud_root := hud.get_child(0) as Control
	var corner := Control.new()
	corner.name = "PistolRigCorner"
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hud_root.add_child(corner)
	rig = PistolRigScene.instantiate()
	rig.position = RIG_OFFSET
	corner.add_child(rig)
	rig_player = rig.get_node("AnimationPlayer")

	_key_label = hud.get("_key_label")
	icon_root = KeycardIconScene.instantiate()
	icon_root.position = ICON_OFFSET
	icon_root.scale = Vector2.ONE * ICON_SCALE
	_key_label.add_child(icon_root)
	icon = icon_root.get_node("KeycardIcon")
	icon_player = icon_root.get_node("AnimationPlayer")

	player.reload_changed.connect(_on_reload_changed)
	player.died.connect(func() -> void: rig_event(&"died"))
	_key_label.visibility_changed.connect(_on_key_label_visibility)

	_enter_rig(RIG_START)
	_enter_key(KEY_START)
	if _key_label.visible:
		key_event(&"keycard_acquired")


func _on_reload_changed(active: bool) -> void:
	rig_event(&"reload_started" if active else &"reload_finished")


func _on_key_label_visibility() -> void:
	if _key_label.visible:
		key_event(&"keycard_acquired")


## Applies `event` to the rig's table; an event the current state does not
## list is ignored (so a repeated reload_started never restarts the clip).
func rig_event(event: StringName) -> void:
	var next: Variant = RIG_TABLE[rig_state].on.get(event)
	if next != null:
		_enter_rig(next)


func key_event(event: StringName) -> void:
	var next: Variant = KEY_TABLE[key_state].on.get(event)
	if next != null:
		_enter_key(next)


func _enter_rig(state: StringName) -> void:
	rig_state = state
	var clip: StringName = RIG_TABLE[state].clip
	if clip == &"":
		_rest_pose()
	else:
		rig_player.stop()
		rig_player.play(clip)


func _enter_key(state: StringName) -> void:
	key_state = state
	var clip: StringName = KEY_TABLE[state].clip
	if clip == &"":
		icon_player.stop()
		icon.visible = false
	else:
		icon.visible = true
		icon_player.play(clip)


## Stops the rig at the RESET pose (the rest values the RESET clip holds).
func _rest_pose() -> void:
	rig_player.play(REST_CLIP)
	rig_player.seek(0.0, true)
	rig_player.stop()
