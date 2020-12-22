
# MultiViewer 2
_A very basic multi-image viewer intended for displaying art references. Made with Love2D._

A rewrite of my [Defold Multiviewer](https://github.com/rgrams/multiviewer) in Love2D.

![Demo .gif of the Defold version](demo.gif)

### Missing features from Defold version:
* No native file dialogs (which only worked on Windows and MacOS anyway).

### Added features from Defold version:
* No CPU cost at rest
	- The window is only redrawn when you interact with it, so the CPU load should be pretty much zero when the program is just sitting there.
* Can accept a command-line argument to open a project file on startup.
	- Therefore you can associate the ".multiview" file type with the executable and then double-click on those files to open them.
* Zoom to the mouse cursor position.
* Ctrl-Middle-Mouse drag to zoom precisely.
* Show asterisk in window title when project has unsaved changes.
	- Panning or zooming the camera counts as a change and is saved in file.

### Controls
* Drag and drop images or folders-of-images onto the window to add them.
* <kbd>Delete</kbd> -- Removes hovered image.
* <kbd>Ctrl-S</kbd> -- Save project
	- Saves the project file opened at startup, OR saves as "_project.multiview" in the executable's folder (will overwrite).
* <kbd>Left-Click-Drag</kbd> -- Move image
* <kbd>Right-Click OR Mouse-Button-4 & Drag</kbd> -- Scale image
* <kbd>Middle-Click-Drag</kbd> -- Pan Viewport
* <kbd>Ctrl-Middle-Click-Drag</kbd> -- Zoom viewport.
* <kbd>Mouse Wheel</kbd> -- Zoom Viewport
* <kbd>Page Up</kbd> -- Move image under cursor up in draw order
	- Hold Ctrl to move all the way to the top.
* <kbd>Page Down</kbd> -- Move image under cursor down in draw order
	- Hold Ctrl to move all the way to the bottom.
* <kbd>Alt-Enter</kbd> -- Toggle borderless window mode.

#### Notes on Saving & Loading Projects
* Opening a .multiview file just adds in the saved images to your viewport, it won't remove any images you've already loaded.
* Saving a project will record all the images you have open.
