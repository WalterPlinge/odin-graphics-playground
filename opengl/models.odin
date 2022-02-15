package opengl_models

import "core:c"
import "core:math/linalg/glsl"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

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

	// I'm going to move the shader code down under main to save space up here
	// you could easily have them in their own files and load them with `gl.load_shaders_files`
	shader, _ := gl.load_shaders_source(vertex_shader_code, fragment_shader_code)
	gl.UseProgram(shader)

	model := glsl.mat4(1.0)
	view := glsl.mat4LookAt(eye = 0.7 * {3, 1, 1}, centre = {0, 0, 0}, up = {0, 0, 1})
	perspective := glsl.mat4Perspective(glsl.radians(f32(60)), f32(width) / f32(height), 0.1, 100)

	gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "model"), 1, false, &model[0, 0])
	gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "view"), 1, false, &view[0, 0])
	gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "perspective"), 1, false, &perspective[0, 0])

	// we can load models as well (put this in a function because it's kinda big)
	mesh, mesh_size := load_model("assets/models/minicooper.obj"); defer delete(mesh)
	vao, vbo: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, 0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 0, 3 * size_of(mesh[0]) * uintptr(mesh_size))
	gl.BufferData(gl.ARRAY_BUFFER, len(mesh) * size_of(mesh[0]), raw_data(mesh), gl.STATIC_DRAW)

	old_time := time.now()
	running := true
	for running {
		delta_time := time.duration_seconds(time.diff(old_time, time.now()))
		old_time = time.now()

		event: sdl.Event
		for sdl.PollEvent(&event) != 0 {
			if event.type == .QUIT {
				running = false
			}
			if event.type == .KEYDOWN && event.key.keysym.scancode == .ESCAPE {
				sdl.PushEvent(&sdl.Event{type = .QUIT})
			}
		}

		model = glsl.mat4Rotate({0, 0, 1}, glsl.radians(f32(30 * delta_time))) * model
		gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "model"), 1, false, &model[0, 0])

		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.DrawArrays(gl.TRIANGLES, 0, mesh_size)

		sdl.GL_SwapWindow(window)
	}
}

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
fragment_shader_code := `#version 330
layout (location = 0) out vec4 out_colour;
in vec4 normal;
vec4 colour = vec4(0.82352941176470588235294117647059, 0.50980392156862745098039215686275, 0.21960784313725490196078431372549, 1.0);
void main() {
	vec3 sun_dir = normalize(vec3(2, 3, 5));
	float angle = dot(normal.xyz, sun_dir);
	angle = angle / 2.0 + 0.5;
	out_colour = colour * angle * angle;
}
`

load_model :: proc(filename: string) -> (mesh: []f32, mesh_size: i32) {
	// obj files are complicated, and they handle more than just a bunch of triangles
	// so this will only be the most naive loader
	data, _ := os.read_entire_file(filename); defer delete(data)
	line_iterator := string(data)

	// we're only going to read positions, normals, and faces right now
	positions: [dynamic][3]f32; defer delete(positions)
	normals: [dynamic][3]f32; defer delete(normals)
	indices: [dynamic][2]int; defer delete(indices)

	// let's keep track of the model bounds so we can condense it down to a range of [-1,1]
	bounds := [2][3]f32{{max(f32), max(f32), max(f32)}, {min(f32), min(f32), min(f32)}}

	// let's go
	for l in strings.split_lines_iterator(&line_iterator) {
		// we can just skip if it's an empty line or a comment
		if len(l) == 0 || l[0] == '#' do continue

		tokens := strings.fields(l, context.temp_allocator)

		switch tokens[0] {
		case "v":
			position: [3]f32
			position.x, _ = strconv.parse_f32(tokens[1])
			position.y, _ = strconv.parse_f32(tokens[2])
			position.z, _ = strconv.parse_f32(tokens[3])
			append(&positions, position)

			// update our bounds
			for p, i in position {
				if p < bounds[0][i] do bounds[0][i] = p
				if p > bounds[1][i] do bounds[1][i] = p
			}

		case "vn":
			normal: [3]f32
			normal.x, _ = strconv.parse_f32(tokens[1])
			normal.y, _ = strconv.parse_f32(tokens[2])
			normal.z, _ = strconv.parse_f32(tokens[3])
			append(&normals, cast([3]f32)glsl.normalize(glsl.vec3(normal)))

		case "f":
			// let's assume that a face will only have 3 vertices, because we want triangles
			for t in tokens[1:] {
				vertex := strings.split(t, "/", context.temp_allocator)
				index: [2]int
				index.x, _ = strconv.parse_int(vertex[0])
				index.y, _ = strconv.parse_int(vertex[2])
				append(&indices, index)
			}
		}
	}

	// now we know the bounds of the model, we can normalise the positions to [-1, 1]
	range := bounds[1] - bounds[0]
	div := max(range.x, range.y, range.z)
	for p in &positions {
		// subtract the lower bound to move p between 0 and `div`
		// multiply by 2 (so it's 2x range) so we can subtract the range and have it centered on the origin
		// then divide to move p between -1 and 1
		p = ((p - bounds[0]) * 2 - range) / div
	}

	// this will be the buffer we pass back, containing all the positions followed by all the normals
	buffer: [dynamic]f32
	for i, p in indices {
		pos := positions[i[0] - 1]
		append(&buffer, pos.x, pos.y, pos.z)
	}
	for i in indices {
		normal := normals[i[1] - 1]
		append(&buffer, normal.x, normal.y, normal.z)
	}

	return buffer[:], i32(len(indices))
}
