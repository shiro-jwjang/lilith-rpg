# Implementation Plan

## Goal

Align the current Godot 4.6 + GDScript codebase with `docs/architecture.md` without breaking the existing headless-friendly core or the current `530` passing tests.

This plan is intentionally phased so each phase is:

- independently committable
- independently testable
- backward-compatible with current `GameRunner` tests and terminal flow

The priority order follows the current risk profile:

1. `EventBus` and signal decoupling
2. terminal UI decomposition
3. `RunState` extraction
4. `GameRunner` bootstrap/autoload alignment
5. `SaveManager` / `SceneManager`
6. boss phase 2 and missing headless scripts

## Current State Summary

- `scripts/rpg/game_runner.gd` is the active orchestration layer and already `extends RefCounted`.
- `GameRunner` currently owns a mutable `run_state: Dictionary`.
- `GameRunner` currently defines and emits these direct presentation signals:
  - `battle_state_changed(state: Dictionary)`
  - `map_state_changed(state: Dictionary)`
  - `player_input_requested(choices: Array)`
  - `message_logged(text: String)`
  - `run_ended(result: Dictionary)`
- `scenes/terminal/main.gd` creates `GameRunner` directly.
- `scenes/terminal/terminal_ui.gd` is a single `646` line `Control` that both builds UI and contains gameplay flow logic.
- `project.godot` has an empty `[autoload]` section.
- There is no `autoload/` directory yet.

## Non-Negotiable Rules For Every Phase

- Keep `scripts/rpg/*` core logic classes `RefCounted`.
- Keep `godot --headless --quit --script test/test_runner.gd` green after every phase.
- Do not remove `GameRunner`’s current public methods during the migration.
- Do not remove `GameRunner.run_state: Dictionary` until all callers are migrated and covered by tests.
- Prefer additive compatibility shims first, then caller migration, then cleanup.

## Phase 1: Introduce `EventBus` As The Single Signal Hub

### Purpose

Fix the current bug source first: direct `GameRunner -> terminal_ui` signal coupling. The first phase adds `EventBus` and routes all presentation events through it while preserving the existing `GameRunner` signal API for tests and current callers.

### Files To Create

- `autoload/event_bus.gd`
- `test/rpg/test_event_bus.gd`

### Files To Modify

- `project.godot`
  - register `EventBus="*res://autoload/event_bus.gd"` under `[autoload]`
- `scripts/rpg/game_runner.gd`
  - accept optional injected bus in `_init(config: Dictionary = {})`
    - `var event_bus = _config.get("event_bus", null)`
  - add a private helper for dual emission during migration:
    - `func _emit_presentation_event(signal_name: StringName, payload) -> void`
  - replace direct `emit_signal(...)` calls with dual emission:
    - emit to `EventBus` first
    - emit the legacy `GameRunner` signal second
  - route these current presentation events through `EventBus`:
    - `battle_state_changed(state: Dictionary)`
    - `map_state_changed(state: Dictionary)`
    - `player_input_requested(choices: Array)`
    - `message_logged(text: String)`
    - `run_ended(result: Dictionary)`
  - emit architecture-level domain signals where the data already exists:
    - `battle_started(enemy_ids: Array[String])`
    - `battle_ended(victory: bool, rewards: Dictionary)`
    - `floor_entered(floor_num: int)`
    - `node_selected(node)`
    - `event_choice_made(event_id: String, choice_id: String, result: Dictionary)`
    - `gold_changed(amount: int)`
    - `item_acquired(item_id: String, item_type: String)`
- `scenes/terminal/terminal_ui.gd`
  - stop connecting directly to `runner.*` signals
  - connect to `EventBus.*` instead
  - keep `runner` only for imperative calls such as:
    - `select_node(node_id: String)`
    - `enter_node()`
    - `next_turn()`
    - `player_attack(skill_index: int)`
    - `resolve_event_choice(choice_id: String)`
    - `shop_purchase(item_index: int)`
    - `campfire_rest()`
    - `campfire_invest(stat_name: String)`
    - `complete_node(defer_floor_advance: bool = false)`
- `scenes/terminal/main.gd`
  - no behavioral change required, but explicitly rely on autoloaded `EventBus` being present

### `EventBus` Signal Surface For Phase 1

`autoload/event_bus.gd` should define both:

1. architecture signals from section 5
2. temporary compatibility presentation signals already used by the current terminal layer

Recommended Phase 1 signal list:

```gdscript
extends Node

signal run_started()
signal run_ended(victory: bool)

signal scene_transition_requested(target: String, params: Dictionary)
signal scene_transition_completed(target: String)

signal battle_started(enemy_ids: Array[String])
signal battle_ended(victory: bool, rewards: Dictionary)
signal turn_started(unit)
signal turn_ended(unit)
signal skill_used(user, skill_id: String, targets: Array)
signal damage_dealt(target, amount: int, is_crit: bool)
signal healing_done(target, amount: int)
signal status_applied(target, effect_id: String, stacks: int)
signal status_removed(target, effect_id: String)
signal combatant_died(unit)
signal boss_phase_changed(enemy)

signal floor_entered(floor_num: int)
signal node_selected(node)
signal floor_cleared(floor_num: int)

signal gold_changed(amount: int)
signal item_acquired(item_id: String, item_type: String)
signal item_equipped(party_index: int, slot_type: String, item_id: String)
signal item_removed(item_id: String)

signal event_choice_made(event_id: String, choice_id: String, result: Dictionary)

signal toast_requested(message: String)
signal screen_shake_requested(intensity: float)

# Temporary migration bridge
signal battle_state_changed(state: Dictionary)
signal map_state_changed(state: Dictionary)
signal player_input_requested(choices: Array)
signal message_logged(text: String)
signal run_result_emitted(result: Dictionary)
```

`run_result_emitted(result: Dictionary)` is recommended as a temporary bridge because the architecture signal `run_ended(victory: bool)` does not carry the current summary payload that existing callers expect.

### Tests To Add

- `test/rpg/test_event_bus.gd`
  - `EventBus` exists and is loadable
  - it defines the compatibility and architecture signals listed above
- extend `test/rpg/test_game_runner.gd`
  - assert that `start_run()` emits `EventBus.map_state_changed`
  - assert that `enter_combat()` emits `EventBus.battle_started`
  - assert that boss victory emits both:
    - `EventBus.run_ended(true)`
    - `EventBus.run_result_emitted(result)`
- add a focused terminal wiring test:
  - `test/rpg/test_terminal_event_bus.gd`
  - verify `terminal_ui.gd` can receive a map update through `EventBus` without a direct runner signal connection

### Acceptance Criteria

- Existing `GameRunner` signal tests still pass unchanged.
- `terminal_ui.gd` no longer subscribes directly to `runner.battle_state_changed`, `runner.map_state_changed`, `runner.player_input_requested`, `runner.message_logged`, or `runner.run_ended`.
- One gameplay event produces one terminal update in the web build path.
- All existing tests still pass.

### Risks

- Dual-emitting from `GameRunner` can temporarily double-fire if `terminal_ui.gd` remains subscribed to both layers. Migration must switch terminal subscriptions in the same commit.
- The architecture signal `run_ended(victory: bool)` is narrower than the current `run_ended(result: Dictionary)`. The compatibility bridge must stay until all consumers are updated.

## Phase 2: Extract `RunState` Without Breaking `GameRunner.run_state`

### Purpose

Move run data ownership toward the architecture’s `RunState` singleton while preserving the current dictionary-based API that tests and callers use.

### Files To Create

- `autoload/run_state.gd`
- `test/rpg/test_run_state.gd`

### Files To Modify

- `project.godot`
  - register `RunState="*res://autoload/run_state.gd"` after `EventBus`
- `scripts/rpg/game_runner.gd`
  - accept optional injected state object:
    - `var run_state_store = _config.get("run_state_store", null)`
  - on `start_run()`, initialize both:
    - `RunState.start_new_run(...)` or equivalent
    - compatibility `run_state: Dictionary`
  - add private sync helpers:
    - `func _sync_run_state_dict_from_store() -> void`
    - `func _sync_store_from_run_state_dict() -> void` only where necessary for compatibility
  - move source-of-truth updates for:
    - `current_floor`
    - `floors_cleared`
    - `nodes_visited`
    - `combats_won`
    - `gold_earned`
    - `current_node_id`
    - `victory`
    - `defeat`
    - `ended`
    - `party`
    - `inventory`
  - keep `runner.run_state: Dictionary` populated so current tests continue to pass
- `scenes/terminal/terminal_ui.gd`
  - no functional change required beyond reading summary from runner as before

### Recommended `RunState` API

```gdscript
extends Node

var party: Array = []
var inventory = null
var wallet = null
var current_floor: int = 1
var current_node_id: String = ""
var floors_cleared: int = 0
var nodes_visited: Array = []
var combats_won: int = 0
var gold_earned: int = 0
var victory: bool = false
var defeat: bool = false
var ended: bool = false
var active_boss_id: String = ""

func start_new_run(config: Dictionary = {}) -> void
func reset() -> void
func to_dict() -> Dictionary
func load_from_dict(data: Dictionary) -> void
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

### Tests To Add

- `test/rpg/test_run_state.gd`
  - `start_new_run()` initializes expected defaults
  - `to_dict()` matches current `GameRunner.run_state` shape
  - `serialize()` / `deserialize()` round-trip safely
- extend `test/rpg/test_game_runner.gd`
  - assert `runner.run_state` still behaves like a Dictionary
  - assert `RunState.current_floor` matches `runner.run_state["current_floor"]`
  - assert reward and floor progression update both views consistently

### Acceptance Criteria

- `RunState` exists as an autoload singleton.
- `GameRunner.run_state` remains available as a Dictionary for backward compatibility.
- No current tests need to be rewritten to use `RunState`.
- All existing tests still pass.

### Risks

- Two writable sources of truth can drift. During this phase, `RunState` should become authoritative and `runner.run_state` should be treated as a mirrored compatibility view.

## Phase 3: Decompose `terminal_ui.gd` Into Reusable Components

### Purpose

Break the `646` line terminal UI into architecture-aligned pieces while keeping the same user-visible terminal behavior and the same `main.tscn` entry point.

### Files To Create

- `scenes/terminal/components/text_log.gd`
- `scenes/terminal/components/choice_panel.gd`
- `scenes/terminal/battle_view.gd`
- `scenes/terminal/map_view.gd`
- `scenes/terminal/battle_view.tscn`
- `scenes/terminal/map_view.tscn`
- `test/rpg/test_terminal_components.gd`

### Files To Modify

- `scenes/terminal/terminal_ui.gd`
  - reduce to a shell/composition controller
  - own shared references:
    - `runner`
    - `status_label`
    - `version_label`
    - `TextLog`
    - `ChoicePanel`
    - child `MapView`
    - child `BattleView`
  - move narrative rendering helpers out where possible
- `scenes/terminal/terminal_screen.tscn`
  - keep as the terminal root scene
  - instantiate component nodes instead of relying on one monolithic script

### Proposed Responsibilities

- `scenes/terminal/components/text_log.gd`
  - wrapper around `RichTextLabel`
  - methods:
    - `func append_line(text: String) -> void`
    - `func clear_log() -> void`
    - `func get_plain_text() -> String`
- `scenes/terminal/components/choice_panel.gd`
  - owns choice button creation/cleanup
  - methods:
    - `func clear_choices() -> void`
    - `func set_choices(choices: Array[Dictionary], callback_factory: Callable) -> void`
    - `func add_choice(label: String, callback: Callable) -> void`
- `scenes/terminal/map_view.gd`
  - render map floor header, party overview, node list
  - methods:
    - `func render_map_state(state: Dictionary, party_status: Array) -> void`
- `scenes/terminal/battle_view.gd`
  - render battle intro, turn prompts, combat follow-up text
  - methods:
    - `func render_battle_state(state: Dictionary, battle_type: String) -> void`
    - `func render_input_choices(choices: Array, current_turn_name: String) -> void`
    - `func render_auto_action(turn_result: Dictionary, ally_name_resolver: Callable) -> void`

### Tests To Add

- `test/rpg/test_terminal_components.gd`
  - `TextLog.append_line()` appends newline-terminated content
  - `ChoicePanel.clear_choices()` removes existing buttons
  - `MapView.render_map_state()` produces one button per available node
  - `BattleView.render_input_choices()` produces one button per skill choice
- extend `test/rpg/test_ui_output.gd`
  - verify the current terminal text flow still contains the same Korean battle/map copy

### Acceptance Criteria

- `terminal_ui.gd` becomes a thin controller, not the place where all rendering and flow logic live.
- Terminal behavior remains visually and functionally unchanged.
- All existing tests still pass.

### Risks

- UI text regressions are easy to introduce during extraction. Existing output tests should be extended before large moves.

## Phase 4: Split Terminal Flow By Screen Mode (`MapView` / `BattleView`)

### Purpose

Finish the terminal decomposition so the terminal layer matches the architecture’s 3-tier presentation intent more closely and becomes a safe stepping stone for later graphic scenes.

### Files To Create

- `scenes/terminal/terminal_screen.gd`
- `test/rpg/test_terminal_screen.gd`

### Files To Modify

- `scenes/terminal/terminal_screen.tscn`
  - switch script from `terminal_ui.gd` to `terminal_screen.gd`
- `scenes/terminal/terminal_ui.gd`
  - either remove after migration or keep as a temporary compatibility wrapper that forwards to `TerminalScreen`
- `scenes/terminal/main.gd`
  - continue to instantiate the terminal root only, not child views directly

### Recommended `terminal_screen.gd` Surface

```gdscript
extends Control

func setup(game_runner) -> void
func show_map(state: Dictionary) -> void
func show_battle(state: Dictionary) -> void
func show_event(data: Dictionary) -> void
func show_shop(data: Dictionary) -> void
func show_campfire(data: Dictionary) -> void
func show_run_end(result: Dictionary) -> void
```

`terminal_screen.gd` should subscribe to `EventBus` and delegate rendering to:

- `MapView`
- `BattleView`
- `TextLog`
- `ChoicePanel`

### Tests To Add

- `test/rpg/test_terminal_screen.gd`
  - terminal root responds to `EventBus.map_state_changed`
  - terminal root responds to `EventBus.battle_state_changed`
  - terminal root delegates choice rendering without duplicating buttons

### Acceptance Criteria

- The terminal layer has explicit screen/view boundaries instead of one mixed file.
- The root scene continues to load from `scenes/main.tscn` without flow changes.
- All existing tests still pass.

### Risks

- If this phase also changes text copy, signal wiring, and scene structure at once, debugging failures becomes slow. Keep this phase focused on composition and delegation only.

## Phase 5: Align Bootstrap With Architecture (`GameRunner` Autoload Wrapper, `SceneManager`, `SaveManager`)

### Purpose

Add the missing architecture singletons without violating the requirement that core logic stays `RefCounted`.

### Files To Create

- `autoload/game_runner.gd`
- `autoload/save_manager.gd`
- `autoload/scene_manager.gd`
- `test/rpg/test_game_runner_autoload.gd`
- `test/rpg/test_save_manager.gd`
- `test/rpg/test_scene_manager.gd`

### Files To Modify

- `project.godot`
  - register in this order:
    - `EventBus`
    - `RunState`
    - `SaveManager`
    - `SceneManager`
    - `GameRunner`
- `scenes/terminal/main.gd`
  - stop instantiating `scripts/rpg/game_runner.gd` directly
  - use the autoload wrapper singleton instead
- `scripts/rpg/game_runner.gd`
  - no inheritance change
  - remain the canonical RefCounted orchestration implementation

### Recommended Wrapper Strategy

Because `GameRunner` must remain `RefCounted` for headless compatibility, `autoload/game_runner.gd` should be a `Node` wrapper, not a moved rewrite.

Suggested shape:

```gdscript
extends Node

const GAME_RUNNER_IMPL := preload("res://scripts/rpg/game_runner.gd")
var current_run = null

func create_runner(config: Dictionary = {}) -> RefCounted:
    current_run = GAME_RUNNER_IMPL.new(config)
    return current_run

func get_runner():
    return current_run
```

This keeps:

- architecture compliance for singleton access
- headless compatibility for the real runner
- test stability for direct `scripts/rpg/game_runner.gd` unit tests

### `SaveManager` Scope In This Phase

Implement only the architecture’s documented MVP surface:

- `func load_persistent() -> Dictionary`
- `func save_persistent(data: Dictionary) -> void`
- `func unlock_boss(boss_id: String) -> void`
- `func save_run() -> void`
- `func load_run() -> bool`
- `func delete_run_save() -> void`

### `SceneManager` Scope In This Phase

Implement only terminal-safe minimum behavior:

- `func go_to(target: String, params: Dictionary = {}) -> void`
- `_resolve_path(target: String) -> String`
- `_load_scene(path: String, params: Dictionary) -> void`

No fancy transition effects are required yet. A synchronous scene swap is enough if the API is stable.

### Tests To Add

- `test/rpg/test_game_runner_autoload.gd`
  - wrapper creates a `GameRunner` implementation
  - wrapper does not change `GameRunner`’s runtime API
- `test/rpg/test_save_manager.gd`
  - persistent save load defaults
  - unlock writes expected boss/act data
  - run save round-trips through `RunState.serialize()`
- `test/rpg/test_scene_manager.gd`
  - target names resolve to expected scene paths
  - terminal target resolves to `res://scenes/terminal/terminal_screen.tscn`

### Acceptance Criteria

- `project.godot` contains the architecture singletons.
- `main.gd` no longer manually constructs the core `GameRunner` implementation.
- `SaveManager` and `SceneManager` exist with stable APIs.
- All existing tests still pass.

### Risks

- Autoload registration order matters.
- Turning the actual `scripts/rpg/game_runner.gd` into a `Node` would violate the headless constraint. The wrapper approach avoids that and should be used explicitly.

## Phase 6: Implement Boss Phase 2

### Purpose

Close the boss architecture gap without expanding beyond the documented MVP.

### Files To Create

- `test/rpg/test_boss_phase2.gd`

### Files To Modify

- `scripts/rpg/combat/battle_manager.gd`
  - add:
    - `func _check_boss_phase_transition() -> void`
  - call it after damage application and before battle-end resolution
- `scripts/rpg/combat/unit.gd` or current enemy/boss data holder
  - add phase flags and phase transition behavior:
    - `var phase_2_triggered: bool = false`
    - `func enter_phase_2() -> void`
- any boss content source used by current Act 1 boss data
  - add fields necessary for phase 2 skills/stats

### Required Signal

- emit `EventBus.boss_phase_changed(enemy)` when phase 2 starts

### Tests To Add

- `test/rpg/test_boss_phase2.gd`
  - crossing `<= 50%` HP triggers phase 2 once
  - repeated damage below threshold does not retrigger
  - `EventBus.boss_phase_changed` fires once

### Acceptance Criteria

- The Act 1 boss changes state at half HP.
- The transition is observable through `EventBus`.
- Existing boss tests still pass.

### Risks

- Boss phase changes can alter battle pacing and break duration/balance tests. Keep phase-2 stat changes minimal first, then tune.

## Phase 7: Add Missing Headless Scripts

### Purpose

Match the architecture’s Layer 1 tooling and make regression/balance runs first-class.

### Files To Create

- `headless/balance_test.gd`
- `headless/regression_test.gd`
- `test/rpg/test_headless_scripts.gd`

### Files To Modify

- `headless/simulation.gd`
  - optionally switch its subscriptions from direct `GameRunner` signals to `EventBus` for consistency

### Recommended Script Scope

- `headless/balance_test.gd`
  - argument: `--count=<N>`
  - run N autoplay runs
  - print:
    - win rate
    - average floors cleared
    - average combats won
    - average gold earned
- `headless/regression_test.gd`
  - deterministic seed set
  - run one or more canonical autoplay scenarios
  - exit non-zero if expected summary values drift outside a defined tolerance

### Tests To Add

- `test/rpg/test_headless_scripts.gd`
  - scripts load successfully
  - expected public entry pattern exists
  - optional smoke test via subprocess if CI environment allows it

### Acceptance Criteria

- All three headless scripts exist:
  - `simulation.gd`
  - `balance_test.gd`
  - `regression_test.gd`
- They can be invoked with the architecture-documented commands.
- All existing tests still pass.

### Risks

- Do not make `balance_test.gd` part of the normal fast unit-test path if it is expensive. It should be a separate CI or local workflow tool.

## Suggested Commit Boundaries

1. `feat(autoload): add EventBus and migrate terminal subscriptions`
2. `feat(state): add RunState singleton with GameRunner compatibility mirror`
3. `refactor(terminal): extract TextLog and ChoicePanel`
4. `refactor(terminal): split map and battle views behind terminal screen`
5. `feat(autoload): add GameRunner wrapper, SaveManager, and SceneManager`
6. `feat(boss): implement boss phase 2 transition`
7. `feat(headless): add balance and regression scripts`

## Recommended Test Gate After Every Phase

Run at minimum:

```bash
godot --headless --quit --script test/test_runner.gd
```

For phases 1, 3, 4, and 5 also manually verify:

1. launch the terminal build
2. enter one combat node
3. confirm each map/battle update appears once
4. complete one event/shop/campfire path
5. complete one boss run and confirm summary still renders

## Final Notes

The safest migration path is:

- add `EventBus` first
- keep `GameRunner`’s old signals temporarily
- extract `RunState` behind a mirror
- split the terminal UI without changing copy or flow
- add autoload wrappers only after the signal/state boundaries are stable

The highest-risk anti-pattern to avoid is doing `EventBus`, `RunState`, `GameRunner` relocation, and terminal decomposition in one commit. That would make duplicate-signal bugs and regression diagnosis unnecessarily difficult.
