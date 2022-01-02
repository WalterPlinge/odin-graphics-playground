# Odin OpenGL SDL2 GLFW3 Playground
Playground for OpenGL in Odin using SDL2 or GLFW3

Required DLL files (SDL2.dll, glfw3.dll) should come with the vendor libraries of the Odin compiler

[https://github.com/Odin-Lang/Odin]

Run each example with `odin run <example>/<filename>.odin`
- DLLs must be in the folder you run the command from for the executable to find it
- Odin Language Server (OLS) users may also see highlighted errors, as each version redeclares `main`

Examples:
- Basic - creates an OpenGL window with a green color, the `ESCAPE` key will close the window
