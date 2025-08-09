class_name UIUtils

static func get_group_bounds(parent: Control) -> Dictionary:	
	var top_left = Vector2(INF, INF);
	var bot_right = Vector2(-INF, -INF);
	
	var rect := parent.get_global_rect()
	top_left = rect.position;
	bot_right = rect.position + rect.size;

	for child in parent.get_children():
		if child is Control:
			var child_bounds = get_group_bounds(child)
			top_left = top_left.min(child_bounds.top_left)
			bot_right = bot_right.max(child_bounds.bot_right)

	return {
		"top_left": top_left,
		"bot_right": bot_right,
		"size": abs(bot_right - top_left)
	}

static func get_camera_world_bound(camera: Camera2D) -> Variant:
	var viewport_size = camera.get_viewport().get_visible_rect().size;
	var zoom = camera.zoom;
	
	var size = viewport_size / zoom;
	var top_left = camera.global_position - (size / 2);
	var bot_right = camera.global_position + (size / 2);
	
	return { 
		"top_left": top_left,
		"bot_right": bot_right,
		"size": size
	};
