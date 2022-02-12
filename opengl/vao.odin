package opengl_vao

import "core:c"

import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

main :: proc() {
	width, height: c.int = 1280, 720
	sdl.Init(sdl.INIT_VIDEO)
	window := sdl.CreateWindow(
		"Odin SDL2 OpenGL",
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		width,
		height,
		sdl.WindowFlags{.OPENGL},
	)
	opengl_context := sdl.GL_CreateContext(window)
	gl.load_up_to(3, 3, sdl.gl_set_proc_address)
	gl.Viewport(0, 0, width, height)
	gl.ClearColor(
		0.21960784313725490196078431372549,
		0.50980392156862745098039215686275,
		0.82352941176470588235294117647059,
		1.0,
	)



	// lets make the rectangle (screen is -1,-1 to 1,1 and we're not doing any transformations)
	vertices := [][3]f32{
		[3]f32{-0.5,  0.5, 0},
		[3]f32{-0.5, -0.5, 0},
		[3]f32{ 0.5, -0.5, 0},
		[3]f32{ 0.5, -0.5, 0},
		[3]f32{ 0.5,  0.5, 0},
		[3]f32{-0.5,  0.5, 0},
	}

	// this will be our vertex array object (we generate, and then bind to use it)
	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	// let's enable an attribute array for the buffer we need (we'll use array 0)
	gl.EnableVertexAttribArray(0)

	// this will be our vertex buffer object, to hold the rectangle vertices
	vbo: u32
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

	// let's describe the buffer for the VAO (first argument is the array we enabled: 0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, 0)

	// now we can use the vertex data
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)
	// it doesn't appear to require a custom shader, the default should make it white



	running := true
	for running {
		event: sdl.Event
		for sdl.PollEvent(&event) != 0 {
			if event.type == .QUIT {
				running = false
			}
			if event.type == .KEYDOWN && event.key.keysym.scancode == .ESCAPE {
				sdl.PushEvent(&sdl.Event{type = .QUIT})
			}
		}

		gl.Clear(gl.COLOR_BUFFER_BIT)

		// Make sure the vertex array object is bound so opengl knows what to draw
		gl.DrawArrays(gl.TRIANGLES, 0, cast(i32)len(vertices))

		sdl.GL_SwapWindow(window)
	}
}
