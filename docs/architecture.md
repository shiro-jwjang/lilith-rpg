# 로구라이크 RPG — 아키텍처 설계서 (v0.1 Draft)

> Godot 4 · GDScript · 1막 MVP

---

## 목차


---

## 1. 디렉토리 구조

```
project/
├── project.godot
├── autoload/                    # 오토로드 스크립트
│   ├── event_bus.gd
│   ├── run_state.gd
│   ├── data_tables.gd
│   ├── save_manager.gd
│   └── scene_manager.gd
├── scenes/
│   ├── main.tscn                # 루트 씬 (Window → SceneSwitcher)
│   ├── title/
│   │   └── title_screen.tscn
│   ├── map/
│   │   └── map_screen.tscn
│   ├── battle/
│   │   ├── battle_screen.tscn
│   │   └── components/          # 전투 UI 컴포넌트
│   │       ├── turn_order_bar.tscn
│   │       ├── character_hud.tscn
│   │       ├── enemy_hud.tscn
│   │       ├── skill_panel.tscn
│   │       └── battle_log.tscn
│   ├── event/
│   │   └── event_screen.tscn
│   ├── treasure/
│   │   └── treasure_screen.tscn
│   ├── shop/
│   │   └── shop_screen.tscn
│   ├── campfire/
│   │   └── campfire_screen.tscn
│   ├── boss_result/
│   │   └── boss_result_screen.tscn
│   └── run_over/
│       └── run_over_screen.tscn
├── scripts/
│   ├── battle/                  # 전투 엔진 로직
│   │   ├── battle_engine.gd
│   │   ├── turn_manager.gd
│   │   ├── damage_calculator.gd
│   │   ├── status_effect_system.gd
│   │   ├── enemy_ai.gd
│   │   └── battle_reward.gd
│   ├── map/
│   │   ├── map_generator.gd
│   │   └── map_node.gd
│   ├── event/
│   │   └── event_resolver.gd
│   ├── reward/
│   │   └── reward_pool.gd
│   ├── inventory/
│   │   ├── inventory_manager.gd
│   │   └── equipment_slot.gd
│   ├── economy/
│   │   └── wallet.gd
│   ├── entities/
│   │   ├── combatant.gd         # 전투원 베이스
│   │   ├── party_member.gd      # 플레이어 파티원
│   │   └── enemy_unit.gd        # 적 유닛
│   └── save/
│       └── run_save_data.gd
├── data/
│   ├── tables/
│   │   ├── CharacterTable.json
│   │   ├── SkillTable.json
│   │   ├── EnemyTable.json
│   │   ├── RelicTable.json
│   │   ├── EquipmentTable.json
│   │   ├── NodeTable.json
│   │   ├── EventTable.json
│   │   └── RewardTable.json
│   └── saves/
│       ├── persistent.json      # 해금 등 영구 데이터
│       └── run_save.json        # 런 중단용 세이브 (선택)
├── resources/                   # Godot Resource (.tres) — 필요시만
└── tests/                       # GUT 단위 테스트
    ├── test_damage_calculator.gd
    ├── test_turn_manager.gd
    ├── test_map_generator.gd
    └── test_reward_pool.gd
```

---

## 2. 씬 트리 구조

### 2-1. 루트 씬 (`main.tscn`)

```
Window (main)
└── SceneSwitcher (Control)        # autoload SceneManager가 제어
```

- `SceneManager` 오토로드가 `SceneSwitcher` 노드에 자식 씬을 add/remove
- 모든 화면 씬은 `SceneSwitcher` 아래에 로드됨

### 2-2. 오토로드 등록 순서 (project.godot)

```
EventBus        → 시그널 허브 (의존성 없음)
DataTables      → JSON 테이블 로더
RunState        → 런 상태 보관 (DataTables 의존)
SaveManager     → 세이브/로드 (RunState 의존)
SceneManager    → 씬 전환 (EventBus 의존)
```

> **순서가 중요**: 의존 관계의 하위 → 상위 순으로 등록

### 2-3. 전투 씬 (`battle_screen.tscn`)

```
BattleScreen (Control)
├── BackgroundLayer (TextureRect)
├── EnemyArea (Control)
│   └── [EnemyUnit instances — 동적 생성]
├── PartyArea (Control)
│   └── [CharacterHUD × 3]
├── TurnOrderBar (HBoxContainer)
├── SkillPanel (VBoxContainer)
│   └── [SkillButton × N]
├── BattleLog (RichTextLabel)
├── AnimationPlayer
└── BattleEngine (Node)           # 로직 컨트롤러 (스크립트만, 시각 없음)
```

### 2-4. 맵 씬 (`map_screen.tscn`)

```
MapScreen (Control)
├── FloorLabel (Label)            # "층 1 / 3"
├── NodeContainer (Control)       # 노드 UI 동적 배치
├── PartyStatusBar (HBoxContainer)
└── MapGenerator (Node)           # 로직 컨트롤러
```

### 2-5. 상점 씬 (`shop_screen.tscn`)

```
ShopScreen (Control)
├── ShopItemList (VBoxContainer)
├── WalletDisplay (Label)
├── BuyButton / SellButton
└── InventoryPanel
```

---

## 3. 코어 클래스 다이어그램

### 3-1. 클래스 관계도 (텍스트)

```
Combatant (ResourceRefCounted)        # 전투원 데이터 베이스
├── PartyMember : Combatant           # 플레이어 캐릭터
│   └── equipped_items: Array[EquipSlot]
├── EnemyUnit : Combatant             # 적
│   └── ai_priority_table: Dictionary
│
BattleEngine (Node)                   # 전투 씬의 루트 로직
├── turn_manager: TurnManager
├── damage_calculator: DamageCalculator
├── status_system: StatusEffectSystem
├── enemy_ai: EnemyAI
├── party: Array[PartyMember]
├── enemies: Array[EnemyUnit]
│
TurnManager (RefCounted)              # 턴 순서/흐름 관리
DamageCalculator (RefCounted)         # 피해 계산 (순수 함수)
StatusEffectSystem (RefCounted)       # 상태이상 적용/해제
EnemyAI (RefCounted)                  # 적 행동 결정
│
MapGenerator (Node)                   # 노드 그래프 생성
MapNode (RefCounted)                  # 단일 노드 데이터
│
EventResolver (RefCounted)            # 이벤트 선택지 평가
RewardPool (RefCounted)               # 보상 뽑기 (가중치 랜덤)
│
InventoryManager (RefCounted)         # 인벤토리 CRUD
EquipmentSlot (RefCounted)            # 장비 슬롯 (무기/방어구/액세서리/트링킷)
Wallet (RefCounted)                   # 골드 관리
```

### 3-2. 설계 원칙

| 원칙 | 적용 |
|------|------|
| **Composition over Inheritance** | `BattleEngine`가 `TurnManager`, `DamageCalculator` 등을 소유 |
| **순수 로직 분리** | `DamageCalculator`, `RewardPool`은 Godot Node 없이 `RefCounted` — GUT 테스트 용이 |
| **UI와 로직 분리** | 씬의 컨트롤러 노드는 로직만 담고, UI는 시그널로 구독 |
| **데이터와 행동 분리** | `Combatant`는 데이터이고, 행동은 `BattleEngine`이 수행 |

---

## 4. 상태 관리 — RunState

### 4-1. RunState 오토로드

런 전체의 휘발성 상태를 보관하는 싱글턴. 런 시작 시 초기화, 런 종료/사망 시 폐기.

```gdscript
# run_state.gd
extends Node

# ── 파티 ──
var party: Array[PartyMember] = []

# ── 맵 ──
var current_floor: int = 1
var current_node_index: int = -1
var map_graph: Array[MapNode] = []      # 현재 층 노드 목록

# ── 인벤토리 ──
var inventory: InventoryManager

# ── 경제 ──
var wallet: Wallet

# ── 진행 ──
var floors_cleared: int = 0
var bosses_defeated: Array[String] = [] # 보스 ID 목록
var nodes_visited: int = 0

# ── 보스 ──
var active_boss_id: String = ""

# ── 초기화 ──
func start_new_run() -> void:
    var chars = DataTables.get_characters()
    party.clear()
    for char_id in ["warrior", "guardian", "mage"]:
        var pm = PartyMember.from_data(char_id)
        party.append(pm)
    inventory = InventoryManager.new()
    wallet = Wallet.new()
    current_floor = 1
    floors_cleared = 0
    bosses_defeated.clear()
    nodes_visited = 0
    EventBus.run_started.emit()

func end_run(victory: bool) -> void:
    if victory:
        for boss_id in bosses_defeated:
            SaveManager.unlock_boss(boss_id)
    EventBus.run_ended.emit(victory)
    reset()

func reset() -> void:
    party.clear()
    inventory = null
    wallet = null
    current_floor = 1
```

### 4-2. 데이터 소유권 요약

| 데이터 | 보관 위치 | 수명 |
|--------|-----------|------|
| 파티 상태 (HP, 버프 등) | `RunState.party` | 런 동안 |
| 인벤토리 | `RunState.inventory` | 런 동안 |
| 골드 | `RunState.wallet` | 런 동안 |
| 현재 층/노드 | `RunState.current_floor` | 런 동안 |
| 해금 내역 | `SaveManager` → `persistent.json` | 영구 |
| JSON 테이블 원본 | `DataTables` (메모리 캐시) | 앱 생존 |
| 런 세이브 | `SaveManager` → `run_save.json` | 수동 저장 시 |

---

## 5. 시그널 버스 — EventBus

모든 시스템 간 통신은 `EventBus` 오토로드의 시그널을 경유. 직접 참조 금지.

```gdscript
# event_bus.gd
extends Node

# ── 런 라이프사이클 ──
signal run_started()
signal run_ended(victory: bool)

# ── 씬 전환 ──
signal scene_transition_requested(target: String, params: Dictionary)
signal scene_transition_completed(target: String)

# ── 전투 ──
signal battle_started(enemy_ids: Array[String])
signal battle_ended(victory: bool, rewards: Dictionary)
signal turn_started(combatant: Combatant)
signal turn_ended(combatant: Combatant)
signal skill_used(user: Combatant, skill_id: String, targets: Array[Combatant])
signal damage_dealt(target: Combatant, amount: int, is_crit: bool)
signal healing_done(target: Combatant, amount: int)
signal status_applied(target: Combatant, effect_id: String, stacks: int)
signal status_removed(target: Combatant, effect_id: String)
signal combatant_died(combatant: Combatant)

# ── 맵 ──
signal floor_entered(floor_num: int)
signal node_selected(node: MapNode)
signal floor_cleared(floor_num: int)

# ── 인벤토리 & 경제 ──
signal gold_changed(amount: int)
signal item_acquired(item_id: String, item_type: String)
signal item_equipped(party_index: int, slot_type: String, item_id: String)
signal item_removed(item_id: String)

# ── 이벤트 ──
signal event_choice_made(event_id: String, choice_id: String, result: Dictionary)

# ── UI 요청 ──
signal toast_requested(message: String)
signal screen_shake_requested(intensity: float)
```

### 구독 예시

```gdscript
# battle_screen.gd
func _ready() -> void:
    EventBus.damage_dealt.connect(_on_damage_dealt)
    EventBus.battle_ended.connect(_on_battle_ended)

func _exit_tree() -> void:
    EventBus.damage_dealt.disconnect(_on_damage_dealt)
    EventBus.battle_ended.disconnect(_on_battle_ended)

func _on_damage_dealt(target: Combatant, amount: int, is_crit: bool) -> void:
    # 데미지 팝업 표시
    _show_damage_popup(target, amount, is_crit)
```

---

## 6. 전투 엔진 구조

### 6-1. BattleEngine — 전체 흐름

```
BattleEngine (Node)
│
│  1. setup(enemy_ids)          — 적 생성, 턴 큐 초기화
│  2. start_battle()            — 첫 턴 시작
│  3. [턴 루프]
│     ├─ TurnManager.next_turn()
│     ├─ 현재 행동자가 파티원 → 플레이어 입력 대기 (SkillPanel 활성화)
│     ├─ 현재 행동자가 적 → EnemyAI.decide_action()
│     ├─ execute_action(action) → DamageCalculator + StatusEffectSystem
│     ├─ 턴 종� 처리 (도트 데미지, 상태이상 턴 감소)
│     └─ 승리/패배 판정
│  4. end_battle(victory)
│
└── 하위 시스템 (composition)
    ├── TurnManager
    ├── DamageCalculator
    ├── StatusEffectSystem
    └── EnemyAI
```

### 6-2. TurnManager — 속도 기반 턴 순서

```gdscript
# turn_manager.gd
extends RefCounted

var _combatants: Array[Combatant] = []
var _turn_queue: Array[Combatant] = []
var _current_index: int = 0

func setup(combatants: Array[Combatant]) -> void:
    _combatants = combatants
    _build_turn_order()

func _build_turn_order() -> void:
    # 속도 높은 순 정렬, 동점은 랜덤
    _turn_queue = _combatants.duplicate()
    _turn_queue.shuffle()
    _turn_queue.sort_custom(func(a, b): return a.effective_speed() > b.effective_speed())
    _current_index = 0

func get_current() -> Combatant:
    return _turn_queue[_current_index]

func advance_turn() -> void:
    _current_index = (_current_index + 1) % _turn_queue.size()
    # 모든 행동자가 1턴 돌면 재정렬 (둔화 등 속도 변동 반영)
    if _current_index == 0:
        _build_turn_order()
```

### 6-3. DamageCalculator — 피해 계산 파이프라인

```gdscript
# damage_calculator.gd
extends RefCounted

func calculate(base_atk: int, skill_multiplier: float, target_def: int,
              is_crit: bool, buffs: Dictionary) -> int:
    # 1. 기본 피해
    var raw: int = floori(float(base_atk) * skill_multiplier)
    # 2. 치명타
    if is_crit:
        raw = floori(float(raw) * 1.5)
    # 3. 버프/디버프 보정
    if buffs.has("attack_up"):
        raw = floori(float(raw) * (1.0 + buffs["attack_up"]))
    if buffs.has("weakened"):
        raw = floori(float(raw) * 0.7)  # 약화: 피해 30% 감소
    # 4. 방어력 차감
    var final_damage: int = maxi(1, raw - target_def)
    return final_damage

func roll_crit(crit_rate: float) -> bool:
    return randf() < crit_rate
```

> **테스트**: 순수 함수이므로 GUT에서 `DamageCalculator.new().calculate(...)` 로 직접 검증 가능

### 6-4. StatusEffectSystem — 상태이상

```gdscript
# status_effect_system.gd
extends RefCounted

enum EffectId { BLEED, BURN, SLOW, WEAKEN, SHATTER, STUN }

# 턴 시작/종료에 호출
func process_turn_start(combatant: Combatant) -> void:
    for effect in combatant.active_effects:
        match effect.id:
            EffectId.BLEED:
                combatant.take_flat_damage(effect.stacks * 3)
            EffectId.BURN:
                combatant.take_flat_damage(effect.stacks * 2)
            EffectId.STUN:
                combatant.set_stunned(true)

func process_turn_end(combatant: Combatant) -> void:
    var expired: Array[StatusEffect] = []
    for effect in combatant.active_effects:
        effect.remaining_turns -= 1
        if effect.remaining_turns <= 0:
            expired.append(effect)
    for e in expired:
        combatant.remove_effect(e)
        EventBus.status_removed.emit(combatant, e.id)
```

### 6-5. EnemyAI — 적 행동 결정

```gdscript
# enemy_ai.gd
extends RefCounted

func decide_action(enemy: EnemyUnit, party: Array[PartyMember],
                   enemies: Array[EnemyUnit]) -> BattleAction:
    var table = enemy.ai_priority_table  # JSON에서 로드
    # 우선순위표의 조건 평가 후, 가능한 행동 중 가중치 랜덤 선택
    var candidates = _evaluate_priorities(table, party, enemies)
    return _weighted_random_select(candidates)

func _evaluate_priorities(table: Array, party, enemies) -> Array:
    var valid = []
    for entry in table:
        if _check_condition(entry.condition, party, enemies):
            valid.append(entry)
    return valid

func _weighted_random_select(candidates: Array) -> BattleAction:
    var total_weight = 0
    for c in candidates:
        total_weight += c.weight
    var roll = randi() % total_weight
    var cumulative = 0
    for c in candidates:
        cumulative += c.weight
        if roll < cumulative:
            return BattleAction.new(c.action_id, c.target_type)
    return candidates[-1]  # fallback
```

### 6-6. 보스 2페이즈

```gdscript
# battle_engine.gd 내부
func _check_boss_phase_transition() -> void:
    for enemy in _enemies:
        if enemy.is_boss and enemy.current_hp <= enemy.max_hp * 0.5 \
           and not enemy.phase_2_triggered:
            enemy.phase_2_triggered = true
            enemy.enter_phase_2()  # 스탯 변화, 새 스킬 해금, 패턴 변경
            EventBus.boss_phase_changed.emit(enemy)
```

---

## 7. 맵 시스템

### 7-1. MapGenerator — 노드 그래프 생성

```gdscript
# map_generator.gd
extends Node

const FLOOR_CONFIGS = {
    1: { node_count_range = [3, 4], boss_required = false },
    2: { node_count_range = [3, 4], boss_required = false },
    3: { node_count_range = [3, 4], boss_required = true },  # 최종 보스
}

enum NodeType { BATTLE, EVENT, TREASURE, SHOP, CAMPFIRE, UNIQUE, BOSS }

func generate_floor(floor_num: int) -> Array[MapNode]:
    var config = FLOOR_CONFIGS[floor_num]
    var count = randi_range(config.node_count_range[0], config.node_count_range[1])
    var nodes: Array[MapNode] = []
    # 마지막 노드: 보스 (3층) 또는 일반
    if floor_num == 3 or config.boss_required:
        nodes.append(MapNode.new(NodeType.BOSS, _get_boss_id(floor_num)))
        count -= 1
    # 나머지 노드: 가중치 랜덤으로 타입 결정
    for i in count:
        var type = _roll_node_type(floor_num)
        nodes.append(MapNode.new(type, _get_node_data(type)))
    nodes.shuffle()
    return nodes
```

### 7-2. MapNode

```gdscript
# map_node.gd
extends RefCounted

var type: MapGenerator.NodeType
var data_id: String          # EnemyTable/EventTable 등의 ID 참조
var visited: bool = false

func _init(p_type: MapGenerator.NodeType, p_data_id: String) -> void:
    type = p_type
    data_id = p_data_id
```

---

## 8. 이벤트 시스템

### 8-1. EventResolver — 선택지 평가

```gdscript
# event_resolver.gd
extends RefCounted

func resolve(event_id: String, choice_id: String) -> Dictionary:
    var event_data = DataTables.get_event(event_id)
    var choice = _find_choice(event_data.choices, choice_id)
    # 조건 평가
    if choice.has("condition"):
        if not _check_condition(choice.condition):
            return _apply_result(choice.failure_result)
    # 성공 판정 (확률 기반 or 스탯 기반)
    if choice.has("success_rate"):
        if randf() < choice.success_rate:
            return _apply_result(choice.success_result)
        return _apply_result(choice.failure_result)
    # 조건 없는 선택지는 바로 적용
    return _apply_result(choice.result)

func _check_condition(cond: Dictionary) -> bool:
    match cond.type:
        "gold":
            return RunState.wallet.gold >= cond.value
        "relic":
            return RunState.inventory.has_relic(cond.id)
        "hp_threshold":
            return RunState.party.any(func(m): return m.hp_ratio() >= cond.value)
    return true
```

### 8-2. 숨겨진 선택지

```json
// EventTable.json 예시
{
  "id": "mysterious_shrine",
  "choices": [
    { "id": "pray", "label": "기도하기", "success_rate": 0.6,
      "success_result": { "relic": "holy_amulet" },
      "failure_result": { "damage_all": 15 } },
    { "id": "ignore", "label": "무시하기", "result": {} },
    { "id": "secret_donate", "label": "황금을 바치다",
      "hidden": true,
      "condition": { "type": "gold", "value": 50 },
      "result": { "relic": "golden_faith", "gold_cost": 50 } }
  ]
}
```

- `hidden: true` 인 선택지는 기본 표시되지 않음
- 조건(`condition`)을 만족할 때만 UI에 노출

---

## 9. 보상 시스템

### 9-1. RewardPool — 가중치 랜덤 보상

```gdscript
# reward_pool.gd
extends RefCounted

func roll_rewards(pool_id: String, count: int = 1) -> Array[Dictionary]:
    var pool = DataTables.get_reward_pool(pool_id)
    var results: Array[Dictionary] = []
    for i in count:
        var entry = _weighted_random(pool.entries)
        var reward = _resolve_reward(entry)
        results.append(reward)
    return results

func _weighted_random(entries: Array) -> Dictionary:
    var total = entries.reduce(func(sum, e): return sum + e.weight, 0)
    var roll = randi() % total
    var acc = 0
    for e in entries:
        acc += e.weight
        if roll < acc:
            return e
    return entries[-1]

func _resolve_reward(entry: Dictionary) -> Dictionary:
    match entry.type:
        "gold":        return { "type": "gold", "amount": entry.amount }
        "equipment":   return { "type": "equipment", "id": entry.id }
        "relic":       return { "type": "relic", "id": entry.id }
        "potion":      return { "type": "potion", "id": entry.id, "count": entry.get("count", 1) }
        _:             return {}
```

### 9-2. 보상 출처별 풀 ID 규칙

| 출처 | 풀 ID 규칙 | 예시 |
|------|------------|------|
| 일반 전투 | `battle_floor{N}` | `battle_floor1` |
| 보스 전투 | `boss_{boss_id}` | `boss_kraken` |
| 이벤트 | 이벤트 데이터 내장 | — |
| 보물 상자 | `treasure_floor{N}` | `treasure_floor2` |

---

## 10. 인벤토리 & 경제

### 10-1. InventoryManager

```gdscript
# inventory_manager.gd
extends RefCounted

const MAX_EQUIPMENT_SLOTS = 6
const MAX_RELIC_SLOTS = 4
const MAX_POTION_STACK = 5

var equipment_bags: Array[Dictionary] = []   # [{id, slot_type, enhance_level}]
var relics: Array[String] = []                # 유물 ID 목록
var potions: Dictionary = {}                  # {potion_id: count}

func add_equipment(eq_id: String) -> bool:
    if equipment_bags.size() >= MAX_EQUIPMENT_SLOTS:
        return false
    var data = DataTables.get_equipment(eq_id)
    equipment_bags.append({
        "id": eq_id,
        "slot_type": data.slot_type,  # weapon / armor / accessory / trinket
        "enhance_level": 0
    })
    EventBus.item_acquired.emit(eq_id, "equipment")
    return true

func add_relic(relic_id: String) -> bool:
    if relics.size() >= MAX_RELIC_SLOTS:
        return false
    relics.append(relic_id)
    EventBus.item_acquired.emit(relic_id, "relic")
    return true

func add_potion(potion_id: String, count: int = 1) -> void:
    var current = potions.get(potion_id, 0)
    var new_count = mini(current + count, MAX_POTION_STACK)
    potions[potion_id] = new_count
    EventBus.item_acquired.emit(potion_id, "potion")
```

### 10-2. EquipmentSlot — 장비 장착

```gdscript
# equipment_slot.gd
extends RefCounted

enum SlotType { WEAPON, ARMOR, ACCESSORY, TRINKET }

# PartyMember가 소유
var weapon: Dictionary = {}
var armor: Dictionary = {}
var accessory: Dictionary = {}
var trinket: Dictionary = {}

func equip(item: Dictionary) -> Dictionary:
    # 기존 장비 반환 (교체), 빈 슬롯이면 {} 반환
    var slot_name = item.slot_type.to_lower()
    var old = get(slot_name)
    set(slot_name, item)
    return old

func get_all_equipped() -> Array[Dictionary]:
    return [weapon, armor, accessory, trinket].filter(func(e): return not e.is_empty())
```

### 10-3. Wallet

```gdscript
# wallet.gd
extends RefCounted

var gold: int = 0

func add(amount: int) -> void:
    gold += amount
    EventBus.gold_changed.emit(gold)

func spend(amount: int) -> bool:
    if gold < amount:
        return false
    gold -= amount
    EventBus.gold_changed.emit(gold)
    return true

func can_afford(amount: int) -> bool:
    return gold >= amount
```

### 10-4. 장비 강화

```gdscript
# inventory_manager.gd 내부
func enhance_equipment(bag_index: int) -> bool:
    if bag_index >= equipment_bags.size():
        return false
    var item = equipment_bags[bag_index]
    if item.enhance_level >= 3:
        return false
    var cost = (item.enhance_level + 1) * 50  # +1: 50G, +2: 100G, +3: 150G
    if not RunState.wallet.spend(cost):
        return false
    item.enhance_level += 1
    return true
```

---

## 11. 데이터 로딩 — DataTables

### 11-1. 설계 방침

- **JSON 파일을 직접 로드** — Godot `Resource` (`@export`)는 MVP에서 과한 추상화
- `_ready()` 시 전체 테이블을 메모리에 캐시
- 접근은 `DataTables.get_xxx(id)` 형태의 팩토리 메서드

### 11-2. 구현

```gdscript
# data_tables.gd
extends Node

var _tables: Dictionary = {}

func _ready() -> void:
    _load_table("CharacterTable")
    _load_table("SkillTable")
    _load_table("EnemyTable")
    _load_table("RelicTable")
    _load_table("EquipmentTable")
    _load_table("NodeTable")
    _load_table("EventTable")
    _load_table("RewardTable")

func _load_table(name: String) -> void:
    var path = "res://data/tables/%s.json" % name
    var file = FileAccess.open(path, FileAccess.READ)
    var json = JSON.new()
    var err = json.parse(file.get_as_text())
    if err == OK:
        _tables[name] = json.data  # Array 또는 Dictionary
    else:
        push_error("DataTable load failed: %s — %s" % [name, json.get_error_message()])

# ── 접근자 ──

func get_character(id: String) -> Dictionary:
    return _find_by_id("CharacterTable", id)

func get_skill(id: String) -> Dictionary:
    return _find_by_id("SkillTable", id)

func get_enemy(id: String) -> Dictionary:
    return _find_by_id("EnemyTable", id)

func get_characters() -> Dictionary:
    # 모든 캐릭터 (id → data 맵으로 변환)
    var result = {}
    for entry in _tables["CharacterTable"]:
        result[entry.id] = entry
    return result

func get_event(id: String) -> Dictionary:
    return _find_by_id("EventTable", id)

func get_reward_pool(pool_id: String) -> Dictionary:
    return _find_by_id("RewardTable", pool_id)

func get_equipment(id: String) -> Dictionary:
    return _find_by_id("EquipmentTable", id)

func _find_by_id(table_name: String, id: String) -> Dictionary:
    for entry in _tables[table_name]:
        if entry.id == id:
            return entry
    push_error("DataTables: %s id='%s' not found" % [table_name, id])
    return {}

# ── 테스트용: 외부에서 테이블 주입 ──
func inject_table(name: String, data) -> void:
    _tables[name] = data
```

### 11-3. JSON 스키마 예시

```json
// CharacterTable.json
[
  {
    "id": "warrior",
    "name": "전위 검사",
    "role": "dps",
    "base_hp": 120, "base_atk": 18, "base_def": 8, "base_speed": 12,
    "crit_rate": 0.15,
    "skills": ["slash", "heavy_strike", "war_cry"]
  },
  {
    "id": "guardian",
    "name": "방패 수호자",
    "role": "tank",
    "base_hp": 180, "base_atk": 10, "base_def": 16, "base_speed": 8,
    "crit_rate": 0.05,
    "skills": ["shield_bash", "taunt", "fortify"]
  },
  {
    "id": "mage",
    "name": "현자",
    "role": "support",
    "base_hp": 80, "base_atk": 22, "base_def": 5, "base_speed": 14,
    "crit_rate": 0.10,
    "skills": ["fireball", "heal", "barrier"]
  }
]
```

```json
// SkillTable.json
[
  {
    "id": "slash",
    "name": "베기",
    "type": "damage",
    "multiplier": 1.0,
    "target": "single_enemy",
    "mp_cost": 0,
    "cooldown": 0,
    "status_apply": null
  },
  {
    "id": "fireball",
    "name": "화염구",
    "type": "damage",
    "multiplier": 1.8,
    "target": "all_enemies",
    "mp_cost": 15,
    "cooldown": 2,
    "status_apply": { "id": "burn", "chance": 0.4, "stacks": 1, "duration": 3 }
  }
]
```

```json
// EnemyTable.json
[
  {
    "id": "goblin_scout",
    "name": "고블린 정찰병",
    "hp": 40, "atk": 8, "def": 3, "speed": 14,
    "is_boss": false,
    "skills": ["goblin_stab"],
    "ai_table": "goblin_scout_ai",
    "rewards": "battle_floor1"
  },
  {
    "id": "kraken",
    "name": "크라켄",
    "hp": 300, "atk": 22, "def": 12, "speed": 10,
    "is_boss": true,
    "skills": ["tentacle_slam", "ink_cloud", "devour"],
    "phase2_skills": ["rage_tentacle", "tidal_wave", "devour"],
    "ai_table": "kraken_ai",
    "rewards": "boss_kraken"
  }
]
```

---

## 12. 씬 전환 & 데이터 전달

### 12-1. SceneManager 오토로드

```gdscript
# scene_manager.gd
extends Node

@onready var _switcher: Control = get_node("/root/Main/SceneSwitcher")

var _current_scene: Node = null
var _transitioning: bool = false

func go_to(target: String, params: Dictionary = {}) -> void:
    if _transitioning:
        return
    _transitioning = true
    var scene_path = _resolve_path(target)
    # 페이드아웃 → 씬 교체 → 페이드인
    _fade_out()
    await _fade_out_completed
    _unload_current()
    _load_scene(scene_path, params)
    _fade_in()
    await _fade_in_completed
    _transitioning = false
    EventBus.scene_transition_completed.emit(target)

func _resolve_path(target: String) -> String:
    match target:
        "title":       return "res://scenes/title/title_screen.tscn"
        "map":         return "res://scenes/map/map_screen.tscn"
        "battle":      return "res://scenes/battle/battle_screen.tscn"
        "event":       return "res://scenes/event/event_screen.tscn"
        "treasure":    return "res://scenes/treasure/treasure_screen.tscn"
        "shop":        return "res://scenes/shop/shop_screen.tscn"
        "campfire":    return "res://scenes/campfire/campfire_screen.tscn"
        "boss_result": return "res://scenes/boss_result/boss_result_screen.tscn"
        "run_over":    return "res://scenes/run_over/run_over_screen.tscn"
        _:             return "res://scenes/title/title_screen.tscn"

func _load_scene(path: String, params: Dictionary) -> void:
    var packed = load(path)
    _current_scene = packed.instantiate()
    _switcher.add_child(_current_scene)
    # 씬이 init(params) 메서드를 가지면 호출
    if _current_scene.has_method("init"):
        _current_scene.init(params)
```

### 12-2. 씬 간 데이터 전달 패턴

데이터는 **RunState 오토로드**를 통해 전달. `params` 딕셔너리는 최소 정보만:

```gdscript
# 맵 씬에서 전투 씬으로 이동 시
func _on_battle_node_selected(node: MapNode) -> void:
    SceneManager.go_to("battle", { "enemy_ids": ["goblin_scout", "goblin_scout"] })
    # RunState에서 파티/인벤토리를 읽으므로 params는 최소화

# 전투 씬의 init
func init(params: Dictionary) -> void:
    var enemy_ids: Array = params.get("enemy_ids", [])
    _battle_engine.setup(enemy_ids)
```

### 12-3. 화면 흐름도

```
[타이틀] ──새런──→ [맵]
                        │
                    노드 선택
                   /    |    \
              [전투] [이벤트] [보물] [상점] [모닥불]
                │        │       │       │       │
              승리/패배  결과    획득    구매    회복
                │        │       │       │       │
                └────────┴───────┴───────┴───────┘
                                  │
                             [맵] ← 돌아오기
                                  │
                           3층 보스 노드
                                  │
                           [보스전] → [보스결과] → [맵] or [런종료]
```

---

## 13. 세이브/로드

### 13-1. SaveManager 오토로드

```gdscript
# save_manager.gd
extends Node

const PERSISTENT_PATH = "user://persistent.json"
const RUN_SAVE_PATH = "user://run_save.json"

# ── 영구 데이터 (해금 등) ──

func load_persistent() -> Dictionary:
    if not FileAccess.file_exists(PERSISTENT_PATH):
        return _default_persistent()
    var file = FileAccess.open(PERSISTENT_PATH, FileAccess.READ)
    var json = JSON.new()
    json.parse(file.get_as_text())
    return json.data

func save_persistent(data: Dictionary) -> void:
    var file = FileAccess.open(PERSISTENT_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "\t"))

func _default_persistent() -> Dictionary:
    return {
        "unlocked_bosses": [],
        "unlocked_items": [],
        "unlocked_acts": [1],      # 1막은 기본 해금
        "total_runs": 0,
        "total_wins": 0,
    }

func unlock_boss(boss_id: String) -> void:
    var data = load_persistent()
    if boss_id not in data.unlocked_bosses:
        data.unlocked_bosses.append(boss_id)
        # 1막 보스 클리어 → 2막 해금
        if boss_id == "act1_final_boss" and 2 not in data.unlocked_acts:
            data.unlocked_acts.append(2)
        save_persistent(data)

# ── 런 세이브 (선택 기능) ──

func save_run() -> void:
    var data = RunState.serialize()
    var file = FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "\t"))

func load_run() -> bool:
    if not FileAccess.file_exists(RUN_SAVE_PATH):
        return false
    var file = FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
    var json = JSON.new()
    if json.parse(file.get_as_text()) != OK:
        return false
    RunState.deserialize(json.data)
    return true

func delete_run_save() -> void:
    if FileAccess.file_exists(RUN_SAVE_PATH):
        DirAccess.remove_absolute(RUN_SAVE_PATH)
```

### 13-2. RunState 직렬화

```gdscript
# run_state.gd 내부

func serialize() -> Dictionary:
    return {
        "current_floor": current_floor,
        "floors_cleared": floors_cleared,
        "bosses_defeated": bosses_defeated,
        "nodes_visited": nodes_visited,
        "party": party.map(func(m): return m.serialize()),
        "inventory": inventory.serialize(),
        "wallet": { "gold": wallet.gold },
    }

func deserialize(data: Dictionary) -> void:
    current_floor = data.current_floor
    floors_cleared = data.floors_cleared
    bosses_defeated = data.bosses_defeated
    nodes_visited = data.nodes_visited
    wallet = Wallet.new()
    wallet.gold = data.wallet.gold
    inventory = InventoryManager.new()
    inventory.deserialize(data.inventory)
    party.clear()
    for pd in data.party:
        party.append(PartyMember.deserialize(pd))
```

---

## 14. 해금 시스템

```gdscript
# save_manager.gd의 unlock 시리즈

func is_act_unlocked(act_num: int) -> bool:
    var data = load_persistent()
    return act_num in data.unlocked_acts

func is_boss_unlocked(boss_id: String) -> bool:
    var data = load_persistent()
    return boss_id in data.unlocked_bosses

func increment_total_runs() -> void:
    var data = load_persistent()
    data.total_runs += 1
    save_persistent(data)

func increment_total_wins() -> void:
    var data = load_persistent()
    data.total_wins += 1
    save_persistent(data)
```

> **MVP 범위**: 해금은 데이터만 관리. 2막 실제 콘텐츠는 MVP 이후.

---

## 15. 테스트 전략

### 15-1. 테스트 가능성 설계

- `DamageCalculator`, `TurnManager`, `StatusEffectSystem`, `EnemyAI`, `RewardPool`, `EventResolver` 등 핵심 로직은 모두 `RefCounted` (Nodeless)
- Godot 의존이 없으므로 GUT에서 직접 인스턴스화하여 테스트 가능
- `DataTables.inject_table()` 로 테스트용 데이터 주입 가능

### 15-2. 테스트 예시

```gdscript
# tests/test_damage_calculator.gd
extends GutTest

var calc: DamageCalculator

func before_each():
    calc = DamageCalculator.new()

func test_normal_damage():
    var result = calc.calculate(20, 1.0, 5, false, {})
    assert_eq(result, 15)  # 20*1.0 - 5 = 15

func test_critical_damage():
    var result = calc.calculate(20, 1.0, 5, true, {})
    assert_eq(result, 25)  # floor(20*1.0*1.5) - 5 = 25

func test_minimum_damage():
    var result = calc.calculate(5, 0.5, 10, false, {})
    assert_eq(result, 1)  # floor(5*0.5) - 10 = -8 → max(1, -8) = 1

func test_weakened_debuff():
    var result = calc.calculate(20, 1.0, 5, false, {"weakened": true})
    assert_eq(result, 10)  # floor(floor(20*1.0)*0.7) - 5 = floor(14) - 5 = 9
```

```gdscript
# tests/test_reward_pool.gd
extends GutTest

func test_weighted_random_deterministic():
    # inject_table로 고정 데이터 사용
    var pool = RewardPool.new()
    # 가중치가 100:0이면 항상 첫 항목
    var results = []
    for i in 100:
        results.append(pool._weighted_random([
            {"id": "gold_50", "weight": 100},
            {"id": "relic_rare", "weight": 0}
        ]).id)
    assert_eq(results.all(func(r): return r == "gold_50"), true)
```

### 15-3. 테스트 실행

```
프로젝트 설정 → GUT 플러그인 추가
명령줄: godot --path . --script addons/gut/gut_cmdln.gd -dtest=tests/
```

---

## 부록 A: 전체 씬 전환 시그널 흐름

```
MapScreen
  └─ node_selected(node)
       └─ SceneManager.go_to("battle", {enemy_ids: [...]})
            └─ BattleScreen.init(params)
                 └─ BattleEngine.setup(enemy_ids)
                      └─ BattleEngine.start_battle()
                           └─ EventBus.battle_started.emit()
                                ...
                           └─ EventBus.battle_ended.emit(victory, rewards)
                                └─ BattleScreen._on_battle_ended()
                                     └─ SceneManager.go_to("map")
                                          └─ MapScreen.init() → map 갱신
```

## 부록 B: JSON 테이블 ID 네이밍 컨벤션

| 테이블 | ID 형식 | 예시 |
|--------|---------|------|
| CharacterTable | snake_case | `warrior`, `guardian`, `mage` |
| SkillTable | snake_case | `heavy_strike`, `fireball`, `shield_bash` |
| EnemyTable | snake_case | `goblin_scout`, `skeleton_knight`, `kraken` |
| RelicTable | snake_case | `holy_amulet`, `golden_faith` |
| EquipmentTable | snake_case | `iron_sword`, `leather_armor` |
| EventTable | snake_case | `mysterious_shrine`, `wandering_merchant` |
| RewardTable | 소문자_밀줄 | `battle_floor1`, `boss_kraken`, `treasure_floor2` |
| NodeTable | 사용 안 함 (MapGenerator가 직접 생성) | — |

---

*문서 버전: v0.1 Draft | 작성일: 2026-04-26*
