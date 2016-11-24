import std.stdio;

// For core API functions.
import derelict.opengl3.gl;
import derelict.sdl2.sdl;
import std.conv;

string opBinaryVectorMixin(ubyte vN)
{
    assert(vN <= 9);
    vN += '0';
    char[] result = cast(char[]) `vX opBinary(string op, VT)(const VT rhs)
	{
		v3 result;
		static if (is(VT == v3) || is(VT == v2) || is(VT == v4)) {
		static if (op == "+" || op == "-")
		{
			foreach (i;0 .. min(` ~ vN ~ `, cast(uint)rhs.E.length))
			{
				mixin("result.E[i] = E[i] " ~ op ~ " rhs.E[i]"); 
			}
		}
		else static assert ("No can do \"" ~ op ~ "\"");
	} else static if (is(VT : float)) {
		static if (op == "*")
		{
			foreach(i; 0 .. ` ~ vN ~ `)
			{
				result.E[i] = E[i] * rhs;
			}
		}
	} else static assert("No can do");
	
	return result;
	}
	`;

    result[1] = vN;
    return cast(string) result;
}

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

uint min(uint a, uint b)
{
    return a < b ? a : b;
}

struct v2
{
    union
    {
        struct
        {
            float x, y;
        }

        float[2] E;
    }

    mixin(opBinaryVectorMixin(2));
    alias toPtr this;
    const(float)* toPtr() const pure nothrow
    {
        return &E[0];
    }

    v2 perp()
    {
        return v2(-y, x);
    }

    v2 mirror()
    {
        return v2(y, x);
    }

    v3 V3(float z = 0.0) const pure nothrow
    {
        return v3(x, y, z);
    }

    v4 V4(float z = 0.0, float w = 1.0) const pure nothrow
    {
        return v4(x, y, z, w);
    }
}

struct v3
{
    union
    {
        struct
        {
            float r, g, b;
        }

        struct
        {
            float x, y, z;
        }

        float[3] E;
    }

    alias toPtr this;
    const(float)* toPtr() const pure nothrow
    {
        return &E[0];
    }

    mixin(opBinaryVectorMixin(3));

    v2 V2() const pure nothrow
    {
        return v2(x, y);
    }

    v4 V4(float w) const pure nothrow
    {
        return v4(x, y, z, w);
    }
}

struct v4
{
    union
    {
        struct
        {
            float r, g, b, a;
        }

        struct
        {
            float x, y, z, w;
        }

        float[4] E;
    }

    alias toPtr this;
    const(float)* toPtr() const pure nothrow
    {
        return &E[0];
    }

    mixin(opBinaryVectorMixin(4));

    v3 V3() const pure nothrow
    {
        return v3(r, g, b);
    }
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

    v3[] points1 = [v3(-1.0, -1.0, 0.0), v3(0.0, 0.0, 0.0), v3(0.0, -1.0, 0.0)];
    v3[] points2 = [v3(1.0, 0.0, 0.0), v3(0.0, 0.0, 0.0), v3(0.0, -1.0, 0.0)];
    v3[] points4 = [v3(1.0, -1.0, 0.0), v3(0.0, 0.0, 0.0), v3(1.0, 1.0, 0.0)];
    v3[] points3 = [v3(-1.0, 1.0, 0.0), v3(0.0, 0.0, 0.0), v3(1.0, 1.0, 0.0)];

    v3[][] points = [points1, points2, points3, points4];

    v3[] colorTable = [v3(1.0, 0.0, 0.0), v3(0.0, 1.0, 0.0), v3(0.0, 0.0, 1.0)];

    glIndexPointer(GL_FLOAT, 0, &colorTable[0]);
    int x = xInit;
    glClearColor(1.0, 1.0, 1.0, 1.0);

    v3[2] rotateAxis(float angle)
    {
        import std.math;

        v3[2] Result;
        float _cos = cos(angle);
        float _sin = sin(angle);

        Result[0] = v3(_cos, _sin);
        Result[1] = v3(-_sin, _cos);
        return Result;
    }

    char lastKey;
    bool showTransformed;
    int ctr;
    while (lastKey != 'q')
    {
        if (lastKey == 't')
            showTransformed = !showTransformed;
        if (lastKey == 'c')
            ctr++;
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
                auto axis = rotateAxis(xm);

                foreach (ip, _p; points[i])
                {
                    auto np = v2(_p.y, _p.x).perp.perp.mirror.perp.V3;
                    glColor3fv(colorTable[ip]);
                    glVertex3fv(np);
                }

                foreach (ip, _p; points[i])
                {
                    auto np = _p.V2.mirror.V3;
                    glColor3fv(colorTable[ip]);
                    glVertex3fv(np);
                }
                foreach (ip, _p; points[i])
                {
                    auto np = _p.V2.perp.perp.mirror.perp.V3;
                    glColor3fv(colorTable[ip]);
                    glVertex3fv(np);
                }
                foreach (ip, _p; points[i])
                {
                    auto np = _p.V2.perp.perp.perp.mirror.mirror.V3;
                    glColor3fv(colorTable[ip]);
                    glVertex3fv(np);
                }
            }
            foreach (ip, _p; points[i])
            {

                glColor3fv(colorTable[ip]);
                glVertex3fv(_p);

            }
            glEnd();
        }
        SDL_GL_SwapWindow(ctx.window);
    }

    scope (exit)
        ShutdownOpenGL(ctx);
    return 0;
}
