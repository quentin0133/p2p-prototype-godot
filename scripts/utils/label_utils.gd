class_name LabelUtils

static func get_visible_text(text: String, visible_ratio: float) -> String:
	if visible_ratio >= 1.0:
		return text;
	if visible_ratio <= 0.0:
		return "";
	var char_count = int(text.length() * visible_ratio);
	return text.substr(0, char_count);
