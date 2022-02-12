## Examples

1. Setup - setting up OpenGL with SDL2 or GLFW3
2. VAO - setting up a vertex buffer to hold a rectangle
3. VAO Index - setting up an index buffer to determine the draw order of the vertices
4. Shaders - setting up a shader program to colour a rectangle
5. Uniforms - passing variables to a shader uniform at runtime
6. Projection - setting up matrices for 3d
7. Normals - using normals for basic lighting



### 1 - Setup: General steps for setting up OpenGL

- Create a window (needs to support OpenGL)
- Create an OpenGL context on the window
- Load all the OpenGL functions up to the version you require
- Set OpenGL variables and create OpenGL objects for assets (e.g. 2D textures, 3D models)
- Then in the render loop:
	- Clear the OpenGL buffer
	- Do any rendering logic
	- Swap the buffers



### 2 - VAO: General steps for drawing an array of vertices

- Generate a Vertex Array Object (VAO)
- Bind the VAO to modify
- Enable an attribute array for the buffer
- Generate a Vertex Buffer Object (VBO)
- Bind the VBO to `GL_ARRAY_BUFFER`
- Describe the buffer attributes to the VAO
- Store the vertex data to be drawn in the VBO
- Then in the render loop:
	- Bind the VAO so OpenGL knows what to draw
	- Draw the VAO using `glDrawArrays` (or a variation)



### 3 - VAO Index: General steps for using an index buffer to draw vertices

- Generate a buffer for indices
- Bind the buffer to `GL_ELEMENT_ARRAY_BUFFER`
- Store the index data in the buffer
- Then in the render loop:
	- Bind the VAO
	- Draw using `glDrawElements` (or a variation)



### 4 - Shaders: General steps for creating a shader to use when drawing

- Load the shader code for each stage of the pipeline
	- Vertex shader is required
	- Tessellation, Geometry, and Fragment shaders are optional
- Create shaders for each type
- Point the shaders to the source code
- Compile the shaders
- Create a program
- Attach shaders
- Link program
- Then in the render loop:
	- Use program before drawing



### 5 - Uniforms: General steps for passing a variable to a shader uniform

- Get the location of the uniform
- Set the value using one of many glUniform* functions
	- Matrices will use glUniformMatrix*
	- It will have the length `1, 2, 3, 4`
	- It will have the type `i, u, f, d` for (int, unsigned int, float, doulbe) respectively
	- The functions marked `v` take a pointer to the vector/matrix, rather than each value individually
	- Example: glUniformMatrix4fv will allow you to set a matrix uniform of size 4x4 of type float



### 6 - Projection: General steps for setting up matrices for 3d projection

- Projection matrix
	- Changes a model from model space to screen space
	- Consists of a Model, View, and Perspective matrix (this order specific when they're used, or one expression `P*V*M * vertex`)
		- Model matrix
			- Changes the model vertices from model space to world space
			- Consists of a Scale, Rotation, and Translation matrix (this order specific when they're used, or one expression `T*R*S * vertex`)
		- View matrix
			- Changes the world space to camera space (so the camera is at 0,0)
			- Odin has functions to help with this matrix (core:math/linalg.matrix4_look_at, core:math/linalg/glsl.mat4LookAt)
		- Perspective matrix
			- Changes the camera space to a box that can fit in screen space
			- Odin has functions to help with this matrix (core:math.linalg.matrix4_perspective, core:math/linalg/glsl.mat4Perspective)
- This is easily applied by passing this to a matrix uniform in the vertex shader



### 7 - Normals: using normals for basic lighting

- Normals can be passed to shaders just like positions, using an attribute array
- Normals can be stored in many ways
	- A separate buffer object
	- The same buffer object, after the positions (looks like [P P P N N N], the example uses this one)
	- The same buffer obejct, interleaved (looks like [P N P N P N], using `glVertexAttribPointer`'s `stride` parameter)
