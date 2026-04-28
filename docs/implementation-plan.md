# DTR Roguelike RPG — TDD Implementation Plan

> Godot 4.6 / GUT test framework / Pure logic (no UI/scene dependencies)
> New code: `scripts/rpg/` | Tests: `test/rpg/`
> Do NOT modify existing bakery code.

---

## Phase 1: Data Tables (Foundation)

### Goal
Build typed, validated data table schemas and registry for all 8 tables (Character, Skill, Enemy, Relic, Equipment, Node, Event, Reward). Every subsequent phase depends on this.

### Dependencies
None (foundation phase).

### Test IDs
`datatable-001` through `datatable-050`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `data/base_record.gd` | Base class: ID uniqueness, required-field validation |
| `data/character_record.gd` | CharacterTable record: character_id, name, role (front/guardian/support), max_hp, max_mp, attack, defense, speed, crit_rate (0~1), effect_accuracy, effect_resistance, skill_ids[] |
| `data/skill_record.gd` | SkillTable record: skill_id, name, mp_cost (>=0), target_type (single_enemy/all_enemies/single_ally/all_allies/self), damage_ratio (>=0), base_status_chance (0~1), status_effect_ids[], status_duration, tags[] |
| `data/enemy_record.gd` | EnemyTable record: enemy_id, name, tier (normal/elite/unique/boss), max_hp (>0), attack, defense, speed, reward_group_id, ai_pattern_id, loot_table_id, status_immunities[] |
| `data/relic_record.gd` | RelicTable record: relic_id, name, rarity, trigger_condition, effect_text, stack_rule, penalty_text |
| `data/equipment_record.gd` | EquipmentTable record: equipment_id, name, slot (weapon/armor/accessory/trinket), rarity, primary_bonus{stat, value}, secondary_bonus, upgrade_level_max (>=1), special_effect_text |
| `data/node_record.gd` | NodeTable record: node_id, node_type (combat/event/treasure/shop/campfire/unique/boss), unlock_condition, outgoing_edges[], encounter_pool_id, reward_group_id |
| `data/event_record.gd` | EventTable record: event_id, title, options[] (min 2), required_conditions[], success_outcomes[], failure_outcomes[], followup_node_type |
| `data/reward_record.gd` | RewardTable record: reward_group_id, guaranteed_rewards[], optional_rewards[], selection_count (>=0), rarity_floor, pity_rule{threshold (>0), guaranteed_rarity} |
| `data/table_registry.gd` | Central registry: register(records[]), get_by_id(id), validate_all(), duplicate ID detection |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_data_tables.gd` | datatable-001~050 |

### Detailed Spec

**CharacterTable required fields** (datatable-001~002):
- character_id, name, role, max_hp, max_mp, attack, defense, speed, crit_rate, effect_accuracy, effect_resistance, skill_ids
- role enum: `front`, `guardian`, `support` (datatable-003~006)
- max_hp must be > 0 (datatable-007~008)
- crit_rate range [0, 1] (datatable-009~010)
- skill_ids allows empty array (datatable-046)

**SkillTable required fields** (datatable-011~018):
- skill_id, name, mp_cost, target_type, damage_ratio, base_status_chance, status_effect_ids, status_duration, tags
- target_type enum: `single_enemy`, `all_enemies`, `single_ally`, `all_allies`, `self` (datatable-012~013)
- mp_cost >= 0 (datatable-014~015)
- damage_ratio >= 0 (datatable-016)
- base_status_chance range [0, 1] (datatable-017~018)
- status_effect_ids allows empty array (datatable-047)

**EnemyTable required fields** (datatable-019~022):
- enemy_id, name, tier, max_hp, attack, defense, speed, reward_group_id, ai_pattern_id, loot_table_id, status_immunities
- tier enum: `normal`, `elite`, `unique`, `boss` (datatable-020~021)
- max_hp > 0 (datatable-022)
- status_immunities allows empty array (datatable-048)

**RelicTable required fields** (datatable-023~024):
- relic_id, name, rarity, trigger_condition, effect_text, stack_rule, penalty_text

**EquipmentTable required fields** (datatable-025~029):
- equipment_id, name, slot, rarity, primary_bonus{stat, value}, secondary_bonus, upgrade_level_max, special_effect_text
- slot enum: `weapon`, `armor`, `accessory`, `trinket` (datatable-026~027)
- upgrade_level_max >= 1 (datatable-028~029)

**NodeTable required fields** (datatable-030~033):
- node_id, node_type, unlock_condition, outgoing_edges[], encounter_pool_id, reward_group_id
- node_type enum: `combat`, `event`, `treasure`, `shop`, `campfire`, `unique`, `boss` (datatable-031~032)
- outgoing_edges allows empty array (datatable-033)

**EventTable required fields** (datatable-034~039):
- event_id, title, options[] (>=2 entries), required_conditions[], success_outcomes[], failure_outcomes[], followup_node_type
- options minimum 2 entries (datatable-035~038)

**RewardTable required fields** (datatable-040~045):
- reward_group_id, guaranteed_rewards[], optional_rewards[], selection_count (>=0), rarity_floor, pity_rule{threshold (>0), guaranteed_rarity}
- selection_count >= 0 (datatable-042~043)
- guaranteed_rewards allows empty array (datatable-044)

**Cross-cutting** (datatable-049~050):
- Duplicate ID detection across all tables (datatable-049)
- Empty table allowed (datatable-050)

### Verification
- [ ] All 50 datatable tests pass
- [ ] Each table record validates required fields, enums, ranges
- [ ] TableRegistry rejects duplicate IDs
- [ ] Empty tables/arrays handled gracefully

---

## Phase 2: Combat Core

### Goal
Implement the damage formula, critical hit system, turn order resolution, and turn structure pipeline (start → action → end).

### Dependencies
Phase 1 (CharacterRecord, SkillRecord, EnemyRecord)

### Test IDs
`combat-001` through `combat-010`, `combat-019` through `combat-029`, `combat-039` through `combat-041`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `combat/damage_calculator.gd` | Static class: `calculate_base_damage(atk, coefficient, def) → int`, `apply_critical(base_damage, is_critical, multiplier=1.5) → int`, `calculate_fixed_damage(amount) → int` |
| `combat/turn_order.gd` | Sort units by speed desc; tiebreak: ally > enemy → lower HP% → lower internal ID |
| `combat/unit.gd` | Combat unit state: current_hp, max_hp, current_mp, max_mp, atk, def, speed, status_effects{}, internal_id, is_ally, alive |
| `combat/turn_manager.gd` | Turn pipeline: on_turn_start() → tick buffs/debuffs → check stun → on_action() → on_turn_end() → apply DOT → check death |
| `combat/battle_manager.gd` | Orchestrator: init_battle(allies[], enemies[]), next_turn(), check_battle_end() → "victory"/"defeat"/null, run_terminate() |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_damage_calculator.gd` | combat-001~010 |
| `test_turn_order.gd` | combat-019~021 |
| `test_turn_manager.gd` | combat-022~026 |
| `test_mp_system.gd` | combat-027~029 |
| `test_battle_duration.gd` | combat-039~041 |

### Detailed Spec

**Damage formula** (combat-001~005):
```
base_damage = max(1, floor(attacker_atk * skill_coefficient) - defender_def)
```
- Normal: ATK=100, coeff=1.2, DEF=30 → `floor(120) - 30 = 90` (combat-001)
- Min guarantee: ATK=50, coeff=1.0, DEF=80 → `max(1, 50-80) = 1` (combat-002)
- Boundary zero: ATK=100, coeff=0.5, DEF=50 → `max(1, floor(50)-50) = 1` (combat-003)
- Floor decimals: ATK=77, coeff=0.7, DEF=10 → `max(1, floor(53.9)-10) = 43` (combat-004)
- Zero DEF: ATK=80, coeff=1.5, DEF=0 → `max(1, 120-0) = 120` (combat-005)

**Critical hits** (combat-006~008):
- Critical: `base_damage * 1.5` → 100 * 1.5 = 150 (combat-006)
- Non-critical: damage unchanged → 100 (combat-007)
- Critical + min: if base=1, stays 1 (combat-008)

**Fixed damage** (combat-009~010):
- Ignores DEF, ignores critical → always exact value (50)

**Turn order** (combat-019~021):
- Primary sort: speed descending
- Tiebreak 1: ally before enemy
- Tiebreak 2: lower HP ratio first
- Tiebreak 3: lower internal_id first

**Turn structure** (combat-022~026):
- Turn start: decrement buff/debuff durations, remove expired, check stun (skip action)
- Turn action: execute skill
- Turn end: apply DOT damage → check death
- Battle end: after all actions, check all allies dead → defeat+run_end, all enemies dead → victory+continue

**MP system** (combat-027~029):
- MP < cost → skill unusable (combat-027)
- MP >= cost → deduct, use skill (combat-028)
- MP == cost exactly → usable, MP becomes 0 (combat-029)

**Battle duration targets** (combat-039~041):
- Normal enemy: 2~4 turns
- Elite enemy: 4~6 turns
- Boss enemy: 6~8 turns

### Verification
- [ ] All combat core tests pass (combat-001~010, 019~029, 039~041)
- [ ] Damage formula matches exact expected values
- [ ] Turn order handles all tiebreak rules
- [ ] Turn pipeline correctly processes stun, DOT, death checks

---

## Phase 3: Status Effects

### Goal
Implement 6 status effect types (bleed, burn, slow, weaken, shatter, stun) with stacking/refresh rules, hit/resist formula, and boss immunity.

### Dependencies
Phase 1 (data tables), Phase 2 (damage calculator, unit)

### Test IDs
`combat-011` through `combat-018` (DOT damage), `status-001` through `status-034`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `status/status_effect.gd` | Base: type enum, stacks, remaining_turns, apply(), on_tick(), on_expire() |
| `status/bleed_effect.gd` | DOT: `floor(max_hp * 0.05 * stacks)` per turn, stacks up to 3, refresh duration to 3 |
| `status/burn_effect.gd` | DOT: `floor(max_hp * 0.06 * stacks)` per turn, stacks up to 3, refresh duration to 3 |
| `status/slow_effect.gd` | Stat: speed * 0.8, no stack (refresh only), duration 2 turns |
| `status/weaken_effect.gd` | Stat: atk * 0.8, no stack (refresh only), duration 2 turns |
| `status/shatter_effect.gd` | Stat: def * 0.75, no stack (refresh only), duration 2 turns |
| `status/stun_effect.gd` | Action block, no stack (refresh only), duration 1 turn |
| `status/status_manager.gd` | Attach to unit: apply_effect(), has_effect(), tick_all(), get_effective_stat(), check_boss_immunity() |
| `status/effect_chance_calculator.gd` | `final_chance = clamp(base_chance + effect_hit - effect_resist, 0.0, 1.0)` |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_bleed.gd` | combat-011~014, status-001~004, status-029, status-031 |
| `test_burn.gd` | combat-015~017, status-005~007, status-030, status-032 |
| `test_dot_combined.gd` | combat-018, status-033 |
| `test_slow.gd` | status-008~009 |
| `test_weaken.gd` | status-010~011 |
| `test_shatter.gd` | status-012~014 |
| `test_stun.gd` | status-015~016, status-034 |
| `test_effect_chance.gd` | status-017~023 |
| `test_boss_immunity.gd` | status-024~026 |
| `test_status_combined.gd` | status-027~028 |

### Detailed Spec

**Bleed** (stacking, max 3):
- Damage: `floor(max_hp * 0.05 * stacks)` — ignores DEF (combat-011~014)
- New: 1 stack, 3 turns (status-001)
- Reapply: stacks+1 (max 3), refresh to 3 turns (status-002~003)
- Tick: decrement duration; at 0 → remove (status-004)
- Can kill: HP 5 - floor(100*0.05) = 0 → death (combat-014)
- Floor edge: max_hp=33, 1 stack → floor(1.65) = 1 (status-029)
- Max: max_hp=1000, 3 stacks → floor(150) = 150 (status-031)

**Burn** (stacking, max 3):
- Damage: `floor(max_hp * 0.06 * stacks)` — ignores DEF (combat-015~017)
- New: 1 stack, 3 turns (status-005)
- Reapply: stacks+1 (max 3), refresh to 3 turns (status-006~007)
- Floor edge: max_hp=33, 1 stack → floor(1.98) = 1 (status-030)
- Max: max_hp=1000, 3 stacks → floor(180) = 180 (status-032)

**Combined DOT** (combat-018, status-033):
- Bleed 2 stacks + burn 1 stack on max_hp=200: `floor(200*0.05*2) + floor(200*0.06*1) = 20+12 = 32` (combat-018)
- Bleed 3 + burn 3 on max_hp=1000: `150+180 = 330` (status-033)

**Slow** (non-stacking, refresh):
- Speed * 0.8, duration 2 turns (status-008)
- Reapply: no stack change, duration refresh to 2 (status-009)

**Weaken** (non-stacking, refresh):
- ATK * 0.8, duration 2 turns (status-010)
- Reapply: no stack, duration refresh to 2 (status-011)

**Shatter** (non-stacking, refresh):
- DEF * 0.75, duration 2 turns (status-012)
- Reapply: no stack, duration refresh to 2 (status-013)
- Integration: ATK=100, coeff=1.0, base_def=100, shatter → effective_def=75 → damage=25 (status-014)

**Stun** (non-stacking, refresh):
- Action blocked, duration 1 turn (status-015)
- Reapply: duration stays 1 (status-016)
- Next turn: stun expires, normal action (status-034)

**Combined debuffs** (status-027):
- Slow+weaken+shatter simultaneously: speed=80, atk=80, def=75

**Debuff expiry** (status-028):
- All at 1 remaining → tick → all removed → stats restored

**Effect hit/resist formula** (status-017~023):
```
final_chance = clamp(base_chance + effect_hit - effect_resist, 0.0, 1.0)
```
- Base only: clamp(0.80+0-0) = 0.80 (status-017)
- Hit boost: clamp(0.80+0.25-0) = clamp(1.05) = 1.00 (status-018)
- Full resist: clamp(0.80+0-0.80) = 0.00 (status-019)
- 100% resist: clamp(1.00+0-1.00) = 0.00 (status-020)
- Negative: clamp(0.30+0-0.80) = clamp(-0.50) = 0.00 (status-021)
- Overflow: clamp(0.80+0.50-0) = clamp(1.30) = 1.00 (status-022)
- Mixed: clamp(0.75+0.20-0.10) = 0.85 (status-023)

**Boss immunity** (status-024~026):
- Boss with immune_tags: status in tags → always rejected (status-024)
- Boss with 100% resist: clamp(any+0-1.0) = 0.00 (status-025)
- Boss without tag for that effect: normal roll (status-026)

### Verification
- [ ] All status effect tests pass (combat-011~018, status-001~034)
- [ ] DOT formulas match exact floor() values
- [ ] Stacking/refresh rules correct for all 6 types
- [ ] Hit/resist clamp formula verified at boundaries
- [ ] Boss immunity works via tags and 100% resist

---

## Phase 4: Equipment System

### Goal
Implement equipment enhancement (+1~+3), stat scaling, unique effects at +3, and equip/swap logic.

### Dependencies
Phase 1 (EquipmentRecord)

### Test IDs
`equip-001` through `equip-048`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `equipment/equipment_instance.gd` | Instance of EquipmentRecord with upgrade_level (0~3), computed stats |
| `equipment/enhancement_calculator.gd` | Cost lookup by grade+level; stat multiplier: `base * (1 + 0.10 * level)` |
| `equipment/enhancement_costs.gd` | Cost table constants (see below) |
| `equipment/unique_effects.gd` | Strategy pattern for +3 unique effects per equipment |
| `equipment/equipment_manager.gd` | Equip/swap, inventory (max 6), enhance with gold deduction |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_enhancement_cost.gd` | equip-001~011, equip-047~048 |
| `test_enhancement_stats.gd` | equip-012~015 |
| `test_unique_effects.gd` | equip-016~030 |
| `test_equipment_stats.gd` | equip-031~042 |
| `test_equipment_swap.gd` | equip-043~046 |

### Detailed Spec

**Enhancement cost table** (equip-001~011):

| Grade | +1 | +2 | +3 | Total 0→+3 |
|-------|-----|-----|-----|------------|
| 일반 (normal) | 20 | 35 | 60 | 115 (equip-047) |
| 고급 (high) | 35 | 55 | 90 | 180 (equip-048) |
| 희귀 (rare) | — | 80 | 120 | — |

- Gold insufficient (cost-1): fail, gold unchanged (equip-009)
- Gold exact match: success, gold becomes 0 (equip-010)
- Level > 3: reject with MAX_LEVEL error (equip-011)

**Stat scaling** (equip-012~015):
- Main stat at level N: `base * (1 + 0.10 * N)`
- +1: 5 * 1.10 = 5.5 (equip-012)
- +2: 5 * 1.20 = 6.0 (equip-013)
- Sub stat (percent) +1: 3 * 1.10 = 3.3 (equip-014)
- Sub stat +2: boosted (equip-015)

**Unique effects at +3** (equip-016~030):
| Equipment | +3 Unique Effect | Test IDs |
|-----------|-----------------|----------|
| 녹슨 검 | 기본 공격 계수 +0.1 | equip-016~017 |
| 붉은 달 단도 | 치명타 발생 시 출혈 1 부여 | equip-018 |
| 균열 완드 | 디버프 대상에게 피해 +10% | equip-019 |
| 견고한 흉갑 | 피해 10% 감소 (방어형 보정) | equip-020~021 |
| 사냥견 가죽갑 | 첫 턴 받는 피해 -5% | equip-022 |
| 의식가 로브 | 스킬 적중 시 MP +2 | equip-023 |
| 붉은 실 반지 | 출혈 계열 성공률 +5% | equip-024 |
| 달빛 부적 | 첫 턴 속도 +2 | equip-025~026 |
| 파편 목걸이 | HP 50% 이하 받는 피해 -8% | equip-027 |
| 봉인된 열쇠 | 보물/이벤트 잠금 선택지 1회 해금 | equip-028 |
| 잠든 종 | 모닥불 회복 +10%, 이벤트 페널티 -20% | equip-029 |
| 재의 조각 | 화상 피해 +15%, 화상 부여 확률 +5% | equip-030 |

**Base stats** (equip-031~042):
| Equipment | Type | Grade | Stats |
|-----------|------|-------|-------|
| 녹슨 검 | 무기 | 일반 | ATK+4 |
| 붉은 달 단도 | 무기 | 고급 | ATK+3, SPD+2, CRIT+5% |
| 균열 완드 | 무기 | 희귀 | ATK+2, MP+4, E.Hit+10% |
| 견고한 흉갑 | 방어구 | 일반 | HP+18, DEF+3 |
| 사냥견 가죽갑 | 방어구 | 고급 | HP+12, DEF+2, SPD+3 |
| 의식가 로브 | 방어구 | 희귀 | HP+10, DEF+1, E.Hit+8%, E.Resist+5% |
| 붉은 실 반지 | 장신구 | 일반 | CRIT+4%, E.Hit+4% |
| 달빛 부적 | 장신구 | 고급 | SPD+4, E.Resist+5% |
| 파편 목걸이 | 장신구 | 희귀 | HP+14, CRIT+3%, E.Hit+6% |
| 봉인된 열쇠 | 트링킷 | 일반 | Gold+15 |
| 잠든 종 | 트링킷 | 고급 | 모닥불 회복+10% |
| 재의 조각 | 트링킷 | 희귀 | 화상 피해+15%, 화상 확률+5% |

**Equip/swap** (equip-043~046):
- Inventory not full (3/6): swap success, old goes to inventory → 4/6 (equip-043)
- Inventory full (6/6): swap success, old discarded → still 6/6 (equip-044)
- Boundary add at 5/6 → 6/6 success (equip-045)
- Add at 6/6 → fail (equip-046)

### Verification
- [ ] All 48 equipment tests pass
- [ ] Enhancement costs match grade×level exactly
- [ ] Stat scaling formula: `base * (1 + 0.10 * level)`
- [ ] All 12 unique effects at +3 verified
- [ ] Equip/swap respects 6-slot inventory

---

## Phase 5: Inventory System

### Goal
Implement the inventory with equipment slots (6), relic slots (4), potion stacking (5 per type, 4 potion types), use/buy logic, and run-reset rules.

### Dependencies
Phase 1 (data tables), Phase 4 (equipment), Phase 6 (relics) — but tests can mock relic logic.

### Test IDs
`inventory-001` through `inventory-030`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `inventory/inventory.gd` | Master inventory: equipment[6], relics[4], potions{type: count} |
| `inventory/potion.gd` | Potion data: name, cost, effect_type, value |
| `inventory/potion_registry.gd` | 4 potion definitions with costs and effects |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_equipment_inventory.gd` | inventory-001~003, inventory-007~008 |
| `test_relic_inventory.gd` | inventory-004~006 |
| `test_potion_buy.gd` | inventory-009~012, inventory-026~027 |
| `test_potion_stack.gd` | inventory-015~017 |
| `test_potion_use.gd` | inventory-018~025, inventory-028 |
| `test_inventory_reset.gd` | inventory-029~030 |

### Detailed Spec

**Equipment slots** (inventory-001~003):
- Max 6 items. Add at 0→1: success (inventory-001)
- Add at 6→7: fail (inventory-002)
- Boundary: 5→6: success (inventory-003)

**Relic slots** (inventory-004~006):
- Max 4 items. Add at 0→1: success (inventory-004)
- Add at 4→5: fail (inventory-005)
- Boundary: 3→4: success (inventory-006)

**Equip swap via inventory** (inventory-007~008):
- Full inventory + new equip → old discarded (inventory-007)
- Not full → old stored (inventory-008)

**Potion catalog** (inventory-009~012):
| Potion | Cost | Effect |
|--------|------|--------|
| 소형 치료 물약 | 15 gold | HP +35 (inventory-009) |
| 소형 마나 물약 | 20 gold | MP +20 (inventory-010) |
| 정화 물약 | 20 gold | Remove 1 debuff + HP +10 (inventory-011) |
| 전투 집중 물약 | 25 gold | Crit+10%, E.Hit+10% for 2 turns (inventory-012) |

**Potion stacking** (inventory-015~017):
- Same type stacks to max 5. 4→5: success (inventory-015)
- 5→6: fail (inventory-016)
- Different types independent counts (inventory-017)

**Potion use** (inventory-018~025, 028):
- 소형 치료 물약: HP+35, cap at max_hp. HP 90/100 → 100 (healed 10) (inventory-018)
- 소형 치료 물약: HP+35. HP 30/100 → 65 (inventory-019)
- 소형 마나 물약: MP+20. MP 10/50 → 30 (inventory-020)
- 소형 마나 물약: MP+20, cap. MP 40/50 → 50 (restored 10) (inventory-021)
- 정화 물약: remove 1 debuff from [bleed, burn, slow] → [burn, slow] + HP+10 (inventory-022)
- 정화 물약 with no debuffs → fail, count unchanged (inventory-023)
- 전투 집중 물약: Crit+10%, E.Hit+10%, 2 turns (inventory-024)
- 전투 집중 물약 expiry: after 2 turns → stats back to normal (inventory-025)
- 0 count → use fails (inventory-028)

**Potion purchase boundary** (inventory-026~027):
- Gold 14 < cost 15 → fail (inventory-026)
- Gold 15 == cost → success, gold 0 (inventory-027)

**Run reset** (inventory-029~030):
- Full state snapshot: equip 6 + relic 4 + potions all at 5 (inventory-029)
- Run end: relics reset to 0, equipment + potions preserved (inventory-030)

### Verification
- [ ] All 30 inventory tests pass
- [ ] Equipment slot boundary 6 enforced
- [ ] Relic slot boundary 4 enforced
- [ ] Potion stacking max 5 per type
- [ ] Potion use heals capped at max_hp/max_mp
- [ ] Run end clears relics only

---

## Phase 6: Relic System

### Goal
Implement 6 relics with their effects, acquisition, and run-scoped lifecycle.

### Dependencies
Phase 1 (RelicRecord), Phase 2 (damage calculator), Phase 3 (status effects)

### Test IDs
`relic-001` through `relic-021`, `relic-024`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `relics/relic_instance.gd` | Relic state: relic_id, active, uses_remaining |
| `relics/relic_effects.gd` | Per-relic effect logic (strategy/enum dispatch) |
| `relics/relic_manager.gd` | Inventory (max 4), duplicate check, apply_effects(), on_run_end() → clear all |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_relic_acquire.gd` | relic-001~004 |
| `test_relic_fragment.gd` | relic-005~008, relic-024 |
| `test_relic_shield.gd` | relic-009~010 |
| `test_relic_fang.gd` | relic-011~012 |
| `test_relic_ember.gd` | relic-013~014 |
| `test_relic_thread.gd` | relic-015~016 |
| `test_relic_bell.gd` | relic-017~020 |
| `test_relic_lifecycle.gd` | relic-021 |

### Detailed Spec

**Relic acquisition** (relic-001~004):
- Inventory not full (2/4) → add → 3/4 (relic-001)
- Boundary (3/4) → add → 4/4 (relic-002)
- Full (4/4) → reject, discarded (relic-003)
- Duplicate → reject (relic-004)

**Relic effects & penalties:**

| Relic | Effect | Penalty | Test IDs |
|-------|--------|---------|----------|
| 붉은 달의 파편 | 전투당 첫 치명타 1회: 피해 +25%, MP +5 | None | relic-005~008 |
| 녹슨 방패편 | 방어 행동 시 2턴간 DEF +3, 받는 피해 -10% | None | relic-009~010 |
| 사냥개의 이빨 | 출혈 부여량 +1, 출혈 피해 +2% max HP | None | relic-011~012 |
| 재의 잔향 | 화상 피해 +2% max HP, 화상 지속 +1턴 | None | relic-013~014 |
| 균열의 실 | 효과 적중 +15%, 둔화/파쇄 부여 확률 +10% | None | relic-015~016 |
| 고요한 종 | 모닥불 회복 +10%, 이벤트 실패 페널티 -20% | None | relic-017~020 |

**Additional damage post-DEF** (relic-008, relic-024):
- Formula: `final_damage = base_final_damage * 1.25`
- relic-008: `50 * 1.25 = 62`
- relic-024: `80 * 0.7 * 1.25 = 70`

**고요한 종 multiplicative stacking** (relic-020):
- `base_heal * other_buff * (1 + 0.10) = 50 * 1.10 = 55`

**Run lifecycle** (relic-021):
- Run end → all relics cleared, not carried to next run

### Verification
- [ ] All relic tests pass
- [ ] Each relic's effect triggers correctly
- [ ] Run reset clears all relics

---

## Phase 7: Reward System

### Goal
Implement battle-type reward pools (normal/elite/unique/boss), guaranteed drops, treasure node rewards, and overflow handling.

### Dependencies
Phase 1 (RewardTable), Phase 4 (equipment), Phase 5 (inventory), Phase 6 (relics)

### Test IDs
`reward-001` through `reward-017`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `rewards/reward_generator.gd` | Generate rewards by battle_type; gold ranges, item pools |
| `rewards/reward_tables.gd` | Constants for gold ranges and drop rates per battle type |
| `rewards/reward_manager.gd` | Grant rewards to player, handle overflow, track pity |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_reward_gold.gd` | reward-001~002, reward-004, reward-006, reward-008, reward-015~016 |
| `test_reward_items.gd` | reward-002~003, reward-005, reward-007, reward-009 |
| `test_reward_special.gd` | reward-010~011, reward-013~014, reward-017 |
| `test_reward_event.gd` | reward-011~012 |

### Detailed Spec

**Gold ranges** (uniform distribution):
| Battle Type | Gold Min | Gold Max | Test IDs |
|-------------|----------|----------|----------|
| Normal | 20 | 35 | reward-001, 015, 016 |
| Elite | 60 | 80 | reward-004 |
| Unique | 80 | 100 | reward-006 |
| Boss | 120 (fixed) | 120 | reward-008 |

**Item reward rates** (10000-run simulation, tolerance ±0.03):
| Battle Type | Reward Pool | Rates | Test IDs |
|-------------|------------|-------|----------|
| Normal | 1 item: 일반장비 40%, 물약 60% | reward-002, 003 |
| Elite | 1 item: 고급장비 50%, 유물후보 30%, 희귀장비 20% | reward-005 |
| Unique | 1 item: 고급장비 30%, 유물후보 50%, 희귀장비 20% | reward-007 |
| Boss | 유물 1개 확정 + 해금체크 1회 | reward-009, 017 |

**Treasure node** (reward-010): 1 relic guaranteed.

**Event node** (reward-011~012): 1 reward per choice, no duplicates.

**Error handling** (reward-013~014):
- Empty reward → BUG_EMPTY_REWARD error (reward-013)
- Full inventory → queue or discard with notification, no crash (reward-014)

### Verification
- [ ] All 17 reward tests pass
- [ ] Gold ranges correct per battle type
- [ ] Item drop rates within ±3% over 10000 runs
- [ ] Boss always drops 1 relic + 1 unlock check
- [ ] Empty reward triggers error handling

---

## Phase 8: Map / Node System

### Goal
Implement 1-act 3-floor map generation with node type distribution, global rules, floor progression, and pipeline (select → enter → complete → advance).

### Dependencies
Phase 1 (NodeRecord, EventRecord)

### Test IDs
`map-001` through `map-050`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `map/node.gd` | Node: id, type (enum), floor_index, position, visited |
| `map/floor.gd` | Floor: nodes[], floor_number (1~3), generate_nodes() |
| `map/map_generator.gd` | Generate full act: 3 floors with constraints |
| `map/map_validator.gd` | Validate global rules (treasure, shop, campfire, unique, event diversity) |
| `map/map_pipeline.gd` | State machine: `select_node → node_entered → result_reflected → next_floor_ready` |
| `map/map_manager.gd` | Current floor, selected nodes, enforce forward-only progression |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_floor_nodes.gd` | map-001~006 |
| `test_floor1_distribution.gd` | map-007~010 |
| `test_floor2_distribution.gd` | map-011~016 |
| `test_floor3_distribution.gd` | map-017~020 |
| `test_global_rules.gd` | map-021~028 |
| `test_event_diversity.gd` | map-029~030 |
| `test_node_enum.gd` | map-031~032 |
| `test_map_selection.gd` | map-033~034 |
| `test_floor_progression.gd` | map-035~038 |
| `test_map_pipeline.gd` | map-039~041 |
| `test_map_structure.gd` | map-042 |
| `test_map_validation.gd` | map-043~050 |

### Detailed Spec

**Floor node counts:**
| Floor | Min Nodes | Max Nodes | Test IDs |
|-------|-----------|-----------|----------|
| 1 | 3 | 4 | map-001, 002 |
| 2 | 3 | 4 | map-003, 004 |
| 3 | 2 | 3 | map-005, 006 |

**Floor 1 distribution** (map-007~010):
- Combat (normal): 1~2
- Event: exactly 1
- Campfire: 0~1
- Boss: 0 (forbidden)

**Floor 2 distribution** (map-011~016):
- Combat (normal): exactly 1
- Elite: exactly 1
- Event: exactly 1
- Treasure: 0~1
- Shop: 0~1
- Boss: 0 (forbidden)

**Floor 3 distribution** (map-017~020):
- Boss: exactly 1 (mandatory)
- Unique: 0~1
- Combat (normal): 0~1
- Event: 0~1

**Global rules** (1 act total) (map-021~028):
- Treasure: 1~2 total (map-021, 022)
- Shop: minimum 1 (map-023)
- Campfire: 1~2 total (map-024, 025)
- Unique: exactly 1 (map-026)
- Unique allowed on floors 2 or 3 only (map-027)
- Unique placed as pre-boss node (map-028)
- Event diversity: 4 distinct events, no same-event on consecutive floors (map-029, 030)

**Node enum** (map-031~032):
- Valid types: `combat`, `event`, `treasure`, `shop`, `campfire`, `unique`, `boss`
- Invalid type → error

**Selection rules** (map-033~034):
- Exactly 1 node per floor
- 2+ nodes → error

**Floor progression** (map-035~038):
- Forward only: 1→2 allowed (map-035)
- Backward forbidden: 2→1 (map-036), 3→2 (map-037), 3→1 (map-038)

**Pipeline states** (map-039~041):
- select_node → `node_entered` (map-039)
- complete_node → `result_reflected` with rewards (map-040)
- advance → `next_floor_ready` with floor 2 displayed (map-041)

**Map structure** (map-042): exactly 3 floors per act.

**Validation errors** (map-043~049):
- treasure < 1 → violation (map-043)
- treasure > 2 → violation (map-044)
- unique > 1 → violation (map-045)
- unique on floor 1 → violation (map-046)
- duplicate event IDs → violation (map-047)
- same event consecutive floors → violation (map-048)
- floor 3 missing boss → violation (map-049)
- Valid complete map passes (map-050)

### Verification
- [ ] All 50 map tests pass
- [ ] Floor node counts within bounds
- [ ] Per-floor distribution rules satisfied
- [ ] Global rules enforced across all 3 floors
- [ ] Pipeline state machine transitions correctly
- [ ] Validation catches all violations

---

## Phase 9: Event System

### Goal
Implement 4 events (ruined_altar, ruin_merchant, sealed_ward, moonlight_rift) with branching choices, probability outcomes, hidden option conditions, and event combat.

### Dependencies
Phase 1 (EventRecord), Phase 2 (combat), Phase 7 (rewards)

### Test IDs
`event-001` through `event-028`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `events/event_manager.gd` | Load events, present choices, resolve outcomes, track visit/wins |
| `events/event_ruined_altar.gd` | 무너진 제단: 기도/봉헌/파괴/기원(hidden) |
| `events/event_ruin_merchant.gd` | 폐허 상인: 구매/강탈/특별거래(hidden) |
| `events/event_sealed_ward.gd` | 봉인된 병실: 치료/해방/약탈/봉인해제(hidden) |
| `events/event_moonlight_rift.gd` | 달빛 균열: 탐사/봉인/수용/균열강화(hidden) |
| `events/event_condition_checker.gd` | Hidden choice visibility: visit_count, gold, battle_wins, status_effects |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_event_basic.gd` | event-001~004 |
| `test_event_altar.gd` | event-005~010 |
| `test_event_merchant.gd` | event-011~015 |
| `test_event_ward.gd` | event-016~021 |
| `test_event_rift.gd` | event-022~027 |
| `test_event_deadlock.gd` | event-028 |

### Detailed Spec

**Global event rules** (event-001~004):
- Every event has >= 2 choices (event-001)
- Event ends → next node assigned (event-002)
- Failure → penalty (HP/MP/gold loss, status, or combat) (event-003)
- Event combat → normal battle rules + event enemy pool (event-004)

**무너진 제단 (ruined_altar)** (event-005~010):
| Choice | Cost | Outcome | Test IDs |
|--------|------|---------|----------|
| 기도 | HP-15%, MP-5% | Relic selection 100% | event-005 |
| 봉헌 | MP-10% | Reward 100% | event-006 |
| 파괴 | None | Relic 50% / Combat 50% | event-007 |
| 기원 (hidden) | HP-30%, MP-15% | Relic 1 guaranteed | event-010 |
- Hidden: visit_count >= 3 (event-008~009)
- 기도: HP 100*0.85=85, MP 50*0.95=47.5 (event-005)
- 기원: HP 100*0.70=70, MP 50*0.85=42.5 (event-010)

**폐허 상인 (ruin_merchant)** (event-011~015):
| Choice | Cost | Outcome | Test IDs |
|--------|------|---------|----------|
| 구매 | Gold | Equipment/potion/material | event-011 |
| 강탈 | None | Gold bonus 60% / Combat 40% | event-012 |
| 특별 거래 (hidden) | Gold | High equipment 1 | event-015 |
- Hidden: gold >= 100 (event-013~014)

**봉인된 병실 (sealed_ward)** (event-016~021):
| Choice | Cost | Outcome | Test IDs |
|--------|------|---------|----------|
| 치료 | None | HP recovery | event-016 |
| 해방 | None | Debuff removal + gold | event-017 |
| 약탈 | None | Equipment 50% / Combat 50% | event-018 |
| 봉인 해제 (hidden) | None | Relic candidate | event-021 |
- Hidden: battle_wins >= 3 (event-019~020)

**달빛 균열 (moonlight_rift)** (event-022~027):
| Choice | Cost | Outcome | Test IDs |
|--------|------|---------|----------|
| 탐사 | None | Relic candidate 65% / Combat 35% | event-022 |
| 봉인 | None | Next combat enemy speed -2 | event-023 |
| 수용 | HP-10% | Equipment 1 | event-024 |
| 균열 강화 (hidden) | None | Remove all debuffs + relic candidate | event-027 |
- Hidden: status_effects >= 2 (event-025~026)
- 수용: HP 100*0.90=90 (event-024)

**No dead-ends** (event-028): Every choice of every event produces a valid next state.

### Verification
- [ ] All 28 event tests pass
- [ ] Each event's choices produce correct outcomes
- [ ] Hidden options only visible when conditions met
- [ ] Probability outcomes within ±3% over 10000 runs
- [ ] No dead-end states

---

## Phase 10: Shop + Campfire Systems

### Goal
Implement shop inventory generation, pricing, purchase flow, and campfire rest/stat-investment actions.

### Dependencies
Phase 1 (data tables), Phase 4 (equipment), Phase 5 (inventory, potions)

### Test IDs
`shop-001` through `shop-014`, `campfire-001` through `campfire-012`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `shop/shop_manager.gd` | Generate pool (3~4 equip, 2 relics once/run, 4 potions), purchase flow |
| `shop/shop_pool_generator.gd` | Random equipment pool by tier with price ranges |
| `campfire/campfire_manager.gd` | Rest action (35% max HP heal), stat investment (+1 stat for 25 gold) |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_shop_pool.gd` | shop-001, 004, 008, 010, 013~014 |
| `test_shop_pricing.gd` | shop-002~003, 005 |
| `test_shop_purchase.gd` | shop-006~007, 009, 011~012 |
| `test_campfire_rest.gd` | campfire-001~004 |
| `test_campfire_invest.gd` | campfire-005~008 |
| `test_campfire_map_rules.gd` | campfire-009~012 |

### Detailed Spec

**Shop equipment pool** (shop-001, 013, 014):
- Display 3~4 equipment items per visit
- Re-rolled each visit (refresh)

**Equipment pricing** (shop-002~003):
| Tier | Price Range |
|------|------------|
| Normal (일반) | 30~45 gold |
| High (고급) | 50~70 gold |

**Relic pool** (shop-004~007):
- Exactly 2 relics displayed
- Price range: 60~90 gold
- Shown only once per run (subsequent visits: no relic pool)
- Preview shown before purchase

**Potions** (shop-008~009):
- All 4 types always available
- Unlimited purchase quantity (no stock limit)

**Purchase flow** (shop-011~012):
- Gold < price → fail (shop-011)
- Gold == price → success, gold becomes 0 (shop-012)

**Campfire rest** (campfire-001~004):
- Heal: `min(current_hp + floor(max_hp * 0.35), max_hp)`
- HP 20/100 → 20+35=55 (campfire-001)
- HP 100/100 → 100 (no overheal) (campfire-002)
- HP 80/100 → 100 (capped) (campfire-003)
- HP 0/200 → floor(200*0.35)=70 (campfire-004)

**Campfire stat investment** (campfire-005~008):
- Cost: 25 gold per +1 stat
- Stats: strength, vitality, intelligence, agility, luck
- Gold < 25 → fail (campfire-006)
- Gold == 25 → success, gold becomes 0 (campfire-007)
- Each stat independently investable (campfire-008)

**Campfire map rules** (campfire-009~012):
- Per act: minimum 1, maximum 2 campfire nodes
- Valid counts: 1 or 2

### Verification
- [ ] All 14 shop tests pass
- [ ] All 12 campfire tests pass
- [ ] Equipment pool 3~4 items, prices in range
- [ ] Relic shown once per run
- [ ] Rest heals exactly 35% max HP, capped
- [ ] Stat investment costs exactly 25 gold

---

## Phase 11: Enemy AI + Boss Patterns

### Goal
Implement enemy AI with weighted random selection (normal), fixed loop patterns (elite/unique/boss), and targeting logic.

### Dependencies
Phase 1 (EnemyRecord), Phase 2 (combat), Phase 3 (status effects)

### Test IDs
`combat-030` through `combat-037`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `ai/enemy_ai.gd` | Base AI: select_skill(), select_target() |
| `ai/normal_ai.gd` | Weighted random: basic_attack 50%, status_effect 30%, high_coefficient 20%. Fallback chain. |
| `ai/pattern_ai.gd` | Fixed loop: iterate skill_loop[], wrap around. |
| `ai/target_selector.gd` | Single: lowest HP% ally. AoE: all allies. Status: ally without that status. |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_normal_ai.gd` | combat-030~032 |
| `test_pattern_ai.gd` | combat-033~034 |
| `test_target_selector.gd` | combat-035~037 |

### Detailed Spec

**Normal AI weighted selection** (combat-030~032):
- Weights: basic_attack=50, status_effect=30, high_coefficient=20 (sum=100) (combat-030)
- If first choice condition not met → evaluate next candidate (combat-031)
- All conditions fail → basic_attack fallback (combat-032)

**Pattern AI (elite/unique/boss)** (combat-033~034):
- Fixed loop array, index increments each turn
- Wraps: `next_index = (current_index + 1) % loop_length`
- Index 0 → skill_a, next=1 (combat-033)
- Index 1 of [a,b] → skill_b, next=0 (combat-034)

**Target selection** (combat-035~037):
- Single: ally with lowest HP ratio → ally_1 (30%) (combat-035)
- AoE: all allies regardless of state (combat-036)
- Status target: ally WITHOUT the specified status → ally_2 (no bleed) (combat-037)

### Verification
- [ ] All 7 AI tests pass
- [ ] Normal AI respects weight distribution
- [ ] Pattern AI loops correctly
- [ ] Target selection matches priority rules

---

## Phase 12: Content Data (Godot Resources)

### Goal
Create all game content as Godot Resource files: 12 enemies, 12 skills (3 characters × 4), 6 relics, 12 equipment, 4 potions. Verify stats match spec.

### Dependencies
Phase 1 through Phase 11 (all systems in place)

### Test IDs
`content-001` through `content-038`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `data/resources/characters/` | 3 CharacterRecord .tres files (전위딜러, 수호자, 마법지원가) |
| `data/resources/skills/` | 12 SkillRecord .tres files |
| `data/resources/enemies/normal/` | 6 EnemyRecord .tres files |
| `data/resources/enemies/elite/` | 3 EnemyRecord .tres files |
| `data/resources/enemies/unique/` | 2 EnemyRecord .tres files |
| `data/resources/enemies/boss/` | 1 EnemyRecord .tres (붉은 달의 파수꾼) |
| `data/resources/relics/` | 6 RelicRecord .tres files |
| `data/resources/equipment/` | 12 EquipmentRecord .tres files |
| `data/resources/potions/` | 4 Potion .tres files |
| `data/content_loader.gd` | Load all .tres, register in TableRegistry |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_normal_enemies.gd` | content-001~006, content-026 |
| `test_elite_enemies.gd` | content-007~009, content-027 |
| `test_unique_enemies.gd` | content-010~011, content-028 |
| `test_boss.gd` | content-012~013, content-034 |
| `test_character_skills.gd` | content-014~025, content-029~031 |
| `test_status_coverage.gd` | content-032~033 |
| `test_balance_ranges.gd` | content-035~038 |

### Detailed Spec

**Normal enemies (6)** (content-001~006, 026):
| Name | HP | ATK | DEF | SPD | Special |
|------|-----|-----|-----|-----|---------|
| 녹슨 검병 | 82 | 13 | 5 | 10 | none |
| 붉은 사냥견 | 74 | 14 | 4 | 12 | 출혈 |
| 그을린 궁수 | 76 | 15 | 4 | 11 | 화상 |
| 파쇄 집사 | 88 | 12 | 6 | 9 | 파쇄 |
| 균열 병졸 | 90 | 12 | 5 | 10 | 둔화 |
| 달빛 사제 | 79 | 13 | 4 | 11 | 약화 |

**Elite enemies (3)** (content-007~009, 027):
| Name | HP | ATK | DEF | SPD | Status | Loop |
|------|-----|-----|-----|-----|--------|------|
| 철갑 감시자 | 160 | 17 | 8 | 10 | — | 3 turns |
| 화염 집행관 | 148 | 20 | 6 | 12 | 화상 | 3 turns |
| 붉은 달 의식사 | 138 | 18 | 7 | 13 | 약화+파쇄 | 4 turns |

**Unique enemies (2)** (content-010~011, 028):
| Name | HP | ATK | DEF | SPD | Mechanic | Loop |
|------|-----|-----|-----|-----|----------|------|
| 봉인된 문지기 | 190 | 18 | 8 | 11 | 반격 | 3 turns |
| 달의 사냥꾼 | 176 | 20 | 6 | 15 | 출혈 | 4 turns |

**Boss** (content-012~013, 034):
- 붉은 달의 파수꾼: HP=450, ATK=22, DEF=8, SPD=10
- 2 phases, transitions at HP <= 50% (225 HP)
- Phase 1 != Phase 2 patterns

**Character skills (12)** (content-014~025, 029~031):

| Character | Skill | MP | Target | Multiplier | Status | Chance |
|-----------|-------|-----|--------|------------|--------|--------|
| 전위딜러 | 기본공격 | 0 | single | 1.0 | — | 0% |
| 전위딜러 | 강타 | 5 | single | 1.3 | — | 0% |
| 전위딜러 | 돌진베기 | 8 | single | 1.6 | 출혈 | 30% |
| 전위딜러 | 회전참격 | 12 | all | 0.7 | — | 0% |
| 수호자 | 기본공격 | 0 | single | 1.0 | — | 0% |
| 수호자 | 방어태세 | 3 | self | — | DEF+30% | — |
| 수호자 | 도발 | 5 | all_enemies | — | taunt | — |
| 수호자 | 방패타격 | 8 | single | 1.3 | 둔화 | 40% |
| 마법지원가 | 기본공격 | 0 | single | 1.0 | — | 0% |
| 마법지원가 | 화염 | 6 | single | 1.3 | 화상 | 35% |
| 마법지원가 | 치유 | 8 | ally_single | — | Heal 20% max HP | — |
| 마법지원가 | 약화저주 | 10 | single | 0.8 | 약화 | 50% |

**Status coverage** (content-032~033):
- 5 types defined: 출혈, 화상, 파쇄, 둔화, 약화 (content-033)
- 돌진베기 bleed 30%: 1000 runs → 25%~35% range (content-032)

**Balance ranges** (content-035~038):
- Normal HP: 60~100 (content-035)
- Elite HP: 100~200 (content-036)
- Unique HP >= Elite avg (149) (content-037)
- Boss HP (450) >= Unique HP (176) * 2 = 352 ✓ (content-038)

### Verification
- [ ] All 38 content tests pass
- [ ] All 12 enemies have correct stats
- [ ] All 12 skills have correct MP/target/multiplier/status
- [ ] Boss phase transition at 50% HP
- [ ] Balance ranges validated

---

## Phase 13: UI / UX

### Goal
Define UI constants, layout rules, and animation timings as pure logic constants. UI scenes are NOT created here — only the data/constants layer that UI code will consume.

### Dependencies
None (constant definitions only)

### Test IDs
`ui-001` through `ui-034`

### Files to Create

**Implementation (`scripts/rpg/`):**
| File | Purpose |
|------|---------|
| `ui/ui_constants.gd` | Resolution (1920×1080), safe area (48px), font sizes, animation timings, layer z-indices |
| `ui/ui_theme.gd` | Button specs (56px height, 240px min width), modal dim (0.6), toast durations/colors |
| `ui/feedback_constants.gd` | Animation durations: attack 350ms, hit_flash 120ms, status 150ms, reward 300ms, victory 500ms |
| `ui/node_icons.gd` | Icon mapping per node type: battle→붉은검, event→보라두루마리, treasure→금색상자, etc. |
| `ui/toast_config.gd` | Toast types: acquire=gold, loss=red, status=purple, fail=gray. Duration 1500ms. Top-center. |

**Tests (`test/rpg/`):**
| File | Covers |
|------|--------|
| `test_ui_constants.gd` | ui-001~003 |
| `test_ui_layers.gd` | ui-004~006 |
| `test_ui_buttons.gd` | ui-007~010 |
| `test_ui_toast.gd` | ui-011~012 |
| `test_ui_dialog.gd` | ui-013 |
| `test_ui_battle_hud.gd` | ui-014~015 |
| `test_ui_map.gd` | ui-016~018 |
| `test_ui_event.gd` | ui-019~020 |
| `test_ui_feedback.gd` | ui-021~023 |
| `test_ui_animations.gd` | ui-024~029 |
| `test_ui_camera.gd` | ui-030 |
| `test_ui_fonts.gd` | ui-031~034 |

### Detailed Spec

**Resolution** (ui-001~002):
- Canvas: 1920×1080, aspect 16:9, locked
- Window resize: letterbox/pillarbox to maintain 16:9

**Safe area** (ui-003):
- All sides: 48px padding
- UI elements bounded: top>=48, left>=48, right<=1872, bottom<=1032

**UI layers** (ui-004~006):
- Z-order: background < info_panel < interaction < modal_toast
- Modal overlay: 60% opacity (0.6)
- Modal open: background interaction blocked

**Buttons** (ui-007~010):
- Height: 56px, min width: 240px
- States: default, hover, pressed, disabled (4 visual states)
- Styles: primary, secondary, destructive (3 distinct styles)
- Disabled button: click ignored

**Toast** (ui-011~012):
- Position: top-center
- Duration: 1500ms default
- Colors: acquire=gold, loss=red, status=purple, fail=gray

**Confirm dialog** (ui-013):
- 1 sentence + 2 buttons (confirm=destructive, cancel=secondary)

**Battle HUD** (ui-014~015):
- Always visible: HP bar, MP bar, turn order, status effects
- Skill preview: bottom-center, shows name/MP/description

**Map UI** (ui-016~018):
- Node icons: battle=붉은검, event=보라두루마리, treasure=금색상자, shop=초록가방, campfire=주황불꽃, unique=은색왕관, boss=검은해골
- Selectable node: 100% opacity
- Unselectable: 35% opacity
- Current node: white pulse ring, 1500ms cycle

**Event UI** (ui-019~020):
- Options: 2~4 per event
- Phases: description → choices → result toast (3 separated phases)

**Feedback** (ui-021~023):
- Damage number display: within 200ms
- HP bar animation: within 250ms
- Critical: gold color, 120% scale, unique sound

**Animation timings** (ui-024~028):
- Basic attack: 350ms
- Hit flash: 120ms
- Status effect appear: 150ms
- Reward popup: 300ms
- Victory/defeat: 500ms

**Particles & camera** (ui-029~030):
- Max 12 particles per skill
- Camera shake on hit: max ±6%

**Fonts** (ui-031~034):
- Font family: Pretendard or Noto Sans KR
- Body text: >= 24px
- Warning/important: >= 28px
- HUD: body number 24px, label 20px, important 28px

### Verification
- [ ] All 34 UI tests pass
- [ ] All constants match spec exactly
- [ ] Animation durations match millisecond values
- [ ] Font sizes meet minimums
- [ ] Layer ordering correct

---

## Cross-Phase Dependency Graph

```
Phase 1: Data Tables
  ├─→ Phase 2: Combat Core
  │     ├─→ Phase 3: Status Effects
  │     ├─→ Phase 11: Enemy AI
  │     └─→ Phase 9: Events (combat trigger)
  ├─→ Phase 4: Equipment
  │     └─→ Phase 5: Inventory
  ├─→ Phase 6: Relics
  │     └─→ Phase 5: Inventory (relic slots)
  ├─→ Phase 7: Rewards
  ├─→ Phase 8: Map/Nodes
  ├─→ Phase 9: Events
  ├─→ Phase 10: Shop + Campfire
  └─→ Phase 12: Content Data (depends on all above)
Phase 13: UI/UX (standalone constants)
```

## Test ID Summary by Phase

| Phase | Test IDs | Count |
|-------|----------|-------|
| 1. Data Tables | datatable-001~050 | 50 |
| 2. Combat Core | combat-001~010, 019~029, 039~041 | 24 |
| 3. Status Effects | combat-011~018, status-001~034 | 42 |
| 4. Equipment | equip-001~048 | 48 |
| 5. Inventory | inventory-001~030 | 30 |
| 6. Relics | relic-001~021, relic-024 | 22 |
| 7. Rewards | reward-001~017 | 17 |
| 8. Map/Nodes | map-001~050 | 50 |
| 9. Events | event-001~028 | 28 |
| 10. Shop+Campfire | shop-001~014, campfire-001~012 | 26 |
| 11. Enemy AI | combat-030~037 | 8 |
| 12. Content | content-001~038 | 38 |
| 13. UI/UX | ui-001~034 | 34 |
| **Total** | | **417** |

## Conventions

- All tests extend GUT's test class (`extends "res://addons/gut/test.gd"`)
- Pure logic: no scene tree, no physics, no signals from UI
- Each test file is independently runnable
- Use `assert_eq`, `assert_true`, `assert_near` (for floats)
- Mock RNG with seed for deterministic probability tests
- File names: `test_<feature>.gd` in `test/rpg/`
- Implementation: `class_name` PascalCase, file snake_case in `scripts/rpg/`
