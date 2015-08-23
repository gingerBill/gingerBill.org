#ifndef MATH_HPP
#define MATH_HPP

////////////////////////////////
// Constants
////////////////////////////////

constexpr f32 TAU    = 6.28318530718f;
constexpr f32 SQRT_2 = 1.41421356237f;
constexpr f32 SQRT_3 = 1.73205080757f;

////////////////////////////////
// Helper functions
////////////////////////////////

inline f32
min(f32 a, f32 b)
{
	return a < b ? a : b;
}


inline f32
max(f32 a, f32 b)
{
	return a > b ? a : b;
}

inline f32
lerp(f32 x, f32 y, f32 t)
{
	return x + (y - x) * t;
}

inline f32
clamp(f32 x, f32 min, f32 max)
{
	if (x < min)
		return min;
	if (x > max)
		return max;
	return x;
}

inline f32
abs(f32 v)
{
	return fabsf(v);
}

inline s32
abs(s32 v)
{
	const s32 mask = v >> (32 - 1);

	return (v + mask) ^ mask;
}

inline f32
random(f32 min, f32 max)
{
	return (f32)(rand() / (f32)RAND_MAX) * (max - min) + min;
}

////////////////////////////////
// Vector Math
////////////////////////////////

union Vector2 {
	struct {
		f32 x, y;
	};

	f32 data[2];
};

union Vector3 {
	struct {
		f32 x, y, z;
	};

	Vector2 xy;

	f32 data[3];
};

////////////////////////////////
// Vector 2 Functions
////////////////////////////////

inline Vector2
operator-(const Vector2& a)
{
	return {-a.x, -a.y};
}

inline Vector2
operator+(const Vector2& a, const Vector2& b)
{
	return {a.x + b.x, a.y + b.y};
}

inline Vector2
operator-(const Vector2& a, const Vector2& b)
{
	return {a.x - b.x, a.y - b.y};
}

inline Vector2
operator*(const Vector2& a, f32 f)
{
	return {a.x * f, a.y * f};
}

inline Vector2
operator/(const Vector2& a, f32 f)
{
	return {a.x / f, a.y / f};
}

inline Vector2
operator*(f32 f, const Vector2& a)
{
	return operator*(a, f);
}

inline Vector2
operator*(const Vector2& a, const Vector2& b)
{
	return {a.x * b.x, a.y * b.y};
}

inline Vector2
operator/(const Vector2& a, const Vector2& b)
{
	return {a.x / b.x, a.y / b.y};
}

inline Vector2&
operator+=(Vector2& a, const Vector2& b)
{
	return (a = a + b);
}

inline Vector2&
operator-=(Vector2& a, const Vector2& b)
{
	return (a = a - b);
}

inline Vector2&
operator*=(Vector2& a, const Vector2& b)
{
	return (a = a * b);
}

inline Vector2&
operator/=(Vector2& a, const Vector2& b)
{
	return (a = a / b);
}

inline Vector2&
operator*=(Vector2& a, f32 b)
{
	return (a = a * b);
}

inline Vector2&
operator/=(Vector2& a, f32 b)
{
	return (a = a / b);
}

inline bool
operator==(const Vector2& a, const Vector2& b)
{
	return (a.x == b.x) && (a.y && b.y);
}

inline bool
operator!=(const Vector2& a, const Vector2& b)
{
	return !operator==(a, b);
}

inline f32
dot(const Vector2& a, const Vector2& b)
{
	return a.x * b.x + a.y * b.y;
}

inline f32
length(const Vector2& a)
{
	return sqrtf(dot(a, a));
}

inline f32
cross(const Vector2& a, const Vector2& b)
{
	return a.x * b.y - b.x * a.y;
}

inline Vector2
normalize(const Vector2& a)
{
	if (length(a) > 0)
		return a * (1.0f / length(a));
	return {0, 0};
}

inline Vector2
lerp(Vector2 x, Vector2 y, f32 t)
{
	return x + (y - x) * t;
}

////////////////////////////////
// Vector3 Functions
////////////////////////////////

inline Vector3
operator-(const Vector3& a)
{
	return {-a.x, -a.y, -a.z};
}

inline Vector3
operator+(const Vector3& a, const Vector3& b)
{
	return {a.x + b.x, a.y + b.y, a.z + b.z};
}

inline Vector3
operator-(const Vector3& a, const Vector3& b)
{
	return {a.x - b.x, a.y - b.y, a.z - b.z};
}

inline Vector3
operator*(const Vector3& a, f32 f)
{
	return {a.x * f, a.y * f, a.z * f};
}

inline Vector3
operator/(const Vector3& a, f32 f)
{
	return {a.x / f, a.y / f, a.z / f};
}

inline Vector3
operator*(f32 f, const Vector3& a)
{
	return operator*(a, f);
}

inline Vector3
operator*(const Vector3& a, const Vector3& b)
{
	return {a.x * b.x, a.y * b.y, a.z * b.z};
}

inline Vector3
operator/(const Vector3& a, const Vector3& b)
{
	return {a.x / b.x, a.y / b.y, a.z / b.z};
}

inline Vector3&
operator+=(Vector3& a, const Vector3& b)
{
	return (a = a + b);
}

inline Vector3&
operator-=(Vector3& a, const Vector3& b)
{
	return (a = a - b);
}

inline Vector3&
operator*=(Vector3& a, const Vector3& b)
{
	return (a = a * b);
}

inline Vector3&
operator/=(Vector3& a, const Vector3& b)
{
	return (a = a / b);
}

inline Vector3&
operator*=(Vector3& a, f32 b)
{
	return (a = a * b);
}

inline Vector3&
operator/=(Vector3& a, f32 b)
{
	return (a = a / b);
}

inline bool
operator==(const Vector3& a, const Vector3& b)
{
	return (a.x == b.x) && (a.y && b.y) && (a.z && b.z);
}

inline bool
operator!=(const Vector3& a, const Vector3& b)
{
	return !operator==(a, b);
}

inline f32
dot(const Vector3& a, const Vector3& b)
{
	return a.x * b.x + a.y * b.y + a.z * b.z;
}

inline f32
length_squared(const Vector3& a)
{
	return dot(a, a);
}

inline f32
length(const Vector3& a)
{
	return sqrtf(length_squared(a));
}

inline Vector3
cross(const Vector3& a, const Vector3& b)
{
	return {a.y * b.z - b.y * a.z, b.x * a.z - a.x * b.z, a.x * b.y - b.x * a.y};
}

inline Vector3
normalize(const Vector3& a)
{
	if (length(a) > 0)
		return a * (1.0f / length(a));
	return {0, 0};
}

inline Vector3
lerp(Vector3 x, Vector3 y, f32 t)
{
	return x + (y - x) * t;
}

#endif
