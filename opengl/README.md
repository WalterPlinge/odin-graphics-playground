## Examples

- Setup - setting up OpenGL with SDL2 or GLFW3
- VAO - setting up a vertex buffer to hold a rectangle
- VAO Index - setting up an index buffer to determine the draw order of the vertices
- Shaders - setting up a shader program to colour a rectangle
- Uniforms - passing variables to a shader uniform at runtime
- Projection - setting up matrices for 3d
- Normals - using normals for basic lighting
- Models - a simple obj loader to render simple meshes
- sRGB - a shader showing the difference between linear rgb and srgb



## Setup: General steps for setting up OpenGL

- Create a window (needs to support OpenGL)
- Create an OpenGL context on the window
- Load all the OpenGL functions up to the version you require
- Set OpenGL variables and create OpenGL objects for assets (e.g. 2D textures, 3D models)
- Then in the render loop:
	- Clear the OpenGL buffer
	- Do any rendering logic
	- Swap the buffers



## VAO: General steps for drawing an array of vertices

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



## VAO Index: General steps for using an index buffer to draw vertices

- Generate a buffer for indices
- Bind the buffer to `GL_ELEMENT_ARRAY_BUFFER`
- Store the index data in the buffer
- Then in the render loop:
	- Bind the VAO
	- Draw using `glDrawElements` (or a variation)



## Shaders: General steps for creating a shader to use when drawing

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



## Uniforms: General steps for passing a variable to a shader uniform

- Get the location of the uniform
- Set the value using one of many glUniform* functions
	- Matrices will use glUniformMatrix*
	- It will have the length `1, 2, 3, 4`
	- It will have the type `i, u, f, d` for (int, unsigned int, float, doulbe) respectively
	- The functions marked `v` take a pointer to the vector/matrix, rather than each value individually
	- Example: glUniformMatrix4fv will allow you to set a matrix uniform of size 4x4 of type float



## Projection: General steps for setting up matrices for 3d projection

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



## Normals: General steps for using normals for basic lighting

- Normals can be passed to shaders just like positions, using an attribute array
- Normals can be stored in many ways
	- A separate buffer object (buffers will look like [PPP] [NNN])
	- The same buffer object, after the positions (looks like [P P P N N N], the example uses this one)
	- The same buffer obejct, interleaved (looks like [P N P N P N], using `glVertexAttribPointer`'s `stride` parameter)
- You can multiply the colour by the angle between the normal and the direction of a light source
	- This will provide the most basic shading to stop the flat look of the projection example



## Models: General steps to loading a model

- The way the cube is loaded in the normals example is essentially how any other mesh can be loaded
- The `.obj` file format is one of many model formats that exist
	- The simplest cases only require parsing positions and faces (normals and texture coordinates are optional but also simple)
		- Loop through the file and store a list of all the positions and normals etc.
		- Every face will have at least 3 indices referencing the positions/normals/etc.
		- After parsing the file, loop through the indices and build a new list of the indexed positions/normals/etc.
		- This new list is a format compatible with opengl
			- It can be loaded to a VBO and accessed with attribute arrays
	- This example only handles the basics to get the same information used in the normals example
	- This example also scales the model down to fit within a 2x2x2 cube centered at the origin
