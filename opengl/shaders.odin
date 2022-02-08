package opengl_shaders

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

	vertices := [][3]f32{
		[3]f32{-0.5,  0.5, 0},
		[3]f32{-0.5, -0.5, 0},
		[3]f32{ 0.5, -0.5, 0},
		[3]f32{ 0.5, -0.5, 0},
		[3]f32{ 0.5,  0.5, 0},
		[3]f32{-0.5,  0.5, 0},
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



	// we can have a small shader to colour the rectangle (ginger)
	vertex_shader_code : cstring = `#version 330
layout (location = 0) in vec3 in_position;
void main() {
	gl_Position = vec4(in_position, 1.0);
}
`
	fragment_shader_code : cstring = `#version 330
layout (location = 0) out vec4 out_colour;
void main() {
	out_colour = vec4(
		0.82352941176470588235294117647059,
		0.50980392156862745098039215686275,
		0.21960784313725490196078431372549,
		1.0);
}
`
	// now we can compile the shaders
	vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertex_shader, 1, &vertex_shader_code, nil)
	gl.CompileShader(vertex_shader)

	fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragment_shader, 1, &fragment_shader_code, nil)
	gl.CompileShader(fragment_shader)

	// and link the program
	shader_program := gl.CreateProgram()
	gl.AttachShader(shader_program, vertex_shader)
	gl.AttachShader(shader_program, fragment_shader)
	gl.LinkProgram(shader_program)

	// we need to tell opengl to use the program (this can be done during a frame when using multiple programs)
	gl.UseProgram(shader_program)



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

		// Make sure the program is being used so opengl knows how to draw
		gl.DrawArrays(gl.TRIANGLES, 0, cast(i32) len(vertices))

		sdl.GL_SwapWindow(window)
	}
}
