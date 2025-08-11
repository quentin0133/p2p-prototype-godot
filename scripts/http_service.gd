class_name HttpService
extends Node

const TIMEOUT := 5.0;

func request_json(url: String, method: HTTPClient.Method, data = null, show_loading = true) -> Dictionary:
	var json_text = "";
	if (data != null):
		json_text = JSON.stringify(data);
	
	var http_request = HTTPRequest.new();
	add_child(http_request);
	http_request.timeout = TIMEOUT
	var err = http_request.request(url, ["Content-Type: application/json"], method, json_text)
	
	if err != OK:
		push_error("HTTP Request error: %s" % str(err))
		return {"error": 400, "message": "Request failed"}
	
	if (show_loading):
		PopUpManager.show_pop_up_loading()
	
	var on_request_completed_param = await http_request.request_completed;
	
	if (show_loading):
		PopUpManager.remove_pop_up();
	
	var result = on_request_completed_param[0];
	var response_code = on_request_completed_param[1];
	var body = on_request_completed_param[3].get_string_from_utf8();
	
	if result != OK:
		return {"error": response_code, "message": "Network error"}
	
	if response_code < 200 || response_code > 300:
		return {"error": response_code, "message": "HTTP error %d" % response_code}
	
	var json_result = JSON.parse_string(body)
	if !json_result:
		return {"error": response_code, "message": "JSON parse error"}
	
	return {"error": response_code, "data": json_result}
