Shader "Tholin/GenericInputLayer"
{
	Properties
	{
		_IN1 ("Data In 1", Float) = 0
		_IN2 ("Data In 2", Float) = 0
		_IN3 ("Data In 3", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Background-6" }
		Cull Off
		ZWrite Off
		ZTest Always
		LOD 100

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
				float4 vertex : SV_POSITION;
			};

			float _IN1;
			float _IN2;
			float _IN3;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				float4 col = fixed4(_IN1, _IN2, _IN3, 1);
				return col;
			}
			ENDCG
		}
	}
}
