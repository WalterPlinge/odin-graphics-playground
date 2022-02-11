## Examples

- Setup - setting up OpenGL with SDL2 or GLFW3
- VAO - setting up a vertex buffer to hold a rectangle
- VAO Index - setting up a vertex buffer to be indexed when drawn
- Shaders - setting up a shader program to colour a rectangle
- Uniforms - setting up a shader to pass in data as a uniform variable at runtime



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
	- Draw the VAO using glDrawArrays (or a variation)



## General steps for using an index buffer to draw vertices

- Generate a buffer for indices
- Bind the buffer to GL_ELEMENT_ARRAY_BUFFER
- Store the index data in the buffer
- Then in the render loop:
	- Bind the VAO
	- Draw using glDrawElements (or a variation)



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



## General steps for passing a uniform variable to a shader

- Get the location of the uniform
- Set the value using one of many glUniform* functions
	- Matrices will use glUniformMatrix*
	- It will have the length (1, 2, 3, 4)
	- It will have the type (i, u, f, d) for (int, unsigned int, float, doulbe) respectively
	- The functions marked "v" take a pointer to the vector/matrix, rather than each value individually
	- Example: glUniformMatrix4fv will allow you to set a matrix uniform of size 4x4 of type float
