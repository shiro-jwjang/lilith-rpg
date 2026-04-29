# 미구현 스킬 효과 — 전체 구현 계획

## 현재 상태
- 아군 스킬 12개 중 5개가 effect 구현 완료 (기본공격×3, 방어태세, 도발, 치유)
- 나머지 7개는 데미지만 처리하고 부가 효과 미구현

## 미구현 항목

### A. 상태이상 시스템 (Status Effect System)
스펙: §9-3, §10-4, §11-2, §11-3, §11-4

| 상태이상 | 중첩 | 지속 | 턴종료 효과 | 적용 스킬 |
|----------|------|------|------------|----------|
| 출혈 | 최대 3 | 3턴 | 최대HP 5%/스택 | 돌진베기(30%) |
| 화상 | 최대 3 | 3턴 | 최대HP 6%/스택 | 화염(35%) |
| 둔화 | 비중첩 | 2턴 | 속도 -20% | 방패타격(40%) |
| 약화 | 비중첩 | 2턴 | 공격력 -20% | 약화저주(50%) |
| 파쇄 | 비중첩 | 2턴 | 방어력 -25% | (현재 스킬 없음, 적 전용 가능) |
| 기절 | 비중첩 | 1턴 | 행동 불가 | (현재 스킬 없음) |

**적중률 공식** (§11-2):
> clamp(기본확률 + 효과적중 - 대상효과저항, 0%, 100%)

**현재 문제점**:
- Unit에 상태이상 저장 구조 없음
- player_attack() default 브랜치에서 status_effects/status_chance 무시
- 턴종료 도트 퍼지 처리 없음
- 치명타율/효과적중/효과저항이 Unit 필드에 없음 (content_data에는 정의 안 됨)

### B. 전체 공격 (AoE Attack)
- 회전참격 (`target: "all"`, multiplier 0.7) — 현재 단일 타겟만 공격
- player_attack() default 브랜치가 `_first_living_enemy()`로 단일 대상만 처리

### C. 치명타 시스템
- damage_calculator.gd에 `apply_critical()` 메서드는 있으나 호출되지 않음
- Unit에 crit_rate 필드 없음
- 스펙 §11-1: 배수 1.5배, 캐릭터별 기본 치명타율 정의됨 (§10-1)

## 구현 순서 (의존성 기준)

### Phase 1: Unit 상태이상 인프라
1. Unit에 `status_effects: Dictionary` 구조 추가
   ```
   status_effects = {
     "출혈": {"stacks": 0, "duration": 0},
     "화상": {"stacks": 0, "duration": 0},
     "둔화": {"stacks": 0, "duration": 0},
     "약화": {"stacks": 0, "duration": 0},
     "파쇄": {"stacks": 0, "duration": 0},
     "기절": {"stacks": 0, "duration": 0},
   }
   ```
2. Unit 메서드: `apply_status(type, stacks, duration)`, `process_turn_end_status()`, `has_status(type)`, `get_status(type)`
3. Unit 필드: `crit_rate: float`, `effect_hit: float`, `effect_resist: float`, `base_speed: int` (둔화 원복용)
4. 상태이상 중첩 규칙 구현 (출혈/화상은 중첩, 나머지는 갱신만)

### Phase 2: 상태이상 적용 (player_attack)
1. default 브랜치에서 status_effects + status_chance 읽어서 적중률 계산
2. 적중 시 타겟에 apply_status() 호출
3. 반손(return)에 적용된 상태이상 정보 포함

### Phase 3: 턴종료 상태이상 처리
1. next_turn()에서 아군/적 턴종료 시 process_turn_end_status() 호출
2. 출혈/화상: 도트 퍼지 (방어력 무시, §11-3)
3. 모든 상태이상: duration 감소, 0이면 제거
4. 기절: 행동 스킵 로직

### Phase 4: 전체 공격 (AoE)
1. player_attack() default 브랜치에서 `target: "all"` 분기
2. 모든 살아있는 적에게 데미지 + 상태이상 적용
3. 보스 페이즈 전이 체크 (모든 적 타격 후)

### Phase 5: 치명타
1. Unit에 crit_rate 필드 반영
2. 데미지 계산 시 crit 판정 → apply_critical() 호출
3. 반환값에 is_critical 포함

### Phase 6: 둔화/약화/파쇄 스탯 수정 효과
1. apply_status()에서 둔화 → speed 수정, 약화 → atk 수정, 파쇄 → def 수정
2. remove_status()에서 원래 스탯 복원 (base_speed 등 필요)
3. 턴 시작 시 스탯 재계산

## 스펙 참조
- §9-3: 상태이상 규칙 (중첩/갱신/면역)
- §10-1: 캐릭터별 기본 스탯 (치명타율, 효과적중, 효과저항)
- §10-4: 상태이상 수치 (피해량, 지속턴, 중첩상한)
- §11-1: 치명타 규칙
- §11-2: 효과적중/효과저항 공식
- §11-3: 연속피해/고정피해 (방어력 무시)
- §11-4: 상태이상 중첩 규칙

## 제외 (MVP 이후)
- 파쇄: 현재 아군 스킬에 없음 (적 전용이면 나중에)
- 기절: 현재 아군 스킬에 없음
- 보스 면역 태그
