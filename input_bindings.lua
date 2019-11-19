
-- {name, type, device, input}
local bindings = {
	{ "quit", "button", "key", "escape" },

	{ "save", "button", "key", "s" },
	{ "rename", "button", "scancode", "f2" },
	{ "text", "text", "text", "text" },
	{ "backspace", "button", "scancode", "backspace" },
	{ "confirm", "button", "scancode", "return" },

	{ "delete", "button", "scancode", "delete" },
	{ "copy", "button", "key", "c" },
	{ "paste", "button", "key", "v" },
	{ "move up", "button", "scancode", "pageup"},
	{ "move down", "button", "scancode", "pagedown"},

	{ "click", "button", "mouse", 1 },
	{ "scale", "button", "mouse", 2 },
	{ "scale2", "button", "mouse", 4 },
	{ "snap", "button", "scancode", "lshift" },
	{ "zoom", "axis", "mouse", "wheel y" },
	{ "pan", "button", "mouse", 3 },

	{ "ctrl", "button", "scancode", "lctrl"},
	{ "alt", "button", "scancode", "lalt"},
}

return bindings
