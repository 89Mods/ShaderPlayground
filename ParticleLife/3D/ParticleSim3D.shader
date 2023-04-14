Shader "Tholin/ParticleSim3D"
{
	Properties
	{
		_Seed ("Seed", Int) = 2849184
		[Toggle] _Reset ("Reset", Int) = 0
		_FieldSize ("Field Size", float) = 500
		_SimSpeed ("Sim Speed", float) = 0.5
		_Innertia ("Inneratia", float) = 0.5
		_WallRepel ("Wall repel", float) = 5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Lighting Off
		Blend One Zero
		LOD 100

		Pass
		{
			Name "VelocityUpdate"
        
			CGPROGRAM
			#define _SelfTexture2D _JunkTexture
			#include "UnityCustomRenderTexture.cginc"
			#undef _SelfTexture2D
			Texture2D<float4> _SelfTexture2D;

			#include "UnityCG.cginc"

			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma target 3.0

			#define CRT_DIM 256
			#define PARTICLE_COUNT ((CRT_DIM*CRT_DIM)>>1)-1

			struct appdata
			{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
			};

			uint _Seed;
			uint _Reset;
			float _FieldSize;
			float _SimSpeed;
			float _Innertia;
			float _Rules[16];
			float _InteractionRadi[16];
			float _WallRepel;
			
			float RNG_at(uint globalSeed, int x, int y, int z, int iters);
			
			#define particleTypeFloat(idx) (_SelfTexture2D[uint2((idx * 2 + 1) % CRT_DIM, (idx * 2 + 1) / CRT_DIM)].w)
			#define particleType(idx) ((uint)(_SelfTexture2D[uint2((idx * 2 + 1) % CRT_DIM, (idx * 2 + 1) / CRT_DIM)].w * 4.0))
			#define particlePos(idx) (_SelfTexture2D[uint2((idx * 2) % CRT_DIM, (idx * 2) / CRT_DIM)].xyz)
			#define particleVel(idx) (_SelfTexture2D[uint2((idx * 2 + 1) % CRT_DIM, (idx * 2 + 1) / CRT_DIM)].xyz)

			float4 frag(v2f_customrendertexture i) : SV_Target {
				uint idxx = (uint)(i.globalTexcoord.x * 2 * CRT_DIM);
				uint idxy = (uint)(i.globalTexcoord.y * CRT_DIM);
				uint type_idx = idxx & 1;

				float3 status = _SelfTexture2D[uint2(CRT_DIM - 1, CRT_DIM - 1)];
				if(status.y < 0.8 || _Reset) {
					if(idxx >= CRT_DIM) return 0;
					if(idxx == CRT_DIM - 1 && idxy == CRT_DIM - 1) return float4(0, 1, 0, 1);
					if(type_idx == 0) return float4(RNG_at(_Seed, idxx, idxy, 33, 12) * _FieldSize, RNG_at(_Seed, idxx + 1, idxy * 353, 643, 12) * _FieldSize, RNG_at(_Seed, idxx + 2, idxy * 998, 999, 12) * _FieldSize, 0);
					if(type_idx == 1) return float4(0, 0, 0, RNG_at(_Seed, idxx * 257, idxy, 121, 12));
					return 0;
				}

				float4 selfVal = _SelfTexture2D[uint2(idxx, idxy)];
				if(status.x > 4) {
					if(idxx == CRT_DIM - 1 && idxy == CRT_DIM - 1) return float4(0, 1, 0, 1);
					if(idxx < CRT_DIM) {
						if(type_idx == 0) return selfVal;
						return _SelfTexture2D[uint2(idxx + CRT_DIM, idxy)];
					}else {
						return 0;
					}
				}else {
					if(idxx == CRT_DIM - 1 && idxy == CRT_DIM - 1) return float4(selfVal.x + 1.1, 1, 0, 1);
					if(idxx < CRT_DIM) return selfVal;
				}

				uint stripIdx = (uint)(status.x + 1);
				if(idxy >= stripIdx * 64 || idxy < (stripIdx - 1) * 64) return selfVal;

				uint idx = idxy * CRT_DIM + (idxx - CRT_DIM);
				uint particle_idx = idx >> 1;
				selfVal = _SelfTexture2D[uint2(idxx - CRT_DIM, idxy)];
				if(particle_idx >= PARTICLE_COUNT || type_idx == 0) return selfVal;
				
				float3 localPos = particlePos(particle_idx);
				float3 localVel = particleVel(particle_idx);
				uint localType = particleType(particle_idx);
				
				float3 f = 0;
				for(int i = 0; i < PARTICLE_COUNT; i++) {
					float3 otherPos = particlePos(i);
					float3 otherVel = particleVel(i);
					uint otherType = particleType(i);
					
					float3 dx = localPos - otherPos;
					float d = dot(dx, dx);
					float ir = _InteractionRadi[otherType * 4 + localType];
					if(d > 1e-8 && d < ir) {
						float F = _Rules[otherType * 4 + localType] * 1.0/sqrt(d);
						d /= ir;
						if(d > 0.9) {
							d = (d - 0.9) / 0.1;
							d = 1 - d;
							F *= d;
						}
						f += F * dx;
					}
				}
				
				localVel = (f * _SimSpeed + localVel) * _Innertia;
				localVel.x += localPos.x < _WallRepel ? (_WallRepel - localPos.x) * 0.1 : 0;
				localVel.y += localPos.y < _WallRepel ? (_WallRepel - localPos.y) * 0.1 : 0;
				localVel.z += localPos.z < _WallRepel ? (_WallRepel - localPos.z) * 0.1 : 0;

				localVel.x += localPos.x > _FieldSize - _WallRepel ? (_FieldSize - _WallRepel - localPos.x) * 0.1 : 0;
				localVel.y += localPos.y > _FieldSize - _WallRepel ? (_FieldSize - _WallRepel - localPos.y) * 0.1 : 0;
				localVel.z += localPos.z > _FieldSize - _WallRepel ? (_FieldSize - _WallRepel - localPos.z) * 0.1 : 0;
				
				return float4(localVel, selfVal.w);
			}
            
			float RNG_at(uint globalSeed, int x, int y, int z, int iters) {
				uint state = globalSeed + ((x << 15) ^ (y << 3) ^ (z << 22));
				state *= 733 * x + 529 * y + 635 * z;
				[Unroll(32)]
				for(int i = 0; i < iters; i++) {
					state ^= state << 13;
					state ^= state << 17;
					state ^= state << 5;
				}
				return (float)(state & 0xFFFFFF) / 16777216.0;
			}
			ENDCG
		}
        
		Pass
		{
			Name "PositionUpdate"
			
			CGPROGRAM
			#define _SelfTexture2D _JunkTexture
			#include "UnityCustomRenderTexture.cginc"
			#undef _SelfTexture2D
			Texture2D<float4> _SelfTexture2D;

			#include "UnityCG.cginc"

			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma target 3.0

			#define CRT_DIM 256
			#define PARTICLE_COUNT ((CRT_DIM*CRT_DIM)>>1)-1

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			uint _Seed;
			uint _Reset;
			float _FieldSize;
			float _SimSpeed;
            
			#define particlePos(idx) (_SelfTexture2D[uint2((idx * 2) % CRT_DIM, (idx * 2) / CRT_DIM)].xyz)
			#define particleVel(idx) (_SelfTexture2D[uint2((idx * 2 + 1) % CRT_DIM, (idx * 2 + 1) / CRT_DIM)].xyz)
            
			float4 frag(v2f_customrendertexture i) : SV_Target {
				uint idxx = (uint)(i.globalTexcoord.x * 2 * CRT_DIM);
				uint idxy = (uint)(i.globalTexcoord.y * CRT_DIM);
				uint idx = idxy * CRT_DIM + idxx;
				uint particle_idx = idx >> 1;
				uint type_idx = idxx & 1;
				
				float3 status = _SelfTexture2D[uint2(CRT_DIM - 1, CRT_DIM - 1)];
				float4 selfVal = _SelfTexture2D[uint2(idxx, idxy)];
				if(idxx >= CRT_DIM) return selfVal;
				if(status.y < 0.8 || _Reset || type_idx == 1) return selfVal;
				if(idxx == CRT_DIM - 1 && idxy == CRT_DIM - 1) return selfVal;
				
				float3 localPos = particlePos(particle_idx);
				float3 localVel = particleVel(particle_idx);
				
				localPos += localVel * _SimSpeed * 0.25;
				
				return float4(localPos, selfVal.w);
			}
            
			ENDCG
		}
	}
}
