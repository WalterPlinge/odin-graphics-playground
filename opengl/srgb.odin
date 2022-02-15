package opengl_srgb

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

	shader, _ := gl.load_shaders_source(vertex_shader_code, fragment_shader_code)
	gl.UseProgram(shader)

	// we want to draw two halves of the screen differently, so we'll have a width uniform
	gl.Uniform1i(gl.GetUniformLocation(shader, "screen_width"), width)

	// also we'll make 2 triangles to show off the rgb differences
	//odinfmt: disable
	mesh_size: i32 = 6
	mesh := []f32{
		// triangle 1 (XYZ RGB)
		-0.5,  0.7, 0.0,    1.0, 0.0, 0.0,
		-1.0, -0.7, 0.0,    0.0, 1.0, 0.0,
		 0.0, -0.7, 0.0,    0.0, 0.0, 1.0,
		// triangle 2
		 0.5,  0.7, 0.0,    1.0, 0.0, 0.0,
		 0.0, -0.7, 0.0,    0.0, 1.0, 0.0,
		 1.0, -0.7, 0.0,    0.0, 0.0, 1.0,
	}
	//odinfmt: enable
	vao, vbo: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

	// since the position and colour info is interleaved, we'll specify the stride
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(mesh[0]), 0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(mesh[0]), 3 * size_of(mesh[0]))
	gl.BufferData(gl.ARRAY_BUFFER, len(mesh) * size_of(mesh[0]), raw_data(mesh), gl.STATIC_DRAW)

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

		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.DrawArrays(gl.TRIANGLES, 0, mesh_size)

		sdl.GL_SwapWindow(window)
	}
}

vertex_shader_code := `#version 330
layout (location = 0) in vec3 in_position;
layout (location = 1) in vec3 in_colour;
out vec3 colour;
void main() {
	gl_Position = vec4(in_position, 1.0);
	colour = in_colour;
}
`
fragment_shader_code := `#version 330
layout (location = 0) out vec4 out_colour;
in vec3 colour;
uniform int screen_width;
vec3 linear_to_srgb(vec3 linear_rgb) {
	bvec3 cutoff = lessThan(linear_rgb, vec3(0.0031308));
	vec3 higher = 1.055 * pow(linear_rgb, vec3(1.0 / 2.4)) - 0.055;
	vec3 lower = linear_rgb * 12.92;
	return mix(higher, lower, cutoff);
}
vec3 srgb_to_linear(vec3 srgb) {
	bvec3 cutoff = lessThan(srgb, vec3(0.04045));
	vec3 higher = pow((srgb + 0.055) / 1.055, vec3(2.4));
	vec3 lower = srgb / 12.92;
	return mix(higher, lower, cutoff);
}
void main() {
	if (gl_FragCoord.x < screen_width / 2) {
		out_colour = vec4(colour, 1.0);
	} else {
		out_colour = vec4(linear_to_srgb(colour), 1.0);
	}
}
`
