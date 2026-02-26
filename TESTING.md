# 🧪 Testing Guide for UNTformatic

Comprehensive guide для запуска, написания и отладки тестов.

## Содержание

1. [Quick Start](#quick-start)
2. [Test Structure](#test-structure)
3. [Running Tests](#running-tests)
4. [Writing Tests](#writing-tests)
5. [CI/CD Integration](#cicd-integration)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Windows (PowerShell)

```powershell
cd .\untmatric
.\tests\run_tests.bat
```

### Linux/macOS (Bash)

```bash
cd untmatric
chmod +x tests/run_tests.sh
./tests/run_tests.sh
```

### Godot Editor

1. Откройте `untmatric` проект в Godot 4.5
2. Перейдите в `Scene → Open Scene`
3. Откройте `res://tests/TestRunner.tscn`
4. Нажмите **F5** для запуска

---

## Test Structure

Каждый файл тестов имеет стандартную структуру:

```gdscript
extends Node
class_name TestFeatureName

var test_results: Dictionary = {"passed": 0, "failed": 0}

func _ready():
    run_all_tests()

func run_all_tests():
    print("\n[TEST SUITE] My Tests")
    
    test_feature_a()
    test_feature_b()
    test_feature_c()
    
    print_results()

# ============= TESTS =============

func test_feature_a():
    print("\n[TEST] Feature A")
    assert_equal(compute(), expected, "Should compute correctly")

func test_feature_b():
    print("\n[TEST] Feature B")
    assert_true(condition, "Should satisfy condition")

# ============= HELPERS =============

func assert_equal(actual, expected, msg: String = ""):
    if actual == expected:
        test_results["passed"] += 1
        print("  ✓ %s" % msg)
    else:
        test_results["failed"] += 1
        print("  ✗ FAILED: %s (got %s, expected %s)" 
            % [msg, actual, expected])

func print_results():
    var total = test_results["passed"] + test_results["failed"]
    var rate = (float(test_results["passed"]) / total * 100) if total > 0 else 0
    
    print("\n" + "=".repeat(60))
    print("📊 TEST RESULTS")
    print("✅ Passed: %d | ❌ Failed: %d | 📈 %.1f%%" 
        % [test_results["passed"], test_results["failed"], rate])
    print("=".repeat(60))
```

---

## Running Tests

### 1. Headless (No Window)

```bash
# Linux/macOS
godot --headless --scene res://tests/TestRunner.tscn

# PowerShell
& "C:\Program Files\Godot\godot.exe" --headless --scene res://tests/TestRunner.tscn
```

### 2. With Window

```bash
godot --scene res://tests/TestRunner.tscn
```

### 3. Single Test Suite

```bash
# Только GlobalMetrics тесты
godot --scene res://tests/test_global_metrics.gd
```

### 4. With Debug Output

```bash
# Сохраняет вывод в файл
godot --headless --scene res://tests/TestRunner.tscn > test-results.txt 2>&1
```

---

## Writing Tests

### Example: Test для новой функции

Допустим, вы добавили новый метод в `GlobalMetrics`:

```gdscript
# GlobalMetrics.gd
func calculate_combo_multiplier(combo: int) -> float:
    if combo < 0: return 1.0
    if combo == 0: return 1.0
    if combo > 50: combo = 50
    return 1.0 + (combo * 0.05)
```

Напишите тест:

```gdscript
# tests/test_global_metrics.gd (добавьте в файл)

func test_combo_multiplier():
    print("\n[TEST] Combo Multiplier Calculation")
    
    # Edge case: negative
    var mult = metrics.calculate_combo_multiplier(-5)
    assert_equal(mult, 1.0, "Negative combo should return 1.0")
    
    # Zero
    mult = metrics.calculate_combo_multiplier(0)
    assert_equal(mult, 1.0, "Zero combo should return 1.0")
    
    # Normal combo
    mult = metrics.calculate_combo_multiplier(10)
    assert_equal(mult, 1.5, "10 combo should be 1.0 + 0.5 = 1.5")
    
    # Cap at 50
    mult = metrics.calculate_combo_multiplier(100)
    assert_equal(mult, 3.5, "Should cap at 50 combo (1.0 + 2.5)")
```

### Test Organization

**Группируйте тесты логически:**

```gdscript
func run_all_tests():
    # Группа 1: Setup & Initialization
    test_setup()
    test_reset()
    
    # Группа 2: Core Logic
    test_calculation_a()
    test_calculation_b()
    
    # Группа 3: Edge Cases
    test_edge_case_1()
    test_edge_case_2()
    
    # Группа 4: Integration
    test_integration()
    
    print_results()
```

---

## CI/CD Integration

### GitHub Actions

Тесты автоматически запускаются при:
- Push в `main` или `develop`
- Pull Request в эти ветки

**Статус:**
- ✅ Все тесты пройдены → PR можно merge'ить
- ❌ Тесты провалены → PR заблокирован

**Просмотр результатов:**

1. GitHub → UNTformatic repo
2. Actions tab
3. Latest workflow run
4. See output или скачайте artifacts

### Local CI Simulation

```bash
# Запустите как GitHub Actions делает это:
godot --headless --scene res://tests/TestRunner.tscn

# Проверьте exit code
echo $?  # На Linux/macOS (0 = успех)
echo %ERRORLEVEL%  # На Windows (0 = успех)
```

---

## Troubleshooting

### ❌ Tests won't run

**Проблема:** `res://scripts/GlobalMetrics.gd not found`

**Решение:**
```bash
# Убедитесь что файл существует
ls -la untmatric/scripts/GlobalMetrics.gd

# Проверьте project.godot
cat untmatric/project.godot | grep GlobalMetrics
```

### ❌ "preload" returns null

**Проблема:** `preload()` в тестах возвращает `null`

**Решение:**

```gdscript
# ✗ Неправильно
var metrics = preload("res://scripts/GlobalMetrics.gd")

# ✓ Правильно (с явным путем)
var metrics = preload("res://scripts/GlobalMetrics.gd").new()
add_child(metrics)
```

### ❌ Tests timeout / hang

**Проблема:** Тесты висят или зависают

**Решение:**

```gdscript
# Используйте await для асинхронных операций
func test_async_operation():
    print("\n[TEST] Async Operation")
    
    var operation_done = false
    metrics.async_task.connect(func(): operation_done = true)
    
    metrics.start_async_task()
    
    # Ждём максимум 5 секунд
    var timeout = 0
    while not operation_done and timeout < 50:
        await get_tree().process_frame
        timeout += 1
    
    assert_true(operation_done, "Async task should complete")
```

### ❌ Stability shield tests FAILING

**Проблема:** `test_frequency_shield_blocking` иногда падает

**Причина:** `Time.get_ticks_msec()` может быть нестабильна в быстрых тестах

**Решение:**

```gdscript
# Добавьте небольшую задержку между checks
for i in range(5):
    var result = metrics.check_solution(42, 42)
    await get_tree().process_frame  # 1 frame delay
```

### ❌ Matrix tests give wrong HD

**Проблема:** Matrix hamming distance не совпадает ожиданиям

**Отладка:**

```gdscript
func test_matrix_hd_debug():
    metrics.start_matrix_quest()
    
    # Print target matrix
    print("Target matrix:")
    for r in range(6):
        print("  Row %d: %s" % [r, metrics.matrix_target[r]])
    
    # Print constraints
    print("Row constraints:")
    for r in range(6):
        print("  Row %d: hex=%d, visible=%s" % [r, 
            metrics.matrix_row_constraints[r].hex_value,
            metrics.matrix_row_constraints[r].is_hex_visible])
    
    # Check calculation
    var hd = metrics.validate_matrix_logic()
    print("Calculated HD: %s" % hd)
```

---

## Test Coverage Goals

| Component | Current | Target |
|-----------|---------|--------|
| GlobalMetrics | 36 tests | 40+ |
| MatrixSolver | 7 tests | 10+ |
| Shields | 8 tests | 12+ |
| LogicQuests | 0 tests | 15+ |
| UI Components | 0 tests | 10+ |
| **Total** | **51** | **87+** |

---

## Performance Testing

Добавьте бенчмарки для критичных функций:

```gdscript
func test_performance_hamming_distance():
    print("\n[TEST] Performance: Hamming Distance")
    
    var start_time = Time.get_ticks_msec()
    
    for i in range(1000):
        var hd = metrics._calculate_hamming_distance(0xABCD, 0x1234)
    
    var elapsed = Time.get_ticks_msec() - start_time
    
    print("  1000 iterations in %dms (%.2f µs per call)" 
        % [elapsed, elapsed * 1000.0 / 1000.0])
    
    assert_true(elapsed < 100, "Should complete in < 100ms")
```

---

## Best Practices

✅ **DO:**
- Используйте описательные имена тестов: `test_frequency_shield_triggers_on_5_checks`
- Тестируйте edge cases: пустые значения, границы, экстремумы
- Группируйте свои на логические блоки
- Используйте `before/after` helpers где нужно
- Изолируйте тесты (один тест = один код path)

❌ **DON'T:**
- Не полагайтесь на порядок выполнения тестов
- Не создавайте зависимости между тестами
- Не используйте случайные значения без seed
- Не печатайте большой объемы данных (замедляет тесты)
- Не забывайте нормализовать state перед каждым тестом

---

## Resources

- [Godot 4.5 Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [Godot AutoLoad/Singletons](https://docs.godotengine.org/en/stable/tutorials/misc/singletons_autoload.html)

---

**Last Updated:** 2026-02-26
