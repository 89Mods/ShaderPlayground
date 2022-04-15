Shader "Tholin/AudioReactiveFractalShader"
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
        _AudioColor ("Audio Color", Color) = (1,1,1,1)
        _FractGrad ("Color Gradient Strength", Range(0,2)) = 1
        _MinEmission ("Minimum Emission", Range(0,1)) = 0
        _MaxEmission ("Maximum Emission", Range(0,1)) = 1
        _OffsetBias ("Fractal offset bias", Range(-1,1)) = 0
        _EmissionBias ("Emission bias", Range(-1,1)) = 0

        _RippleTest ("Ripple Test", Range(0, 1)) = 0
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
        uniform sampler2D _AudioTexture;

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
        fixed4 _AudioColor;
        float _FractGrad;
        float4 _FractalOffset;
        float _MinEmission;
        float _MaxEmission;
        float _OffsetBias;
        float _EmissionBias;
        float _RippleTest;

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.localPos = v.vertex.xyz;
        }

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
						float bass = tex2D(_AudioTexture, float2(0.0039, 0.0078)).x;
						float treble = tex2D(_AudioTexture, float2(0.0039, 0.0546)).x;
						float lows = tex2D(_AudioTexture, float2(0.0039, 0.0234)).x;
						float highs = tex2D(_AudioTexture, float2(0.0039, 0.0390)).x;
            // Albedo comes from a texture tinted by color
            fixed mul = tex2D (_MaskTex, IN.uv_MainTex).r;
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            float a = biasFunction(bass, _OffsetBias);
            //float a = sin(max(0, bass) * 3.1415926535);
            float offsetx = _JuliaOffset.x * a + (1 - a) * _JuliaOffset.z;
            float offsety = _JuliaOffset.y * a + (1 - a) * _JuliaOffset.w;
            float4 c_Col = julia_multicolor(IN.localPos.x + _FractalOffset.x, IN.localPos.z + _FractalOffset.y, offsetx, offsety, _Scale, _Iters, _FractInsideColor.rgb, _FractColor.rgb, _FractColor2.rgb, _FractGrad, max(_RippleTest, highs), _AudioColor);

            o.Albedo = mul * c.rgb + (1 - mul) * c_Col.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            float emiss = _MinEmission + (biasFunction(lows, _EmissionBias) * (_MaxEmission - _MinEmission));
            o.Emission = (1 - mul) * c_Col.rgb * c_Col.a * emiss;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
