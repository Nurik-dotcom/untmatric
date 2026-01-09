extends Node

# Identifiers
var install_id: String = ""

# Modes
enum Mode { LEARN, EXAM }
var current_mode = Mode.LEARN

# Session metrics (reset every case)
var t_active_base: float = 0.0
var t_penalty: float = 0.0
var t_app_cost: float = 0.0 # Time spent in your code paths
var t_tech_tax: float = 0.0 # Device/OS overhead
var t_ideal: float = 100.0  # Comes from level config

# Deletion settings (SLA)
var delete_requested: bool = false

func _ready():
	# Initialize anonymous ID
	if install_id == "":
		install_id = OS.get_unique_id()

func reset_metrics(level_t_ideal: float):
	t_active_base = 0.0
	t_penalty = 0.0
	t_app_cost = 0.0
	t_tech_tax = 0.0
	t_ideal = level_t_ideal

func get_ie() -> float:
	var t_actual = t_active_base + t_penalty + t_app_cost + t_tech_tax
	if t_actual == 0:
		return 0.0
	
	var ie = (t_ideal / t_actual) * 100.0
	if t_penalty == 0:
		ie += 10.0 # Bonus for clean run
	return clamp(ie, 0, 110)

# T_residual ("residual time")
func get_t_residual() -> float:
	return t_active_base - t_tech_tax - t_app_cost

func load_level_data(level_id: String) -> Dictionary:
	var file_path = "res://data/levels.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		var data = JSON.parse_string(json_text)
		if data is Dictionary:
			return data.get(level_id, {})
	return {}
