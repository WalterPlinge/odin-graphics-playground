package obj

import "core:math/linalg"
import "core:os"
import "core:strconv"
import "core:strings"

Vertex :: struct {
	position: [3]f32,
	normal: [3]f32,
}

load_file :: proc(filename: string) -> (mesh: []Vertex) {
	// obj files are complicated, and they handle more than just a bunch of triangles
	// so this will only be the most naive loader
	vertices: [dynamic]Vertex

	// load the whole file for now
	data, _ := os.read_entire_file(filename); defer delete(data)

	// we're only going to read positions and normals right now
	positions: [dynamic][3]f32; defer delete(positions)
	normals: [dynamic][3]f32; defer delete(normals)

	// let's keep track of the model bounds so we can condense it down to a range of [-1,1]
	bounds := [2][3]f32{{max(f32), max(f32), max(f32)}, {min(f32), min(f32), min(f32)}}

	iterator := string(data)
	for l in strings.split_lines_iterator(&iterator) {
		// we can just skip if it's an empty line or a comment
		if len(l) == 0 || l[0] == '#' do continue

		tokens := strings.fields(l, context.temp_allocator)
		switch tokens[0] {
		case "v":
			pos: [3]f32
			pos.x, _ = strconv.parse_f32(tokens[1])
			pos.y, _ = strconv.parse_f32(tokens[2])
			pos.z, _ = strconv.parse_f32(tokens[3])
			append(&positions, pos)

			// update our bounds
			for p, i in pos {
				if p < bounds[0][i] do bounds[0][i] = p
				if p > bounds[1][i] do bounds[1][i] = p
			}

		case "vn":
			normal: [3]f32
			normal.x, _ = strconv.parse_f32(tokens[1])
			normal.y, _ = strconv.parse_f32(tokens[2])
			normal.z, _ = strconv.parse_f32(tokens[3])
			append(&normals, linalg.normalize(normal))

		case "f":
			// we will only handle 3 vertices properly (no triangle fan), because we want triangles
			for t in tokens[1:] {
				vertex := strings.split(t, "/", context.temp_allocator)
				// this currently doesn't handle negative indices
				pos_index, _ := strconv.parse_int(vertex[0])
				normal_index, _ := strconv.parse_int(vertex[2])
				append(&vertices, Vertex{
					positions[pos_index - 1],
					normals[normal_index - 1],
				})
			}
		}
	}

	// (optional) now we know the bounds of the model, we can normalise the positions to [-1, 1]
	range := bounds[1] - bounds[0]
	div := max(range.x, range.y, range.z)
	for v in &vertices {
		// subtract the lower bound to move p between 0 and `div`
		// multiply by 2 (so it's 2x range) so we can subtract the range and have it centered on the origin
		// then divide to move p between -1 and 1
		v.position = ((v.position - bounds[0]) * 2 - range) / div
	}

	return vertices[:]
}
