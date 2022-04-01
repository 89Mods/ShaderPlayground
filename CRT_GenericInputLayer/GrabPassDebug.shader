Shader "Tholin/GrabPassDebug"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Off
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

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

			sampler2D _CRTInputGrabPass;

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
				fixed4 col = tex2D(_CRTInputGrabPass, i.uv);
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
