Shader "Tholin/MazeGenShader"
{
	Properties
	{
		_Seed1 ("Seed 1", Int) = 1234567
		_Seed2 ("Seed 2", Int) = 3337890
		_ItersPerFrame ("Iterations Per Frame", Int) = 3
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Lighting Off
		Blend One Zero
		LOD 100

		Pass
		{
			Name "Generate Maze"

			CGPROGRAM
			#define _SelfTexture2D _JunkTexture
			#include "UnityCustomRenderTexture.cginc"
			#undef _SelfTexture2D
			Texture2D<uint4> _SelfTexture2D;

			#include "UnityCG.cginc"

			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma target 3.0

			#define MAZE_SIZE 32
			#define STACK_PNTR_LOC (MAZE_SIZE * MAZE_SIZE - 1)

			struct appdata
			{
					float2 uv : TEXCOORD0;
			};

			uint _Seed1;
			uint _Seed2;
			sampler2D _CRTInputGrabPass;

			uint RNG_at(uint globalSeedHi, uint globalSeedLo, int x, int y, int z, int iters);

			uint4 frag (v2f_customrendertexture i) : SV_Target {
				uint idxx = (uint)(i.globalTexcoord.x * MAZE_SIZE);
				uint idxy = (uint)(i.globalTexcoord.y * MAZE_SIZE);
				uint idx = idxy * MAZE_SIZE + idxx;
				uint stackPntr = _SelfTexture2D[uint2(MAZE_SIZE - 1, MAZE_SIZE - 1)].y;
				float3 inputColor = tex2D(_CRTInputGrabPass, float2(0.5, 0.5));
				if(stackPntr == 65535 || stackPntr == 0) {
					uint4 selfVal = _SelfTexture2D[uint2(idxx, idxy)];
					uint state = _SelfTexture2D[uint2(MAZE_SIZE - 3, MAZE_SIZE - 1)].y;
					if(state == 0 && inputColor.r >= 0.6 && inputColor.r < 0.8 && inputColor.g >= 0.1 && inputColor.g <= 0.3) { //r = 0.7, g = 0.2
						if(idx == STACK_PNTR_LOC - 2) selfVal.y = 4;
						if(idx == STACK_PNTR_LOC - 3) selfVal.y = 0;
						if(idx == STACK_PNTR_LOC - 5) selfVal.z = 255;
					}else if(state == 4) {
						uint timer = _SelfTexture2D[uint2(MAZE_SIZE - 4, MAZE_SIZE - 1)].y;
						timer += (uint)(unity_DeltaTime.x * 10000.0);
						if(idx == STACK_PNTR_LOC - 3) selfVal.y = timer;
						if(timer >= 10000) {
							if(idx == STACK_PNTR_LOC - 2) selfVal.y = 0;
							if(inputColor.r >= 0.1 && inputColor.r < 0.3 && inputColor.g >= 0.6 && inputColor.g <= 0.8) { //r = 0.2, g = 0.7
								if(idx == STACK_PNTR_LOC) selfVal.y = 60000;
							}
						}
					}
					return selfVal;
				}
				uint4 selfVal = _SelfTexture2D[uint2(idxx, idxy)];
				if(!(inputColor.r >= 0.1 && inputColor.r < 0.3 && inputColor.g >= 0.6 && inputColor.g <= 0.8)) return selfVal;
				if(stackPntr == 60000) { //Initialize
					if(idx == 0) return uint4(15, 512 | 3, 0, 255);
					if(idx == STACK_PNTR_LOC) return uint4(15, 1, 0, 255);
					if(idx == STACK_PNTR_LOC - 1) return uint4(15, (uint)(tex2D(_CRTInputGrabPass, float2(0.5, 0.5)).b * 100), 0, 255);
					if(idxx == 0 || idxy == 0 || idxx == MAZE_SIZE - 1 || idxy == MAZE_SIZE - 1) return uint4(15, 0, 0, 255);
					return uint4(255, 0, 0, 255);
				}
				uint val = _SelfTexture2D[uint2((stackPntr - 1) % MAZE_SIZE, (stackPntr - 1) / MAZE_SIZE)].y;
				uint rngLoc = _SelfTexture2D[uint2(MAZE_SIZE - 2, MAZE_SIZE - 1)].y;
				uint x = val & 0xFF;
				uint y = (val >> 8) & 0xFF;
				uint cellbuff = _SelfTexture2D[uint2(x, y)].x;
				uint currCell = cellbuff & 239;
				if(idxx == x && idxy == y) selfVal.x = currCell;
				if(idx == STACK_PNTR_LOC - 1) {
					selfVal.y = selfVal.y + 1;
					rngLoc = rngLoc + 1;
				}

				if((_SelfTexture2D[uint2(x + 1, y)].x & 16) == 0 && (_SelfTexture2D[uint2(x, y + 1)].x & 16) == 0 && (_SelfTexture2D[uint2(x - 1, y)].x & 16) == 0 && (_SelfTexture2D[uint2(x, y - 1)].x & 16) == 0) {
					stackPntr--;
					if(idx == stackPntr) selfVal.y = 0;
					if(stackPntr == 0) stackPntr = 65535;
					if(idx == STACK_PNTR_LOC) selfVal.y = stackPntr;
					return selfVal;
				}

				uint loopCntr = 0;
				uint rngCntr = 0;
				uint x_new,y_new;
				while(1) {
					uint indx_r = RNG_at(_Seed1, _Seed2, rngLoc, rngCntr++, 2, 3) & 3;
					x_new = x;
					y_new = y;
					if(indx_r == 0) x_new++;
					else if(indx_r == 1) y_new++;
					else if(indx_r == 2) x_new--;
					else if(indx_r == 3) y_new--;
					if(_SelfTexture2D[uint2(x_new, y_new)].x & 16) break;
					loopCntr++;
					if(loopCntr == 201) {
						stackPntr--;
						if(idx == stackPntr) selfVal.y = 0;
						if(stackPntr == 0) stackPntr = 65535;
						if(idx == STACK_PNTR_LOC) selfVal.y = stackPntr;
						break;
					}
				}
				if(loopCntr == 201) return selfVal;
				if(idx == stackPntr) {
					selfVal.y = x_new | (y_new << 8);
				}
				if(idx == STACK_PNTR_LOC) {
					stackPntr++;
					if(idx == STACK_PNTR_LOC) selfVal.y = stackPntr;
				}
				if(x_new > x) {
					currCell &= 247;
					if(idxx == x && idxy == y) selfVal.x = currCell;
					cellbuff = _SelfTexture2D[uint2(x_new, y_new)];
					cellbuff &= 251;
					if(idxx == x_new && idxy == y_new) selfVal.x = cellbuff;
				}
				if(x_new < x) {
					currCell &= 251;
					if(idxx == x && idxy == y) selfVal.x = currCell;
					cellbuff = _SelfTexture2D[uint2(x_new, y_new)];
					cellbuff &= 247;
					if(idxx == x_new && idxy == y_new) selfVal.x = cellbuff;
				}
				if(y_new > y) {
					currCell &= 253;
					if(idxx == x && idxy == y) selfVal.x = currCell;
					cellbuff = _SelfTexture2D[uint2(x_new, y_new)];
					cellbuff &= 254;
					if(idxx == x_new && idxy == y_new) selfVal.x = cellbuff;
				}
				if(y_new < y) {
					currCell &= 254;
					if(idxx == x && idxy == y) selfVal.x = currCell;
					cellbuff = _SelfTexture2D[uint2(x_new, y_new)];
					cellbuff &= 253;
					if(idxx == x_new && idxy == y_new) selfVal.x = cellbuff;
				}

				return selfVal;
			}

			uint RNG_at(uint globalSeedHi, uint globalSeedLo, int x, int y, int z, int iters) {
				uint k,k2,k3;
				k = (x << 4) + y * 12 + z * 2421;
				k2 = (y << 4) + x * 99 + z * 1111;
				k3 = (z << 4) + (x * 2425) - y * 24525;
				uint iseed1 = (globalSeedHi + k3 * 19438) * (globalSeedLo - k * 35741) - k2 * 333;
				uint iseed2 = (globalSeedLo + k3 * 13145) * (globalSeedHi - k * 132532) - k2 * 4623;

				for(int i = 0; i < iters; i++) {
					k = iseed1 / 53668;
					iseed1 = 40014 * (iseed1 - k * 53668) - k * 12211;
					k = iseed2 / 52774;
					iseed2 = 40692 * (iseed2 - k * 52774) - k * 3791;
				}
				int res = iseed1 - iseed2;
				if(res < 0) res = -res;
				return (uint)res;
			}
			ENDCG
		}
	}
}
