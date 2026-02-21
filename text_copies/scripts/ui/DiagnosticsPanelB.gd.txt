extends PanelContainer

@onready var trace_label = $VBoxContainer/TraceList
@onready var explain_label = $VBoxContainer/ExplainList
@onready var btn_close = $VBoxContainer/BtnClose

func _ready():
	btn_close.pressed.connect(_on_close_pressed)

func setup(explain_lines: Array, trace_steps: Array):
	# Explain
	var txt = "[b]АНАЛИЗ:[/b]\n"
	for line in explain_lines:
		txt += "- " + str(line) + "\n"
	explain_label.text = txt

	# Trace
	var trace_txt = ""
	if trace_steps.is_empty():
		trace_txt = "Трассировка недоступна."
	else:
		for step in trace_steps:
			# Trace format: i=1 | s: 0 -> 1
			trace_txt += "i=%s | s: %s -> %s\n" % [
				str(step.get("i", "?")),
				str(step.get("s_before", "?")),
				str(step.get("s_after", "?"))
			]
	trace_label.text = trace_txt

func _on_close_pressed():
	visible = false
