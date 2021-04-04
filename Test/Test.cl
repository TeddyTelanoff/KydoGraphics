#define SAFE 1

typedef struct Vertex Vertex;
typedef struct Rect Rect;
typedef uint Indice;
typedef uint Color;

struct Vertex
{
	uint X, Y;
	Color Color;
};

struct Rect
{
	uint Left;
	uint Top;
	uint Right;
	uint Bottom;
};

static uint Min(uint x, uint y)
{ return x < y ? x : y; }

static uint Max(uint x, uint y)
{ return x > y ? x : y; }

static float Abs(float x)
{
	((uchar *)&x)[3] &= 0x7F; // What's this ugly code?
	return x;
}

static uchar Lerp(float x, float y, float t)
{ return x + t * (y - x); }

// #define Red(x) (x << 16 & 0xFF)
// #define Green(x) (x << 8 & 0xFF)
// #define Blue(x) (x << 0 & 0xFF)
// #define RGB(r, g, b) (r << 16 | g << 8 | b << 0)

static uint Red(Color x)
{ return x >> 16 & 0xFF; }

static uint Green(Color x)
{ return x >> 8 & 0xFF; }

static uint Blue(Color x)
{ return x >> 0 & 0xFF; }


static float Redf(Color x)
{ return (float)Red(x) / 255; }

static float Greenf(Color x)
{ return (float)Green(x) / 255; }

static float Bluef(Color x)
{ return (float)Blue(x) / 255; }


static Color RGB(uchar r, uchar g, uchar b)
{ return (((uint)r) << 16) | (((uint)g) << 8) | (((uint)b) << 0); }

static Color RGBf(float r, float g, float b)
{ return RGB(r * 255, g * 255, b * 255); }

static uint Blend(uint x, uint y, float t)
{
	uint out = 0;
	uint t0, t1;
	
	t0 = Red(x);
	t1 = Red(y);
	out |= Lerp(t0, t1, t) << 16;
	
	t0 = Green(x);
	t1 = Green(y);
	out |= Lerp(t0, t1, t) << 8;
	
	t0 = Blue(x);
	t1 = Blue(y);
	out |= Lerp(t0, t1, t) << 0;
	
	return out;
}

#define Sqrt(x) sqrt((float)(x))

static float Dist(float x1, float y1, float x2, float y2)
{
	float dx = x1 - x2;
	float dy = y1 - y2;
	return Sqrt(Abs(dx * dx + dy * dy));
	// return Abs(dx * dx + dy * dy);
	// return Abs(dx + dy);
}

static void DrawPixel(global uint *pixels, uint x, uint y, uint col)
{
	#if SAFE
	if (x < 512 && y < 512)
	#endif
		pixels[x + y * 512] = col;
}

static void DrawVertex(global uint *pixels, Vertex *vert)
{ DrawPixel(pixels, vert->X, vert->Y, vert->Color); }

// Taken from -> https://github.com/tuliosouza99/rasterization
void DrawLine(global Color *pixels, global Vertex *a, global Vertex *b)
{
	Vertex newVert = *a;
	int d, incrE, incrNe;
	int dx = Abs((int)(a->X - b->X));
	int dy = Abs((int)(a->Y - b->Y));
	float finalStep = Sqrt(dx * dx + dy * dy);
	float step = 0;

	DrawVertex(pixels, &newVert);
	if (dx >= dy)
	{
		incrE = 2 * dy;
		incrNe = 2 * (dy - dx);

		d = 2 * dy - dx;
		while (newVert.X != b->X)
		{
			if (d <= 0)
				d += incrE;
			else
			{
				d += incrNe;
				if (b->Y >= a->Y)
					newVert.Y++;
				else
					newVert.Y--;
			}

			if (b->X >= a->X)
				newVert.X++;
			else
				newVert.X--;

			newVert.Color = Blend(a->Color, b->Color, step / finalStep);
			DrawVertex(pixels, &newVert);
			step++;
		}
	}
	else
	{
		incrE = 2 * dx;
		incrNe = 2 * (dx - dy);

		d = 2 * (dx - dy);
		while (newVert.Y != b->Y)
		{
			if (d <= 0)
				d += incrE;
			else
			{
				d += incrNe;
				if (b->X >= a->X)
					newVert.X++;
				else
					newVert.X--;
			}

			if (b->Y >= a->Y)
				newVert.Y++;
			else
				newVert.Y--;

			newVert.Color = Blend(a->Color, b->Color, step / finalStep);
			DrawVertex(pixels, &newVert);
			step++;
		}
	}
}

// Taken from -> https://www.scratchapixel.com/lessons/3d-basic-rendering/rasterization-practical-implementation/rasterization-stage
// With some chedder from -> http://www.jeffreythompson.org/collision-detection/tri-point.php
float TriangleArea(float x1, float y1, float x2, float y2, float x3, float y3)
{ return Abs((x1 - x2) * (y3 - y2) - (x3 - x2) * (y1 - y2)); }

kernel void Draw(global Color *pixels, global Vertex *verts, global Indice *indices)
{
	uint id = get_global_id(0);
	global Vertex
		*a = &verts[indices[id * 3 + 0]],
		*b = &verts[indices[id * 3 + 1]],
		*c = &verts[indices[id * 3 + 2]];
	
	uint minX = Min(a->X, Min(b->X, c->X));
	uint maxX = Max(a->X, Max(b->X, c->X));
	
	uint minY = Min(a->Y, Min(b->Y, c->Y));
	uint maxY = Max(a->Y, Max(b->Y, c->Y));
	
	float tdab = Dist(a->X, a->Y, b->X, b->Y);
	float tdbc = Dist(b->X, b->Y, c->X, c->Y);
	float tdca = Dist(c->X, c->Y, a->X, a->Y);
	
	float area = Abs(((float)b->X - (float)a->X) * ((float)c->Y - (float)a->Y) - ((float)c->X -(float)a->X) * ((float)b->Y - (float)a->Y));
	for (uint y = minY; y <= maxY; y++)
		for (uint x = minX; x <= maxX; x++)
		{
			float areaC = TriangleArea(a->X, a->Y, x, y, b->X, b->Y);
			float areaA = TriangleArea(b->X, b->Y, x, y, c->X, c->Y);
			float areaB = TriangleArea(c->X, c->Y, x, y, a->X, a->Y);

			if (areaA + areaB + areaC == area)
			{
				areaA /= area;
				areaB /= area;
				areaC /= area;
				
				float red   = areaA * Redf  (a->Color) + areaB * Redf  (b->Color) + areaC * Redf  (c->Color);
				float green = areaA * Greenf(a->Color) + areaB * Greenf(b->Color) + areaC * Greenf(c->Color);
				float blue  = areaA * Bluef (a->Color) + areaB * Bluef (b->Color) + areaC * Bluef (c->Color);
				DrawPixel(pixels, x, y, RGBf(red, green, blue));
			}
		}
	
	DrawLine(pixels, a, b);
	DrawLine(pixels, b, c);
	DrawLine(pixels, c, a);
}

kernel void Clear(global Color *pixels, uint col)
{
	uint y = get_global_id(0);
	for (uint x = 0; x < 512; x++)
		DrawPixel(pixels, x, y, 0x404040);
}