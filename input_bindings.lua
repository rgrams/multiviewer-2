
-- {name, type, device, input}
local bindings = {
	{ "quit", "button", "key", "escape" },
	{ "reset", "button", "scancode", "delete" },
	{ "pause", "button", "key", "rshift" },

	{ "save", "button", "scancode", ";" },
	{ "rename", "button", "scancode", "f2" },
	{ "set script", "button", "scancode", "s" },
	{ "text", "text", "text", "text" },
	{ "backspace", "button", "scancode", "backspace" },
	{ "confirm", "button", "scancode", "return" },

	{ "add", "button", "scancode", "a" },
	{ "delete", "button", "scancode", "delete" },
	{ "reparent", "button", "scancode", "r" },

	{ "click", "button", "mouse", 1 },
	{ "scale", "button", "mouse", 2 },
	{ "snap", "button", "scancode", "lshift" },
	{ "zoom", "axis", "mouse", "wheel y" },
	{ "pan", "button", "mouse", 3 },
}

return bindings
