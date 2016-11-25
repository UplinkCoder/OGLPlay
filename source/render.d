module render;
import vector;
import derelict.opengl3.gl;
import derelict.sdl2.sdl;
struct renderer
{
   v2 TargetDimensions;
   render_element_base[265][3] ElementPlanes;
   uint[typeof(ElementPlanes).length] ElementCount;
   void Rect(v2 A, v2 B, v4 Color) { Rect_(&this, A, B, Color); }
}


renderer* beginRender(v2 TargetDimensions)
{
  return new renderer(TargetDimensions);
}

void Rect_(renderer* R, v2 A, v2 B, v4 Color, uint Plane = 0)
{
  auto InvTargetDimensions = v2(R.TargetDimensions.x/1, R.TargetDimensions.y/1);
  R.ElementPlanes[R.ElementCount[Plane]++][Plane] = render_element_base(render_element_type.Rectangle, A, B, Color);  
}

/// This assumes that an openGL-Context is already open and ready to draw to;
void endRender(renderer* Renderer, SDL_Window *window)
{
//  glBegin(GL_TRIANGLES);
  foreach(PI; 0 .. Renderer.ElementPlanes.length)
    foreach(EI; 0 .. Renderer.ElementCount[PI])
    {
      auto Element = Renderer.ElementPlanes[EI][PI];
      render_rectangle(Element.A, Element.B, Element.Color);
    }
//  glEnd();
  SDL_GL_SwapWindow(window);
}

void render_rectangle(v2 A, v2 B, v4 Color)
{
  v2[6] result;
  glColor4fv(Color);
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
    struct {
      v2 B;
      v4 Color;
    }

//    struct {
//      v2 B;
//      v2 C;
//    }
  }

}

pragma(msg, renderer.ElementPlanes.length);
