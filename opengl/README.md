## Examples

- Setup - setting up OpenGL with SDL2 or GLFW3
- VAO - setting up a vertex buffer to hold a rectangle
- Shaders - setting up a shader program to colour a rectangle



## General steps for setting up OpenGL

- Create a window (needs to support OpenGL)
- Create an OpenGL context on the window
- Load all the OpenGL functions up to the version you require
- Set OpenGL variables and create OpenGL objects for assets (e.g. 2D textures, 3D models)
- Then in the render loop:
	- Clear the OpenGL buffer
	- Do any rendering logic
	- Swap the buffers



## General steps for drawing an array of vertices

- Generate a Vertex Array Object (VAO)
- Bind the VAO to modify
- Enable an attribute array for the buffer
- Generate a Vertex Buffer Object (VBO)
- Bind the VBO to GL_ARRAY_BUFFER
- Describe the buffer attributes to the VAO
- Store the vertex data to be drawn in the VBO
- Then in the render loop:
	- Bind the VAO so OpenGL knows what to draw
	- Draw the VAO



## General steps for creating a shader to use when drawing

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
