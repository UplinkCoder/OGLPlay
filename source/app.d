import std.stdio;
import core.stdc.string;
import vector;

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

init_opengl_result InitOpenGL(int winWidth = 1024, int winHeight = 786)
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
    SDL_GetWindowSize(Result.window, &winWidth, &winHeight);
    Result.context = SDL_GL_CreateContext(Result.window);
    SDL_GL_MakeCurrent(Result.window, Result.context);
    glViewport(0, 0, winWidth, winHeight);
    writeln("Width:", winWidth, " Height:", winHeight);
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

char getKey()
{
    SDL_Event e;
    while (SDL_PollEvent(&e) != 0)
    {
        // Quit if the user closes the window or presses Q
        if (e.type == SDL_QUIT)
        {
            return 'q';
        }
        else if (e.type == SDL_KEYDOWN)
        {
            switch (e.key.keysym.sym)
            {
            case SDLK_q:
                return 'q';
            case SDLK_t:
                return 't';
            case SDLK_c:
                return 'c';
            case SDLK_w:
                return 'w';
            case SDLK_s:
                return 's';
            case SDLK_d:
                return 'd';
            case SDLK_r:
                return 'r';

            default:
                {
                }
            }
        }
    }
    return '\0';

}

int main()
{
    auto ctx = InitOpenGL();
    enum xInit = 512;
    enum xInv = 1.0 / xInit;
    uint[] primes = [1, 3, 5, 7];
    uint toUnique1_3(uint x, uint idx)
    {
        return x % primes[idx];
    }

    v3[] centeredTriangle = [v3(-0.5, -0.5, 0.0), v3(0.0, 0.5, 0.0), v3(0.5, -0.5,
        0.0)];
    v3[] points1 = [v3(-1.0, -1.0, 0.0), v3(0.0, 0.0, 0.0), v3(0.0, -1.0, 0.0)];
    v3[] points2 = [v3(1.0, 0.0, 0.0), v3(0.0, 0.0, 0.0), v3(0.0, -1.0, 0.0)];
    v3[] points4 = [v3(1.0, -1.0, 0.0), v3(0.0, 0.0, 0.0), v3(1.0, 1.0, 0.0)];
    v3[] points3 = [v3(-1.0, 1.0, 0.0), v3(0.0, 0.0, 0.0), v3(1.0, 1.0, 0.0)];

    v3[][] points = [points1, points2, points3, points4, centeredTriangle];

    v3[] colorTable = [v3(1.0, 0.0, 0.0), v3(0.0, 1.0, 0.0), v3(0.0, 0.0, 1.0)];

    int x = xInit;
    glClearColor(0.5, 0.5, 0.5, 1.0);

    v3[2] rotateAxis(float d_angle)
    {
        import std.math;

        float r_angle = d2r(d_angle);
        v3[2] Result;
        float _cos = cos(r_angle);
        float _sin = sin(r_angle);

        Result[0] = v3(_cos, _sin);
        Result[1] = v3(-_sin, _cos);
        return Result;
    }

    char lastKey;
    bool showTransformed;
    bool translate;
    float scale = 1.0;
    int ctr;
    int di;
    while (lastKey != 'q')
    {
        if (x-- == 0)
            x = xInit;

        switch (lastKey)
        {
        case 't':
            showTransformed = !showTransformed;
            break;
        case 'c':
            ctr++;
            break;
        case 'w':
            scale += (0.33);
            break;
        case 's':
            scale -= (0.33);
            break;
        case 'r':
            scale = 1.0;
            break;
        case 'd':
            translate = !!(di++ % 4);
            break;
        default:
            break;

        }
        lastKey = getKey();
        float xm = x * xInv;
        //rotate(&points[0], xm);
        //rotate(&points[1], xm);
        //rotate(&points[2], xm);
        glClear(GL_COLOR_BUFFER_BIT);
        int i = ctr % cast(int) points.length;
        {
            glBegin(GL_TRIANGLES);
            if (showTransformed)
            {
                {
                    foreach (ip, _p; points[i])
                    {
                        auto np = v2(-_p.y, _p.x);
                        glColor3fv(colorTable[ip]);
                        glVertex2fv(np * scale);
                    }

                    foreach (ip, _p; points[i])
                    {
                        auto np = v2(-_p.x, -_p.y);
                        glColor3fv(colorTable[ip]);
                        glVertex2fv(np * scale);
                    }

                    foreach (ip, _p; points[i])
                    {
                        auto np = v2(_p.y, -_p.x);
                        glColor3fv(colorTable[ip]);
                        glVertex2fv(np * scale);
                    }
                }
            }
            foreach (ip, _p; points[i])
            {
                glColor3fv(colorTable[ip]);
                glVertex3fv(
                    _p - (translate ? centeredTriangle[di % centeredTriangle.length] : v3(0,
                    0, 0)));
            }
            glEnd();
        }
        SDL_GL_SwapWindow(ctx.window);
    }

    scope (exit)
        ShutdownOpenGL(ctx);
    auto slv = glGetString(GL_SHADING_LANGUAGE_VERSION);
    writeln(slv[0 .. strlen(slv)]);
    return 0;
}
