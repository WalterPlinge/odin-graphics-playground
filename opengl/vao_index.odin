package opengl_vao_index

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



	// this time we only need the unique vertices, as the indices will define the drawing order and can reuse vertices
	vertices := [][3]f32{
		[3]f32{-0.5,  0.5, 0},
		[3]f32{-0.5, -0.5, 0},
		[3]f32{ 0.5, -0.5, 0},
		[3]f32{ 0.5,  0.5, 0},
	}
	vao, vbo: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, 0)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)

	// these are the indices, the order in which to draw the vertices
	indices := []u32{0, 1, 2, 2, 3, 0}

	// we need another buffer to store them (we don't need to enable an attribute array for this though)
	ibo: u32
	gl.GenBuffers(1, &ibo)

	// it gets bound and used from the point GL_ELEMENT_ARRAY_BUFFER
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(indices[0]),
		raw_data(indices),
		gl.STATIC_DRAW,
	)



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

		// we use the DrawElements function to tell it what type the indices are, and which position to start
		gl.DrawElements(gl.TRIANGLES, cast(i32)len(indices), gl.UNSIGNED_INT, rawptr(uintptr(0)))

		sdl.GL_SwapWindow(window)
	}
}
