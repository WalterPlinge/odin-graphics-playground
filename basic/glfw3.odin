package main

import "core:c"

import "vendor:OpenGL"
import "vendor:glfw"

main :: proc() {
	width, height : c.int = 1280, 720

	// initialise glfw
	glfw.Init()

	// create a window (this also makes an opengl context)
	window := glfw.CreateWindow(width, height, "Odin GLFW OpenGL", nil, nil)

	// we still need to use the context though
	glfw.MakeContextCurrent(window)

	// glfw uses callbacks to handle input events
	key_callback : glfw.KeyProc : proc "c" (window : glfw.WindowHandle, key, scancode, action, mods : c.int) {
		if key == glfw.KEY_ESCAPE && action == glfw.PRESS {
			glfw.SetWindowShouldClose(window, glfw.TRUE)
		}
	}
	glfw.SetKeyCallback(window, key_callback)

	// need to load opengl functions (using a handy glfw function)
	OpenGL.load_up_to(3, 1, glfw.gl_set_proc_address)

	// set a couple opengl options (like a nice green color)
	OpenGL.Viewport(0, 0, width, height)
	OpenGL.ClearColor(0.2, 0.7, 0.3, 1.0)

	for !glfw.WindowShouldClose(window) {
		// poll all events currently recieved
		glfw.PollEvents()
		// we could also call WaitEvents() if we only need to update after an event

		// now we clear the buffer
		OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

		// any rendering would go here

		// and tell glfw to swap the window's display buffers
		// (the one being shown with the one we've just rendered)
		glfw.SwapBuffers(window)
	}
}
