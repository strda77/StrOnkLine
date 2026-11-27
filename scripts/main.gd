
extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const TARGET_SCRIPT = preload("res://scripts/training_target.gd")
const BOT_SCRIPT = preload("res://scripts/bot_enemy.gd")

var player: CharacterBody3D
var ammo_label: Label
var aim_button: Button
var status_label: Label
var hit_marker: Label
var hp_label: Label
var armor_label: Label



func _ready() -> void:
    create_ground()
    create_environment_objects()
    create_player()
    create_bot_enemy()
    create_training_target()
    create_mobile_controls()
    create_hud()


func create_ground() -> void:
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    add_child(ground)

    var mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(100, 100)
    mesh.mesh = plane

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.19, 0.25, 0.18)
    material.roughness = 1.0
    mesh.material_override = material
    ground.add_child(mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(100, 0.2, 100)
    collision.shape = shape
    collision.position.y = -0.1
    ground.add_child(collision)


func create_environment_objects() -> void:
    for i in range(12):
        var obstacle := StaticBody3D.new()
        obstacle.name = "Cover_%02d" % i

        var box := BoxMesh.new()
        box.size = Vector3(2, 2, 2)

        var mesh := MeshInstance3D.new()
        mesh.mesh = box

        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.25, 0.29, 0.25)
        material.roughness = 0.9
        mesh.material_override = material
        obstacle.add_child(mesh)

        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(2, 2, 2)
        collision.shape = shape
        obstacle.add_child(collision)

        obstacle.position = Vector3(
            float((i % 4) * 8 - 12),
            1.0,
            float((i / 4) * -8 - 8)
        )

        add_child(obstacle)


func create_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 0, 0)
    add_child(player)

    player.connect(
        "ammo_changed",
        Callable(self, "_on_ammo_changed")
    )

    player.connect(
        "aim_changed",
        Callable(self, "_on_aim_changed")
    )
    player.connect(
        "hit_confirmed",
        Callable(self, "_on_hit_confirmed")
    )

    player.connect(
        "shot_missed",
        Callable(self, "_on_shot_missed")
    )

    player.connect(
        "vitals_changed",
        Callable(self, "_on_vitals_changed")
    )

    player.connect(
        "player_defeated",
        Callable(self, "_on_player_defeated")
    )
    _on_ammo_changed(30, 120)


func create_mobile_controls() -> void:
    var layer := CanvasLayer.new()
    layer.name = "MobileControls"
    layer.layer = 1
    add_child(layer)

    create_control_button(
        layer, "↑", Vector2(90, -170),
        Vector2(70, 70), Vector2(0, -1)
    )

    create_control_button(
        layer, "↓", Vector2(90, -30),
        Vector2(70, 70), Vector2(0, 1)
    )

    create_control_button(
        layer, "←", Vector2(20, -100),
        Vector2(70, 70), Vector2(-1, 0)
    )

    create_control_button(
        layer, "→", Vector2(160, -100),
        Vector2(70, 70), Vector2(1, 0)
    )

    create_action_button(
        layer, "JUMP",
        Vector2(-225, -110),
        Vector2(95, 65),
        player.request_jump
    )

    create_action_button(
        layer, "RUN",
        Vector2(-115, -190),
        Vector2(85, 60),
        Callable(),
        player.set_running
    )

    aim_button = Button.new()
    aim_button.text = "AIM"
    aim_button.toggle_mode = true
    aim_button.custom_minimum_size = Vector2(95, 65)
    set_bottom_right(aim_button, Vector2(-225, -190))
    layer.add_child(aim_button)
    aim_button.toggled.connect(player.set_aim)

    create_action_button(
        layer, "FIRE",
        Vector2(-115, -110),
        Vector2(95, 65),
        player.fire_weapon
    )

    create_action_button(
        layer, "RELOAD",
        Vector2(-225, -270),
        Vector2(95, 60),
        player.reload_weapon
    )


func set_bottom_right(
    control: Control,
    offset: Vector2
) -> void:
    control.anchor_left = 1.0
    control.anchor_top = 1.0
    control.anchor_right = 1.0
    control.anchor_bottom = 1.0

    control.offset_left = offset.x
    control.offset_top = offset.y
    control.offset_right = offset.x + control.custom_minimum_size.x
    control.offset_bottom = offset.y + control.custom_minimum_size.y


func create_action_button(
    layer: CanvasLayer,
    label: String,
    offset: Vector2,
    button_size: Vector2,
    action: Callable,
    hold_action: Callable = Callable()
) -> void:
    var button := Button.new()
    button.text = label
    button.custom_minimum_size = button_size
    set_bottom_right(button, offset)
    layer.add_child(button)

    if hold_action.is_valid():
        button.button_down.connect(
            hold_action.bind(true)
        )
        button.button_up.connect(
            hold_action.bind(false)
        )
    elif action.is_valid():
        button.pressed.connect(action)


func create_control_button(
    layer: CanvasLayer,
    label: String,
    offset: Vector2,
    button_size: Vector2,
    direction: Vector2
) -> void:
    var button := Button.new()
    button.text = label
    button.custom_minimum_size = button_size

    button.anchor_left = 0.0
    button.anchor_top = 1.0
    button.anchor_right = 0.0
    button.anchor_bottom = 1.0

    button.offset_left = offset.x
    button.offset_top = offset.y
    button.offset_right = offset.x + button_size.x
    button.offset_bottom = offset.y + button_size.y

    layer.add_child(button)

    button.button_down.connect(
        player.set_direction.bind(direction, true)
    )

    button.button_up.connect(
        player.set_direction.bind(direction, false)
    )


func create_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "GameHUD"
    layer.layer = 2
    add_child(layer)

    var title := Label.new()
    title.text = "STRONKLINE"
    title.position = Vector2(25, 20)
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override(
        "font_color", Color(0.75, 0.85, 0.72)
    )
    layer.add_child(title)

    status_label = Label.new()
    status_label.text = "MATCH STATUS: WAITING"
    status_label.position = Vector2(25, 55)
    status_label.add_theme_font_size_override("font_size", 15)
    status_label.add_theme_color_override(
        "font_color", Color(0.9, 0.85, 0.55)
    )
    layer.add_child(status_label)

    hp_label = Label.new()
    hp_label.text = "HP  100"
    hp_label.position = Vector2(25, 95)
    hp_label.add_theme_font_size_override("font_size", 20)
    hp_label.add_theme_color_override(
    "font_color", Color(0.35, 0.95, 0.45)
    )
    layer.add_child(hp_label)

    armor_label = Label.new()
    armor_label.text = "ARMOR  100"
    armor_label.position = Vector2(25, 125)
    armor_label.add_theme_font_size_override("font_size", 18)
    armor_label.add_theme_color_override(
    "font_color", Color(0.35, 0.75, 1.0)
    )
    layer.add_child(armor_label)

    _on_vitals_changed(100, 100)

    ammo_label = Label.new()
    ammo_label.text = "AMMO  30 / 120"
    ammo_label.anchor_left = 1.0
    ammo_label.anchor_right = 1.0
    ammo_label.offset_left = -250
    ammo_label.offset_right = -25
    ammo_label.offset_top = 30
    ammo_label.offset_bottom = 65
    ammo_label.add_theme_font_size_override("font_size", 22)
    ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    ammo_label.add_theme_color_override(
        "font_color", Color(1.0, 0.85, 0.45)
    )
    layer.add_child(ammo_label)

    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.anchor_left = 0.5
    crosshair.anchor_top = 0.5
    crosshair.anchor_right = 0.5
    crosshair.anchor_bottom = 0.5
    crosshair.offset_left = -12
    crosshair.offset_top = -18
    crosshair.offset_right = 12
    crosshair.offset_bottom = 18
    crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    crosshair.add_theme_font_size_override("font_size", 30)
    crosshair.add_theme_color_override(
        "font_color", Color(0.9, 0.95, 0.85)
    )
    layer.add_child(crosshair)
    hit_marker = Label.new()
    hit_marker.text = "X"
    hit_marker.anchor_left = 0.5
    hit_marker.anchor_top = 0.5
    hit_marker.anchor_right = 0.5
    hit_marker.anchor_bottom = 0.5
    hit_marker.offset_left = -15
    hit_marker.offset_top = -20
    hit_marker.offset_right = 15
    hit_marker.offset_bottom = 20
    hit_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hit_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hit_marker.add_theme_font_size_override("font_size", 32)
    hit_marker.add_theme_color_override(
        "font_color", Color(1.0, 0.25, 0.18)
    )
    hit_marker.visible = false
    layer.add_child(hit_marker)


func _on_ammo_changed(current: int, reserve: int) -> void:
    if ammo_label:
        ammo_label.text = "AMMO  %02d / %03d" % [current, reserve]


func _on_aim_changed(active: bool) -> void:
    if status_label:
        status_label.text = (
            "WEAPON STATUS: AIMING"
            if active
            else "MATCH STATUS: WAITING"
        )

func create_bot_enemy() -> void:
    var bot := CharacterBody3D.new()
    bot.set_script(BOT_SCRIPT)
    bot.position = Vector3(6, 0, -10)
    add_child(bot)
    bot.set_player(player)
    bot.connect(
    "enemy_defeated",
    Callable(self, "_on_bot_defeated")
)

func create_training_target() -> void:
    var target := StaticBody3D.new()
    target.set_script(TARGET_SCRIPT)
    target.position = Vector3(0.7, 0, -12)
    add_child(target)

func _on_hit_confirmed() -> void:
    show_hit_marker("X", Color(1.0, 0.25, 0.18))


func _on_shot_missed() -> void:
    show_hit_marker(".", Color(1.0, 0.85, 0.35))


func show_hit_marker(symbol: String, marker_color: Color) -> void:
    if not is_instance_valid(hit_marker):
        return

    hit_marker.text = symbol
    hit_marker.add_theme_color_override("font_color", marker_color)
    hit_marker.visible = true

    var timer := get_tree().create_timer(0.25)
    timer.timeout.connect(func():
        if is_instance_valid(hit_marker):
            hit_marker.visible = false
    )
func _on_vitals_changed(current_health: int, current_armor: int) -> void:
    if is_instance_valid(hp_label):
        hp_label.text = "HP  %03d" % current_health

    if is_instance_valid(armor_label):
        armor_label.text = "ARMOR  %03d" % current_armor


func _on_player_defeated() -> void:
    if is_instance_valid(status_label):
        status_label.text = "YOU ARE ELIMINATED"
        status_label.add_theme_color_override(
            "font_color", Color(1.0, 0.2, 0.2)
        )
func _on_bot_defeated() -> void:
    if is_instance_valid(status_label):
        status_label.text = "ENEMY ELIMINATED"
        status_label.add_theme_color_override(
            "font_color", Color(0.35, 1.0, 0.35)
        )
