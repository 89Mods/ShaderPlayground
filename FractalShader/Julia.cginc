#ifndef JULIA
#define JULIA
float sigmoid(float x) {
	return 1.0 / (1.0 + exp(-x));
}

float biasFunction(float x, float bias) {
	float k = 1.0 - bias;
	k = k * k * k;
	return (x * k) / (x * k - x + 1.0);
}


int julia_iters(float x, float y, float cx, float cy, float scale, uint iterCount) {
	float zx = x * scale;
	float zy = y * scale;
	uint i = 0;
	while(i < iterCount && zx * zx + zy * zy < 4)
	{
			float newx = zx * zx - zy * zy + cx;
			zy = 2 * zx * zy + cy;
			zx = newx;
			i++;
	}
	return i;
}

float4 julia_simple_color(float x, float y, float cx, float cy, float scale, uint iterCount, float3 insideColor, float3 color, float3 color2, float fractPow) {
	uint i = julia_iters(x, y, cx, cy, scale, iterCount);
	if(i == iterCount) return float4(insideColor, 1);
	uint halfIters = (iterCount >> 1) - 1;
	if(i <= halfIters)
	{
			float colScale = (float)i / (float)halfIters;
			colScale = pow(colScale, fractPow);
			return float4(color * colScale, colScale * 0.5);
	}
	float colScale = (float)(i - halfIters) / (float)halfIters;
	return float4((1 - colScale) * color + colScale * color2, colScale + 0.5);
}

float4 julia_multicolor(float x, float y, float cx, float cy, float scale, uint iterCount, float3 insideColor, float3 color, float3 color2, float fractPow, float highs, float3 highsColor) {
	uint i = julia_iters(x, y, cx, cy, scale, iterCount);
	if(i == iterCount) return float4(insideColor, 1);
	uint halfIters = (iterCount >> 1) - 1;
	if(i <= halfIters)
	{
			float colScale = (float)i / (float)halfIters;
			colScale = pow(colScale, fractPow);
			float4 ret = float4(color * colScale, colScale * 0.5);
			highs = biasFunction(highs * (1.0 / 0.8), -0.3);
			colScale = 1 - colScale;
			colScale -= highs;
			if(colScale > -0.2 && colScale < 0) {
				colScale = sin(colScale / -0.2 * 3.1415926535);
				ret = colScale * float4(highsColor, ret.w) + (1 - colScale) * ret;
			}
			return ret;
	}
	float colScale = (float)(i - halfIters) / (float)halfIters;
	return float4((1 - colScale) * color + colScale * color2, colScale + 0.5);
}
#endif
