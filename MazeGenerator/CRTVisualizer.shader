Shader "Tholin/CRTVisualizer"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
			Tags { "RenderType"="Opaque" }
			LOD 100

			Pass
			{
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag
					#pragma multi_compile_fog

					#include "UnityCG.cginc"

					#define MAZE_SIZE 32

					struct appdata
					{
						float4 vertex : POSITION;
						float2 uv : TEXCOORD0;
					};

					struct v2f
					{
						float2 uv : TEXCOORD0;
						UNITY_FOG_COORDS(1)
						float4 vertex : SV_POSITION;
					};

					Texture2D<uint4> _MainTex;

					v2f vert (appdata v)
					{
						v2f o;
						o.vertex = UnityObjectToClipPos(v.vertex);
						o.uv = v.uv;
						UNITY_TRANSFER_FOG(o,o.vertex);
						return o;
					}

					fixed4 frag (v2f i) : SV_Target
					{
						uint4 ival = _MainTex[uint2((uint)(i.uv.x * MAZE_SIZE), (uint)(i.uv.y * MAZE_SIZE))];
						fixed4 col = fixed4(clamp((fixed)ival.x / 255.0, 0, 1), clamp((fixed)ival.y / 255.0, 0, 1), clamp((fixed)ival.z / 255.0, 0, 1), 1.0);
						UNITY_APPLY_FOG(i.fogCoord, col);
						return col;
					}
					ENDCG
			}
	}
}
