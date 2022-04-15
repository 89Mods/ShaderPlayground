Shader "Tholin/RainbowFractalShader"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_MaskTex ("Mask (Grayscale)", 2D) = "black" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Iters ("Iterations", Int) = 32
		_Scale ("Scale", Range(0.01,3)) = 1
		_JuliaOffsetX ("Julia Offset X", Range(0,0.75)) = 0.4
		_JuliaOffsetY ("Julia Offset Y", Range(0,0.75)) = 0.4
		_FractalOffset ("Fractal Coord Offset", Vector) = (0, 0, 0, 0)
		_FractGrad ("Color Gradient Strength", Range(0,2)) = 1
		_EmissionLM ("Emission", Float) = 0
		_ColorScale ("Color gradient scale", float) = 10
		_ColorCuttoff ("Color cutoff point", Range(0, 1)) = 0.1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Off

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		#include "Julia.cginc"

		sampler2D _MainTex;
		sampler2D _MaskTex;

		struct Input
		{
			float2 uv_MainTex;
			float3 localPos;
			float3 worldPos;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		int _Iters;
		float _Scale;
		float _JuliaOffsetX;
		float _JuliaOffsetY;
		float _FractGrad;
		float4 _FractalOffset;
		float _EmissionLM;
		float _ColorScale;
		float _ColorCuttoff;

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.localPos = v.vertex.xyz;
		}

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		float3 hsv_to_rgb(float3 HSV) {
			float3 RGB = HSV.z;

			float var_h = HSV.x * 6;
			float var_i = floor(var_h);
			float var_1 = HSV.z * (1.0 - HSV.y);
			float var_2 = HSV.z * (1.0 - HSV.y * (var_h-var_i));
			float var_3 = HSV.z * (1.0 - HSV.y * (1-(var_h-var_i)));
			if      (var_i == 0) { RGB = float3(HSV.z, var_3, var_1); }
			else if (var_i == 1) { RGB = float3(var_2, HSV.z, var_1); }
			else if (var_i == 2) { RGB = float3(var_1, HSV.z, var_3); }
			else if (var_i == 3) { RGB = float3(var_1, var_2, HSV.z); }
			else if (var_i == 4) { RGB = float3(var_3, var_1, HSV.z); }
			else                 { RGB = float3(HSV.z, var_1, var_2); }

			return RGB;
		}

		void surf (Input IN, inout SurfaceOutputStandard o)
		{
			fixed mul = tex2D (_MaskTex, IN.uv_MainTex).r;
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

			int i = julia_iters(IN.localPos.x + _FractalOffset.x, IN.localPos.z + _FractalOffset.y, _JuliaOffsetX, _JuliaOffsetY, _Scale, _Iters);
			/*float h = (float)i / (float)_Iters;
			float s = 0.9;
			float v = 0.9;
			if(h < 0.15) {
				if(h < 0.05) s = v = 0;
				else {
					s *= (h - 0.05) / 0.1;
					v *= (h - 0.05) / 0.1;
				}
			}*/

			float h = (sin((IN.localPos.x + _FractalOffset.x) * _ColorScale * 3.1415968) + 1.0) * 0.5 + (cos((IN.localPos.z + _FractalOffset.y) * _ColorScale * 3.1415968) + 1.0) * 0.5;
			if(h < 0) h = -h;
			h %= 1;
			float s = 0.9;

			float f = (float)i / (float)_Iters;
			f -= _ColorCuttoff;
			f /= (1 - _ColorCuttoff);
			if(f < 0) f = 0;
			float v = 0.9 * f;
			float4 c_Col = float4(hsv_to_rgb(float3(h, s, v)), 1);

			//c_Col = float4(f, f, f, 1);

			o.Albedo = mul * c.rgb + (1 - mul) * c_Col.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
			o.Emission = (1 - mul) * c_Col.rgb * c_Col.a * _EmissionLM;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
