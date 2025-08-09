extends TextEdit

@export var remove_horizontal_scroll = false;
@export var remove_vertical_scroll = false;

func _ready():
	for child in get_children():
		if child is VScrollBar && remove_vertical_scroll:
			remove_child(child)
		elif child is HScrollBar && remove_horizontal_scroll:
			remove_child(child)  
