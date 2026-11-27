
extends CharacterBody3D

signal enemy_defeated

const MAX_HEALTH := 100
const MOVE_SPEED := 3.5
const DETECTION_RANGE := 25.0
const ATTACK_RANGE := 2.0
const ATTACK_DAMAGE := 10
const ATTACK_INTERVAL := 1.2
const GRAVITY := 18.0

var health := MAX_HEALTH
var player: Node3D
var attack_timer := 0.0
var defeated := false

var body_mesh: MeshInstance3D
var health_label: Label3D


func _ready() -> void:
    name = "BotEnemy"
    create_enemy()


func create_enemy() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)

    body_mesh = MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.4
    mesh.height = 1.8
    body_mesh.mesh = mesh
    body_mesh.position.y = 0.9

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.65, 0.12, 0.08)
    material.roughness = 0.85
    body_mesh.material_override = material
    add_child(body_mesh)

    health_label = Label3D.new()
    health_label.text = "ENEMY 100 HP"
    health_label.position.y = 2.1
    health_label.font_size = 32
    health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(health_label)


func set_player(target: Node3D) -> void:
    player = target


func take_damage(amount: int) -> void:
    if defeated or amount <= 0:
        return

    health = maxi(0, health - amount)
    health_label.text = "ENEMY %d HP" % health

    if health <= 0:
        eliminate()


func eliminate() -> void:
    if defeated:
        return

    defeated = true
    velocity = Vector3.ZERO
    enemy_defeated.emit()

    collision_layer = 0
    collision_mask = 0
    body_mesh.visible = false
    health_label.text = "ENEMY ELIMINATED"

    var collision := get_node_or_null("CollisionShape3D")
    if collision:
        collision.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
    if defeated:
        return

    attack_timer = maxf(0.0, attack_timer - delta)

    if not is_on_floor():
        velocity.y -= GRAVITY * delta

    if not is_instance_valid(player):
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return

    var distance := global_position.distance_to(player.global_position)

    if distance > DETECTION_RANGE:
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return

    var direction := player.global_position - global_position
    direction.y = 0.0

    if distance > ATTACK_RANGE:
        direction = direction.normalized()
        velocity.x = direction.x * MOVE_SPEED
        velocity.z = direction.z * MOVE_SPEED

        if direction.length() > 0.01:
            look_at(
                Vector3(player.global_position.x, global_position.y, player.global_position.z),
                Vector3.UP
            )
    else:
        velocity.x = 0.0
        velocity.z = 0.0

        if attack_timer <= 0.0:
            attack_timer = ATTACK_INTERVAL

            if player.has_method("take_damage"):
                player.take_damage(ATTACK_DAMAGE)

    move_and_slide()
