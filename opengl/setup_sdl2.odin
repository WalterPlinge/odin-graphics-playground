package opengl_setup_sdl2

import "core:c"

import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

main :: proc() {
	width, height : c.int = 1280, 720

	// initialise sdl2
	sdl.Init(sdl.INIT_VIDEO)

	// create a centered, opengl window
	window := sdl.CreateWindow("Odin SDL2 OpenGL", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, width, height, sdl.WindowFlags{ .OPENGL })

	// also a context
	opengl_context := sdl.GL_CreateContext(window)

	// need to load opengl functions (using a handy sdl function)
	gl.load_up_to(3, 3, sdl.gl_set_proc_address)

	// set a couple opengl options (like a nice blue color)
	gl.Viewport(0, 0, width, height)
	gl.ClearColor(0.21960784313725490196078431372549, 0.50980392156862745098039215686275, 0.82352941176470588235294117647059, 1.0)

	running := true
	for running {
		// this is our event loop for input processing
		event : sdl.Event
		for sdl.PollEvent(&event) != 0 {
			if event.type == .QUIT {
				running = false
			}
			if event.type == .KEYDOWN && event.key.keysym.scancode == .ESCAPE {
				sdl.PushEvent(&sdl.Event{ type = .QUIT })
			}
		}

		// now we clear the buffer
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// any rendering would go here

		// and tell sdl to swap the window's display buffers
		// (the one being shown with the one we've just rendered)
		sdl.GL_SwapWindow(window)
	}
}
