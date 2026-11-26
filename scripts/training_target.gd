
extends StaticBody3D

signal target_destroyed

const MAX_HEALTH := 100
const RESPAWN_TIME := 3.0

var health := MAX_HEALTH
var collision_shape: CollisionShape3D
var target_mesh: MeshInstance3D
var health_label: Label3D
var target_material: StandardMaterial3D


func _ready() -> void:
    name = "TrainingTarget"
    create_target()


func create_target() -> void:
    collision_shape = CollisionShape3D.new()

    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.55
    capsule.height = 2.0

    collision_shape.shape = capsule
    collision_shape.position.y = 1.0
    add_child(collision_shape)

    target_mesh = MeshInstance3D.new()

    var mesh := CapsuleMesh.new()
    mesh.radius = 0.55
    mesh.height = 2.0

    target_mesh.mesh = mesh
    target_mesh.position.y = 1.0

    target_material = StandardMaterial3D.new()
    target_material.albedo_color = Color(0.65, 0.12, 0.08)
    target_material.roughness = 0.8
    target_mesh.material_override = target_material

    add_child(target_mesh)

    health_label = Label3D.new()
    health_label.text = "TARGET 100 HP"
    health_label.position.y = 2.3
    health_label.font_size = 48
    health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    health_label.modulate = Color(1.0, 0.85, 0.35)

    add_child(health_label)


func take_damage(amount: int) -> void:
    if health <= 0:
        return

    health = max(0, health - amount)

    health_label.text = "TARGET %d HP" % health

    target_material.albedo_color = Color(1.0, 0.8, 0.15)

    await get_tree().create_timer(0.12).timeout

    if health > 0:
        target_material.albedo_color = Color(0.65, 0.12, 0.08)
        return

    destroy_target()


func destroy_target() -> void:
    target_destroyed.emit()

    health_label.text = "TARGET DESTROYED"
    target_mesh.visible = false
    collision_shape.set_deferred("disabled", true)

    await get_tree().create_timer(RESPAWN_TIME).timeout

    health = MAX_HEALTH
    target_mesh.visible = true
    collision_shape.set_deferred("disabled", false)

    health_label.text = "TARGET 100 HP"
    target_material.albedo_color = Color(0.65, 0.12, 0.08)
