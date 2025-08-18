class_name TransitionUtils;

static func fade_time(valueA: float, valueB: float, time: float, callback: Callable):
	var elapsed := 0.0;
	var prev_time := Time.get_ticks_msec() / 1000.0;
	var current_value = valueA;
	
	callback.call(valueA);
	while current_value < valueB:
		await Engine.get_main_loop().process_frame
		var current_time := Time.get_ticks_msec() / 1000.0;
		var delta := current_time - prev_time;
		prev_time = current_time;
		elapsed += delta;
		current_value = lerp(valueA, valueB, elapsed / time);
		callback.call(current_value);
	callback.call(valueB);

static func fade_speed(valueA: float, valueB: float, speed: float, callback: Callable):
	var prev_time := Time.get_ticks_msec() / 1000.0;
	var current_value = valueA;
	
	callback.call(valueA);
	while (valueA < valueB && current_value < valueB) || (valueA > valueB && current_value > valueB):
		await Engine.get_main_loop().process_frame
		var current_time := Time.get_ticks_msec() / 1000.0
		var delta := current_time - prev_time
		prev_time = current_time
		
		if valueA < valueB:
			current_value += speed * delta
			current_value = min(current_value, valueB)
		else:
			current_value -= speed * delta
			current_value = max(current_value, valueB)
		
		callback.call(current_value)
	callback.call(valueB);
