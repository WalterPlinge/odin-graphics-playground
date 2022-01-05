## General steps for setting up OpenGL

- Create a window (needs to support OpenGL)
- Create an OpenGL context on the window
- Load all the OpenGL functions up to the version you require
- Set OpenGL variables and create OpenGL objects for assets (e.g. 2D textures, 3D models)
- Then in the render loop:
	- Clear the OpenGL buffer
	- Do any rendering logic
	- Swap the buffers

## Examples
- Setup - setting up OpenGL with SDL2 or GLFW3
