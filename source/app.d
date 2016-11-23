import std.stdio;

// For core API functions.
import derelict.opengl3.gl;
import derelict.sdl2.sdl;
import std.conv;

struct init_opengl_result
{
    SDL_Window* window;
    SDL_GLContext context;

    bool opCast(T : bool)()
    {
        return window !is null;
    }
}

init_opengl_result InitOpenGL(uint winHeight = 0, uint winWidth = 0)
{
    init_opengl_result Result;
    // Load OpenGL versions 1.0 and 1.1.
    DerelictGL.load();
    DerelictSDL2.load();
    // Initialize SDL Video subsystem.
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        // SDL_Init returns a negative number on error.
        writeln("SDL Video subsystem failed to initialize");
        return init_opengl_result.init;
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

    Result.window = SDL_CreateWindow("Hello Triangle", SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED, winWidth, winHeight, SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN);
    if (!Result.window)
        throw new Error("Failed to create window: " ~ to!string(SDL_GetError()));

    Result.context = SDL_GL_CreateContext(Result.window);
    SDL_GL_MakeCurrent(Result.window, Result.context);
    glViewport(0,0, 1024, 786);
    SDL_GL_SetSwapInterval(0);
    if (!Result.context)
        throw new Error("Failed to create GL context: " ~ to!string(SDL_GetError()));
    DerelictGL3.reload();

    return Result;
}

void ShutdownOpenGL(init_opengl_result gl)
{
    // Deinitialize SDL at exit.
    SDL_GL_DeleteContext(gl.context);
    SDL_Quit();

    DerelictGL3.unload();
    DerelictSDL2.unload();
}

int main()
{
    auto ctx = InitOpenGL();
    GLuint vertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    enum xInit = 3096;
    enum xInv = 1.0/xInit;
    int x = xInit;
	glClearColor(1.0, 1.0, 1.0, 1.0);

	while(x--) {
	   float xm = x*xInv;

	glClear(GL_COLOR_BUFFER_BIT);
    	glBegin(GL_TRIANGLES);
		glColor3f(1.0,0,0);
		glVertex3f(-0.5, xm, 0.0);
		glColor3f(0.0,0,1.0);
		glVertex3f(-0.5, xm-1.0f, 0.0);
		glColor3f(0,1.0,0);
		glVertex3f(0.5, -xm, 0.0);
		glEnd();
      SDL_GL_SwapWindow(ctx.window);
    }

    ShutdownOpenGL(ctx);
    return 0;
}
