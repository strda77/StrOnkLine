extends CharacterBody3D

signal ammo_changed(current: int, reserve: int)
signal aim_changed(active: bool)
signal weapon_fired
signal hit_confirmed
signal shot_missed

const WALK_SPEED := 5.0
const RUN_SPEED := 8.0
const JUMP_VELOCITY := 5.0
const GRAVITY := 18.0
const TOUCH_SENSITIVITY := 0.12

const MAGAZINE_SIZE := 30
const RELOAD_TIME := 1.6
const FIRE_INTERVAL := 0.12
const NORMAL_FOV := 75.0
const AIM_FOV := 48.0

const HIP_RECOIL := 2.0
const AIM_RECOIL := 1.2
const RECOIL_RECOVERY := 8.0

var move_direction := Vector2.ZERO
var pressed_directions: Dictionary = {}
var jump_requested := false
var running := false

var camera_pivot: Node3D
var camera: Camera3D
var camera_pitch := -12.0
var camera_touch_index := -1

var weapon: Node3D
var muzzle_flash: MeshInstance3D
var muzzle_light: OmniLight3D
var muzzle_timer := 0.0

var recoil_pitch := 0.0
var recoil_yaw := 0.0

var aiming := false
var reloading := false
var current_ammo := MAGAZINE_SIZE
var reserve_ammo := 120
var fire_cooldown := 0.0


func _ready() -> void:
    name = "Player"
    create_character()
    create_camera()
    create_weapon()


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
    camera_pivot.rotation_degrees.x = camera_pitch
    add_child(camera_pivot)

    var arm := SpringArm3D.new()
    arm.spring_length = 5.0
    camera_pivot.add_child(arm)

    camera = Camera3D.new()
    camera.position = Vector3(0.7, 0.3, 0.5)
    camera.fov = NORMAL_FOV
    camera.current = true
    arm.add_child(camera)


func create_weapon() -> void:
    weapon = Node3D.new()
    weapon.name = "AssaultRifle"
    weapon.position = Vector3(0.42, -0.32, -0.75)
    camera.add_child(weapon)

    add_weapon_part(
        Vector3(0.0, 0.0, 0.0),
        Vector3(0.12, 0.13, 0.55),
        Color(0.12, 0.14, 0.12)
    )

    add_weapon_part(
        Vector3(0.0, -0.02, -0.36),
        Vector3(0.055, 0.055, 0.42),
        Color(0.07, 0.08, 0.07)
    )

    add_weapon_part(
        Vector3(0.0, -0.15, 0.08),
        Vector3(0.09, 0.22, 0.12),
        Color(0.16, 0.17, 0.14)
    )

    add_weapon_part(
        Vector3(0.0, 0.11, 0.03),
        Vector3(0.07, 0.07, 0.22),
        Color(0.08, 0.09, 0.08)
    )

    create_muzzle_effect()


func add_weapon_part(
    part_position: Vector3,
    part_size: Vector3,
    part_color: Color
) -> void:
    var part := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = part_size
    part.mesh = mesh
    part.position = part_position

    var material := StandardMaterial3D.new()
    material.albedo_color = part_color
    material.metallic = 0.35
    material.roughness = 0.65
    part.material_override = material

    weapon.add_child(part)


func create_muzzle_effect() -> void:
    muzzle_flash = MeshInstance3D.new()

    var flash_mesh := SphereMesh.new()
    flash_mesh.radius = 0.09
    flash_mesh.height = 0.18

    muzzle_flash.mesh = flash_mesh
    muzzle_flash.position = Vector3(0.0, -0.02, -0.67)

    var flash_material := StandardMaterial3D.new()
    flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    flash_material.albedo_color = Color(1.0, 0.65, 0.12)
    flash_material.emission_enabled = true
    flash_material.emission = Color(1.0, 0.35, 0.05)
    muzzle_flash.material_override = flash_material

    weapon.add_child(muzzle_flash)
    muzzle_flash.visible = false

    muzzle_light = OmniLight3D.new()
    muzzle_light.position = Vector3(0.0, -0.02, -0.7)
    muzzle_light.light_color = Color(1.0, 0.55, 0.18)
    muzzle_light.light_energy = 2.0
    muzzle_light.omni_range = 2.5
    muzzle_light.shadow_enabled = false

    weapon.add_child(muzzle_light)
    muzzle_light.visible = false


func _input(event: InputEvent) -> void:
    var screen_size := get_viewport().get_visible_rect().size

    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x > screen_size.x * 0.45 \
            and event.position.y < screen_size.y - 220:
                camera_touch_index = event.index
        elif event.index == camera_touch_index:
            camera_touch_index = -1

    elif event is InputEventScreenDrag:
        if event.index == camera_touch_index:
            rotate_camera(event.screen_relative)


func rotate_camera(delta_position: Vector2) -> void:
    rotate_y(-delta_position.x * TOUCH_SENSITIVITY * 0.01)

    camera_pitch -= delta_position.y * TOUCH_SENSITIVITY
    camera_pitch = clamp(camera_pitch, -55.0, 65.0)

    camera_pivot.rotation_degrees.x = camera_pitch - recoil_pitch


func set_direction(direction: Vector2, pressed: bool) -> void:
    if pressed:
        pressed_directions[direction] = true
    else:
        pressed_directions.erase(direction)

    var combined := Vector2.ZERO

    for key in pressed_directions:
        combined += key

    move_direction = combined.normalized()


func request_jump() -> void:
    jump_requested = true


func set_running(value: bool) -> void:
    running = value


func set_aim(value: bool) -> void:
    if aiming == value:
        return

    aiming = value
    camera.fov = AIM_FOV if aiming else NORMAL_FOV
    weapon.position.x = 0.25 if aiming else 0.42
    weapon.position.y = -0.28 if aiming else -0.32
    aim_changed.emit(aiming)


func apply_recoil() -> void:
    var amount := AIM_RECOIL if aiming else HIP_RECOIL

    recoil_pitch += amount
    recoil_yaw += randf_range(-0.35, 0.35)

    recoil_pitch = minf(recoil_pitch, 8.0)
    recoil_yaw = clampf(recoil_yaw, -2.0, 2.0)

    camera_pivot.rotation_degrees.x = camera_pitch - recoil_pitch
    camera_pivot.rotation_degrees.y = recoil_yaw


func show_muzzle_effect() -> void:
    muzzle_timer = 0.07
    muzzle_flash.visible = true
    muzzle_light.visible = true


func fire_weapon() -> void:
    if reloading or fire_cooldown > 0.0:
        return

    if current_ammo <= 0:
        print("MAGAZINE EMPTY - RELOAD")
        return

    current_ammo -= 1
    fire_cooldown = FIRE_INTERVAL

    ammo_changed.emit(current_ammo, reserve_ammo)
    weapon_fired.emit()

    apply_recoil()
    show_muzzle_effect()

    if OS.has_feature("android"):
        Input.vibrate_handheld(25)

    var center := get_viewport().get_visible_rect().size / 2.0
    var origin := camera.project_ray_origin(center)
    var direction := camera.project_ray_normal(center)

    var query := PhysicsRayQueryParameters3D.create(
        origin,
        origin + direction * 200.0
    )

    query.exclude = [get_rid()]
    query.collision_mask = 1

    var result := get_world_3d().direct_space_state.intersect_ray(query)

    if not result.is_empty():
        var hit_object = result.get("collider")

        if hit_object.has_method("take_damage"):
            hit_object.take_damage(25)
            hit_confirmed.emit()
            print("TARGET HIT - 25 DAMAGE")
        else:
            print("HIT: ", hit_object.name)
            shot_missed.emit()
    else:
        shot_missed.emit()
        print("SHOT MISSED")


func reload_weapon() -> void:
    if reloading:
        return

    if current_ammo >= MAGAZINE_SIZE:
        return

    if reserve_ammo <= 0:
        print("NO RESERVE AMMO")
        return

    reloading = true
    print("RELOADING...")

    await get_tree().create_timer(RELOAD_TIME).timeout

    if not is_inside_tree():
        return

    var needed := MAGAZINE_SIZE - current_ammo
    var loaded := min(needed, reserve_ammo)

    current_ammo += loaded
    reserve_ammo -= loaded

    reloading = false
    ammo_changed.emit(current_ammo, reserve_ammo)
    print("RELOAD COMPLETE")


func _process(delta: float) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)

    recoil_pitch = move_toward(
        recoil_pitch, 0.0, RECOIL_RECOVERY * delta
    )

    recoil_yaw = move_toward(
        recoil_yaw, 0.0, RECOIL_RECOVERY * delta
    )

    camera_pivot.rotation_degrees.x = camera_pitch - recoil_pitch
    camera_pivot.rotation_degrees.y = recoil_yaw

    if muzzle_timer > 0.0:
        muzzle_timer -= delta

        if muzzle_timer <= 0.0:
            muzzle_flash.visible = false
            muzzle_light.visible = false


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
