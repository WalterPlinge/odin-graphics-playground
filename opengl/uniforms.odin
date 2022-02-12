package opengl_uniforms

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
		[3]f32{-0.5, 0.5, 0},
		[3]f32{-0.5, -0.5, 0},
		[3]f32{0.5, -0.5, 0},
		[3]f32{0.5, -0.5, 0},
		[3]f32{0.5, 0.5, 0},
		[3]f32{-0.5, 0.5, 0},
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

	vertex_shader_code := `#version 330
layout (location = 0) in vec3 in_position;
void main() {
	gl_Position = vec4(in_position, 1.0);
}
`



	// let's modify the fragment shader to have a colour uniform
	fragment_shader_code := `#version 330
layout (location = 0) out vec4 out_colour;
uniform vec4 colour;
void main() {
	out_colour = colour;
}
`
	shader_program, _ := gl.load_shaders_source(vertex_shader_code, fragment_shader_code)
	gl.UseProgram(shader_program)

	// this will be our colour value
	colour := [4]f32{
		0.82352941176470588235294117647059,
		0.50980392156862745098039215686275,
		0.21960784313725490196078431372549,
		1.0,
	}

	// we need the uniform location in order to set the value
	uniform_location := gl.GetUniformLocation(shader_program, "colour")

	// and then we can set the value
	gl.Uniform4fv(uniform_location, 1, &colour[0])



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

		gl.DrawArrays(gl.TRIANGLES, 0, cast(i32)len(vertices))

		sdl.GL_SwapWindow(window)
	}
}
