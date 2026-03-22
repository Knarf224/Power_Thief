extends CanvasLayer

# Shown as a full-screen overlay from the Home Screen.
# Displays either the auth form (login/register) or the account info
# panel (if the player is already logged in).

const BG_COLOR    := Color(0.04, 0.04, 0.08, 0.97)
const TITLE_COLOR := Color(0.88, 0.82, 1.00)
const BTN_NORMAL  := Color(0.10, 0.10, 0.16)
const BTN_HOVER   := Color(0.18, 0.16, 0.28)
const BTN_TEXT    := Color(0.78, 0.74, 0.95)
const TAB_ACTIVE  := Color(0.22, 0.18, 0.40)
const ACCENT      := Color(0.55, 0.45, 0.90)
const SUCCESS_CLR := Color(0.45, 0.90, 0.55)
const ERROR_CLR   := Color(1.00, 0.45, 0.45)

enum Tab { LOGIN, REGISTER }

var _current_tab    := Tab.LOGIN
var _tab_login_btn:  Button
var _tab_reg_btn:    Button
var _username_field: LineEdit
var _password_field: LineEdit
var _email_row:      Control
var _email_field:    LineEdit
var _status_label:   Label
var _submit_btn:     Button


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

	PlayerAuth.register_result.connect(_on_register_result)
	PlayerAuth.login_result.connect(_on_login_result)

	# Disconnect signals when this screen is freed so they don't fire into the void.
	tree_exiting.connect(func():
		if PlayerAuth.register_result.is_connected(_on_register_result):
			PlayerAuth.register_result.disconnect(_on_register_result)
		if PlayerAuth.login_result.is_connected(_on_login_result):
			PlayerAuth.login_result.disconnect(_on_login_result)
	)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(420, 0)
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "ACCOUNT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	if PlayerAuth.is_logged_in():
		_build_logged_in_view(vbox)
	else:
		_build_auth_form(vbox)


# ── LOGGED-IN VIEW ─────────────────────────────────────────────────────────

func _build_logged_in_view(vbox: VBoxContainer) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(gap)

	var info := Label.new()
	info.text = "Logged in as:"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.60, 0.58, 0.72))
	vbox.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = PlayerAuth.username.to_upper()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 32)
	name_lbl.add_theme_color_override("font_color", Color(0.70, 0.90, 1.00))
	vbox.add_child(name_lbl)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(gap2)

	var logout_btn := _make_btn("LOG OUT", Color(0.28, 0.08, 0.08), Color(0.42, 0.12, 0.12))
	logout_btn.add_theme_color_override("font_color", Color(1.0, 0.70, 0.70))
	logout_btn.pressed.connect(_on_logout_pressed)
	vbox.add_child(logout_btn)

	var back_btn := _make_btn("BACK", BTN_NORMAL, BTN_HOVER)
	back_btn.pressed.connect(queue_free)
	vbox.add_child(back_btn)


# ── AUTH FORM ──────────────────────────────────────────────────────────────

func _build_auth_form(vbox: VBoxContainer) -> void:
	# Tab row: LOG IN | REGISTER
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	vbox.add_child(tabs)

	_tab_login_btn = _make_btn("LOG IN", BTN_NORMAL, BTN_HOVER)
	_tab_login_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_login_btn.pressed.connect(func(): _set_tab(Tab.LOGIN))
	tabs.add_child(_tab_login_btn)

	_tab_reg_btn = _make_btn("REGISTER", BTN_NORMAL, BTN_HOVER)
	_tab_reg_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_reg_btn.pressed.connect(func(): _set_tab(Tab.REGISTER))
	tabs.add_child(_tab_reg_btn)

	# Username
	vbox.add_child(_make_field_label("USERNAME"))
	_username_field = _make_lineedit("Enter username…", false)
	_username_field.text_submitted.connect(func(_t): _on_submit_pressed())
	vbox.add_child(_username_field)

	# Password
	vbox.add_child(_make_field_label("PASSWORD"))
	_password_field = _make_lineedit("Enter password…", true)
	_password_field.text_submitted.connect(func(_t): _on_submit_pressed())
	vbox.add_child(_password_field)

	# Email — only shown when REGISTER tab is active
	_email_row = VBoxContainer.new()
	_email_row.add_theme_constant_override("separation", 8)
	_email_row.visible = false
	var email_lbl := _make_field_label("EMAIL  (optional — for future password recovery)")
	_email_row.add_child(email_lbl)
	_email_field = _make_lineedit("Enter email… or leave blank", false)
	_email_row.add_child(_email_field)
	vbox.add_child(_email_row)

	# Status message
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(420, 36)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", ERROR_CLR)
	_status_label.text = ""
	vbox.add_child(_status_label)

	# Submit
	_submit_btn = _make_btn("LOG IN", BTN_NORMAL, BTN_HOVER)
	_submit_btn.pressed.connect(_on_submit_pressed)
	vbox.add_child(_submit_btn)

	# Back
	var back_btn := _make_btn("BACK", BTN_NORMAL, BTN_HOVER)
	back_btn.pressed.connect(queue_free)
	vbox.add_child(back_btn)

	_refresh_tab_style()


# ── TAB SWITCHING ──────────────────────────────────────────────────────────

func _set_tab(tab: Tab) -> void:
	_current_tab = tab
	_status_label.text = ""
	_refresh_tab_style()


func _refresh_tab_style() -> void:
	var login_active := _current_tab == Tab.LOGIN
	_email_row.visible = not login_active
	_submit_btn.text   = "LOG IN" if login_active else "CREATE ACCOUNT"
	_apply_tab_highlight(_tab_login_btn, login_active)
	_apply_tab_highlight(_tab_reg_btn,   not login_active)


func _apply_tab_highlight(btn: Button, active: bool) -> void:
	var bg := TAB_ACTIVE if active else BTN_NORMAL
	var hv := TAB_ACTIVE if active else BTN_HOVER
	_style_btn(btn, bg, hv)
	var col := Color(0.85, 0.78, 1.00) if active else BTN_TEXT
	btn.add_theme_color_override("font_color", col)


# ── CALLBACKS ──────────────────────────────────────────────────────────────

func _on_submit_pressed() -> void:
	var uname := _username_field.text.strip_edges()
	var pass_  := _password_field.text

	if uname.is_empty():
		_show_status("Username cannot be empty.", false)
		return
	if "@" in uname or " " in uname:
		_show_status("Username cannot contain @ or spaces.", false)
		return
	if pass_.length() < 6:
		_show_status("Password must be at least 6 characters.", false)
		return

	_submit_btn.disabled = true
	_show_status("Please wait…", true)

	if _current_tab == Tab.LOGIN:
		PlayerAuth.login(uname, pass_)
	else:
		var email := _email_field.text.strip_edges() if _email_row != null else ""
		PlayerAuth.register(uname, pass_, email)


func _on_register_result(success: bool, message: String) -> void:
	_submit_btn.disabled = false
	_show_status(message, success)
	if success:
		# Auto-close after a moment so the player sees the success message.
		get_tree().create_timer(1.4).timeout.connect(queue_free)


func _on_login_result(success: bool, message: String) -> void:
	_submit_btn.disabled = false
	_show_status(message, success)
	if success:
		get_tree().create_timer(1.0).timeout.connect(queue_free)


func _on_logout_pressed() -> void:
	PlayerAuth.logout()
	queue_free()


# ── UI HELPERS ─────────────────────────────────────────────────────────────

func _show_status(text: String, ok: bool) -> void:
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", SUCCESS_CLR if ok else ERROR_CLR)


func _make_field_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.52, 0.68))
	return lbl


func _make_lineedit(placeholder: String, secret: bool) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.secret = secret
	le.custom_minimum_size = Vector2(420, 44)
	le.add_theme_font_size_override("font_size", 17)
	le.add_theme_color_override("font_color",             Color(0.90, 0.88, 1.00))
	le.add_theme_color_override("font_placeholder_color", Color(0.38, 0.36, 0.48))
	le.add_theme_color_override("caret_color",            ACCENT)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.08, 0.14)
	normal.set_corner_radius_all(5)
	normal.content_margin_left   = 10.0
	normal.content_margin_right  = 10.0
	normal.content_margin_top    = 4.0
	normal.content_margin_bottom = 4.0
	le.add_theme_stylebox_override("normal", normal)
	le.add_theme_stylebox_override("read_only", normal)

	var focus_box := normal.duplicate() as StyleBoxFlat
	focus_box.bg_color    = Color(0.10, 0.10, 0.19)
	focus_box.border_color = ACCENT
	focus_box.set_border_width_all(1)
	le.add_theme_stylebox_override("focus", focus_box)

	return le


func _make_btn(label: String, normal_color: Color, hover_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(420, 56)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color",         BTN_TEXT)
	btn.add_theme_color_override("font_hover_color",   Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	_style_btn(btn, normal_color, hover_color)
	return btn


func _style_btn(btn: Button, normal_color: Color, hover_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_color
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal",  normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
