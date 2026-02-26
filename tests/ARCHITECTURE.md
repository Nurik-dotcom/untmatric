# 🏗️ Test Architecture

Описание архитектуры и организации unit тестов для UNTformatic.

## Принципы

### 1. Независимость (Isolation)

Каждый тест полностью независим:
- Использует `reset_engine()` для очистки состояния
- Не полагается на результаты других тестов
- Может запуститься в любом порядке

```gdscript
func _ready():
    metrics = preload("res://scripts/GlobalMetrics.gd").new()
    add_child(metrics)
    metrics._ready()  # Initialize
    run_all_tests()

func test_stability():
    metrics.reset_engine()  # Clean state
    # ... test ...
```

### 2. Ясность (Clarity)

Каждый тест имеет понятное имя и описание:

```gdscript
func test_frequency_shield_blocks_5_checks_in_15_seconds():
    print("\n[TEST] Frequency Shield blocks 5+ checks in 15 seconds")
    # Очень понятно что этот тест проверяет
```

### 3. Быстрота (Speed)

Тесты выполняются быстро (< 5 сек всего):

```gdscript
# ✓ Быстро: простой расчет
for i in range(100):
    var hd = metrics._calculate_hamming_distance(42, 50)

# ✗ Медленно: ждём input
await get_tree().process_frame
await get_tree().process_frame  # Лишние задержки
```

### 4. Надежность (Reliability)

Тесты всегда дают одинаковый результат:

```gdscript
# ✓ Детерминированный
metrics.start_level(0)
assert_equal(metrics.current_mode, "DEC")

# ✗ Недетерминированный (зависит от randomize)
var random_value = randi() % 100
```

---

## Структура теста

```gdscript
extends Node
class_name TestComponentName

# 1. SETUP
var component: Node
var test_results: Dictionary = {
    "passed": 0,
    "failed": 0
}

# 2. LIFECYCLE
func _ready():
    setup_component()
    run_all_tests()

func setup_component():
    component = preload("res://path/to/component.gd").new()
    add_child(component)

# 3. MAIN TEST RUNNER
func run_all_tests():
    print("\n[TEST SUITE] Component Tests")
    
    # Группа 1
    test_feature_a()
    test_feature_b()
    
    # Группа 2
    test_edge_case_1()
    test_edge_case_2()
    
    print_results()

# 4. TESTS
func test_feature_a():
    print("\n[TEST] Feature A")
    
    component.reset_state()
    var result = component.compute_something()
    assert_equal(result, expected_value, "Should compute X")

# 5. ASSERTIONS
func assert_equal(actual, expected, msg: String = ""):
    if actual == expected:
        test_results["passed"] += 1
        print("  ✓ %s" % msg)
    else:
        test_results["failed"] += 1
        print("  ✗ FAILED: %s (got %s, expected %s)" 
            % [msg, actual, expected])

# 6. REPORTING
func print_results():
    var total = test_results["passed"] + test_results["failed"]
    var rate = float(test_results["passed"]) / total * 100 if total > 0 else 0
    
    print("\n" + "=".repeat(60))
    print("✅ Passed: %d | ❌ Failed: %d | 📈 %.1f%%" 
        % [test_results["passed"], test_results["failed"], rate])
    print("=".repeat(60))
```

---

## Организация по категориям

### GlobalMetrics Tests

```
test_global_metrics.gd
├── STABILITY TESTS (4)
│   ├── Clamping (max 100)
│   ├── Clamping (min 0)
│   ├── Normal values
│   └── Game over signal
├── HAMMING DISTANCE TESTS (5)
│   ├── Identical (HD=0)
│   ├── Single bit (HD=1)
│   ├── Multiple bits
│   ├── All different (HD=8)
│   └── Common values (42 vs 50)
├── FREQUENCY SHIELD TESTS (2)
│   ├── Basic logic (5+ checks)
│   └── Cleanup old timestamps
├── LAZY SEARCH SHIELD TESTS (2)
│   ├── Not triggered when HD≤2
│   └── Triggered when <3 unique bits
├── PENALTY TESTS (3)
│   ├── HD=1 → -10
│   ├── HD=2 → -15
│   └── HD≥5 → -50
├── LEVEL PROGRESSION TESTS (5)
│   ├── DEC mode (0-4)
│   ├── OCT mode (5-9)
│   ├── HEX mode (10-14)
│   ├── Stability reset
│   └── Rank system
├── ARITHMETIC TESTS (7)
│   ├── Addition
│   ├── Subtraction
│   ├── Shift left
│   └── Boundary checks
└── MATRIX TESTS (3)
    ├── Quest generation
    ├── Constraint validity
    └── Solution count
```

### MatrixSolver Tests

```
test_matrix_solver.gd
├── Size Validation (1)
├── Row Constraints (1)
├── Column Constraints (1)
├── Hamming Distance (1)
├── Solution Validation (1)
├── Quest Uniqueness (1)
└── Edge Cases (1)
```

### Shields Tests

```
test_shields.gd
├── FREQUENCY SHIELD (3)
│   ├── Basic logic
│   ├── Cleanup mechanism
│   └── Blocking
├── LAZY SEARCH SHIELD (3)
│   ├── HD conditions
│   ├── Bit tracking
│   └── Matrix version
├── SIGNALS (1)
├── RECOVERY (1)
├── CONCURRENT (1)
└── NO PENALTY ON BLOCK (1)
```

---

## Матрица зависимостей тестов

```
┌─────────────────────────────────────────┐
│  GlobalMetrics._calculate_hamming_distance()
│  (5 tests + используется в 15+ других)
└─────────────────────────────────────────┘
         ↓           ↓           ↓
    [Shields]   [Matrix]    [Penalties]
```

**Критичные функции** (которые тестируются в первую очередь):
1. `_calculate_hamming_distance()` — база всего
2. `check_solution()` - главный entry point
3. `_check_lazy_search()` - защита от читерства
4. `_calculate_matrix_hd()` - матричная логика

---

## Test Flow

```
┌──────────────────────────────┐
│     TestRunner._ready()      │
└──────────┬───────────────────┘
           │
    ┌──────┴──────┬──────────┬──────────┐
    ▼             ▼          ▼          ▼
[GlobalMetrics][MatrixSolver][Shields][...]
    │             │          │
    └─────┬───────┴──────────┘
          │
    ┌─────▼──────────────────┐
    │  print_summary()       │
    │  - Total passed/failed │
    │  - Pass rate %         │
    │  - Per-suite results   │
    └─────┬──────────────────┘
          │
    ┌─────▼──────────────────┐
    │  Exit code (0 or 1)    │
    └────────────────────────┘
```

---

## Assertion Types

### assert_equal

```gdscript
assert_equal(actual, expected, "message")
# Проверяет: actual == expected
# ✓ Perfect for: числа, строки, enum
# ✗ Не подходит для: объекты, массивы (используйте assert_has)
```

### assert_true / assert_false

```gdscript
assert_true(condition, "message")
assert_false(condition, "message")
# ✓ Perfect for: boolean условия
```

### assert_not_equal

```gdscript
assert_not_equal(actual, not_expected, "message")
# ✓ Perfect for: проверка что значение ≠ нежелательному
```

### assert_not_empty

```gdscript
assert_not_empty(array_or_dict, "message")
# ✓ Perfect for: проверка что array/dict не пустой
```

---

## Performance Considerations

### Time Budget

- **Per test:** < 100ms
- **Per suite:** < 1 second
- **Total:** < 5 seconds

### Optimization Tips

```gdscript
# ✓ Быстро: Прямые вычисления
for i in range(1000):
    var result = calculate(i)

# ✗ Медленно: Много signal connects
for i in range(100):
    some_node.signal_a.connect(func(): pass)
    some_node.signal_b.connect(func(): pass)

# ✗ Медленно: File I/O
var data = FileAccess.open("res://data/large_file.json", FileAccess.READ)

# ✗ Медленно: Scene instancing
var scene = preload("res://scenes/complex_scene.tscn").instantiate()
```

---

## Error Handling

### Test Failures

```gdscript
# ✓ Test fails -> report it
var result = compute()
assert_equal(result, expected, "Should be 42")
# → Автоматически добавится в отчет

# ✗ Test crashes -> ошибка
var result = null_reference.some_method()  # Crash!
```

### Shield Tests Edge Cases

```gdscript
# Frequency shield может быть уже активным от предыдущих проверок
metrics.blocked_until = 0.0  # Reset
metrics.check_timestamps.clear()

# Теперь safe запустить тест
test_frequency_shield()
```

---

## Maintenance

### Adding Tests

1. Добавьте функцию `test_new_feature()` в соответствующий файл
2. Добавьте вызов в `run_all_tests()`
3. Запустите: `godot --headless --scene res://tests/TestRunner.tscn`
4. Verify все тесты проходят

### Updating Component

Если вы меняете `GlobalMetrics.gd`:

1. **Запустите affected tests:**
   ```bash
   godot --headless --scene res://tests/test_global_metrics.gd
   ```

2. **Обновите тесты если нужно:**
   - Если изменилась логика → обновите assert
   - Если добавился новый режим → добавьте тест

3. **Commit вместе:**
   ```bash
   git add scripts/GlobalMetrics.gd tests/test_global_metrics.gd
   git commit -m "feat: add new feature + tests"
   ```

---

## Debugging Failed Tests

### Step 1: Run with output

```bash
godot --headless --scene res://tests/test_global_metrics.gd 2>&1 | grep -A 5 "FAILED"
```

### Step 2: Add debug prints

```gdscript
func test_stability():
    print("\n[TEST] Stability")
    print("Before: stability = %f" % metrics.stability)
    
    metrics.stability = 150.0
    
    print("After: stability = %f" % metrics.stability)
    assert_equal(metrics.stability, 100.0, "Should clamp")
```

### Step 3: Run single test

```gdscript
# Edit test_global_metrics.gd
func run_all_tests():
    # Комментируйте все тесты кроме одного
    # test_stability_clamping()
    test_hamming_distance()  # Только этот
    # test_frequency_shield()
    
    print_results()
```

### Step 4: Check state

```gdscript
# В конце теста:
print("Final state:")
print("  stability: %f" % metrics.stability)
print("  blocked_until: %f" % metrics.blocked_until)
print("  last_checked_bits: %s" % [metrics.last_checked_bits])
```

---

## Best Practices Checklist

- [ ] Каждый тест использует `reset_engine()` или `reset_state()`
- [ ] Тесты имеют описательные имена
- [ ] Каждый тест проверяет одно (test = single responsibility)
- [ ] Используются правильные assertions
- [ ] Edge cases покрыты
- [ ] Нет зависимостей между тестами
- [ ] Тесты быстрые (< 100ms каждый)
- [ ] Код читаемый (comments где нужны)

---

**Updated:** 2026-02-26
