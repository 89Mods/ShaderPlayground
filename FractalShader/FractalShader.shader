Shader "Tholin/FractalShader"
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
        _FractInsideColor ("Inside Color", Color) = (0,0,0,1)
        _FractColor ("Base Color", Color) = (0.05,0.1,0.85,1)
        _FractColor2 ("Highlight Color", Color) = (0.85,0.85,0.85,1)
        _FractGrad ("Color Gradient Strength", Range(0,2)) = 1
        _EmissionLM ("Emission", Float) = 0
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
        fixed4 _FractInsideColor;
        fixed4 _FractColor;
        fixed4 _FractColor2;
        float _FractGrad;
        float4 _FractalOffset;
        float _EmissionLM;

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.localPos = v.vertex.xyz;
        }

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed mul = tex2D (_MaskTex, IN.uv_MainTex).r;
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            float4 c_Col = julia_simple_color(IN.localPos.x + _FractalOffset.x, IN.localPos.z + _FractalOffset.y, _JuliaOffsetX, _JuliaOffsetY, _Scale, _Iters, _FractInsideColor.rgb, _FractColor.rgb, _FractColor2.rgb, _FractGrad);

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
