Shader "Tholin/PlasmaShader"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_EffectMask ("Effect Mask", 2D) = "white" {}
		_NoiseField1 ("Noise Field (Red/Green Color Channels)", 2D) = "white" {}
		_NoiseField2 ("Noise Field (Red/Green Color Channels)", 2D) = "white" {}
		_NoiseField3 ("Noise Field (Red/Green Color Channels)", 2D) = "white" {}
		_NoiseDimension ("Noise Dimensions", Vector) = (512, 512, 0, 0)
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
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull off

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows
		
		#pragma target 3.0
		
		sampler2D _MainTex;
		sampler2D _EffectMask;
		sampler2D _NoiseField1;
		sampler2D _NoiseField2;
		sampler2D _NoiseField3;
		uniform sampler2D _AudioTexture;

		struct Input
		{
			float2 uv_MainTex;
		};
		
		fixed4 _Color;
		float4 _NoiseDimension;
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
		
		const float2 noiseSampleOffset = float2(-0.5, -0.5);
		
		float weight(float x) { return 3 * (x * x) - 2 * (x * x * x); }
		float m_lerp(float a0, float a1, float w) { return a0 + w * (a1 - a0); }
		float2 sampleNoisemap(int x, int y, sampler2D noise) { return (tex2D(noise, float2((float)x / floor(_NoiseDimension.x), (float)y / floor(_NoiseDimension.y))).xy - noiseSampleOffset) * 2.0; }
		
		float sampleNoise(float x, float y, sampler2D noise) {
			if(x < 0) x = floor(_NoiseDimension.x) + x;
			if(y < 0) y = floor(_NoiseDimension.y) + y;
			
			int width = (int)_NoiseDimension.x;
			int height = (int)_NoiseDimension.y;
			int nodex = (int)x;
			int nodey = (int)y;
			float2 s = float2(x - (float)nodex, y - (float)nodey);
			
			float wx = weight(s.x);
			float wy = weight(s.y);
			
			nodex %= width + 1;
			nodey %= height + 1;
			int nodex1 = nodex + 1;
			int nodey1 = nodey + 1;
			nodex1 %= width + 1;
			nodey1 %= height + 1;
			
			float2 v1 = sampleNoisemap(nodex, nodey, noise);
			float2 v2 = sampleNoisemap(nodex1, nodey, noise);
			float2 v3 = sampleNoisemap(nodex, nodey1, noise);
			float2 v4 = sampleNoisemap(nodex1, nodey1, noise);
			
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
				float distortOffsetX = (_Time * _DistortAnimSpeedX) % floor(_NoiseDimension.x);
				float distortOffsetY = (_Time * _DistortAnimSpeedY) % floor(_NoiseDimension.y);
				float2 nPos = IN.uv_MainTex * _NoiseScale;
				float dx = sampleNoise(nPos.x + distortOffsetX, nPos.y, _NoiseField1) * distort;
				float dy = sampleNoise(nPos.x, nPos.y + distortOffsetY, _NoiseField2) * distort;
				float n = sampleNoise(nPos.x + dx, nPos.y + dy, _NoiseField3) * _NoiseStrength + _NoiseOffset;
				
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
