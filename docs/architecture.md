# 로그라이크 RPG — 아키텍처 설계서 (v0.3 Draft)

> Godot 4 · GDScript · 1막 MVP · 3-Tier Presentation

---

## 목차


---

---

## 0. 프레젠테이션 3계층 아키텍처

게임 로직과 프레젠테이션을 분리하여 3단계로 개발. 아래 계층(로직)은 상위 계층(프레젠테이션)에 의존하지 않음.

```
┌─────────────────────────────────────────────┐
│          Layer 3: 그래픽 (출시용)            │
│     Godot 씬 (BattleScreen, MapScreen, ...)  │
├─────────────────────────────────────────────┤
│          Layer 2: 텍스트 터미널 (개발용)      │
│     RichTextLabel 기반 텍스트 어드벤처 UI    │
├─────────────────────────────────────────────┤
│          Layer 1: Headless (시뮬레이션)       │
│     godot --headless, 화면 없이 로직만 실행   │
├─────────────────────────────────────────────┤
│          Core: 순수 로직 계층 (모든 계층 공유) │
│  BattleManager, TurnManager, DamageCalculator │
│  MapGenerator, RewardGenerator, EventManager  │
│  Inventory, RewardManager, Unit               │
├─────────────────────────────────────────────┤
│          GameRunner (인터페이스 계층)         │
│  로직 결과를 프레젠테이션으로 브릿징          │
└─────────────────────────────────────────────┘
```

### 0-1. 각 계층 설명

| 계층 | 목적 | 실행 방식 | 주요 용도 |
|------|------|----------|----------|
| **Headless** | 로직 검증, 밸런싱 | `godot --headless --script simulation.gd` | CI 테스트, 밸런싱 시뮬레이션, 회귀 테스트 |
| **터미널** | 게임플레이 검증 | Godot 에디터/실행파일 | 개발 중 전체 흐름 플레이, 디버깅 |
| **그래픽** | 출시 | Godot 에디터/실행파일 | 최종 제품, UX 검증 |

### 0-2. 개발 진행 순서

```
Core 로직 구현 (RefCounted)
  → Headless로 전투/맵/보상 단위 테스트
    → 터미널 UI로 전체 게임 루프 검증
      → 그래픽 UI 적용
```

### 0-3. GameRunner — 프레젠테이션 브릿지

`GameRunner`는 순수 로직 계층과 프레젠테이션 사이의 얇은 어댑터. 게임 전체 흐름(턴 실행, 노드 진입, 보상 지급 등)을 오케스트레이션하고, 결과를 시그널로 프레젠테이션에 전달.

```gdscript
# game_runner.gd
extends RefCounted

signal battle_state_changed(state: Dictionary)   # 턴, HP, 상태이상 등
signal map_state_changed(state: Dictionary)       # 노드 목록, 현재 위치
signal player_input_requested(choices: Array)     # 프레젠테이션이 입력 UI 표시
signal message_logged(text: String)               # 게임 로그 (터미널/디버그용)
signal run_ended(result: Dictionary)              # 런 결과

var battle_manager: BattleManager
var turn_manager: TurnManager
var map_generator: MapGenerator
# ... 기타 코어 시스템 소유

func start_run(config: Dictionary = {}) -> void:
    _init_party(config)
    _generate_floor(1)
    _enter_first_node()

func execute_player_action(action_id: String, targets: Array = []) -> void:
    var result = battle_manager.execute_action(action_id, targets)
    battle_state_changed.emit(result)
```

각 프레젠테이션 계층은 `GameRunner`의 시그널을 구독:
- **Headless**: 시그널을 로그로 출력, 입력은 스크립트에서 직접 주입
- **터미널**: `RichTextLabel`에 텍스트로 렌더링, 버튼으로 선택지 제공
- **그래픽**: 씬 UI(HUD, 애니메이션 등)로 렌더링

### 0-4. 코어 로직의 Node 의존성 제거 원칙

`GameRunner`와 그 아래 코어 로직은 **`Node`가 아닌 `RefCounted`**로 구현. 이 원칙이 지켜지면 `godot --headless`로 실행 가능.

| 대상 | 기존 | 변경 |
|------|------|------|
| `BattleManager` | `extends Node` | `extends RefCounted` |
| `MapGenerator` | `extends Node` | `extends RefCounted` |
| `GameRunner` | (없음) | `extends RefCounted` |
| `EventBus` | `extends Node` (오토로드) | **오토로드 유지** — 시그널 허브는 Node 필요 |
| `RunState` | `extends Node` (오토로드) | **오토로드 유지** — 싱글톤 필요 |
| `ContentData` | `extends Node` (오토로드) | **오토로드 유지** — 구현체는 `RefCounted`, 주입 방식으로 대체 가능 |
| `SceneManager` | `extends Node` (오토로드) | **그래픽/터미널 전용** — headless에서는 미사용 |

> **참고**: `EventBus`, `RunState`, `ContentData`는 오토로드로 유지하되, headless에서는 `GameRunner`가 이들을 직접 생성/주입하는 방식으로 대체 가능. `SceneManager`는 그래픽/터미널 계층에서만 사용.

## 1. 디렉토리 구조

```
project/
├── project.godot
├── autoload/                    # 오토로드 스크립트
│   ├── event_bus.gd
│   ├── run_state.gd
│   ├── data_tables.gd
│   ├── save_manager.gd
│   ├── scene_manager.gd         # 그래픽/터미널 전용
│   └── game_runner.gd           # 게임 오케스트레이터
├── scenes/
│   ├── terminal/                # Layer 2: 텍스트 터미널
│   │   ├── terminal_screen.tscn
│   │   ├── battle_view.tscn     # 터미널용 전투 뷰
│   │   ├── map_view.tscn        # 터미널용 맵 뷰
│   │   └── components/
│   │       ├── text_log.gd      # RichTextLabel 래퍼
│   │       └── choice_panel.gd  # 텍스트 선택지 UI
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
│   └── rpg/
│       ├── ai/
│       │   ├── enemy_ai.gd
│       │   ├── normal_ai.gd
│       │   ├── pattern_ai.gd
│       │   └── target_selector.gd
│       ├── campfire/
│       │   └── campfire_manager.gd
│       ├── combat/
│       │   ├── battle_manager.gd
│       │   ├── damage_calculator.gd
│       │   ├── turn_manager.gd
│       │   ├── turn_order.gd
│       │   └── unit.gd
│       ├── data/
│       │   ├── base_record.gd
│       │   ├── character_record.gd
│       │   ├── content_data.gd
│       │   ├── enemy_record.gd
│       │   ├── equipment_record.gd
│       │   ├── event_record.gd
│       │   ├── node_record.gd
│       │   ├── relic_record.gd
│       │   ├── reward_record.gd
│       │   ├── skill_record.gd
│       │   └── table_registry.gd
│       ├── equipment/
│       │   ├── enhancement_calculator.gd
│       │   ├── enhancement_costs.gd
│       │   ├── equipment_instance.gd
│       │   ├── equipment_manager.gd
│       │   └── unique_effects.gd
│       ├── events/
│       │   ├── event_base.gd
│       │   ├── event_condition_checker.gd
│       │   ├── event_manager.gd
│       │   ├── event_moonlight_rift.gd
│       │   ├── event_ruin_merchant.gd
│       │   ├── event_ruined_altar.gd
│       │   └── event_sealed_ward.gd
│       ├── inventory/
│       │   ├── inventory.gd
│       │   ├── potion.gd
│       │   └── potion_registry.gd
│       ├── map/
│       │   ├── floor.gd
│       │   ├── map_generator.gd
│       │   ├── map_manager.gd
│       │   ├── map_pipeline.gd
│       │   ├── map_validator.gd
│       │   └── node.gd
│       ├── relics/
│       │   ├── relic_effects.gd
│       │   ├── relic_instance.gd
│       │   └── relic_manager.gd
│       ├── rewards/
│       │   ├── reward_generator.gd
│       │   ├── reward_manager.gd
│       │   └── reward_tables.gd
│       ├── shop/
│       │   ├── shop_manager.gd
│       │   └── shop_pool_generator.gd
│       ├── status/
│       │   ├── bleed_effect.gd
│       │   ├── burn_effect.gd
│       │   ├── effect_chance_calculator.gd
│       │   ├── shatter_effect.gd
│       │   ├── slow_effect.gd
│       │   ├── status_effect.gd
│       │   ├── status_manager.gd
│       │   ├── stun_effect.gd
│       │   └── weaken_effect.gd
│       └── ui/
│           ├── feedback_constants.gd
│           ├── node_icons.gd
│           ├── toast_config.gd
│           ├── ui_constants.gd
│           └── ui_theme.gd
├── data/
│   └── saves/
│       ├── persistent.json      # 해금 등 영구 데이터
│       └── run_save.json        # 런 중단용 세이브 (선택)
├── headless/                    # Layer 1: Headless 시뮬레이션 스크립트
│   ├── simulation.gd           # 전체 런 시뮬레이션
│   ├── balance_test.gd         # 밸런싱 테스트 (N회 런 통계)
│   └── regression_test.gd      # 회귀 테스트
├── resources/                   # Godot Resource (.tres) — 필요시만
└── test/
    ├── test_runner.gd
    └── rpg/
        ├── test_base.gd
        ├── integ_*.gd / test_integ_*.gd
        ├── e2e_*.gd / test_e2e_*.gd
        └── test_*.gd
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
ContentData     → 게임 데이터 제공
RunState        → 런 상태 보관 (ContentData 의존)
SaveManager     → 세이브/로드 (RunState 의존)
SceneManager    → 씬 전환 (EventBus 의존)
```

> **순서가 중요**: 의존 관계의 하위 → 상위 순으로 등록

### 2-3. 전투 씬 (`battle_screen.tscn`)

```
BattleScreen (Control)
├── BackgroundLayer (TextureRect)
├── EnemyArea (Control)
│   └── [Unit instances (is_ally=false) — 동적 생성]
├── PartyArea (Control)
│   └── [CharacterHUD × 3]
├── TurnOrderBar (HBoxContainer)
├── SkillPanel (VBoxContainer)
│   └── [SkillButton × N]
├── BattleLog (RichTextLabel)
├── AnimationPlayer
└── BattleManager (RefCounted)     # 로직 컨트롤러 (Nodeless)
```

### 2-4. 맵 씬 (`map_screen.tscn`)

```
MapScreen (Control)
├── FloorLabel (Label)            # "층 1 / 3"
├── NodeContainer (Control)       # 노드 UI 동적 배치
├── PartyStatusBar (HBoxContainer)
└── MapManager (RefCounted)       # 로직 컨트롤러
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
Unit (RefCounted)                     # 단일 전투원 구현체
├── is_ally: bool                     # 아군/적 구분
├── status_manager: StatusManager
└── equipment_manager: EquipmentManager
│
BattleManager (RefCounted)            # 전투 엔진 (Nodeless — headless 대응)
├── turn_manager: TurnManager
├── damage_calculator: DamageCalculator
├── allies: Array[Unit]
├── enemies: Array[Unit]
│
TurnManager (RefCounted)              # 턴 순서/흐름 관리
TurnOrder (RefCounted)                # 턴 정렬/순회 보조
DamageCalculator (RefCounted)         # 피해 계산 (순수 함수)
StatusManager (RefCounted)            # 상태이상 적용/해제
StatusEffect (RefCounted)             # 상태이상 베이스
├── BleedEffect
├── BurnEffect
├── ShatterEffect
├── SlowEffect
├── StunEffect
└── WeakenEffect
EffectChanceCalculator (RefCounted)   # 상태이상 확률 계산
│
EnemyAI (RefCounted)                  # 적 행동 결정 베이스
├── NormalAI : EnemyAI
├── PatternAI : EnemyAI
└── TargetSelector (RefCounted)
│
MapGenerator (RefCounted)             # 노드 그래프 생성 (Nodeless — headless 대응)
├── Floor (RefCounted)
├── Node (RefCounted)
├── MapValidator (RefCounted)
├── MapPipeline (RefCounted)
└── MapManager (RefCounted)
│
EventManager (RefCounted)             # 이벤트 선택지 평가/실행
├── EventBase (RefCounted)
├── EventConditionChecker (RefCounted)
├── EventRuinedAltar : EventBase
├── EventRuinMerchant : EventBase
├── EventSealedWard : EventBase
└── EventMoonlightRift : EventBase
│
RewardGenerator (RefCounted)          # 보상 생성
RewardTables (RefCounted)             # 보상 테이블
RewardManager (RefCounted)            # 보상 지급/적용
│
Inventory (RefCounted)                # 인벤토리 CRUD
Potion (RefCounted)
PotionRegistry (RefCounted)
EquipmentInstance (RefCounted)        # 장비 인스턴스
EquipmentManager (RefCounted)         # 장비 장착/강화
├── EnhancementCalculator (RefCounted)
├── EnhancementCosts (RefCounted)
└── UniqueEffects (RefCounted)
RelicInstance (RefCounted)
RelicManager (RefCounted)
RelicEffects (RefCounted)
│
CampfireManager (RefCounted)
ShopManager (RefCounted)
ShopPoolGenerator (RefCounted)
│
ContentData (RefCounted)              # 구현 데이터 저장소
├── TableRegistry (RefCounted)
├── BaseRecord (RefCounted)
│   ├── CharacterRecord
│   ├── EnemyRecord
│   ├── EquipmentRecord
│   ├── EventRecord
│   ├── NodeRecord
│   ├── RelicRecord
│   ├── RewardRecord
│   └── SkillRecord
│
UIConstants / UITheme / FeedbackConstants / NodeIcons / ToastConfig (RefCounted)
```

### 3-2. 설계 원칙

| 원칙 | 적용 |
|------|------|
| **Composition over Inheritance** | `BattleManager`가 `TurnManager`, `DamageCalculator` 등을 소유 |
| **순수 로직 분리** | `DamageCalculator`, `RewardGenerator`, `EventManager`는 Godot Node 없이 `RefCounted` — `TestBase` 테스트 용이 |
| **UI와 로직 분리** | 씬의 컨트롤러 노드는 로직만 담고, UI는 시그널로 구독 |
| **데이터와 행동 분리** | `Unit`은 전투 상태를 보유하고, 전투 흐름은 `BattleManager`가 수행 |
| **프레젠테이션 3계층** | Headless → 터미널 → 그래픽. `GameRunner`가 로직과 UI 사이 브릿지 |
| **코어 Nodeless** | `BattleManager`, `MapGenerator`, `GameRunner`는 `RefCounted` — headless 호환 |

---

## 4. 상태 관리 — RunState

### 4-1. RunState 오토로드

런 전체의 휘발성 상태를 보관하는 싱글턴. 런 시작 시 초기화, 런 종료/사망 시 폐기.

```gdscript
# run_state.gd
extends Node

# ── 파티 ──
var party: Array[Unit] = []

# ── 맵 ──
var current_floor: int = 1
var current_node_index: int = -1
var map_graph: Array[Node] = []      # 현재 층 노드 목록

# ── 인벤토리 ──
var inventory: Inventory

# ── 진행 ──
var floors_cleared: int = 0
var bosses_defeated: Array[String] = [] # 보스 ID 목록
var nodes_visited: int = 0

# ── 보스 ──
var active_boss_id: String = ""

# ── 초기화 ──
func start_new_run() -> void:
    var chars = ContentData.get_characters()
    party.clear()
    for char_id in ["warrior", "guardian", "mage"]:
        var pm = Unit.from_data(char_id)
        party.append(pm)
    inventory = Inventory.new()
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
    current_floor = 1
```

### 4-2. 데이터 소유권 요약

| 데이터 | 보관 위치 | 수명 |
|--------|-----------|------|
| 파티 상태 (HP, 버프 등) | `RunState.party` | 런 동안 |
| 인벤토리 | `RunState.inventory` | 런 동안 |
| 골드 | `RunState` 내 플레이어 상태 Dictionary / `EquipmentManager` | 런 동안 |
| 현재 층/노드 | `RunState.current_floor` | 런 동안 |
| 해금 내역 | `SaveManager` → `persistent.json` | 영구 |
| 게임 데이터 원본 | `ContentData` (메모리 캐시) | 앱 생존 |
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
signal turn_started(unit: Unit)
signal turn_ended(unit: Unit)
signal skill_used(user: Unit, skill_id: String, targets: Array[Unit])
signal damage_dealt(target: Unit, amount: int, is_crit: bool)
signal healing_done(target: Unit, amount: int)
signal status_applied(target: Unit, effect_id: String, stacks: int)
signal status_removed(target: Unit, effect_id: String)
signal combatant_died(unit: Unit)

# ── 맵 ──
signal floor_entered(floor_num: int)
signal node_selected(node: Node)
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

func _on_damage_dealt(target: Unit, amount: int, is_crit: bool) -> void:
    # 데미지 팝업 표시
    _show_damage_popup(target, amount, is_crit)
```

---

## 6. 전투 엔진 구조

### 6-1. BattleManager — 전체 흐름

```
BattleManager (RefCounted)
│
│  1. setup(enemy_ids)          — 적 생성, 턴 큐 초기화
│  2. start_battle()            — 첫 턴 시작
│  3. [턴 루프]
│     ├─ TurnManager.next_turn()
│     ├─ 현재 행동자가 아군 Unit → 플레이어 입력 대기 (SkillPanel 활성화)
│     ├─ 현재 행동자가 적 Unit → EnemyAI.decide_action()
│     ├─ execute_action(action) → DamageCalculator + StatusManager
│     ├─ 턴 종료 처리 (도트 데미지, 상태이상 턴 감소)
│     └─ 승리/패배 판정
│  4. end_battle(victory)
│
└── 하위 시스템 (composition)
    ├── TurnManager
    ├── DamageCalculator
    ├── StatusManager
    └── EnemyAI
```

### 6-2. TurnManager — 속도 기반 턴 순서

```gdscript
# turn_manager.gd
extends RefCounted

var _combatants: Array[Unit] = []
var _turn_queue: Array[Unit] = []
var _current_index: int = 0

func setup(combatants: Array[Unit]) -> void:
    _combatants = combatants
    _build_turn_order()

func _build_turn_order() -> void:
    # 속도 높은 순 정렬, 동점은 랜덤
    _turn_queue = _combatants.duplicate()
    _turn_queue.shuffle()
    _turn_queue.sort_custom(func(a, b): return a.effective_speed() > b.effective_speed())
    _current_index = 0

func get_current() -> Unit:
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

> **테스트**: 순수 함수이므로 `TestBase` 기반 테스트에서 `DamageCalculator.new().calculate(...)` 로 직접 검증 가능

### 6-4. StatusManager — 상태이상

```gdscript
# status_manager.gd
extends RefCounted

enum EffectId { BLEED, BURN, SLOW, WEAKEN, SHATTER, STUN }

# 턴 시작/종료에 호출
func process_turn_start(combatant: Unit) -> void:
    for effect in combatant.active_effects:
        match effect.id:
            EffectId.BLEED:
                combatant.take_flat_damage(effect.stacks * 3)
            EffectId.BURN:
                combatant.take_flat_damage(effect.stacks * 2)
            EffectId.STUN:
                combatant.set_stunned(true)

func process_turn_end(combatant: Unit) -> void:
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

func decide_action(enemy: Unit, party: Array[Unit],
                   enemies: Array[Unit]) -> BattleAction:
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
# battle_manager.gd 내부
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
extends RefCounted

const FLOOR_CONFIGS = {
    1: { node_count_range = [3, 4], boss_required = false },
    2: { node_count_range = [3, 4], boss_required = false },
    3: { node_count_range = [3, 4], boss_required = true },  # 최종 보스
}

enum NodeType { BATTLE, EVENT, TREASURE, SHOP, CAMPFIRE, UNIQUE, BOSS }

func generate_floor(floor_num: int) -> Array[Node]:
    var config = FLOOR_CONFIGS[floor_num]
    var count = randi_range(config.node_count_range[0], config.node_count_range[1])
    var nodes: Array[Node] = []
    # 마지막 노드: 보스 (3층) 또는 일반
    if floor_num == 3 or config.boss_required:
        nodes.append(Node.new(NodeType.BOSS, _get_boss_id(floor_num)))
        count -= 1
    # 나머지 노드: 가중치 랜덤으로 타입 결정
    for i in count:
        var type = _roll_node_type(floor_num)
        nodes.append(Node.new(type, _get_node_data(type)))
    nodes.shuffle()
    return nodes
```

### 7-2. Node

```gdscript
# node.gd
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

### 8-1. EventManager + EventBase — 선택지 평가

```gdscript
# event_manager.gd
extends RefCounted

func resolve_choice(event_id: String, choice_id: String, context: Dictionary) -> Dictionary:
    var event_data = ContentData.get_event(event_id)
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
            return context.player.get("gold", 0) >= cond.value
        "relic":
            return RunState.inventory.has_relic(cond.id)
        "hp_threshold":
            return context.party.any(func(m): return m.hp_ratio() >= cond.value)
    return true
```

- `EventBase`가 공통 선택지/보상 처리 규약을 제공
- `EventConditionChecker`가 조건 판정을 분리
- 구현 이벤트 서브클래스: `EventRuinedAltar`, `EventRuinMerchant`, `EventSealedWard`, `EventMoonlightRift`

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

### 9-1. RewardGenerator + RewardTables + RewardManager — 가중치 랜덤 보상

```gdscript
# reward_generator.gd
extends RefCounted

func generate_rewards(battle_type: String) -> Dictionary:
    var tables = RewardTables.new()
    var rewards = {
        "gold": _roll_gold(battle_type),
        "items": [],
        "relics": [],
        "potions": []
    }
    var item = _roll_item(battle_type)
    if not item.is_empty():
        rewards.items.append(item)
    return rewards

func _weighted_random(entries: Array) -> Dictionary:
    var total = entries.reduce(func(sum, e): return sum + e.weight, 0)
    var roll = randi() % total
    var acc = 0
    for e in entries:
        acc += e.weight
        if roll < acc:
            return e
    return entries[-1]

func grant_rewards(rewards: Dictionary, inventory: Inventory) -> Dictionary:
    return RewardManager.new().grant_rewards(rewards, inventory)
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

### 10-1. Inventory

```gdscript
# inventory.gd
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
    var data = ContentData.get_equipment(eq_id)
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

### 10-2. EquipmentInstance + EquipmentManager — 장비 장착

```gdscript
# equipment_manager.gd
extends RefCounted

enum SlotType { WEAPON, ARMOR, ACCESSORY, TRINKET }

# Unit이 소유
var weapon: EquipmentInstance = null
var armor: EquipmentInstance = null
var accessory: EquipmentInstance = null
var trinket: EquipmentInstance = null

func equip(item: Dictionary) -> Dictionary:
    # 기존 장비 반환 (교체), 빈 슬롯이면 {} 반환
    var slot_name = item.slot_type.to_lower()
    var old = get(slot_name)
    set(slot_name, item)
    return old

func get_all_equipped() -> Array[EquipmentInstance]:
    return [weapon, armor, accessory, trinket].filter(func(e): return not e.is_empty())
```

### 10-3. 골드 관리

별도 `Wallet` 클래스는 없고, 골드는 플레이어 상태 Dictionary와 `EquipmentManager`/상점 처리 로직에서 직접 관리.

### 10-4. 장비 강화

```gdscript
# equipment_manager.gd 내부
func enhance_equipment(bag_index: int) -> bool:
    if bag_index >= equipment_bags.size():
        return false
    var item = equipment_bags[bag_index]
    if item.enhance_level >= 3:
        return false
    var cost = (item.enhance_level + 1) * 50  # +1: 50G, +2: 100G, +3: 150G
    if RunState.player_state.get("gold", 0) < cost:
        return false
    RunState.player_state.gold -= cost
    item.enhance_level += 1
    return true
```

- 강화 계산은 `EnhancementCalculator`, 비용 표는 `EnhancementCosts`가 담당
- 고유 옵션 적용은 `UniqueEffects`가 담당

---

## 11. 데이터 로딩 — ContentData + TableRegistry

### 11-1. 설계 방침

- **데이터는 `ContentData` 내부 상수/Dictionary로 임베드**
- `TableRegistry`가 레코드 타입 등록과 조회를 관리
- 접근은 `ContentData.get_xxx(...)` 형태의 조회 메서드

### 11-2. 구현

```gdscript
# content_data.gd
extends RefCounted

var _registry := TableRegistry.new()
var _characters: Array[CharacterRecord] = []
var _enemies: Array[EnemyRecord] = []
var _events: Array[EventRecord] = []

func _init() -> void:
    _registry.register("character", CharacterRecord)
    _registry.register("enemy", EnemyRecord)
    _registry.register("event", EventRecord)
    _registry.register("equipment", EquipmentRecord)
    _registry.register("relic", RelicRecord)
    _registry.register("reward", RewardRecord)
    _registry.register("skill", SkillRecord)
    _registry.register("node", NodeRecord)

# ── 접근자 ──

func get_characters() -> Dictionary:
    return {
        "warrior": CharacterRecord.new(),
        "guardian": CharacterRecord.new(),
        "mage": CharacterRecord.new(),
    }

func get_event(event_id: String) -> Dictionary:
    return _registry.make("event", { "id": event_id }).to_dict()

func get_reward_table(key: String) -> Dictionary:
    return _registry.make("reward", { "id": key }).to_dict()
```

### 11-3. BaseRecord 계층

- `BaseRecord`는 공통 필드/직렬화 규약을 제공
- `CharacterRecord`, `EnemyRecord`, `EquipmentRecord`, `EventRecord`, `NodeRecord`, `RelicRecord`, `RewardRecord`, `SkillRecord`가 실제 데이터 타입
- 데이터는 JSON 파일이 아니라 `ContentData` 내부에 정의되어 있으며, `TableRegistry`가 레코드 생성을 중개

### 11-4. 데이터 예시

```json
const _CHARACTERS := [
  {
    "character_id": "warrior",
    "name": "전위딜러",
    "max_hp": 120,
    "attack": 18,
    "defense": 8,
    "speed": 12
  },
  {
    "character_id": "guardian",
    "name": "수호자",
    "max_hp": 180,
    "attack": 10,
    "defense": 16,
    "speed": 8
  },
  {
    "character_id": "mage",
    "name": "현자",
    "max_hp": 80,
    "attack": 22,
    "defense": 5,
    "speed": 14
  }
]
```

```json
// ContentData 내부 스킬 데이터 예시
{
  "skill_id": "skill_front_charge_slash",
  "name": "돌진베기",
  "mp_cost": 8,
  "target": "single",
  "multiplier": 1.6,
  "status_effects": ["출혈"],
  "status_chance": 0.3
}
```

```json
// ContentData 내부 적 데이터 예시
{
  "enemy_id": "enemy_boss_red_moon_warden",
  "name": "붉은 달의 파수꾼",
  "tier": "boss",
  "max_hp": 450,
  "attack": 22,
  "defense": 8,
  "speed": 10,
  "phases": 2
}
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
        # Layer 2: 터미널 모드
        "terminal":          return "res://scenes/terminal/terminal_screen.tscn"
        "terminal_battle":   return "res://scenes/terminal/battle_view.tscn"
        "terminal_map":      return "res://scenes/terminal/map_view.tscn"
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
func _on_battle_node_selected(node: Node) -> void:
    SceneManager.go_to("battle", { "enemy_ids": ["goblin_scout", "goblin_scout"] })
    # RunState에서 파티/인벤토리를 읽으므로 params는 최소화

# 전투 씬의 init
func init(params: Dictionary) -> void:
    var enemy_ids: Array = params.get("enemy_ids", [])
    _battle_manager.setup(enemy_ids)
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
        "player_state": { "gold": player_state.gold },
    }

func deserialize(data: Dictionary) -> void:
    current_floor = data.current_floor
    floors_cleared = data.floors_cleared
    bosses_defeated = data.bosses_defeated
    nodes_visited = data.nodes_visited
    player_state = data.player_state
    inventory = Inventory.new()
    inventory.deserialize(data.inventory)
    party.clear()
    for pd in data.party:
        party.append(Unit.deserialize(pd))
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

- `DamageCalculator`, `TurnManager`, `StatusManager`, `EnemyAI`, `RewardGenerator`, `EventManager` 등 핵심 로직은 모두 `RefCounted` (Nodeless)
- Godot 의존이 없으므로 커스텀 `TestBase`에서 직접 인스턴스화하여 테스트 가능
- `ContentData`와 생성자 주입 패턴으로 테스트용 데이터/설정을 주입 가능

### 15-2. 테스트 예시

```gdscript
# test/rpg/test_damage_calculator.gd
extends TestBase

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
# test/rpg/test_reward_gold.gd
extends TestBase

func test_weighted_random_deterministic():
    var pool = RewardGenerator.new()
    # 가중치가 100:0이면 항상 첫 항목
    var results = []
    for i in 100:
        results.append(pool.generate_rewards("normal_battle").get("gold", 0) >= 0)
    assert_eq(results.all(func(r): return r), true)
```

### 15-3. 테스트 실행

```
명령줄: godot --headless --quit --script test/test_runner.gd
```

### 15-4. 테스트 구성

- 총 451개 테스트: 단위 419개, 통합 18개, E2E 14개
- `test/test_runner.gd`가 `test/rpg/` 아래 `test_*.gd` 파일을 수집해 실행
- 공통 assertion은 `test/rpg/test_base.gd`
- 통합 테스트는 `test/rpg/test_integ_*.gd`, E2E 테스트는 `test/rpg/test_e2e_*.gd` 패턴으로 관리

### 15-5. Headless 시뮬레이션

`godot --headless`로 화면 없이 로직만 실행. 밸런싱 검증, 회귀 테스트, CI 통합에 사용.

```bash
# 전체 런 시뮬레이션 (1회)
godot --headless --script headless/simulation.gd

# 밸런싱 테스트 (1000회 런, 통계 출력)
godot --headless --script headless/balance_test.gd --count=1000

# 회귀 테스트
godot --headless --script headless/regression_test.gd
```

```gdscript
# headless/simulation.gd 예시
extends SceneTree

func _init() -> void:
    var runner = GameRunner.new()
    runner.message_logged.connect(func(msg): print(msg))
    runner.run_ended.connect(func(result): _print_summary(result); quit())
    runner.start_run()

func _print_summary(result: Dictionary) -> void:
    print("=== 런 결과 ===")
    print("승리: %s" % result.victory)
    print("턴 수: %d" % result.turns)
    print("보스 처치: %s" % str(result.bosses_defeated))
```

### 15-6. 밸런싱 시뮬레이션 예시

```gdscript
# headless/balance_test.gd
extends SceneTree

func _init() -> void:
    var win_count = 0
    var run_count = 1000
    var turn_counts: Array[int] = []

    for i in run_count:
        var runner = GameRunner.new()
        runner.start_run({ "auto_play": true })
        var result = await runner.run_completed
        if result.victory:
            win_count += 1
        turn_counts.append(result.turns)

    print("승률: %.1f%%" % (float(win_count) / run_count * 100))
    print("평균 턴 수: %.1f" % (float(turn_counts.reduce(func(a, b): return a + b, 0)) / run_count)
    quit()
```

---

## 부록 A: 전체 씬 전환 시그널 흐름

```
GameRunner
  └─ start_run()
       └─ _generate_floor()
            └─ map_state_changed.emit()
                 ├─ [그래픽] MapScreen → 노드 UI 표시
                 ├─ [터미널] MapView → 텍스트로 노드 목록 출력
                 └─ [Headless] print() → 로그 출력
       └─ _enter_node(node)
            └─ (전투 노드인 경우)
                 └─ BattleManager.setup(enemy_ids)
                      └─ BattleManager.start_battle()
                           └─ battle_state_changed.emit()
                                ├─ [그래픽] BattleScreen → HUD 업데이트, 애니메이션
                                ├─ [터미널] BattleView → RichTextLabel에 텍스트 출력
                                └─ [Headless] print() → 턴 로그
                           └─ player_input_requested.emit(choices)
                                ├─ [그래픽] SkillPanel 활성화
                                ├─ [터미널] ChoicePanel 버튼 표시
                                └─ [Headless] AI 자동 결정
                           └─ run_ended.emit(result)
```

## 부록 B: 데이터 ID 네이밍 컨벤션

| 테이블 | ID 형식 | 예시 |
|--------|---------|------|
| CharacterRecord | snake_case | `warrior`, `guardian`, `mage` |
| SkillRecord | snake_case | `skill_front_charge_slash`, `skill_guardian_taunt` |
| EnemyRecord | snake_case | `enemy_normal_rust_swordsman`, `enemy_boss_red_moon_warden` |
| RelicRecord | snake_case | `holy_amulet`, `golden_faith` |
| EquipmentRecord | snake_case | `iron_sword`, `leather_armor` |
| EventRecord | snake_case | `mysterious_shrine`, `wandering_merchant` |
| RewardRecord | snake_case | `battle_floor1`, `boss_kraken`, `treasure_floor2` |

> 참고: 구현에서는 JSON 파일이 아니라 `ContentData` 내부 데이터와 `BaseRecord` 파생 레코드를 사용한다.

---

*문서 버전: v0.3 Draft | 작성일: 2026-04-28 — 구현과 일치하도록 클래스/파일명 갱신*
