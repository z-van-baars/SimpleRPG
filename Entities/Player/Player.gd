extends KinematicBody2D

signal player_stats_changed
export var speed = 75
var last_direction = Vector2(0, 1)
var attack_playing = false
# Player stats
var health = 100
var health_max = 100
var health_regeneration = 1
var mana = 100
var mana_max = 100
var mana_regeneration = 2

# Attack Variables
var attack_cooldown_time = 600
var next_attack_time = 0
var attack_damage = 30



# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("player_stats_changed", self)


func _process(delta):
		# Regenerates mana
	var new_mana = min(mana + mana_regeneration * delta, mana_max)
	if new_mana != mana:
		mana = new_mana
		emit_signal("player_stats_changed", self)

	# Regenerates health
	var new_health = min(health + health_regeneration * delta, health_max)
	if new_health != health:
		health = new_health
		emit_signal("player_stats_changed", self)

func _physics_process(delta):
	var direction: Vector2
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if abs(direction.x) == 1 and abs(direction.y) == 1:
		direction = direction.normalized()
	
	var movement = speed * direction * delta
	# warning-ignore:return_value_discarded
	if attack_playing:
		movement *= 0.3
	move_and_collide(movement)
	# Animate player based on direction
	if not attack_playing:
		animates_player(direction)
	# Turn Raycast toward movement direction
	if direction != Vector2.ZERO:
		$RayCast2D.cast_to = direction.normalized() * 8
	

func get_animation_direction(direction: Vector2):
	var norm_direction = direction.normalized()
	if norm_direction.y >= 0.707:
		return "down"
	elif norm_direction.y <= -0.707:
		return "up"
	elif norm_direction.x <= -0.707:
		return "left"
	elif norm_direction.x >= 0.707:
		return "right"
	return "down"

func hit(damage):
	health -= damage
	emit_signal("player_stats_change", self)
	if health <= 0:
		set_process(false)
		$AnimationPlayer.play("Game Over")
	else:
		$AnimationPlayer.play("Hit")
func animates_player(direction: Vector2):
	if direction != Vector2.ZERO:
		# gradually update last_direction to counteract the bounce of the analog stick
		last_direction = 0.5 * last_direction + 0.5 * direction
		
		var animation = get_animation_direction(last_direction) + "_walk"
		# Play Walk Animation
		$Sprite.frames.set_animation_speed(animation, 2 + 8 * direction.length())
		$Sprite.play(animation)
	else:
		# Play Idle Animation
		var animation = get_animation_direction(last_direction) + "_idle"
		$Sprite.play(animation)

func _input(event):
	if event.is_action_pressed("attack"):
		var now = OS.get_ticks_msec()
		if now >= next_attack_time:
			# What's the target?
			var target = $RayCast2D.get_collider()
			if target != null:
				if target.name.find("Skeleton") >= 0:
					# Skeleton Hit!
					target.hit(attack_damage)
			# Play Attack Animation
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_attack"
			$Sprite.play(animation)
			next_attack_time = now + attack_cooldown_time

	elif event.is_action_pressed("fireball"):
		if mana >= 25:
			mana -= 25
			emit_signal("player_stats_changed", self)
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_fireball"
			$Sprite.play(animation)

	


func _on_Sprite_animation_finished():
	attack_playing = false
	
