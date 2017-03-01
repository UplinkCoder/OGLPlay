module render;
import vector;
import derelict.opengl3.gl;
import derelict.sdl2.sdl;
nothrow :
struct renderer
{
    v2 TargetDimensions;
    SDL_Window* window;
    render_element_base[1024][3] ElementPlanes;
    uint[typeof(ElementPlanes).length] ElementCount;
    void Rect(v2 A, v2 B, v4 Color, v2[2] Axis = [v2(1, 0), v2(0, 1)], uint plane = 0)
    {
        Rect_(&this, A, B, Color, Axis, plane);
    }

    renderer* thisp()
    {
        return &this;
    }

    ~this()
    {
        endRender(&this, window);
    }
}

renderer beginRender(v2 TargetDimensions, SDL_Window* window)
{
    return renderer(TargetDimensions, window);
}

void Rect_(renderer* R, v2 A, v2 B, v4 Color, v2[2] Axis, uint Plane = 0)
{
    auto InvTargetDimensions = v2(1 / R.TargetDimensions.x, 1 / R.TargetDimensions.y);
    R.ElementPlanes[Plane][R.ElementCount[Plane]++] = render_element_base(
        render_element_type.Rectangle, A, B, Color, Axis);
}

/// This assumes that an openGL-Context is already open and ready to draw to;
void endRender(renderer* Renderer, SDL_Window* window)
{
    glBegin(GL_TRIANGLES);
    foreach (PI; 0 .. Renderer.ElementPlanes.length)
        foreach (EI; 0 .. Renderer.ElementCount[PI])
        {
            auto Element = Renderer.ElementPlanes[PI][EI];
            render_rectangle(Element.A, Element.B, Element.Color);
        }
    glEnd();
    SDL_GL_SwapWindow(window);
}

void render_quad(v2[4] Vertices, v4 Color)
{
    glColor4fv(Color);
    glVertex2fv(Vertices[0]);
    glVertex2fv(Vertices[1]);
    glVertex2fv(Vertices[2]);

    glVertex2fv(Vertices[0]);
    glVertex2fv(Vertices[2]);
    glVertex2fv(Vertices[3]);
}

void render_rectangle(v2 A, v2 B, v4 Color)
{
    pragma(inline, true);
    glColor4fv(Color);
   // v2[2] Axis = [v2(1,0), v2(0,1)];
    glVertex2fv(A);
    glVertex2f(A.x, B.y);
    glVertex2fv(B);
    glVertex2fv(B);
    glVertex2f(B.x, A.y);
    glVertex2fv(A);
}

enum render_element_type
{
    Rectangle,
}

struct render_element_base
{

    render_element_type Type;
    v2 A; /// first vertex (MinCorner in case of recangle)
    union
    {
        struct
        {
            v2 B;
            v4 Color;
        }

//            struct {
//              v2 B;
//              v2 C;
//              v4 Color;
//            }
    }

    v2[2] Axis;
}

//pragma(msg, renderer.ElementPlanes.length);
