extends Node3D

const STAGE_NAMES := ["CLOUDSTEP ISLES", "EMBERLIGHT TEMPLE"]
const STAGE_SKIES := [Color("#8bd4ed"), Color("#26254c")]
const STAGE_GRASS := [Color("#56b99a"), Color("#c97846")]
const STAGE_STONE := [Color("#427f79"), Color("#754568")]
const STAGE_ACCENT := [Color("#ffe16b"), Color("#ffb34d")]
const PLATFORMS := [
	Vector3(0, 0, 0), Vector3(2.7, 0, -17), Vector3(-2.4, 0.25, -34),
	Vector3(2.1, 0.15, -51), Vector3(0, 0, -68)
]

var stage := 0
var collected := 0
var total_items := 0
var finished := false
var jump_queued := false
var player: CharacterBody3D
var player_visual: Node3D
var player_animator: AnimationPlayer
var active_character_animation := ""
var camera: Camera3D
var hud: CanvasLayer
var status_label: Label
var message_label: Label
var active_world: Node3D
var world_env: WorldEnvironment
var player_inside_gate := false

func _ready() -> void:
	Input.set_use_accumulated_input(false)
	_build_hud()
	_start_stage(0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			jump_queued = true
		if event.keycode == KEY_R and finished:
			_start_stage(0)

func _physics_process(delta: float) -> void:
	if player == null or finished:
		return
	var direction := Vector3.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.z += 1.0
	direction = direction.normalized()
	player.velocity.x = direction.x * 7.2
	player.velocity.z = direction.z * 7.2
	if not player.is_on_floor():
		player.velocity.y -= 23.0 * delta
	elif jump_queued:
		player.velocity.y = 9.0
	jump_queued = false
	player.move_and_slide()
	_update_character_animation(direction)
	if player.global_position.y < -9.0:
		_respawn()
	if camera:
		var target := player.global_position + Vector3(0, 8.5, 12.5)
		camera.global_position = camera.global_position.lerp(target, minf(delta * 4.0, 1.0))
		camera.look_at(player.global_position + Vector3(0, 0.7, -4.0), Vector3.UP)
	_update_status()

func _process(delta: float) -> void:
	if active_world == null: return
	for item in active_world.get_tree().get_nodes_in_group("spin_items"):
		if is_instance_valid(item):
			item.rotate_y(delta * 1.8)
			item.position.y = item.get_meta("base_y") + sin(Time.get_ticks_msec() * 0.0025 + item.get_instance_id() % 10) * 0.12
	for hazard in active_world.get_tree().get_nodes_in_group("spin_hazards"):
		if is_instance_valid(hazard): hazard.rotate_y(delta * 1.3)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var panel := ColorRect.new()
	panel.position = Vector2(24, 20)
	panel.size = Vector2(420, 94)
	panel.color = Color(0.035, 0.07, 0.12, 0.76)
	hud.add_child(panel)
	var title := Label.new()
	title.text = "SKYBOUND TRAILS"
	title.position = Vector2(44, 26)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("#fff2c3"))
	hud.add_child(title)
	status_label = Label.new()
	status_label.position = Vector2(44, 59)
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	hud.add_child(status_label)
	var controls := Label.new()
	controls.text = "MOVE  WASD / ARROWS     JUMP  SPACE"
	controls.anchor_left = 1.0
	controls.anchor_right = 1.0
	controls.offset_left = -480
	controls.offset_right = -24
	controls.offset_top = 28
	controls.offset_bottom = 60
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	hud.add_child(controls)
	message_label = Label.new()
	message_label.anchor_left = 0.5
	message_label.anchor_top = 1.0
	message_label.anchor_right = 0.5
	message_label.anchor_bottom = 1.0
	message_label.offset_left = -350
	message_label.offset_top = -84
	message_label.offset_right = 350
	message_label.offset_bottom = -34
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 23)
	message_label.add_theme_color_override("font_color", Color("#fff2c3"))
	message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(message_label)

func _start_stage(index: int) -> void:
	stage = index
	collected = 0
	total_items = 0
	finished = false
	player_inside_gate = false
	if active_world: active_world.queue_free()
	active_world = Node3D.new()
	active_world.name = "Stage_%d" % (stage + 1)
	add_child(active_world)
	_build_stage()
	_spawn_player()
	message_label.text = "Collect every light and find the gate!"
	_update_status()

func _build_stage() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = STAGE_SKIES[stage]
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c8f2ff") if stage == 0 else Color("#ffcb91")
	environment.ambient_light_energy = 0.72
	world_env = WorldEnvironment.new()
	world_env.environment = environment
	active_world.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	active_world.add_child(sun)
	for i in PLATFORMS.size():
		var p: Vector3 = PLATFORMS[i]
		var stone := _mat(STAGE_STONE[stage])
		_add_kit_platform(p)
		_add_static_box(active_world, p + Vector3(0, -0.46, 0), Vector3(14, 0.15, 14))
		_make_box(active_world, p + Vector3(0, -1.45, 0), Vector3(12.5, 1, 12.5), stone, false)
		_make_box(active_world, p + Vector3(-6.7, -0.1, 0), Vector3(0.4, 0.5, 13.9), _mat(STAGE_ACCENT[stage].darkened(0.26)), false)
		_make_box(active_world, p + Vector3(6.7, -0.1, 0), Vector3(0.4, 0.5, 13.9), _mat(STAGE_ACCENT[stage].darkened(0.26)), false)
		if i > 0 and i < PLATFORMS.size() - 1 and i % 2 == 1:
			_add_hazard(p + Vector3(4.0, 0.45, 0.25))
		if i > 0:
			_add_collectible(p + Vector3(0, 1.35, -1.0))
		_add_decor(p, i)
	_add_gate(PLATFORMS[PLATFORMS.size() - 1] + Vector3(0, 0.1, -2.6))
	_add_island_dressing()

func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = PLATFORMS[0] + Vector3(0, 0.12, 1.4)
	player.floor_snap_length = 0.25
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.65
	collider.shape = capsule
	collider.position.y = 0.83
	player.add_child(collider)
	var character_scene := load("res://Assets/PolyPizza/AnimatedPlatformerCharacter.glb") as PackedScene
	player_visual = character_scene.instantiate() as Node3D
	player_visual.name = "PolyPizzaCharacter"
	player_visual.scale = Vector3.ONE
	player_visual.rotation.y = PI
	player.add_child(player_visual)
	player_animator = player_visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	active_character_animation = ""
	active_world.add_child(player)
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.current = true
	camera.fov = 58
	camera.position = player.position + Vector3(0, 8.5, 12.5)
	active_world.add_child(camera)
	camera.look_at(player.global_position + Vector3(0, 0.7, -4.0))

func _add_collectible(at: Vector3) -> void:
	var area := Area3D.new()
	area.position = at
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.2
	shape.shape = sphere
	area.add_child(shape)
	var gem := _mesh_node(SphereMesh.new(), _mat(STAGE_ACCENT[stage]))
	var gem_mesh: SphereMesh = gem.mesh
	gem_mesh.radius = 0.56
	gem_mesh.height = 1.15
	gem.position.y = 0.05
	area.add_child(gem)
	var sparkle := _mesh_node(SphereMesh.new(), _mat(Color.WHITE))
	var sparkle_mesh: SphereMesh = sparkle.mesh
	sparkle_mesh.radius = 0.12
	sparkle_mesh.height = 0.25
	sparkle.position = Vector3(0.16, 0.22, -0.16)
	area.add_child(sparkle)
	area.add_to_group("spin_items")
	area.set_meta("base_y", area.position.y)
	area.body_entered.connect(_on_collectible_touched.bind(area))
	active_world.add_child(area)
	total_items += 1

func _add_kit_platform(at: Vector3) -> void:
	var path := "res://Scenes/PlatformBlue.tscn" if stage == 0 else "res://Scenes/PlatformRed.tscn"
	var platform := (load(path) as PackedScene).instantiate() as Node3D
	platform.name = "StarterKitPlatform_%d" % active_world.get_child_count()
	platform.scale = Vector3(1.7, 0.55, 1.7)
	var top_offset := 0.594 if stage == 0 else 0.216
	platform.position = at - Vector3(0, top_offset, 0)
	active_world.add_child(platform)

func _add_static_box(parent: Node, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	parent.add_child(body)

func _add_hazard(at: Vector3) -> void:
	var area := Area3D.new()
	area.position = at
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.95
	cylinder.height = 1.0
	shape.shape = cylinder
	area.add_child(shape)
	var hub := _mesh_node(SphereMesh.new(), _mat(Color("#533142")))
	var hub_mesh: SphereMesh = hub.mesh
	hub_mesh.radius = 0.28
	hub_mesh.height = 0.56
	area.add_child(hub)
	for arm in 3:
		var spike := _make_box(area, Vector3(0, 0, 0), Vector3(1.65, 0.2, 0.34), _mat(Color("#ff7087")), false)
		spike.rotation.y = arm * TAU / 3.0
	area.add_to_group("spin_hazards")
	area.body_entered.connect(_on_hazard_touched)
	active_world.add_child(area)

func _add_gate(at: Vector3) -> void:
	var gate := Area3D.new()
	gate.position = at
	gate.collision_layer = 0
	gate.collision_mask = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.1, 4.2, 1.5)
	shape.shape = box
	shape.position.y = 2.0
	gate.add_child(shape)
	var gold := _mat(STAGE_ACCENT[stage])
	_make_box(gate, Vector3(-1.2, 1.9, 0), Vector3(0.32, 3.8, 0.35), gold, false)
	_make_box(gate, Vector3(1.2, 1.9, 0), Vector3(0.32, 3.8, 0.35), gold, false)
	_make_box(gate, Vector3(0, 3.75, 0), Vector3(2.7, 0.35, 0.35), gold, false)
	var portal := _mesh_node(CylinderMesh.new(), _mat(Color(0.23, 0.88, 0.91, 0.78)))
	var portal_mesh: CylinderMesh = portal.mesh
	portal_mesh.top_radius = 0.96
	portal_mesh.bottom_radius = 0.96
	portal_mesh.height = 0.12
	portal.position = Vector3(0, 1.9, -0.04)
	portal.rotation_degrees.x = 90
	gate.add_child(portal)
	gate.body_entered.connect(_on_gate_touched)
	gate.body_exited.connect(_on_gate_exited)
	active_world.add_child(gate)

func _add_decor(center: Vector3, n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9127 + stage * 733 + n
	for side in [-1.0, 1.0]:
		var x: float = side * rng.randf_range(4.8, 5.5)
		var z := rng.randf_range(-4.2, 4.2)
		var trunk := _make_box(active_world, center + Vector3(x, 0.42, z), Vector3(0.26, 0.86, 0.26), _mat(Color("#76533b") if stage == 0 else Color("#633d53")), false)
		trunk.rotation.z = side * 0.12
		var crown := _mesh_node(CylinderMesh.new(), _mat(Color("#2e9076") if stage == 0 else Color("#df8250")))
		var cone: CylinderMesh = crown.mesh
		cone.top_radius = 0.0
		cone.bottom_radius = 0.85
		cone.height = 1.5
		crown.position = center + Vector3(x, 1.35, z)
		active_world.add_child(crown)
	if n == 0:
		for side in [-1.0, 1.0]:
			var pillar := _make_box(active_world, center + Vector3(side * 5.8, 0.85, 5.0), Vector3(0.55, 1.9, 0.55), _mat(STAGE_ACCENT[stage].darkened(0.12)), false)
			_make_box(active_world, pillar.position + Vector3(0, 1.05, 0), Vector3(0.85, 0.28, 0.85), _mat(STAGE_ACCENT[stage]), false)

func _add_island_dressing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 801 + stage
	for i in 22:
		var anchor: Vector3 = PLATFORMS[rng.randi_range(0, PLATFORMS.size() - 1)]
		var shard := _mesh_node(PrismMesh.new(), _mat(STAGE_ACCENT[stage].lightened(rng.randf_range(-0.12, 0.17))))
		var crystal: PrismMesh = shard.mesh
		crystal.size = Vector3(rng.randf_range(0.22, 0.55), rng.randf_range(0.65, 1.6), rng.randf_range(0.22, 0.55))
		shard.position = anchor + Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(1.2, 4.0), rng.randf_range(-3.0, 3.0))
		shard.rotation_degrees = Vector3(rng.randf_range(-8, 8), rng.randf_range(0, 360), rng.randf_range(-8, 8))
		active_world.add_child(shard)
	for i in 9:
		var cloud := _mesh_node(SphereMesh.new(), _mat(Color(1, 1, 1, 0.55) if stage == 0 else Color(0.91, 0.64, 0.91, 0.48)))
		var cloud_mesh: SphereMesh = cloud.mesh
		cloud_mesh.radius = 1.0
		cloud_mesh.height = 1.4
		cloud.position = Vector3(rng.randf_range(-14, 14), rng.randf_range(-2, 4), rng.randf_range(-80, 7))
		cloud.scale = Vector3(rng.randf_range(1.2, 2.8), 0.48, rng.randf_range(0.8, 1.8))
		active_world.add_child(cloud)

func _make_box(parent: Node, at: Vector3, size: Vector3, material: Material, collision: bool) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mesh := _mesh_node(box, material)
	mesh.position = at
	if collision:
		var body := StaticBody3D.new()
		body.position = at
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		parent.add_child(body)
	parent.add_child(mesh)
	return mesh

func _mesh_node(mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	return node

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _on_collectible_touched(body: Node3D, area: Area3D) -> void:
	if body != player or not is_instance_valid(area): return
	area.queue_free()
	collected += 1
	message_label.text = "Light collected! Find %d more." % (total_items - collected)
	_update_status()
	if player_inside_gate and collected >= total_items:
		_advance_stage()

func _on_hazard_touched(body: Node3D) -> void:
	if body == player: _respawn()

func _on_gate_touched(body: Node3D) -> void:
	if body != player or finished: return
	player_inside_gate = true
	if collected < total_items:
		message_label.text = "The gate needs every light: %d / %d" % [collected, total_items]
		return
	_advance_stage()

func _on_gate_exited(body: Node3D) -> void:
	if body == player:
		player_inside_gate = false

func _advance_stage() -> void:
	if finished: return
	if stage == 0:
		_start_stage(1)
	else:
		finished = true
		message_label.text = "TRAIL COMPLETE! Press R to play again"
		status_label.text = "All trails cleared  |  %d / %d lights" % [collected, total_items]

func _respawn() -> void:
	if player:
		player.global_position = PLATFORMS[0] + Vector3(0, 0.12, 1.4)
		player.velocity = Vector3.ZERO
		message_label.text = "Back to the trailhead - try another route!"

func _update_character_animation(direction: Vector3) -> void:
	if player_animator == null:
		return
	var wanted := "Idle"
	if not player.is_on_floor():
		wanted = "Jump"
	elif direction.length_squared() > 0.01:
		wanted = "Run"
	var animation_name := ""
	for candidate in player_animator.get_animation_list():
		if candidate == wanted or candidate.ends_with("|" + wanted):
			animation_name = candidate
			break
	if animation_name != "" and animation_name != active_character_animation:
		player_animator.play(animation_name, 0.18)
		active_character_animation = animation_name

func _update_status() -> void:
	if status_label:
		status_label.text = "GATE %d / 2   •   %s   •   LIGHTS %d / %d" % [stage + 1, STAGE_NAMES[stage], collected, total_items]
