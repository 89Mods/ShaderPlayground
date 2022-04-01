Shader "Tholin/MazeRenderer"
{
	Properties
	{
			_MainTex ("Texture", 2D) = "white" {}
			_WallThickness ("Wall thickness", Range(0, 1)) = 0.2
			_GroundColor ("Ground Color", Color) = (1, 1, 1, 1)
			_WallColor ("Walls Color", Color) = (0, 0, 0, 1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "PreviewType"="Plane" }
		Lighting Off
		Blend One Zero
		LOD 100

		Pass
		{
				CGPROGRAM
				#include "UnityCustomRenderTexture.cginc"
				#include "UnityCG.cginc"

				#pragma vertex CustomRenderTextureVertexShader
				#pragma fragment frag
				#pragma target 3.0

				#define MAZE_SIZE 32

				struct appdata
				{
						float2 uv : TEXCOORD0;
				};


				Texture2D<uint4> _MainTex;
				fixed _WallThickness;
				fixed4 _GroundColor;
				fixed4 _WallColor;

				fixed4 frag (v2f_customrendertexture i) : SV_Target
				{
						fixed4 col = _GroundColor;
						uint idxx = (uint)(i.globalTexcoord.x * MAZE_SIZE);
						uint idxy = (uint)(i.globalTexcoord.y * MAZE_SIZE);
						uint idx = idxy * MAZE_SIZE + idxx;
						float inCellX = i.globalTexcoord.x * MAZE_SIZE - idxx;
						float inCellY = i.globalTexcoord.y * MAZE_SIZE - idxy;
						if(idxx == 0 || idxy == 0 || idxx == MAZE_SIZE - 1 || idxy == MAZE_SIZE - 1) col = _WallColor;
						else {
							uint currCell = _MainTex[uint2(idxx, idxy)].x;
							if(currCell == 255) col = _GroundColor;
							else if(inCellX < _WallThickness && (currCell & 4)) {
								col = _WallColor;
							}else if(inCellY < _WallThickness && (currCell & 1)) {
								col = _WallColor;
							}else if(inCellX >= (1.0 - _WallThickness) && (currCell & 8)) {
								col = _WallColor;
							}else if(inCellY >= (1.0 - _WallThickness) && (currCell & 2)) {
								col = _WallColor;
							}
						}

						UNITY_APPLY_FOG(i.fogCoord, col);
						return col;
				}
				ENDCG
		}
	}
}
