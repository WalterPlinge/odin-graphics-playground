# Odin OpenGL SDL2 GLFW3 Playground
Playground for OpenGL in Odin using SDL2 or GLFW3

Required Windows DLL files (SDL2.dll, glfw3.dll) should come with the vendor libraries of the Odin compiler

[https://github.com/Odin-Lang/Odin]

Run each example with `odin run <example>/<filename>.odin`
- Make sure to have the Windows DLLs where they can be found (this repo's root folder would work)
- Odin Language Server (OLS) users may also see highlighted errors, as each version redeclares `main`

Examples:
- Basic
	- creates an OpenGL window with a green color
	- the `ESCAPE` key will close the window
	- no error handling tho
