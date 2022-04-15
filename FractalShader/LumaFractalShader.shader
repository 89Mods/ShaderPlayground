Shader "Tholin/LumaGlowFractalShader"
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
        _JuliaOffset ("Min X, Min Y, Max X, Max Y", Vector) = (0.347, 0.372, 0.379, 0.361)
        _FractalOffset ("Fractal Coord Offset", Vector) = (0, 0, 0, 0)
        _FractInsideColor ("Inside Color", Color) = (0,0,0,1)
        _FractColor ("Base Color", Color) = (0.05,0.1,0.85,1)
        _FractColor2 ("Highlight Color", Color) = (0.85,0.85,0.85,1)
        _FractGrad ("Color Gradient Strength", Range(0,2)) = 1
        _EmissionLM ("Emission", Float) = 0
        [Toggle] _Legends ("Furality Legends mode", int) = 0
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
        uniform sampler2D _Stored;

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
        float4 _JuliaOffset;
        fixed4 _FractInsideColor;
        fixed4 _FractColor;
        fixed4 _FractColor2;
        float _FractGrad;
        float4 _FractalOffset;
        float _EmissionLM;
        int _Legends;

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.localPos = v.vertex.xyz;
        }

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

				float averageBetween(float2 a, float2 b, uint samples) {
					float2 stepSize = (b - a) / (float)samples;
					float sum = 0;
					for(uint i = 0; i < samples; i++) {
						float2 pos = a + stepSize * (float)i;
						sum += length(tex2D(_Stored, pos).rgb * 0.57735);
					}
					return sum / (float)samples;
				}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
						int hasLuma = tex2D(_Stored, float2(0.629, 0.511)).r > 0.25;
						float3 zone1 = hasLuma ? tex2D(_Stored, float2(0.856, 0.522)) : float3(1,1,1);
						float3 zone2 = hasLuma ? tex2D(_Stored, float2(0.856, 0.507)) : float3(1,1,1);
						float3 zone3 = hasLuma ? tex2D(_Stored, float2(0.864, 0.522)) : float3(1,1,1);
						float3 zone4 = hasLuma ? tex2D(_Stored, float2(0.864, 0.507)) : float3(1,1,1);
						if(hasLuma && _Legends) {
							float3 zone4_prev = zone4;
							zone4.y = clamp(averageBetween(float2(0.831675, 1 - 0.50745), float2(0.838308, 1 - 0.50745), 16) * 0.75, 0, 1);
							zone4.z = clamp(averageBetween(float2(0.599502, 1 - 0.50745), float2(0.612769, 1 - 0.50745), 16) * 0.75, 0, 1);
							zone4.x = 0.75 + 0.25 * tex2D(_Stored, float2(0.820896, 1 - 0.513232)).x;

							float a = clamp(length(tex2D(_Stored, float2(0.679104, 1 - 0.485927)).xyz), 0, 1);
							float b = clamp(length(tex2D(_Stored, float2(0.692371, 1 - 0.485927)).xyz), 0, 1);

							zone2 = zone1 * a + (1.0 - a) * _FractColor.rgb;
							zone3 = zone4_prev * b + (1.0 - b) * _FractColor2.rgb;
						}

            // Albedo comes from a texture tinted by color
            fixed mul = tex2D (_MaskTex, IN.uv_MainTex).r;
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

						float offsetx = max(0, min(1, zone4.y));
            offsetx = _JuliaOffset.x * (1.0 - offsetx) + _JuliaOffset.z * offsetx;
            float offsety = max(0, min(1, zone4.z));
            offsety = _JuliaOffset.y * (1.0 - offsety) + _JuliaOffset.w * offsety;
            float4 c_Col = julia_multicolor(IN.localPos.x + _FractalOffset.x, IN.localPos.z + _FractalOffset.y, offsetx, offsety, _Scale, _Iters, (hasLuma && _Legends) ? _FractInsideColor.rgb : _FractInsideColor.rgb * zone1, (hasLuma && _Legends) ? zone2 : _FractColor.rgb * zone2, (hasLuma && _Legends) ? zone3 : _FractColor2.rgb * zone3, _FractGrad, zone1, zone4.x);

            o.Albedo = mul * c.rgb + (1 - mul) * c_Col.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            o.Emission = (1 - mul) * c_Col.rgb * c_Col.a * _EmissionLM;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
