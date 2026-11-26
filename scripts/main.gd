
extends Node3D

func _ready() -> void:
    create_ground()
    create_environment_objects()


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
        var block := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(2, 2, 2)
        block.mesh = box

        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.25, 0.29, 0.25)
        block.material_override = material

        block.position = Vector3(
            float((i % 4) * 8 - 12),
            1.0,
            float((i / 4) * -8 - 8)
        )

        add_child(block)
