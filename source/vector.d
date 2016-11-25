import std.math;

struct rectangle2
{
    v2 MinCorner; /// Left-Bottom
    v2 MaxCorner; /// Right-Top
}

uint min(uint a, uint b)
{
    return a < b ? a : b;
}

double r2d(double x)
{
    return (x) * (180 / PI);
}

float d2r(float x)
{
    return x * (PI / 180);
}

static immutable opBinaryVectorMixin = q{
    auto opBinary(string op, VT)(const VT rhs)
    {

        static if (is(VT == v3) || is(VT == v2) || is(VT == v4))
        {
            static if (op == "+" || op == "-")
            {
                typeof(this) result;
                foreach (i; 0 .. min(cast(uint) E.length, cast(uint) rhs.E.length))
                {
                    mixin("result.E[i] = E[i] " ~ op ~ " rhs.E[i];");
                }
            }
            else static if (op == "*")
            {
                typeof(this.E[0]) result;
                foreach (i; 0 .. min(cast(uint) E.length, cast(uint) rhs.E.length))
                {
                    result += E[i] * rhs.E[i];
                }
            }
            else
                static assert("No can do \"" ~ op ~ "\"");
        }
        else static if (is(VT : float))
        {
	    static if (op == "*" || op == "/")
            {
                typeof(this) result;
                foreach (i; 0 .. E.length)
                {
                    mixin("result.E[i] = E[i] " ~ op ~ " rhs;");
                }
            }
        }
        else
            static assert("No can do");

        return result;
    }
};

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

    mixin(opBinaryVectorMixin);
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
            float r, g, b = 0.0;
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

    mixin(opBinaryVectorMixin);

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
            float r, g, b = 0.0, a = 1.0;
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

    mixin(opBinaryVectorMixin);

    v3 V3() const pure nothrow
    {
        return v3(r, g, b);
    }
}
