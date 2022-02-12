package opengl_perspective

import "core:c"
import "core:fmt"
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
	gl.Enable(gl.DEPTH_TEST)
	gl.Viewport(0, 0, width, height)
	gl.ClearColor(
		0.21960784313725490196078431372549,
		0.50980392156862745098039215686275,
		0.82352941176470588235294117647059,
		1.0,
	)



	// our cube is a list of positions, followed by normals
	cube, vertex_count := generate_cube()

	// we can also pack our data in one VBO, we can still use multiple attribute arrays
	vao, vbo: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, 0)

	// attribute array 1 will be normals (offset is where normals start)
	offset := uintptr(vertex_count) * 3 * size_of(cube[0])
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 0, offset)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(cube) * size_of(cube[0]),
		raw_data(cube),
		gl.STATIC_DRAW,
	)

	// we will take the model, view, and perspective matrices as separate uniforms
	// we calculate the normal going to the fragment shader using only the model matrix for world normals
	vertex_shader_code := `#version 330
layout (location = 0) in vec3 in_position;
layout (location = 1) in vec3 in_normal;
out vec4 normal;
uniform mat4 model;
uniform mat4 view;
uniform mat4 perspective;
void main() {
	gl_Position = perspective * view * model * vec4(in_position, 1.0);
	normal = model * vec4(in_normal, 1.0);
}
`
	// we take in the normal from the vertex shader, and add some lighting to take advantage of it
	fragment_shader_code := `#version 330
layout (location = 0) out vec4 out_colour;
in vec4 normal;
uniform vec4 colour;
void main() {
	vec3 sun_dir = normalize(vec3(2, 3, 5));
	float angle = dot(normal.xyz, sun_dir);
	angle = angle / 2.0 + 0.5;
	angle = angle * angle;
	out_colour = colour * angle;
}
`
	shader, _ := gl.load_shaders_source(vertex_shader_code, fragment_shader_code)
	gl.UseProgram(shader)

	colour := [4]f32{
		0.82352941176470588235294117647059,
		0.50980392156862745098039215686275,
		0.21960784313725490196078431372549,
		1.0,
	}
	gl.Uniform4fv(gl.GetUniformLocation(shader, "colour"), 1, &colour[0])

	model := glsl.mat4(1.0)
	gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "model"), 1, false, &model[0, 0])

	view := glsl.mat4LookAt(eye = {2, 2, 2}, centre = {0, 0, 0}, up = {0, 0, 1})
	gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "view"), 1, false, &view[0, 0])

	perspective := glsl.mat4Perspective(
		fovy = glsl.radians(f32(60)),
		aspect = f32(width) / f32(height),
		near = 0.1,
		far = 100,
	)
	gl.UniformMatrix4fv(
		gl.GetUniformLocation(shader, "perspective"),
		1,
		false,
		&perspective[0, 0],
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

		// we can also rotate the cube 1 degree every frame for a little animation
		// we need to update the uniform every time we change it though
		model = glsl.mat4Rotate({0, 0, 1}, glsl.radians(f32(1))) * model
		gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "model"), 1, false, &model[0, 0])

		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.DrawArrays(gl.TRIANGLES, 0, vertex_count)

		sdl.GL_SwapWindow(window)
	}
}

//odinfmt: disable
generate_cube :: proc() -> (cube: []f32, vertex_count: i32) {
	@static vertex_data := []glsl.vec3{
		{ 0.5,  0.5,  0.5},
		{ 0.5, -0.5,  0.5},
		{ 0.5, -0.5, -0.5},
		{ 0.5,  0.5, -0.5},
		{-0.5,  0.5,  0.5},
		{-0.5, -0.5,  0.5},
		{-0.5, -0.5, -0.5},
		{-0.5,  0.5, -0.5},
	}
	@static indices := []u8{
		// 0 1 2 3 front (from top right facing)
		0, 1, 2, 2, 3, 0,
		// 0 3 7 4 right
		0, 3, 7, 7, 4, 0,
		// 0 4 5 1 top
		0, 4, 5, 5, 1, 0,
		// 6 5 4 7 back (from bottom right facing)
		6, 5, 4, 4, 7, 6,
		// 6 2 1 5 left
		6, 2, 1, 1, 5, 6,
		// 6 7 3 2 bottom
		6, 7, 3, 3, 2, 6,
	}
	@static normal_data := []glsl.vec3{
		{ 1, 0, 0},
		{ 0, 1, 0},
		{ 0, 0, 1},
		{-1, 0, 0},
		{ 0,-1, 0},
		{ 0, 0,-1},
	}

	// fill buffer with positions then normals
	buffer: [dynamic]f32
	for index in indices do append(&buffer, vertex_data[index].x, vertex_data[index].y, vertex_data[index].z)
	for _ , i in indices do append(&buffer, normal_data[i / 6].x, normal_data[i / 6].y, normal_data[i / 6].z)
	return buffer[:], i32(len(indices))
}
//odinfmt: enable
