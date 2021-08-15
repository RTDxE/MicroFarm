extends Node2D

var current_tree = -1
var remaining_time = 3
var has_worm = false
var has_weed = false
var money = 100
var water_count = 5

func _init() -> void:
	GameScore.connect("initialized", self, "_initialize")

func _initialize() -> void:
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	TranslationServer.set_locale("ru" if GameScore.get_lang() == "ru" else "en")
	randomize()
	$GrowButton.connect("pressed", self, "_grow")
	$WaterButton.connect("pressed", self, "make_rain")
	$NoMoney/Close.connect("pressed", $NoMoney, "hide")
	$NoWater/Close.connect("pressed", $NoWater, "hide")
	$BuyMenu/Close.connect("pressed", $BuyMenu, "hide")
	$NoMoney/WatchReward.connect("pressed", self, "_show_reward_money")
	$NoWater/WatchReward.connect("pressed", self, "_show_reward_water")
	$WormButton.connect("pressed", self, "remove_worm")
	$BuyMenu/Control.connect("pressed", self, "plant_tree", [0])
	$BuyMenu/Control2.connect("pressed", self, "plant_tree", [1])
	$BuyMenu/Control3.connect("pressed", self, "plant_tree", [2])
	
	water_count = GameScore.get_field("water_count")
	var ct = OS.get_unix_time()
	var ld = ct - GameScore.get_field("last_drop")
	if (water_count < 5):
		water_count = clamp(water_count + int(ld) / 3600, 0, 5)
	GameScore.set_field("last_drop", ct)
	GameScore.set_field("water_count", water_count)
	
	money = GameScore.get_field("money")
	current_tree = GameScore.get_field("plant_id")
	get_remaining_time()
	
	if GameScore.get_field("worm"):
		has_worm = true
		$Worm.show()
		$WormButton.show()
	
	if GameScore.get_field("weed"):
		has_weed = true
		$Weed.show()
#		$WormButton.show()
	
	$WaterButton/Count.text = str(water_count)
	update_money()
	if current_tree != -1:
		start_timer()
		$TapHand.hide()
		$Tree.texture = load(Trees.list[current_tree].texture[0])
	else:
		$Timer.text = tr("PLANT_NEW")
		$TapHand.show()

func update_money() -> void:
	$Money.text = str(money)

func start_timer() -> void:
	_timer_tick()
	while remaining_time > 0:
		yield(get_tree().create_timer(1), "timeout")
		remaining_time -= 1
		_timer_tick()
	$Timer.text = tr("PICK_IT")

func _timer_tick() -> void:
	var h = int(remaining_time) / 3600
	var m = int(remaining_time - h * 3600) / 60
	var s = remaining_time % 60
	$Timer.text = "%02d:%02d:%02d" % [h, m, s]

func _grow() -> void:
	if current_tree == -1: 
		$BuyMenu.show()
		var pt = GameScore.get_field("tree_planted")
		if pt >= 3:
			$BuyMenu/Control2/ColorRect2.hide()
			$BuyMenu/Control2.disabled = false
		if pt >= 7:
			$BuyMenu/Control3/ColorRect2.hide()
			$BuyMenu/Control3.disabled = false
	elif not has_worm and not has_weed:
		try_pick()

func remove_worm() -> bool:
	if not has_worm: return true
	has_worm = false
	$Net/Anim.play("Pick")
	$WormButton.hide()
	GameScore.set_field("worm", false)
	return false

func remove_weed() -> bool:
	if not has_weed: return true
	has_weed = false
	$Shovel/Anim.play("Shovel")
#	$WormButton.hide()
	GameScore.set_field("weed", false)
	return false

func make_rain() -> void:
	if has_weed or has_worm or current_tree == -1 or $Leica.visible: return
	if water_count <= 0:
		$NoWater.show()
		return
	$Leica/Anim.play("Rain")
	water_count -= 1
	$WaterButton/Count.text = str(water_count)
	yield(get_tree().create_timer(1), "timeout")
	if randi() % 100 < 6:
		has_worm = true
		$Worm.show()
		$WormButton.show()
		GameScore.set_field("worm", true)
	GameScore.add_field("plant_time", -300)
	GameScore.add_field("water_count", -1)
	get_remaining_time()

func get_remaining_time() -> int:
	var tmsp = OS.get_unix_time()
	remaining_time = tmsp - GameScore.get_field("plant_time")
	remaining_time = Trees.list[current_tree].time - remaining_time
	return remaining_time

func plant_tree(id) -> void:
	if current_tree != -1: return
	if clamp(id, 0, 9999) >= Trees.list.size(): return
	var t = Trees.list[id]
	if money < t.cost:
		$BuyMenu.hide()
		$NoMoney.show()
		return
	$Tree.texture = load(t.texture[0])
	remaining_time = t.time
	current_tree = id
	money -= t.cost
	update_money()
	start_timer()
	$TapHand.hide()
	$BuyMenu.hide()
	GameScore.set_field("plant_id", id)
	GameScore.set_field("plant_time", OS.get_unix_time())
	GameScore.add_field("money", -t.cost)

func try_pick() -> void:
	if get_remaining_time() <= 0 and current_tree != -1:
		var profit = Trees.list[current_tree].profit
		money += profit
		current_tree = -1
		$Tree.texture = null
		$Timer.text = tr("PLANT_NEW")
		update_money()
		$TapHand.show()
		GameScore.set_field("plant_id", -1)
		GameScore.add_field("money", profit)
		GameScore.add_field("tree_planted", 1)


func _show_reward_money() -> void:
	$NoMoney.hide()
	GameScore.connect("rewarded", self, "_rewarded_money", [], CONNECT_ONESHOT)
	GameScore.show_rewarded_video()

func _rewarded_money(success) -> void:
	if success:
		money += 100
		GameScore.add_field("money", 100)
		update_money()

func _show_reward_water() -> void:
	$NoWater.hide()
	GameScore.connect("rewarded", self, "_rewarded_water", [], CONNECT_ONESHOT)
	GameScore.show_rewarded_video()

func _rewarded_water(success) -> void:
	if success:
		GameScore.add_field("water_count", 3)
		water_count += 3
		$WaterButton/Count.text = str(water_count)
