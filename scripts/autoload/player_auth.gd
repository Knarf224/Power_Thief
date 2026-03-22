extends Node

# ── SIGNALS ────────────────────────────────────────────────────────────────
signal auth_changed(logged_in: bool)
signal register_result(success: bool, message: String)
signal login_result(success: bool, message: String)

# ── CONFIG ─────────────────────────────────────────────────────────────────
const SUPABASE_URL      := "https://sbwmznwbfjcnnmgqvifv.supabase.co"
const SUPABASE_ANON_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNid216bndiZmpjbm5tZ3F2aWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwMDQ2OTYsImV4cCI6MjA4ODU4MDY5Nn0.EqErGaIauFjyat08c59QAz7m3ZIMTnIHtRu-8rZMpr0"

# ── SESSION STATE ──────────────────────────────────────────────────────────
var user_id:       String = ""
var username:      String = ""
var access_token:  String = ""
var refresh_token: String = ""

# ── WEB FETCH STATE ────────────────────────────────────────────────────────
var _js_pending: Dictionary = {}   # id -> Callable
var _js_next_id: int        = 0


func is_logged_in() -> bool:
	return access_token != ""


# ── LIFECYCLE ──────────────────────────────────────────────────────────────

func _ready() -> void:
	_restore_session()
	if OS.get_name() == "Web":
		_setup_web_listener()


func _setup_web_listener() -> void:
	JavaScriptBridge.eval("""
(function(){
  if(window.__gdNetListening) return;
  window.__gdNetListening = true;
  window.addEventListener('message', function(e){
    if(!e.data || e.data.type !== 'gdnet_res') return;
    var id = e.data.id;
    window['__gdS'+id] = e.data.status;
    window['__gdB'+id] = e.data.body;
  });
})();
""")


# ── PUBLIC AUTH API ────────────────────────────────────────────────────────

func register(p_username: String, p_password: String, p_real_email: String = "") -> void:
	var fake_email := p_username.strip_edges().to_lower() + "@powerthief.invalid"
	var body := JSON.stringify({
		"email":    fake_email,
		"password": p_password,
		"data": {
			"username":   p_username.strip_edges(),
			"real_email": p_real_email.strip_edges()
		}
	})
	_http_post("/auth/v1/signup", body, false, _on_register_response)


func login(p_username: String, p_password: String) -> void:
	var fake_email := p_username.strip_edges().to_lower() + "@powerthief.invalid"
	var body := JSON.stringify({
		"email":    fake_email,
		"password": p_password
	})
	_http_post("/auth/v1/token?grant_type=password", body, false, _on_login_response)


func logout() -> void:
	if not is_logged_in():
		return
	_http_post("/auth/v1/logout", "", true,
		func(_r: int, _c: int, _b: PackedByteArray): pass)
	_clear_session()


# ── PUBLIC HTTP HELPERS ────────────────────────────────────────────────────

func supabase_rpc(fn_name: String, params: Dictionary, callback: Callable) -> void:
	_http_post("/rest/v1/rpc/" + fn_name, JSON.stringify(params), true, callback)


func rest_get(path_and_query: String, callback: Callable) -> void:
	var headers: Array[String] = [
		"apikey: " + SUPABASE_ANON_KEY,
		"Authorization: Bearer " + (access_token if is_logged_in() else SUPABASE_ANON_KEY),
		"Content-Type: application/json"
	]
	_make_request("GET", SUPABASE_URL + "/rest/v1/" + path_and_query, headers, "", callback)


func rest_post(table: String, body: Dictionary, callback: Callable) -> void:
	_http_post("/rest/v1/" + table, JSON.stringify(body), true, callback)


# ── RESPONSE HANDLERS ─────────────────────────────────────────────────────

func _on_register_response(result: int, code: int, body_bytes: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		register_result.emit(false, "Network error — check your connection.")
		return
	var data: Variant = JSON.parse_string(body_bytes.get_string_from_utf8())
	if code == 200 or code == 201:
		if data is Dictionary and data.has("access_token"):
			_apply_session(data)
			register_result.emit(true, "Account created! Welcome, " + username + "!")
			auth_changed.emit(true)
		else:
			register_result.emit(true, "Account created! Please log in.")
	else:
		var msg := "Registration failed."
		if data is Dictionary:
			var raw: String = data.get("msg", data.get("message", msg))
			if "already registered" in raw.to_lower() or "already exists" in raw.to_lower():
				msg = "Username already taken — try another."
			else:
				msg = raw
		register_result.emit(false, msg)


func _on_login_response(result: int, code: int, body_bytes: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		login_result.emit(false, "Network error — check your connection.")
		return
	var data: Variant = JSON.parse_string(body_bytes.get_string_from_utf8())
	if code == 200 and data is Dictionary and data.has("access_token"):
		_apply_session(data)
		login_result.emit(true, "Welcome back, " + username + "!")
		auth_changed.emit(true)
	else:
		login_result.emit(false, "Invalid username or password.")


# ── SESSION MANAGEMENT ─────────────────────────────────────────────────────

func _apply_session(data: Dictionary) -> void:
	access_token  = data.get("access_token",  "")
	refresh_token = data.get("refresh_token", "")
	var user: Variant = data.get("user", {})
	if user is Dictionary:
		user_id = user.get("id", "")
		var meta: Variant = user.get("user_metadata", {})
		if meta is Dictionary:
			username = meta.get("username", "")
	_save_session()


func _save_session() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("session", "access_token",  access_token)
	cfg.set_value("session", "refresh_token", refresh_token)
	cfg.set_value("session", "user_id",       user_id)
	cfg.set_value("session", "username",      username)
	cfg.save("user://session.cfg")


func _restore_session() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://session.cfg") != OK:
		return
	access_token  = cfg.get_value("session", "access_token",  "")
	refresh_token = cfg.get_value("session", "refresh_token", "")
	user_id       = cfg.get_value("session", "user_id",       "")
	username      = cfg.get_value("session", "username",      "")
	if is_logged_in():
		call_deferred("_emit_auth_restored")


func _emit_auth_restored() -> void:
	auth_changed.emit(true)


func _clear_session() -> void:
	access_token  = ""
	refresh_token = ""
	user_id       = ""
	username      = ""
	var cfg := ConfigFile.new()
	cfg.save("user://session.cfg")
	auth_changed.emit(false)


# ── HTTP INTERNALS ─────────────────────────────────────────────────────────

func _http_post(endpoint: String, body: String, use_auth: bool, callback: Callable) -> void:
	var headers: Array[String] = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_ANON_KEY
	]
	if use_auth and is_logged_in():
		headers.append("Authorization: Bearer " + access_token)
	_make_request("POST", SUPABASE_URL + endpoint, headers, body, callback)


func _make_request(method: String, url: String, headers: Array[String], body: String, callback: Callable) -> void:
	if OS.get_name() == "Web":
		_web_fetch(method, url, headers, body, callback)
	else:
		_native_request(method, url, headers, body, callback)


func _native_request(method: String, url: String, headers: Array[String], body: String, callback: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(result: int, code: int, _h: PackedStringArray, body_bytes: PackedByteArray):
			http.queue_free()
			callback.call(result, code, body_bytes)
	)
	var m := HTTPClient.METHOD_GET if method == "GET" else HTTPClient.METHOD_POST
	http.request(url, headers, m, body)


func _web_fetch(method: String, url: String, headers: Array[String], body: String, callback: Callable) -> void:
	var id := _js_next_id
	_js_next_id += 1
	_js_pending[id] = callback

	# Extract path after the Supabase base URL (e.g. "/auth/v1/signup")
	var path := url.replace(SUPABASE_URL, "")

	# Build headers as a Dictionary for clean JSON serialisation
	var headers_dict := {}
	for h in headers:
		var sep := h.find(": ")
		if sep >= 0:
			headers_dict[h.substr(0, sep)] = h.substr(sep + 2)

	# Base64-encode body to avoid any string escaping issues
	var body_b64 := ""
	if not body.is_empty():
		body_b64 = Marshalls.utf8_to_base64(body)

	# Send the request to the parent page via postMessage.
	# The parent page has a listener that fetches /api/supabase+path (same-origin proxy),
	# then posts the result back. Our message listener (set up in _setup_web_listener)
	# stores the response in window.__gdS{id} / window.__gdB{id} for polling.
	var data_json := JSON.stringify({
		"type":    "gdnet_req",
		"id":      id,
		"method":  method,
		"path":    path,
		"headers": headers_dict,
		"body":    body_b64
	})
	JavaScriptBridge.eval("window.parent.postMessage(%s, '*');" % data_json)
	_poll_result(id)


# Polls each frame until JS stores the fetch result, then fires the callback
func _poll_result(id: int) -> void:
	var tries := 0
	while _js_pending.has(id) and tries < 300:
		await get_tree().process_frame
		tries += 1
		var status_val: Variant = JavaScriptBridge.eval("(window.__gdS%d !== undefined) ? window.__gdS%d : null" % [id, id])
		if status_val == null:
			continue
		var s := int(status_val)
		var b := str(JavaScriptBridge.eval("window.__gdB%d" % id))
		JavaScriptBridge.eval("delete window.__gdS%d; delete window.__gdB%d;" % [id, id])
		if not _js_pending.has(id):
			return
		var cb: Callable = _js_pending[id]
		_js_pending.erase(id)
		if s == 0:
			cb.call(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray())
		else:
			cb.call(HTTPRequest.RESULT_SUCCESS, s, b.to_utf8_buffer())
		return
	# Timeout after ~5 seconds
	if _js_pending.has(id):
		var cb: Callable = _js_pending[id]
		_js_pending.erase(id)
		cb.call(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray())
