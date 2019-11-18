
function love.conf(t)
    t.console = false                    -- Attach a console (boolean, Windows only)
    t.window.title = "Multiviewer 2.0"     -- The window title (string)
    t.window.width = 800                -- The window width (number)
    t.window.height = 600               -- The window height (number)
    t.window.borderless = false         -- Remove all border visuals from the window (boolean)
    t.window.resizable = true           -- Let the window be user-resizable (boolean)
    t.window.fullscreen = false         -- Enable fullscreen (boolean)
    t.window.fullscreentype = "desktop" -- Choose between "desktop" fullscreen or "exclusive" fullscreen mode (string)
    t.window.vsync = 1                  -- Vertical sync mode (number)
    t.window.display = 1                -- Index of the monitor to show the window in (number)
end
