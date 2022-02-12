package opengl_setup_glfw3

import "core:c"

import gl "vendor:OpenGL"
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
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	// set a couple opengl options (like a nice blue color)
	gl.Viewport(0, 0, width, height)
	gl.ClearColor(0.21960784313725490196078431372549, 0.50980392156862745098039215686275, 0.82352941176470588235294117647059, 1.0)

	for !glfw.WindowShouldClose(window) {
		// poll all events currently recieved
		glfw.PollEvents()
		// we could also call WaitEvents() if we only need to update after an event

		// now we clear the buffer
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// any rendering would go here

		// and tell glfw to swap the window's display buffers
		// (the one being shown with the one we've just rendered)
		glfw.SwapBuffers(window)
	}
}
