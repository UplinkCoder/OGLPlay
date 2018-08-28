import std.stdio;
import core.stdc.string;
import vector;

// For core API functions.
import derelict.opengl3.gl;
import derelict.sdl2.sdl;
import std.conv;
import render;
import std.datetime : Duration;
import std.system;
import std.process;
import core.thread;

alias sleep = Thread.sleep;

v2 mySquare;
uint boardDim;

char lastKey;
bool paused;
T choice(T)(T[] choices)
{
   import std.random;
   auto u0n = uniform(0, choices.length);
  return choices[u0n];
}

struct init_opengl_result
{
    v2 WindowDimensions;
    v2 DisplayDimensions;
    SDL_Window* window;
    SDL_GLContext context;

    bool Fullscreen;

    bool opCast(T : bool)()
    {
        return window !is null;
    }
}
import std.algorithm : min, max;
const (float) Map01(const float value, const float min, const float max) pure
{
   assert(min < max);
   assert(value >= min);
   assert(value <= max);

   float result;

   result = (value - min) / (max - min);

    return result;
}

static assert(Map01(0.5,0.5,1) == 0.0f);
static assert(Map01(1,0.5,1) == 1.0f);
static assert(Map01(0.75,0.5,1) == 0.5);

v2 arm(float angle)
{
    import std.math;
    return v2(cos(angle), sin(angle));
}

pragma(msg, arm(2.0));

void drawChessBoard(renderer *r, v2 lowerLeftCorner, v2 upperRightCorner, uint count, v2* highlighted = null, v4 black = v4(0,0,0,1), v4 white = v4(1,1,1,1)) pure
{
    float width = upperRightCorner.x - lowerLeftCorner.x;
    //width *= displayDim.x;
    float height = upperRightCorner.y - lowerLeftCorner.y;
    //height *= displayDim.y;

    float ratio = r.TargetDimensions.x / r.TargetDimensions.y;

    float sideWidth = max(width, height) / ratio / count;
    bool isBlack = true;
    foreach(i;0 .. count)
    {
        float sideHeight = sideWidth * ratio;
        auto yoffset = v2(0, sideHeight * i);
        foreach(j;0 .. count)
        {
            if (highlighted && absMod(highlighted.xi, count) == j && absMod(highlighted.yi, count) == i)
            {
                white = v4(1,0,0,1);
                black = v4(0,1,0,1);
            }
            /*else if (i == 0 && j == 2 && buttons[ButtonEnum.RB].IsPressed)
            {
                white = v4(0,1,0,1);
            }
            */

            else
            {
                white = v4(0.7,0.7,0.7,1); 
                black = v4(0.2,0.2,0.2,1); 
            }
            isBlack = !isBlack;
            auto xoffset = v2(sideWidth * j, 0);
           // white = white * (1 / (j+0.0000001));
         //   black = black * (1 / (j+0.0000001));
            r.Rect(lowerLeftCorner + xoffset + yoffset, lowerLeftCorner + v2(sideWidth, sideHeight) + xoffset + yoffset, (isBlack ? black : white), rotateAxis((90/count)*i));
        }

    }
}

float Ratio0(float _this, float overThat)
{
  float result = 0;

  if (overThat != 0)
  {
    result = _this / overThat;
  }

  return result;
}

void drawCircle(renderer* r, float rotation = 1.0, v2 Offset = v2(0, 0))
{
    import std.math;
    float ratio = 1 / (r.TargetDimensions.x / r.TargetDimensions.y);
    v2 ratioV2 = v2(ratio, 1);
    //Offset = v2(-0.5*ratio, -0.5);
    enum radius = .009;
    Offset.Had(ratioV2);
    enum points = 64*4;
    enum Tau32 = cast(float) (PI * 2);
    auto AngleStep = Tau32 / points;
    foreach(i;0 .. points) 
    {
       auto pr = Ratio0(i, points)*2;
       auto lowerCorner = arm(i*AngleStep).Had(ratioV2)*0.4; //*pr;
       r.Rect(lowerCorner + Offset, lowerCorner + Offset + v2(radius*ratio, radius), v4(0,1,1,0)*pr);
    }
}

void toggleFullscreen(init_opengl_result *ogl)
{
    writeln("toggleFullscreen");
    v2 Dim;    
    if (!ogl.Fullscreen)
    {
        Dim = ogl.DisplayDimensions;
        SDL_SetWindowFullscreen(ogl.window, SDL_WINDOW_FULLSCREEN_DESKTOP);
    }
    else
    {
        Dim = ogl.WindowDimensions;
        SDL_SetWindowFullscreen(ogl.window, 0);
    }
    writeln(Dim);
    glViewport(0, 0, Dim.xi, Dim.yi);
    toggle(ogl.Fullscreen);
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
        auto dim = Result.DisplayDimensions = v2(currentDisplayMode.w, currentDisplayMode.h);
        winDim = dim * 0.5;
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

    glViewport(0, 0, winDim.xi, winDim.yi);
        
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
           [2/winDim.x,0,0,-1f],
            [0, 2/winDim.y,0,-1f],
            [0,0,1f,0],
            [0,0,0,1f]

        ]
   );

//    glLoadMatrixf(proj);
    //glOrtho(0, 0, 0, 0, 0, 0);
    Result.WindowDimensions = winDim;

    SDL_GL_SetSwapInterval(0);
    if (!Result.context)
        throw new Error("Failed to create GL context: " ~ to!string(SDL_GetError()));
    //DerelictGL3.reload();
    writeln("finished init");
    return Result;
}

void ShutdownOpenGL(init_opengl_result* gl) nothrow
{
    try    { writeln("calledShutdownOpenGL"); } catch  {}
    // Deinitialize SDL at exit.
    SDL_GL_DeleteContext(gl.context);
    SDL_DestroyWindow(gl.window);
    SDL_Quit();
    
    try {
        DerelictGL3.unload();
        DerelictSDL2.unload();
    } catch (Exception e) {}
    
}

void toggle(ref bool b)
{
    b = !b;
}

ButtonEnum toButtonEnum(SDL_Keycode k) nothrow
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

        case SDLK_f:
            return ButtonEnum.F;

        case SDLK_p:
            return ButtonEnum.P;
        case SDLK_q:
            return ButtonEnum.Q;
        case SDLK_UP:
            return ButtonEnum.Up;
        case SDLK_DOWN:
            return ButtonEnum.Down;
        case SDLK_LEFT:
            return ButtonEnum.Left;
        case SDLK_RIGHT:
            return ButtonEnum.Right;

        default : 
            return ButtonEnum.UnhandledKey;
    }
}

ButtonEnum MouseButtonToButtonEnum(Uint8 MouseButton) nothrow
{
    switch(MouseButton)
    {
        case 1 : return ButtonEnum.LB;
        case 3 : return ButtonEnum.RB;
        default : return ButtonEnum.UnhandledKey;
    }
}
import std.exception;

struct Button
{
    uint count;

    @property bool IsPressed() nothrow
    {
        return (count & (1 << 31)) != 0;
    }

    @property void IsPressed(uint v) nothrow
    {
        if (v)
        { 
            count |= (1 << 31);
        }
        else
        {
            count &= ~(1 << 31);
        }
    }
/*
    uint WasPressed()
    {
        return count & ~(1 << 31);
    }
*/
    bool wasPressed;
    void ClearCount()
    {
        count &= (1 << 31) | (1 << 30);
    }
}
void CountKeyEvent(ButtonEnum b, bool isDown) nothrow
{
    auto Button = &buttons[b];
    if (Button.IsPressed != isDown) Button.count++;
    Button.IsPressed = isDown;
    assert(Button.IsPressed == isDown);
} 

extern (C) int EventHandler(void* userdata, SDL_Event* event) nothrow
{
    auto eventType = event.type;

    switch(eventType)
    {
        case SDL_KEYDOWN, SDL_KEYUP :
            auto KeyEvent = event.key;
            auto KeySym = KeyEvent.keysym.sym;
            auto oldButtons = buttons;
         //   clearButtons();
            buttons[KeySym.toButtonEnum].wasPressed = false;
            if(KeySym.toButtonEnum == ButtonEnum.Q)
            {
            }
  
            if (KeyEvent.state == SDL_RELEASED)
            {
                buttons[KeySym.toButtonEnum].wasPressed = true;
            }
            else if (KeyEvent.repeat != 0)
            {
                buttons[KeySym.toButtonEnum].wasPressed = true;
            }

      //      CountKeyEvent(Keysym.toButtonEnum, eventType == SDL_KEYDOWN);
                return 0;
        case SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP :
            SDL_MouseButtonEvent MouseButton = event.button;
            MouseP.x = MouseButton.x;
            MouseP.y = winDim.y - MouseButton.y;
            CountKeyEvent(MouseButton.button.MouseButtonToButtonEnum, eventType == SDL_MOUSEBUTTONDOWN);
                return 0;
        default : {}
    }
//} catch (Exception e) { } // TODO log exception ?
    return 1;
}


v2[2] rotateAxis(float d_angle) pure
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

    F,
    P,
    Q,

    LB,
    RB,

    Up,
    Down,
    Left,
    Right,

    Plus,
    Minus,

}
/*struct InputState
{
    bool buttons[ButtonEnum.max];
}*/

Button[ButtonEnum.max] buttons;

void clearButtons() nothrow
{
    foreach(ref b; buttons)
    {
        b.wasPressed = false;
    }
}

v2 MouseP;
v2 winDim;

uint absMod(int v, int modBy) pure nothrow
{
  int mod = v % modBy;
  if (v<0) 
    return modBy + mod;
  else
    return mod;
}

static assert(absMod(-1, 3) == 2);

int main()
{
    auto ctx = InitOpenGL();
    SDL_AddEventWatch(&EventHandler, &ctx);
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
            
    boardDim = 3;
    while (!buttons[ButtonEnum.Q].wasPressed)
    {
		SDL_PumpEvents();
    if (buttons[ButtonEnum.P].wasPressed) toggle(paused);
    if (!paused)
    {
        mySquare = mySquare + choice([v2(0,-1), v2(-1,0), v2(0,1), v2(1,0)]);
    }

        if (buttons[ButtonEnum.Up].wasPressed)
        {
            mySquare.y += 1;
        }
        else if (buttons[ButtonEnum.Down].wasPressed)
        {
            mySquare.y -= 1;
        }
        else if (buttons[ButtonEnum.Left].wasPressed)
        {
            mySquare.x -= 1;
        }
        else if (buttons[ButtonEnum.Right].wasPressed)
        {
            mySquare.x += 1;
        }
        else

if (buttons[ButtonEnum.Q].wasPressed)
{
    ShutdownOpenGL(&ctx);
    import core.stdc.stdlib : exit;
    exit(0);
}
 if (buttons[ButtonEnum.F].wasPressed)
        {
            toggleFullscreen(&ctx);
        }

/*
        mySquare.x = absMod(mySquare.xi, boardDim);
        mySquare.y = absMod(mySquare.yi, boardDim);
*/
        float xm = x * xInv;
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
        case 'f': 
           toggleFullscreen(&ctx);
           break;
        default:
            break;
        }

            clearButtons();
            sleep(100.msecs);
        if (ctx.context)
        {
            glClearColor(ClearColor.r, ClearColor.g, ClearColor.b, ClearColor.a);
            glClear(GL_COLOR_BUFFER_BIT);
            //float XYratio = ctx.WindowDimensions.x / ctx.WindowDimensions.y;
            with(beginRender(ctx.WindowDimensions, ctx.window))
            {
                ///Rect(v2(0,0), v2(20,20), TriangleColor*0.1);
                //Rect(v2(-40,-40), v2(-20,-20), TriangleColor*0.3);
                //Rect(v2(-0.3,-0.3), v2(0.0,0.0), TriangleColor*0.7);
                //Rect(v2(400,200), v2(1200,600), TriangleColor*0.3);
                // drawChessBoard(thisp, v2(-1, -1), v2(0.0, 1.0), boardDim, &mySquare);

                drawChessBoard(thisp, v2(-1.0, -1.0), v2(1, 1), 17, &mySquare);
                // drawCircle(thisp, 1.0);

            }
            //endRender(renderer, ctx.window);
        }

    }

   // scope (exit)
 //       ShutdownOpenGL(&ctx);

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
