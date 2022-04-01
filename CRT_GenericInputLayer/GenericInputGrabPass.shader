Shader "Tholin/GenericInputGrabPass"
{
	Properties
	{

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Background-5" "PreviewType"="Quad" }
		Cull Front
		ZWrite Off
		ZTest Always
		LOD 100

		GrabPass
		{
			"_CRTInputGrabPass"
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			uniform sampler2D _CRTInputGrabPass;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(0, 0, 0, 1);
			}
			ENDCG
		}
	}
}
