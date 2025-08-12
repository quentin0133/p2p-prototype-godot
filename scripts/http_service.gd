class_name HttpService
extends Node

const TIMEOUT := 5.0;

func request_json(url: String, method: HTTPClient.Method, data = null) -> Dictionary:
	var json_text = "";
	if (data != null):
		json_text = JSON.stringify(data);
	
	var http_request = HTTPRequest.new();
	add_child(http_request);
	http_request.timeout = TIMEOUT
	var err = http_request.request(url, ["Content-Type: application/json"], method, json_text)
	
	if err != OK:
		PopUpManager.remove_pop_up();
		push_error("HTTP Request error: %s" % str(err))
		return {"error": 400, "message": "Request failed"}
	
	PopUpManager.show_pop_up_loading()
	
	var on_request_completed_param = await http_request.request_completed;
	
	PopUpManager.remove_pop_up();
	
	var result = on_request_completed_param[0];
	var response_code = on_request_completed_param[1];
	var body = on_request_completed_param[3].get_string_from_utf8();
	
	if result != OK:
		return {"error": response_code, "message": "Network error"}
	
	if response_code < 200 || response_code > 300:
		return {"error": response_code, "message": "HTTP error %d" % response_code}
	
	if body.strip_edges().is_empty():
		return {"error": response_code, "data": null}
	
	var json := JSON.new()
	var parse_err := json.parse(body)
	if parse_err != OK:
		return {
			"error": response_code,
			"message": "JSON parse error: %s" % json.get_error_message()
		}
	
	return {"error": response_code, "data": json.get_data()}
