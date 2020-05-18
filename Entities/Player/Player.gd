extends KinematicBody2D

signal player_stats_changed
signal player_level_up

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

# XP
var xp = 0
var xp_next_level = 100
var level = 1

# Attack Variables
var attack_cooldown_time = 600
var next_attack_time = 0
var attack_damage = 30

# Fireball variables
var fireball_damage = 50
var fireball_cooldown_time = 1000
var next_fireball_time = 0

# Inventory
enum Potion { HEALTH, MANA }
var health_potions = 0
var mana_potions = 0
var gems = 0

var fireball_scene = preload("res://Entities/Fireball/Fireball.tscn")


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
				if target.is_in_group("NPCs"):
					# talk to NPC
					target.talk()
					return
			# Play Attack Animation
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_attack"
			$Sprite.play(animation)
			next_attack_time = now + attack_cooldown_time

	elif event.is_action_pressed("fireball"):
		var now = OS.get_ticks_msec()
		if mana >= 25 and now >= next_fireball_time:
			mana -= 25
			emit_signal("player_stats_changed", self)
			attack_playing = true
			var animation = get_animation_direction(last_direction) + "_fireball"
			$Sprite.play(animation)
			next_fireball_time = now + fireball_cooldown_time
	
	elif event.is_action_pressed("drink_health"):
		if health_potions > 0:
			health_potions -= 1
			health = min(health_max, health + 50)
			emit_signal("player_stats_changed", self)
	elif event.is_action_pressed("drink_mana"):
		if mana_potions > 0:
			mana_potions -= 1
			mana = min(mana_max, mana + 50)
			emit_signal("player_stats_changed", self)
		

func _on_Sprite_animation_finished():
	attack_playing = false
	if $Sprite.animation.ends_with("_fireball"):
		# instantiate fireball
		var fireball = fireball_scene.instance()
		fireball.attack_damage = fireball_damage
		fireball.direction = last_direction.normalized()
		fireball.position = position + last_direction.normalized() * 4
		get_tree().root.get_node("Root").add_child(fireball)
	
func add_potion(type):
	if type == Potion.HEALTH:
		health_potions += 1
	else:
		mana_potions += 1
	emit_signal("player_stats_changed", self)

func add_gem():
	gems += 1
	

func add_xp(value):
	xp += value
	if xp >= xp_next_level:
		level += 1
		xp_next_level *= 2
		emit_signal("player_level_up")
	emit_signal("player_stats_changed", self)
