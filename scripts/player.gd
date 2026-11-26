extends CharacterBody3D

const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const JUMP_VELOCITY := 5.0
const GRAVITY := 18.0

var move_direction := Vector2.ZERO
var jump_requested := false
var running := false

var camera_pivot: Node3D


func _ready() -> void:
    name = "Player"
    create_character()
    create_camera()


func create_character() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)

    var body := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.38
    mesh.height = 1.8
    body.mesh = mesh
    body.position.y = 0.9

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.22, 0.29, 0.20)
    material.roughness = 0.9
    body.material_override = material
    add_child(body)


func create_camera() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.position.y = 1.5
    add_child(camera_pivot)

    var arm := SpringArm3D.new()
    arm.spring_length = 5.0
    arm.position.z = 0.0
    camera_pivot.add_child(arm)

    var camera := Camera3D.new()
    camera.position = Vector3(0.7, 0.3, 0.5)
    camera.current = true
    arm.add_child(camera)


func set_direction(direction: Vector2, pressed: bool) -> void:
    if pressed:
        move_direction = direction
    elif move_direction == direction:
        move_direction = Vector2.ZERO


func request_jump() -> void:
    jump_requested = true


func set_running(value: bool) -> void:
    running = value


func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif jump_requested:
        velocity.y = JUMP_VELOCITY

    jump_requested = false

    var direction := Vector3(
        move_direction.x,
        0.0,
        move_direction.y
    )

    direction = global_transform.basis * direction
    direction.y = 0.0
    direction = direction.normalized()

    var speed := RUN_SPEED if running else WALK_SPEED

    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    move_and_slide()

