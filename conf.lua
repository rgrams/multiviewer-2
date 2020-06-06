
function love.conf(t)
	t.console = false
	t.window.title = "Multiviewer 2.1 - No project"
	t.window.icon = "Multiviewer_icon.png"
	t.window.width = 800
	t.window.height = 600
	t.window.borderless = false
	t.window.resizable = true
	t.window.fullscreen = false
	t.window.fullscreentype = "desktop"
	t.window.vsync = 1
	t.window.display = 1

	t.modules.audio = false
	t.modules.data = false
	t.modules.event = true
	t.modules.font = true
	t.modules.graphics = true
	t.modules.image = true
	t.modules.joystick = false
	t.modules.keyboard = true
	t.modules.math = false
	t.modules.mouse = true
	t.modules.physics = false
	t.modules.sound = false
	t.modules.system = false
	t.modules.thread = false
	t.modules.timer = true
	t.modules.touch = true
	t.modules.video = false
	t.modules.window = true
end
