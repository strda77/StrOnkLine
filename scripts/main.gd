
extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")

var player: CharacterBody3D


func _ready() -> void:
    create_ground()
    create_environment_objects()
    create_player()
    create_mobile_controls()


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


func create_mobile_controls() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    create_control_button(layer, "↑", Vector2(90, -170),
        Vector2(70, 70), Vector2(0, -1))
    create_control_button(layer, "↓", Vector2(90, -30),
        Vector2(70, 70), Vector2(0, 1))
    create_control_button(layer, "←", Vector2(20, -100),
        Vector2(70, 70), Vector2(-1, 0))
    create_control_button(layer, "→", Vector2(160, -100),
        Vector2(70, 70), Vector2(1, 0))

    var jump := Button.new()
    jump.text = "JUMP"
    jump.custom_minimum_size = Vector2(95, 65)
    jump.anchor_left = 1.0
    jump.anchor_top = 1.0
    jump.anchor_right = 1.0
    jump.anchor_bottom = 1.0
    jump.offset_left = -125
    jump.offset_top = -110
    jump.offset_right = -30
    jump.offset_bottom = -45
    layer.add_child(jump)
    jump.pressed.connect(player.request_jump)

    var sprint := Button.new()
    sprint.text = "RUN"
    sprint.custom_minimum_size = Vector2(85, 60)

    sprint.anchor_left = 1.0
    sprint.anchor_top = 1.0
    sprint.anchor_right = 1.0
    sprint.anchor_bottom = 1.0

    sprint.offset_left = -125
    sprint.offset_top = -195
    sprint.offset_right = -40
    sprint.offset_bottom = -135

    layer.add_child(sprint)

    sprint.button_down.connect(player.set_running.bind(true))
    sprint.button_up.connect(player.set_running.bind(false))



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
