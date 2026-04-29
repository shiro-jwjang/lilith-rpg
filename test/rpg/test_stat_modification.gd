extends "res://test/rpg/test_base.gd"

var UnitScript = preload("res://scripts/rpg/combat/unit.gd")


func test_unit_has_base_atk_field() -> void:
	"""Unit은 base_atk 필드를 가진다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "atk": 20, "def": 10})
	assert_eq(int(unit.base_atk), 20, "base_atk should be set from config")


func test_unit_has_base_def_field() -> void:
	"""Unit은 base_def 필드를 가진다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "atk": 20, "def": 10})
	assert_eq(int(unit.base_def), 10, "base_def should be set from config")


func test_둔화_reduces_speed() -> void:
	"""둔화는 속도를 20% 감소시킨다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "speed": 10})
	assert_eq(int(unit.base_speed), 10, "base_speed should be 10")
	unit.apply_status("둔화", 1, 2)
	assert_eq(int(unit.speed), 8, "speed should be 80% of base (8)")


func test_둔화_speed_restored_on_expire() -> void:
	"""둔화 만료 시 속도가 복원된다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "speed": 10})
	unit.apply_status("둔화", 1, 1)
	assert_eq(int(unit.speed), 8, "speed should be reduced")
	unit.process_turn_end_status()
	assert_eq(int(unit.speed), 10, "speed should be restored to base")


func test_둔화_refresh_keeps_speed_reduced() -> void:
	"""둔화 갱신 시 속도 감소가 유지된다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "speed": 10})
	unit.apply_status("둔화", 1, 2)
	assert_eq(int(unit.speed), 8, "speed reduced")
	unit.apply_status("둔화", 1, 2)
	assert_eq(int(unit.speed), 8, "speed still reduced after refresh")


func test_약화_reduces_atk() -> void:
	"""약화는 공격력을 20% 감소시킨다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "atk": 20})
	assert_eq(int(unit.base_atk), 20, "base_atk should be 20")
	unit.apply_status("약화", 1, 2)
	assert_eq(int(unit.atk), 16, "atk should be 80% of base (16)")


func test_약화_atk_restored_on_expire() -> void:
	"""약화 만료 시 공격력이 복원된다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "atk": 20})
	unit.apply_status("약화", 1, 1)
	assert_eq(int(unit.atk), 16, "atk should be reduced")
	unit.process_turn_end_status()
	assert_eq(int(unit.atk), 20, "atk should be restored to base")


func test_파쇄_reduces_def() -> void:
	"""파쇄는 방어력을 25% 감소시킨다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "def": 10})
	assert_eq(int(unit.base_def), 10, "base_def should be 10")
	unit.apply_status("파쇄", 1, 2)
	assert_eq(int(unit.def), 7, "def should be 75% of base (floor(10*0.75)=7)")


func test_파쇄_def_restored_on_expire() -> void:
	"""파쇄 만료 시 방어력이 복원된다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "def": 10})
	unit.apply_status("파쇄", 1, 1)
	assert_eq(int(unit.def), 7, "def should be reduced")
	unit.process_turn_end_status()
	assert_eq(int(unit.def), 10, "def should be restored to base")


func test_multiple_stat_mods_independent() -> void:
	"""둔화+약화 동시 적용 시 각각 독립적으로 동작한다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "atk": 20, "def": 10, "speed": 10})
	unit.apply_status("둔화", 1, 2)
	unit.apply_status("약화", 1, 2)
	assert_eq(int(unit.speed), 8, "둔화 should reduce speed")
	assert_eq(int(unit.atk), 16, "약화 should reduce atk")
	assert_eq(int(unit.def), 10, "def should be unchanged")
	unit.active_statuses["둔화"]["duration"] = 1
	unit.active_statuses["약화"]["duration"] = 3
	unit.process_turn_end_status()
	assert_eq(int(unit.speed), 10, "speed restored after 둔화 expires")
	assert_eq(int(unit.atk), 16, "atk still reduced (약화 still active)")


func test_clear_all_restores_all_stats() -> void:
	"""clear_all_statuses는 모든 스탯을 복원한다"""
	var unit = UnitScript.new({"name": "테스트", "max_hp": 100, "atk": 20, "def": 10, "speed": 10})
	unit.apply_status("둔화", 1, 2)
	unit.apply_status("약화", 1, 2)
	unit.apply_status("파쇄", 1, 2)
	assert_eq(int(unit.speed), 8, "should be reduced")
	assert_eq(int(unit.atk), 16, "should be reduced")
	assert_eq(int(unit.def), 7, "should be reduced")
	unit.clear_all_statuses()
	assert_eq(int(unit.speed), 10, "speed restored")
	assert_eq(int(unit.atk), 20, "atk restored")
	assert_eq(int(unit.def), 10, "def restored")


func test_약화_reduces_enemy_damage_in_combat() -> void:
	"""약화된 적의 데미지가 감소한다"""
	var runner = preload("res://scripts/rpg/game_runner.gd").new()
	runner.start_run()
	var ec = runner.content_data.get_enemy_by_name("녹슨 검병")
	assert_false(ec.is_empty(), "enemy should exist")
	runner.enter_combat([_normalize_enemy_config(ec)])
	runner.battle_manager.allies[0].speed = 20
	runner.battle_manager.allies[1].speed = 19
	runner.battle_manager.allies[2].speed = 18
	runner.battle_manager.enemies[0].speed = 10
	for _i in range(30):
		var tr = runner.next_turn()
		if tr.is_empty():
			continue
		if not bool(tr.get("action_allowed", false)):
			continue
		var u = tr.get("unit", null)
		if u != null and bool(u.is_ally) and String(u.name) == "리나":
			break
	var enemy = runner.battle_manager.enemies[0]
	var normal_atk := int(enemy.atk)
	enemy.apply_status("약화", 1, 2)
	var weakened_atk := int(enemy.atk)
	assert_true(weakened_atk < normal_atk, "enemy atk should be reduced by 약화")
