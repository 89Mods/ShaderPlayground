Shader "Tholin/PlasmaShader-LivePerlin"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_EffectMask ("Effect Mask", 2D) = "white" {}
		_NoiseScale ("Noise Scale", Range(0,128)) = 8
		_NoiseOffset ("Noise Offset", Range(-0.5,0.5)) = 0
		_NoiseStrength ("Noise Strength", Range(0,8)) = 1
		_DistortStrength ("Distort Strength", Range(0,4)) = 0.1
		_DistortAnimSpeedX ("Distort Anim Speed (X)", Range(0,16)) = 1
		_DistortAnimSpeedY ("Distort Anim Speed (Y)", Range(0,16)) = 1
		_PulseStrength ("Pulse Strength", float) = 0
		_PulseInterval ("Pulse Interval", float) = 5
		_PulseLength ("Pulse Length", float) = 0.1
		_BaseColor ("Base Color", Color) = (0,0,0,1)
		_NoiseColor ("Noise Color", Color) = (1,1,1,1)
		_EmissionStrength ("Emission Strength", Range(0,1)) = 1
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		[Toggle] _AudioL ("Audio Link", Int) = 0
		 _PulseChannel ("Pulse AL channel (0 = Bass, 1 = Lows, 2 = Highs, 3 = Treble)", Int) = 0
		 _Int ("Seed 1", Int) = 18342155
		 _Int ("Seed 2", Int) = 241325326
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull off

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows
		
		#pragma target 3.0

		#define NOISE_WIDTH 512
		#define NOISE_HEIGHT 512
		#define NOISE_DEPTH 512
		#define RNG_ITERS 3
		#define m_lerp(a0,a1,w) ((a0) + (w) * ((a1) - (a0)))
		#define m_weight(x) (3 * ((x) * (x)) - 2 * ((x) * (x) * (x)))

		sampler2D _MainTex;
		sampler2D _EffectMask;
		uniform sampler2D _AudioTexture;

		struct Input
		{
			float2 uv_MainTex;
		};
		
		fixed4 _Color;
		float _NoiseScale;
		float _DistortStrength;
		float _NoiseOffset;
		float _NoiseStrength;
		float _DistortAnimSpeedX;
		float _DistortAnimSpeedY;
		float _PulseStrength;
		float _PulseInterval;
		float _PulseLength;
		fixed4 _BaseColor;
		fixed4 _NoiseColor;
		float _EmissionStrength;
		half _Glossiness;
		half _Metallic;
		int _AudioL;
		int _PulseChannel;
		uint _Seed1;
		uint _Seed2;

		int RNG_at(uint globalSeedHi, uint globalSeedLo, int x, int y, int z, int iters) {
			uint k,k2,k3;
			k = (x << 4) + y * 12 + z * 2421;
			k2 = (y << 4) + x * 99 + z * 1111;
			k3 = (z << 4) + (x * 2425) - y * 24525;
			uint iseed1 = (globalSeedHi + k3 * 19438) * (globalSeedLo - k * 35741) - k2 * 333;
			uint iseed2 = (globalSeedLo + k3 * 13145) * (globalSeedHi - k * 132532) - k2 * 4623;

			for(int i = 0; i < iters; i++) {
				k = iseed1 / 53668;
				iseed1 = 40014 * (iseed1 - k * 53668) - k * 12211;
				k = iseed2 / 52774;
				iseed2 = 40692 * (iseed2 - k * 52774) - k * 3791;
			}
			return iseed1 - iseed2;
		}

		uint absi(int i) {
			return i < 0 ? -i : i;
		}

		float2 perlin_noisefield_at(int x, int y, int z, uint seedHi, uint seedLo) {
			float f1 = (float)(absi(RNG_at(seedHi, seedLo, x, y, z, RNG_ITERS)) & 65535) / 65535.0 - 0.5;
			float f2 = (float)(absi(RNG_at(seedHi, seedLo, x + NOISE_WIDTH, y + NOISE_DEPTH, z + NOISE_HEIGHT, RNG_ITERS)) & 65535) / 65535.0 - 0.5;
			float2 res = float2(f1, f2);
			res = normalize(res);
			return res;
		}

		float sampleNoise(float x, float y, int z) {
			if(x < 0) x = NOISE_WIDTH + x;
			if(y < 0) y = NOISE_HEIGHT + y;

			int width = NOISE_WIDTH;
			int height = NOISE_HEIGHT;
			int nodex = (int)x;
			int nodey = (int)y;
			float2 s = float2(x - (float)nodex, y - (float)nodey);

			float wx = m_weight(s.x);
			float wy = m_weight(s.y);

			nodex %= width + 1;
			nodey %= height + 1;
			int nodex1 = nodex + 1;
			int nodey1 = nodey + 1;
			nodex1 %= width + 1;
			nodey1 %= height + 1;

			float2 v1 = perlin_noisefield_at(nodex, nodey, z, _Seed1, _Seed2);
			float2 v2 = perlin_noisefield_at(nodex1, nodey, z, _Seed1, _Seed2);
			float2 v3 = perlin_noisefield_at(nodex, nodey1, z, _Seed1, _Seed2);
			float2 v4 = perlin_noisefield_at(nodex1, nodey1, z, _Seed1, _Seed2);

			float dot0 = dot(v1, s);
			float sx = s.x;
			s.x -= 1;
			float dot1 = dot(v2, s);
			s.x = sx;
			s.y -= 1;
			float dot2 = dot(v3, s);
			s.x -= 1;
			float dot3 = dot(v4, s);

			float ix0 = m_lerp(dot0, dot1, wx);
			float ix1 = m_lerp(dot2, dot3, wx);

			return m_lerp(ix0, ix1, wy);
		}

		void surf (Input IN, inout SurfaceOutputStandard o)
		{
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			float mul = tex2D(_EffectMask, IN.uv_MainTex).x;
			
			float4 finalCol = float4(0, 0, 0, 1);
			if(mul > 0) {
				float bass = _AudioL ? tex2D(_AudioTexture, float2(0.0039, 0.0078)).x : 0;
				float treble = _AudioL ? tex2D(_AudioTexture, float2(0.0039, 0.0546)).x : 0;
				float lows = _AudioL ? tex2D(_AudioTexture, float2(0.0039, 0.0234)).x : 0;
				float highs = _AudioL ? tex2D(_AudioTexture, float2(0.0039, 0.0390)).x : 0;

				float distort = _DistortStrength;
				if(_AudioL) {
					distort *= 1.0 + (highs - 0.5) * 0.75;
				}
				float distortOffsetX = (_Time * _DistortAnimSpeedX) % NOISE_WIDTH;
				float distortOffsetY = (_Time * _DistortAnimSpeedY) % NOISE_HEIGHT;
				float2 nPos = IN.uv_MainTex * _NoiseScale;
				float dx = sampleNoise(nPos.x + distortOffsetX, nPos.y, 32) * distort;
				float dy = sampleNoise(nPos.x, nPos.y + distortOffsetY, 64) * distort;
				float n = sampleNoise(nPos.x + dx, nPos.y + dy, 128) * _NoiseStrength + _NoiseOffset;
				
				if(!_AudioL) {
					float pulseTime = (_Time * 10.0) % _PulseInterval;
					if(pulseTime < _PulseLength) {
						float pulse = 1.0 - (sin(pulseTime / _PulseLength * 3.1415926535 * 2 + 3.1415926535 * 0.5) + 1.0) * 0.5;
						n += pulse * _PulseStrength;
					}
				}else n += (_PulseChannel == 1 ? lows : (_PulseChannel == 2 ? highs : bass)) * 0.6;
				
				n = clamp(n, 0, 1);
				finalCol = (1.0 - n) * _BaseColor + n * _NoiseColor;
				o.Emission = mul * finalCol * _EmissionStrength;
				finalCol = mul * finalCol + (1.0 - mul) * c;
				o.Albedo = finalCol.rgb;
			}else {
				o.Emission = float4(0,0,0,1);
				o.Albedo = c;
			}
			
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
