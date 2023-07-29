
-- {name, type, device, input}
local bindings = {
	{ "key", "escape" , "quit" },

	{ "key", "s", "save" },
	{ "scancode", "f2", "rename" },
	{ "scancode", "backspace", "backspace" },
	{ "scancode", "return", "confirm" },

	{ "scancode", "delete", "delete" },
	{ "key", "c", "copy" },
	{ "key", "v", "paste" },
	{ "scancode", "pageup", "move up" },
	{ "scancode", "pagedown", "move down" },

	{ "mouse", 1, "click" },
	{ "mouse", 2, "scale" },
	{ "mouse", 4, "scale" },
	{ "scancode", "s", "scale" },
	{ "scancode", "lshift" , "snap" },
	{ "wheel", 1, "zoom in" },
	{ "wheel", -1, "zoom out" },
	{ "mouse", 3, "pan" },

	{ "scancode", "lctrl", "ctrl" },
	{ "scancode", "lalt", "alt" },
}

return bindings
