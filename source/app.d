import std.stdio;
import core.stdc.string;
import vector;

// For core API functions.
import derelict.opengl3.gl;
import derelict.sdl2.sdl;
import std.conv;
import render;

v2 displayDim;
struct init_opengl_result
{
    v2 TargetDimensions;
    SDL_Window* window;
    SDL_GLContext context;

    bool opCast(T : bool)()
    {
        return window !is null;
    }
}
import std.algorithm : min, max;

void drawChessBoard(renderer *r, v2 lowerLeftCorner, v2 upperRightCorner, ubyte count, v4 black = v4(0,0,0,1), v4 white = v4(1,1,1,1))
{
    float width = upperRightCorner.x - lowerLeftCorner.x;
    //width *= displayDim.x;
    float height = upperRightCorner.y - lowerLeftCorner.y;
    //height *= displayDim.y;

    float ratio = displayDim.x / displayDim.y;

    float sideWidth = max(width, height) / ratio / count;
    bool isBlack = true;
    foreach(i;0 .. count)
    {
        float sideHeight = sideWidth * ratio;
        auto yoffset = v2(0, sideHeight * i);
        foreach(j;0 .. count)
        {
            if (i == 0 && j == 0 && IsPressed[ButtonEnum.LB])
            {
                white = v4(1,0,0,1);
            }
            else if (i == 0 && j == 2 && IsPressed[ButtonEnum.RB])
            {
                white = v4(0,1,0,1);
            }
            else
            {
                white = v4(0.7,0.7,0.7,1); 
            }
            isBlack = !isBlack;
            auto xoffset = v2(sideWidth * j, 0);
           // white = white * (1 / (j+0.0000001));
         //   black = black * (1 / (j+0.0000001));
            r.Rect(lowerLeftCorner + xoffset + yoffset, lowerLeftCorner + v2(sideWidth, sideHeight) + xoffset + yoffset, (isBlack ? black : white), rotateAxis((90/count)*i));
        }

    }
}

init_opengl_result InitOpenGL(v2 winDim = v2(1024, 786))
{
    init_opengl_result Result;
    // Load OpenGL versions 1.0 and 1.1.
    DerelictGL.load();
    try
    {
        DerelictSDL2.load(SharedLibVersion(2, 0, 2));
    } catch (derelict.util.exception.SymbolLoadException se) {
      writeln("got an execption: " ~ se.msg);
    }
    writeln("going to init");
    // Initialize SDL Video subsystem.
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        // SDL_Init returns a negative number on error.
        writeln("SDL Video subsystem failed to initialize");
        return Result;
    }

    writeln("going to create window");
    SDL_DisplayMode currentDisplayMode;
    uint window_flags = SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE;
    if (SDL_GetCurrentDisplayMode(0, &currentDisplayMode) < 0)
    {
        // assume that 0 is the current display;
        writefln("minor: could not get display mode defaulting to %dx%d window", winDim.x, winDim.y);
    }
    else
    {
        winDim = displayDim = v2(currentDisplayMode.w, currentDisplayMode.h);
        winDim = winDim * 0.5;
        //window_flags |= SDL_WINDOW_FULLSCREEN;
    }

    Result.window = SDL_CreateWindow("Hello Triangle", SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED, winDim.xi, winDim.yi, window_flags);
    if (!Result.window)
        throw new Error("Failed to create window: " ~ to!string(SDL_GetError()));
    int windowWidth, windowHeight; 
    SDL_GetWindowSize(Result.window, &windowWidth, &windowHeight);
    Result.context = SDL_GL_CreateContext(Result.window);
    SDL_GL_MakeCurrent(Result.window, Result.context);

    writeln("going to set gl_context attributes");
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

 //   glViewport(0, 0, winDim.xi, winDim.yi);
        
   // glLoadIdentity();

    struct mat4x4
    {
        float[4][4] E;

        this(float[4][4] m)
        {
            this.E = m;
            transpose();
        }

        void transpose()
        {
            import std.algorithm : swap;
            swap(E[0][1],E[1][0]);
            swap(E[0][2],E[2][0]);
            swap(E[0][3],E[3][0]);

            swap(E[1][2],E[2][1]);
            swap(E[1][3],E[3][1]);
            swap(E[1][2],E[2][1]);

            swap(E[2][3],E[3][2]);
        }

        @property const(float)* ptr()
        {
            return &E[0][0];
        }
        alias ptr this;
    }

    mat4x4 proj = mat4x4(
        [
           [2/displayDim.x,0,0,-1f],
            [0, 2/displayDim.y,0,-1f],
            [0,0,1f,0],
            [0,0,0,1f]

        ]
   );

//    glLoadMatrixf(proj);
    //glOrtho(0, 0, 0, 0, 0, 0);
    Result.TargetDimensions = winDim;

    SDL_GL_SetSwapInterval(0);
    if (!Result.context)
        throw new Error("Failed to create GL context: " ~ to!string(SDL_GetError()));
    DerelictGL3.reload();
    writeln("finished init");
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

void toggle(ref bool b)
{
    b = !b;
}

ButtonEnum toButtonEnum(SDL_Keycode k)
{
    switch(k)
    {
        case SDLK_w:
            return ButtonEnum.W;
        case SDLK_a:
            return ButtonEnum.A;
        case SDLK_s:
            return ButtonEnum.S;
        case SDLK_d:
            return ButtonEnum.D;

        case SDLK_q:
            return ButtonEnum.Q;
        case SDLK_UP:
            return ButtonEnum.Up;
        case SDLK_DOWN:
            return ButtonEnum.Down;
        case SDLK_LEFT:
            return ButtonEnum.Left;
        case SDLK_RIGHT:
            return ButtonEnum.Reght;

        default : 
            return ButtonEnum.UnhandledKey;
    }
}

ButtonEnum MouseButtonToButtonEnum(Uint8 MouseButton)
{
    switch(MouseButton)
    {
        case 1 : return ButtonEnum.LB;
        case 3 : return ButtonEnum.RB;
        default : return ButtonEnum.UnhandledKey;
    }
}
import std.exception;

extern (C) int EventHandler(void* userdata, SDL_Event* event) nothrow
{
    try
    {
    switch(event.type)
    {
          //  writeln(event.type);
        case SDL_EventType.SDL_KEYDOWN, SDL_EventType.SDL_KEYUP :
            toggle(IsPressed[event.key.keysym.sym.toButtonEnum]);
                return 0;
        case SDL_EventType.SDL_MOUSEBUTTONDOWN, SDL_EventType.SDL_MOUSEBUTTONUP :
            SDL_MouseButtonEvent MouseButton = event.button;
            MouseP.x = MouseButton.x;
            MouseP.y = winDim.y - MouseButton.y;
            toggle(IsPressed[MouseButton.button.MouseButtonToButtonEnum]);
                return 0;
        default : {}
    }

    } catch (Exception e) {}
    return 1;
}
char GetKey()
{
    SDL_Event e;

    while (SDL_PollEvent(&e) != 0)
    {
        if (e.type == SDL_EventType.SDL_WINDOWEVENT)
        {
            //glViewport(0, 0, e.window.data1, e.window.data2);
            writeln("windowEventType:", cast(SDL_WindowEventID)e.window.event);
        }
        writeln("Got event Type: ", e.type.to!string);
        if (e.type == SDL_EventType.SDL_MOUSEBUTTONUP)
        {
//            Windows
            writeln("x.y: ", v2(e.button.x, e.button.y));
        }
        // Quit if the user closes the window or presses Q
        if (e.type == SDL_QUIT)
        {
            return 'q';
        }
        else if (e.type == SDL_KEYDOWN)
        {
               return cast(char) e.key.keysym.sym;

        }
    }
    return '\0';

}

v2[2] rotateAxis(float d_angle)
{
    import std.math;
    
    float r_angle = d2r(d_angle);
    v2[2] Result;
    float _cos = cos(r_angle);
    float _sin = sin(r_angle);
    
    Result[0] = v2(_cos, _sin);
    Result[1] = v2(-_sin, _cos);
    return Result;
}

enum ButtonEnum
{
    UnhandledKey,

    W,
    A,
    S,
    D,

    Q,

    LB,
    RB,

    Up,
    Down,
    Left,
    Reght,

    Plus,
    Minus,

}
/*struct InputState
{
    bool isPressed[ButtonEnum.max];
}*/

bool IsPressed[ButtonEnum.max];
v2 MouseP;
v2 winDim;

int main()
{
    auto ctx = InitOpenGL();
    SDL_AddEventWatch(&EventHandler, null);
    enum xInit = 265;
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



    char lastKey;
    bool showTransformed;
    bool translate;
    v4 ClearColor = v4(0.5, 0.1, 0.5);
    v4 TriangleColor = v4(1.0, 1.0, 1.0);
    float scale = 1.0;
    int ctr;
    int di;
    while (lastKey != 'q')
    {
        float xm = x * xInv;
        if (IsPressed[ButtonEnum.Q])
            lastKey = 'q';
        switch (lastKey)
        {
        case 'a':
            ClearColor.r += 0.1;
            break;
        case 's':
            ClearColor.g += 0.1;
            break;
        case 'd':
            ClearColor.b += 0.1;
            break;
        case 'w':
            ClearColor = v4(.1, .1, .1, 1.0);
            break;
        case 'j':
            TriangleColor.r -= 0.1;
            break;
        case 'k':
            TriangleColor.g -= 0.1;
            break;
        case 'l':
            TriangleColor.b -= 0.1;
            break;
        case 'i':
            TriangleColor = v4(1.0, 1.0, 1.0, 1.0);
            break;
        default:
            break;
        }

        if (x-- == 0)
        {
            SDL_PumpEvents();
            x = xInit;
            glClearColor(ClearColor.r, ClearColor.g, ClearColor.b, ClearColor.a);
            glClear(GL_COLOR_BUFFER_BIT);
            //float XYratio = ctx.TargetDimensions.x / ctx.TargetDimensions.y;
            with(beginRender(ctx.TargetDimensions, ctx.window))
            {
                ///Rect(v2(0,0), v2(20,20), TriangleColor*0.1);
                //Rect(v2(-40,-40), v2(-20,-20), TriangleColor*0.3);
                //Rect(v2(-0.3,-0.3), v2(0.0,0.0), TriangleColor*0.7);
                //Rect(v2(400,200), v2(1200,600), TriangleColor*0.3);
                drawChessBoard(thisp, v2(-1, -1), v2(1.0, 1.0), 3);
//                drawChessBoard(thisp, v2(-0, -0), v2(1, 1), 3);
                //Rect(v2(-1.0,-1.0).Had(v2(XYratio, 1)), v2(-0.3,-0.3), TriangleColor);

            }
            //endRender(renderer, ctx.window);
        }

        lastKey = IsPressed[ButtonEnum.Q] ? 'q' : ' ';// GetKey();
    }

    scope (exit)
        ShutdownOpenGL(ctx);

    return 0;
}

void renderTriangle(v4 c, float scale = 1.0)
{
    glBegin(GL_TRIANGLES);
    glColor4f(c.r, c.g, c.b, 1.0);
    glVertex3fv(v3(-1.0, -1.0, 0.0) * scale);
    glVertex3fv(v3(1.0, -1.0, 0.0) * scale);
    glVertex3fv(v3(0.0, 1.0, 0.0) * scale);
    glEnd();

}
