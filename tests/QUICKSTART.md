# 🚀 Unit Tests Quick Reference

## 📦 Что создано?

- **51 юнит тестов** покрывающих критичную логику
- **1130 строк тестового кода**
- **Полная документация** + GitHub Actions CI/CD

## ⚡ Быстрый старт

### Windows
```cmd
cd untmatric
tests\run_tests.bat
```

### macOS/Linux
```bash
cd untmatric
./tests/run_tests.sh
```

### Godot Editor
```
Scene → Open → res://tests/TestRunner.tscn → F5
```

## 📊 Тесты

| Компонент | Тестов | Статус |
|-----------|--------|--------|
| GlobalMetrics | 36 | ✅ |
| MatrixSolver | 7 | ✅ |
| Shields | 8 | ✅ |
| **TOTAL** | **51** | **✅** |

## 📁 Файлы

```
tests/
├── test_global_metrics.gd     (360 строк, 36 тестов)
├── test_matrix_solver.gd      (310 строк, 7 тестов)
├── test_shields.gd            (380 строк, 8 тестов)
├── test_runner.gd             (запускатель)
├── TestRunner.tscn            (сцена)
├── run_tests.sh               (Linux/macOS)
├── run_tests.bat              (Windows)
├── README.md                  (документация)
└── DELIVERY_SUMMARY.md        (этот файл)

.github/workflows/
└── tests.yml                  (GitHub Actions)

TESTING.md                      (полный гайд)
```

## 🧪 Что тестируется

### GlobalMetrics
- ✅ Stability clamping (0-100)
- ✅ Hamming distance (все комбинации)
- ✅ Frequency shield (5+ checks за 15 сек)
- ✅ Lazy search shield (< 3 unique bits)
- ✅ Penalties (HD=1,2,5+)
- ✅ Level progression (DEC/OCT/HEX)
- ✅ Arithmetic generation (ADD/SUB/SHIFT)
- ✅ Matrix generation & validation

### MatrixSolver
- ✅ Matrix size (6×6)
- ✅ Row constraints (hex-values)
- ✅ Column constraints (ones, parity)
- ✅ Hamming distance
- ✅ Solution validation
- ✅ Quest uniqueness
- ✅ Edge cases

### Shields
- ✅ Frequency shield logic
- ✅ Lazy search detection
- ✅ Signal emissions
- ✅ Shield recovery
- ✅ Blocking mechanism

## 💡 Примеры

### Запустить один набор тестов
```bash
godot --headless --scene res://tests/test_global_metrics.gd
```

### Сохранить результаты
```bash
godot --headless --scene res://tests/TestRunner.tscn > results.txt 2>&1
cat results.txt
```

### Check exit code
```bash
# Linux/macOS
godot --headless --scene res://tests/TestRunner.tscn
echo $?  # 0 = успех

# Windows PowerShell
& "godot.exe" --headless --scene res://tests/TestRunner.tscn
$LASTEXITCODE
```

## 📖 Документация

| Файл | Для |
|------|-----|
| `tests/README.md` | Обзор + примеры |
| `TESTING.md` | Полный гайд |
| `tests/DELIVERY_SUMMARY.md` | Детали доставки |

## 🔗 CI/CD

Tests автоматически запускаются при:
- `git push` в `main` / `develop`
- Pull Request

Статус: GitHub → Actions tab

## ✨ Next Steps

1. Запустите тесты: `./tests/run_tests.sh`
2. Прочитайте `tests/README.md`
3. Добавьте свои тесты для новых фич
4. Push → GitHub Actions запустит их автоматически

---

**Created:** 2026-02-26  
**Status:** ✅ Ready to use
