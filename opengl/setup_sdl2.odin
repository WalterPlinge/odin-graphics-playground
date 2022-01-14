package opengl_setup_sdl2

import "core:c"

import "vendor:OpenGL"
import "vendor:sdl2"

main :: proc() {
	width, height : c.int = 1280, 720

	// initialise sdl2
	sdl2.Init(sdl2.INIT_VIDEO)

	// create a centered, opengl window
	window := sdl2.CreateWindow("Odin SDL2 OpenGL", sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, width, height, sdl2.WindowFlags{ .OPENGL })

	// also a context
	opengl_context := sdl2.GL_CreateContext(window)

	// need to load opengl functions (using a handy sdl2 function)
	OpenGL.load_up_to(3, 1, sdl2.gl_set_proc_address)

	// set a couple opengl options (like a nice blue color)
	OpenGL.Viewport(0, 0, width, height)
	OpenGL.ClearColor(0.21960784313725490196078431372549, 0.50980392156862745098039215686275, 0.82352941176470588235294117647059, 1.0)

	running := true
	for running {
		// this is our event loop for input processing
		event : sdl2.Event
		for sdl2.PollEvent(&event) != 0 {
			if event.type == .QUIT {
				running = false
			}
			if event.type == .KEYDOWN && event.key.keysym.scancode == .ESCAPE {
				sdl2.PushEvent(&sdl2.Event{ type = .QUIT })
			}
		}

		// now we clear the buffer
		OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

		// any rendering would go here

		// and tell sdl to swap the window's display buffers
		// (the one being shown with the one we've just rendered)
		sdl2.GL_SwapWindow(window)
	}
}
