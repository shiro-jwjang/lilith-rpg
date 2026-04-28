extends "res://test/rpg/test_base.gd"

const WALLET_PATH := "res://scripts/rpg/economy/wallet.gd"


func test_wallet_001_initial_gold_is_zero() -> void:
	var wallet = _make_wallet()
	if wallet == null:
		return
	assert_eq(int(wallet.gold), 0, "wallet-001 expected initial gold 0")


func test_wallet_002_init_with_custom_gold() -> void:
	var wallet = _make_wallet({"gold": 100})
	if wallet == null:
		return
	assert_eq(int(wallet.gold), 100, "wallet-002 expected configured gold 100")


func test_wallet_003_add_gold() -> void:
	var wallet = _make_wallet()
	if wallet == null:
		return
	wallet.add_gold(50)
	assert_eq(int(wallet.gold), 50, "wallet-003 expected gold 50 after add")


func test_wallet_004_add_gold_negative_raises_error() -> void:
	var wallet = _make_wallet({"gold": 25})
	if wallet == null:
		return
	wallet.add_gold(-10)
	assert_eq(int(wallet.gold), 25, "wallet-004 expected gold unchanged after negative add")


func test_wallet_005_spend_gold_success() -> void:
	var wallet = _make_wallet({"gold": 100})
	if wallet == null:
		return
	var success := bool(wallet.spend(30))
	assert_true(success, "wallet-005 expected spend success")
	assert_eq(int(wallet.gold), 70, "wallet-005 expected gold 70 after spend")


func test_wallet_006_spend_gold_insufficient() -> void:
	var wallet = _make_wallet({"gold": 100})
	if wallet == null:
		return
	var success := bool(wallet.spend(200))
	assert_false(success, "wallet-006 expected spend failure")
	assert_eq(int(wallet.gold), 100, "wallet-006 expected gold unchanged")


func test_wallet_007_spend_gold_exact() -> void:
	var wallet = _make_wallet({"gold": 100})
	if wallet == null:
		return
	var success := bool(wallet.spend(100))
	assert_true(success, "wallet-007 expected exact spend success")
	assert_eq(int(wallet.gold), 0, "wallet-007 expected gold 0 after exact spend")


func test_wallet_008_can_afford() -> void:
	var wallet = _make_wallet({"gold": 100})
	if wallet == null:
		return
	assert_true(bool(wallet.can_afford(50)), "wallet-008 expected affordability true")


func test_wallet_009_cannot_afford() -> void:
	var wallet = _make_wallet({"gold": 100})
	if wallet == null:
		return
	assert_false(bool(wallet.can_afford(150)), "wallet-009 expected affordability false")


func test_wallet_010_get_gold() -> void:
	var wallet = _make_wallet({"gold": 75})
	if wallet == null:
		return
	assert_eq(int(wallet.get_gold()), 75, "wallet-010 expected get_gold 75")


func _make_wallet(config: Dictionary = {}):
	var script = load(WALLET_PATH)
	assert_not_null(script, "expected wallet.gd to exist")
	if script == null:
		return null
	return script.new(config)
