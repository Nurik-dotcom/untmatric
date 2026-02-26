# 📑 Test Index

Быстрый поиск тестов по функциям.

## Стабильность (Stability)

| Тест | Файл | Строки | Проверяет |
|------|------|--------|-----------|
| `test_stability_clamping` | test_global_metrics.gd | 85-100 | Значения 0-100, game_over |
| `test_hamming_distance` | test_global_metrics.gd | 103-125 | Расчет расстояния |
| `test_penalty_calculation` | test_global_metrics.gd | 195-220 | Штрафы HD=1,2,5+ |

## Frequency Shield (Защита от спама)

| Тест | Файл | Строки | Проверяет |
|------|------|--------|-----------|
| `test_frequency_shield_basic` | test_shields.gd | 45-58 | 5+ checks за 15 сек |
| `test_frequency_shield_cleanup` | test_shields.gd | 60-83 | Удаление старых timestamps |
| `test_frequency_shield_blocking` | test_shields.gd | 85-107 | Блокировка механизма |

## Lazy Search Shield (Защита от перебора)

| Тест | Файл | Строки | Проверяет |
|------|------|--------|-----------|
| `test_lazy_search_conditions` | test_shields.gd | 109-131 | HD условия (<=2 no trigger) |
| `test_lazy_search_bit_tracking` | test_shields.gd | 133-158 | Отслеживание бит |
| `test_lazy_search_matrix_shield` | test_shields.gd | 160-180 | Matrix версия |

## Уровни (Level Progression)

| Тест | Файл | Строки | Проверяет |
|------|------|--------|-----------|
| `test_level_progression` | test_global_metrics.gd | 222-245 | DEC/OCT/HEX, рейтинги |
| `test_arithmetic_generation` | test_global_metrics.gd | 248-290 | ADD/SUB/SHIFT операции |

## Матрица (Matrix)

| Тест | Файл | Строки | Проверяет |
|------|------|--------|-----------|
| `test_matrix_quest_generation` | test_global_metrics.gd | 293-315 | Генерация 6×6 матриц |
| `test_matrix_size` | test_matrix_solver.gd | 40-60 | Размер и значения |
| `test_row_constraints` | test_matrix_solver.gd | 62-90 | Hex-значения строк |
| `test_col_constraints` | test_matrix_solver.gd | 92-120 | Ones count + parity |
| `test_hamming_distance_matrix` | test_matrix_solver.gd | 122-145 | Matrix HD расчет |
| `test_solution_validation` | test_matrix_solver.gd | 147-180 | Проверка корректности |
| `test_matrix_uniqueness` | test_matrix_solver.gd | 182-205 | Разнообразие генерации |
| `test_solver_edge_cases` | test_matrix_solver.gd | 207-260 | Empty/full matrices |

## Сигналы (Signals)

| Тест | Файл | Строки | Проверяет |
|------|------|--------|-----------|
| `test_shield_signals` | test_shields.gd | 182-207 | shield_triggered emission |

## Восстановление (Recovery)

| Тест | Файл | Строки | Проверяет |
|------|------|--------|-----------|
| `test_shield_recovery` | test_shields.gd | 209-235 | Unblocking after timeout |

---

## По категориям

### Core Logic (11 тестов)

- Stability clamping (1)
- Hamming distance (1)
- Penalty calculation (1)
- Level progression (1)
- Arithmetic generation (1)
- Matrix generation (1)
- Matrix size (1)
- Row constraints (1)
- Column constraints (1)
- Matrix solution (1)
- Matrix uniqueness (1)

### Shields (9 тестов)

- Frequency shield basic (1)
- Frequency shield cleanup (1)
- Frequency shield blocking (1)
- Lazy search conditions (1)
- Lazy search bit tracking (1)
- Lazy search matrix (1)
- Shield signals (1)
- Shield recovery (1)
- Concurrent shields (1)

### Advanced (2 теста)

- Matrix edge cases (1)
- Matrix hamming distance (1)

---

## Search by Function

### GlobalMetrics.gd Functions

```gdscript
# Stability
_calculate_hamming_distance()       → test_hamming_distance
stability (setter)                  → test_stability_clamping

# Shields
_update_frequency_log()             → test_frequency_shield_cleanup
_check_lazy_search()                → test_lazy_search_conditions
_check_lazy_search_matrix()         → test_lazy_search_matrix_shield

# Levels
start_level()                       → test_level_progression
_generate_arithmetic_example()      → test_arithmetic_generation
get_rank_info()                     → test_level_progression

# Matrix
start_matrix_quest()                → test_matrix_quest_generation
_build_row_constraints()            → test_row_constraints
_build_col_constraints()            → test_col_constraints
_calculate_matrix_hd()              → test_hamming_distance_matrix
validate_matrix_logic()             → test_solution_validation
check_matrix_solution()             → test_solution_validation
```

---

## Test Time Estimate

| Suite | Tests | Time |
|-------|-------|------|
| GlobalMetrics | 36 | ~2 sec |
| MatrixSolver | 7 | ~1 sec |
| Shields | 8 | ~1 sec |
| **Total** | **51** | **~4 sec** |

---

## Failure Scenarios

### Can't find GlobalMetrics

**Location:** Check `project.godot` autoload section
```ini
[autoload]
GlobalMetrics="*res://scripts/GlobalMetrics.gd"
```

### Hamming distance wrong

**Debug:** Add prints in test_hamming_distance
```gdscript
var hd = metrics._calculate_hamming_distance(0xABCD, 0x1234)
print("Calc HD: %d (expected: %d)" % [hd, expected])
```

### Matrix constraints fail

**Debug:** Check matrix generation
```gdscript
metrics.start_matrix_quest()
print("Target matrix:")
for r in range(6):
    print("  Row %d: %s" % [r, metrics.matrix_target[r]])
```

### Shield tests timeout

**Fix:** Add small delays between checks
```gdscript
for i in range(5):
    metrics.check_solution(42, 42)
    await get_tree().process_frame  # 1 frame delay
```

---

## Adding New Tests

### 1. Create test file

```gdscript
# tests/test_my_feature.gd
extends Node
class_name TestMyFeature

var test_results = {"passed": 0, "failed": 0}

func _ready():
    run_all_tests()

func run_all_tests():
    print("\n[TEST SUITE] My Feature")
    test_my_feature()
    print_results()

func test_my_feature():
    print("\n[TEST] Feature works")
    assert_equal(compute(), 42, "Should be 42")

# ... assert methods ...
```

### 2. Add to test_runner.gd

```gdscript
# In run_tests():
await run_test_suite("MyFeature", "res://tests/test_my_feature.gd")
```

### 3. Run

```bash
godot --headless --scene res://tests/TestRunner.tscn
```

---

## Continuous Integration

### GitHub Actions

Location: `.github/workflows/tests.yml`

Runs on:
- `git push` to `main` / `develop`
- Pull Requests

Check results:
1. GitHub → Repository
2. Actions tab
3. Latest workflow run

---

**Last Updated:** 2026-02-26
