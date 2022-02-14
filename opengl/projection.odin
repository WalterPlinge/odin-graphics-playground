package opengl_projection

import "core:c"
import "core:math/linalg/glsl"

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

	// we have a cube
	vertices := [][3]f32{
		{-0.5,  0.5,  0.5},
		{-0.5, -0.5,  0.5},
		{ 0.5, -0.5,  0.5},
		{ 0.5,  0.5,  0.5},
		{-0.5,  0.5, -0.5},
		{-0.5, -0.5, -0.5},
		{ 0.5, -0.5, -0.5},
		{ 0.5,  0.5, -0.5},
	}
	indices := []u8{
		// 0 1 2 3 front
		0, 1, 2, 2, 3, 0,
		// 0 3 7 4 top
		0, 3, 7, 7, 4, 0,
		// 0 4 5 1 left
		0, 4, 5, 5, 1, 0,
		// 6 5 4 7 back
		6, 5, 4, 4, 7, 6,
		// 6 7 3 2 right
		6, 7, 3, 3, 2, 6,
		// 6 2 1 5 bottom
		6, 2, 1, 1, 5, 6,
	}
	vao, vbo, ibo: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)
	gl.GenBuffers(1, &ibo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(indices[0]),
		raw_data(indices),
		gl.STATIC_DRAW,
	)
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



	// let's modify the shaders to have a projection matrix
	vertex_shader_code := `#version 330
layout (location = 0) in vec3 in_position;
uniform mat4 projection;
void main() {
	gl_Position = projection * vec4(in_position, 1.0);
}
`
	fragment_shader_code := `#version 330
layout (location = 0) out vec4 out_colour;
uniform vec4 colour;
void main() {
	out_colour = colour;
}
`
	shader_program, _ := gl.load_shaders_source(vertex_shader_code, fragment_shader_code)
	gl.UseProgram(shader_program)

	colour := [4]f32{
		0.82352941176470588235294117647059,
		0.50980392156862745098039215686275,
		0.21960784313725490196078431372549,
		1.0,
	}
	gl.Uniform4fv(gl.GetUniformLocation(shader_program, "colour"), 1, &colour[0])



	// let's keep our cube in the centre of the world
	model := glsl.mat4(1.0)

	// we can position our camera, and look towards a target, we also need to know what 'up' is
	camera := glsl.vec3{2, 2, 2}
	target := glsl.vec3{0, 0, 0}
	up := glsl.vec3{0, 0, 1}
	view := glsl.mat4LookAt(camera, target, up)

	// and here's our camera's frustrum
	// we need our vertical field of view, the aspect ratio of the window, and the near and far planes
	fovy := glsl.radians(f32(60))
	aspect := f32(width) / f32(height)
	near, far: f32 = 0.1, 100.0
	perspective := glsl.mat4Perspective(fovy, aspect, near, far)

	// now we can put them all together
	projection := perspective * view * model

	// and put in in our shader
	gl.UniformMatrix4fv(gl.GetUniformLocation(shader_program, "projection"), 1, false, &projection[0, 0])



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

		gl.DrawElements(
			gl.TRIANGLES,
			cast(i32)len(indices),
			gl.UNSIGNED_BYTE,
			rawptr(uintptr(0)),
		)

		sdl.GL_SwapWindow(window)
	}
}
