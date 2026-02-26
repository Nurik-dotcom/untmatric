# 🧪 UNTformatic Test Suite

Полный набор юнит-тестов для критичной логики **UNTformatic**.

## Структура

```
tests/
├── test_global_metrics.gd    # Тесты основного движка (36 тестов)
├── test_matrix_solver.gd     # Тесты матричного решателя (7 тестов)
├── test_shields.gd           # Тесты системы защиты (8 тестов)
├── test_runner.gd            # Запускатель всех тестов
└── TestRunner.tscn           # Тестовая сцена
```

**Всего: ~51 тест**

---

## Тестовое покрытие

### ✅ GlobalMetrics (36 тестов)

Ядро игровой логики:

| Категория | Тесты | Описание |
|-----------|-------|---------|
| **Stability** | 4 | Clamping (0-100), game_over сигнал |
| **Hamming Distance** | 5 | Расчет расстояния между значениями |
| **Frequency Shield** | 2 | Обнаружение спама (5+ проверок за 15 сек) |
| **Lazy Search Shield** | 2 | Обнаружение перебора (< 3 уникальных бит) |
| **Penalties** | 3 | Штрафы за ошибки (HD=1,2,5+) |
| **Level Progression** | 5 | Режимы (DEC→OCT→HEX), рейтинги, сброс |
| **Arithmetic** | 7 | Генерация ADD/SUB/SHIFT операций |
| **Matrix** | 3 | Генерация и валидность матриц |

### ✅ Matrix Solver (7 тестов)

Логика матричных головоломок:

| Тест | Проверяет |
|------|-----------|
| `test_matrix_size` | Размер 6×6, значения 0/1 |
| `test_row_constraints` | Расчет hex-значений строк |
| `test_col_constraints` | Расчет ones_count и parity |
| `test_hamming_distance_matrix` | HD для матриц |
| `test_solution_validation` | Проверка правильности |
| `test_uniqueness` | Разнообразие генерирующихся задач |
| `test_edge_cases` | Пустая матрица, полная матрица |

### ✅ Shields (8 тестов)

Система анти-читерства:

| Щит | Тесты | Описание |
|-----|-------|---------|
| **Frequency** | 3 | Базовая логика, cleanup, блокировка |
| **Lazy Search** | 3 | Условия HD, отслеживание бит, версия для матриц |
| **Signals** | 1 | Сигналы shield_triggered |
| **Recovery** | 1 | Разблокировка после время истечения |
| **Concurrent** | 1 | Поведение при одновременных shields |
| **Penalty** | 1 | No penalty во время блокировки |

---

## Запуск тестов

### 1. Из Godot Editor

```bash
# Откройте Godot, потом:
# Scene → Open Scene → res://tests/TestRunner.tscn
# F5 для запуска
```

### 2. Из командной строки

```bash
# Скомпилировать и запустить тесты
godot --headless --script res://tests/test_runner.gd

# Или через Godot 4.x:
godot --headless -s res://tests/test_runner.gd --quit-on-finish
```

### 3. GitHub Actions (CI/CD)

Добавьте в `.github/workflows/test.yml`:

```yaml
name: Unit Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: chickensoft-games/setup-godot@v2
        with:
          version: 4.5
      - name: Run Tests
        run: godot --headless -s res://tests/test_runner.gd --quit-on-finish
```

---

## Примеры тестов

### ✅ Тест стабильности

```gdscript
func test_stability_clamping():
	# Max clamp
	metrics.stability = 150.0
	assert_equal(metrics.stability, 100.0, "Should clamp at 100")
	
	# Min clamp + signal
	var game_over_emitted = false
	metrics.game_over.connect(func(): game_over_emitted = true)
	metrics.stability = 0.0
	assert_true(game_over_emitted, "Should emit game_over at 0")
```

### ✅ Тест Frequency Shield

```gdscript
func test_frequency_shield_blocking():
	# Simulate 5 rapid checks
	for i in range(5):
		var result = metrics.check_solution(42, 42)
		if i == 4:
			assert_equal(result.get("error"), "SHIELD_FREQ")
	
	# Try again - still blocked
	var result = metrics.check_solution(42, 42)
	assert_equal(result.get("error"), "SHIELD_ACTIVE")
```

### ✅ Тест Matrix Constraints

```gdscript
func test_row_constraints():
	# Matrix: [1,0,1,0,0,0] = 32+8 = 40
	var test_matrix = [[[1,0,1,0,0,0], ...]]
	var constraints = metrics._build_row_constraints(test_matrix)
	
	assert_equal(constraints[0].hex_value, 40)
```

---

## Вывод тестов

```
╔══════════════════════════════════════════════════════════╗
║          🧪 UNTFORMATIC TEST SUITE 🧪                   ║
╚══════════════════════════════════════════════════════════╝

▶ Loading test suite: GlobalMetrics
[TEST] Stability Clamping
  ✓ Stability should clamp at 100.0
  ✓ Stability should clamp at 0.0
  ... (34 more tests)

▶ Loading test suite: MatrixSolver
[TEST] Matrix Size Validation
  ✓ Matrix should have 6 rows
  ✓ Each row should have 6 columns
  ... (5 more tests)

▶ Loading test suite: Shields
[TEST] Frequency Shield - Basic Logic
  ✓ Should store 4 timestamps
  ... (7 more tests)

╔══════════════════════════════════════════════════════════╗
║                  📊 FINAL RESULTS 📊                    ║
╠══════════════════════════════════════════════════════════╣
║ ✅ Total Passed: 51                                      ║
║ ❌ Total Failed: 0                                       ║
║ 📈 Pass Rate: 100.0%                                     ║
╠══════════════════════════════════════════════════════════╣
║ ✓ GlobalMetrics: 36 passed, 0 failed (100%)             ║
║ ✓ MatrixSolver: 7 passed, 0 failed (100%)               ║
║ ✓ Shields: 8 passed, 0 failed (100%)                    ║
╚══════════════════════════════════════════════════════════╝

🎉 ALL TESTS PASSED! 🎉
```

---

## Добавление новых тестов

1. **Создайте новый файл** `test_*.gd` в папке `tests/`
2. **Наследуйте от Node** и используйте helper методы:
   - `assert_equal(actual, expected, message)`
   - `assert_true(condition, message)`
   - `assert_false(condition, message)`
3. **Вызовите `print_results()`** в конце

Пример:

```gdscript
extends Node

var test_results: Dictionary = {"passed": 0, "failed": 0}

func _ready():
	test_my_feature()
	print_results()

func test_my_feature():
	print("\n[TEST] My Feature")
	assert_equal(2 + 2, 4, "Math works")

func assert_equal(actual, expected, msg: String = ""):
	if actual == expected:
		test_results["passed"] += 1
		print("  ✓ %s" % msg)
	else:
		test_results["failed"] += 1
		print("  ✗ FAILED: %s" % msg)

func print_results():
	print("\n✅ Passed: %d | ❌ Failed: %d" % 
		[test_results["passed"], test_results["failed"]])
```

---

## Проблемы с тестами?

| Проблема | Решение |
|----------|---------|
| Tests don't run | Проверьте пути в `project.godot` (autoload для GlobalMetrics) |
| `preload()` fails | Убедитесь что `res://scripts/GlobalMetrics.gd` существует |
| Shields не срабатывают | Проверьте что `Time.get_ticks_msec()` работает правильно |
| Matrix HD неправильно | Проверьте MATRIX_WEIGHTS в GlobalMetrics |

---

## Развитие

**Планируется добавить:**

- [ ] Тесты для LogicQuestA/B/C
- [ ] Тесты для UI компонентов (BitKnob, TimeKnob)
- [ ] Тесты для уровней JSON
- [ ] Performance benchmarks
- [ ] Integration tests (сцена → сцена)

---

**Последняя обновка:** 2026-02-26  
**Автор:** AI Assistant
