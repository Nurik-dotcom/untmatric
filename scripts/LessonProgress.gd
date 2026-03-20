# scripts/LessonProgress.gd
extends Node

const SAVE_PATH := "user://lesson_progress.cfg"

# Схема: { "lesson_id": { "phase": int, "stars": int, "completed": bool, "attempts": int } }
var _data: Dictionary = {}

signal progress_changed(lesson_id: String)

func _ready() -> void:
    _load()

# Вызывается при завершении любой из 3 фаз урока
# phase: 1 = теория, 2 = упражнение, 3 = квиз (финальное)
# stars: 0-3, актуально только для phase == 3
func mark_phase(lesson_id: String, phase: int, stars: int = 0) -> void:
    if not _data.has(lesson_id):
        _data[lesson_id] = {"phase": 0, "stars": 0, "completed": false, "attempts": 0}
    var rec: Dictionary = _data[lesson_id]
    rec["phase"] = maxi(rec.get("phase", 0), phase)
    rec["attempts"] = rec.get("attempts", 0) + (1 if phase == 1 else 0)
    if phase == 3:
        rec["stars"] = maxi(rec.get("stars", 0), stars)
        rec["completed"] = true
    _data[lesson_id] = rec
    _save()
    progress_changed.emit(lesson_id)

func get_stars(lesson_id: String) -> int:
    return _data.get(lesson_id, {}).get("stars", 0)

func get_phase(lesson_id: String) -> int:
    return _data.get(lesson_id, {}).get("phase", 0)

func is_completed(lesson_id: String) -> bool:
    return _data.get(lesson_id, {}).get("completed", false)

func get_total_completed() -> int:
    var count := 0
    for rec in _data.values():
        if rec.get("completed", false):
            count += 1
    return count

func reset_lesson(lesson_id: String) -> void:
    _data.erase(lesson_id)
    _save()
    progress_changed.emit(lesson_id)

func _save() -> void:
    var cfg := ConfigFile.new()
    for lesson_id in _data:
        var rec: Dictionary = _data[lesson_id]
        cfg.set_value(lesson_id, "phase", rec.get("phase", 0))
        cfg.set_value(lesson_id, "stars", rec.get("stars", 0))
        cfg.set_value(lesson_id, "completed", rec.get("completed", false))
        cfg.set_value(lesson_id, "attempts", rec.get("attempts", 0))
    cfg.save(SAVE_PATH)

func _load() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    for lesson_id in cfg.get_sections():
        _data[lesson_id] = {
            "phase": cfg.get_value(lesson_id, "phase", 0),
            "stars": cfg.get_value(lesson_id, "stars", 0),
            "completed": cfg.get_value(lesson_id, "completed", false),
            "attempts": cfg.get_value(lesson_id, "attempts", 0),
        }
