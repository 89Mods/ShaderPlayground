Shader "Tholin/ParticleRenderer"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ParticleTex ("Particle texture", 2D) = "white" {}
        _FieldSize ("Field Size", float) = 500
        _Scale ("Scale", float) = 2
        _ParticleSize ("Particle Size", float) = 0.07
        _Intensity ("Intensity", float) = 1
        
        _Type0Color ("Type 0 Color", Color) = (1, 0.3, 0.2, 1)
        _Type1Color ("Type 1 Color", Color) = (0.3, 1, 0.2, 1)
        _Type2Color ("Type 2 Color", Color) = (1, 0.6, 0.2, 1)
        _Type3Color ("Type 3 Color", Color) = (0.1, 0.8, 0.5, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent+1000" "DisableBatching"="True" "IgnoreProjector"="True" }
        LOD 100

        Pass
        {
			Cull Back
			Blend One One
			ZWrite Off
			ZTest LEqual
        
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "SimplexNoise3D.cginc"

            struct appdata
            {
            };

            struct fragIn
            {
                fixed4 color : COLOR0;
                float4 position : SV_POSITION;
                half2 uv : TEXCOORD0;
            };
            
            appdata vert (appdata v)
            {
				return v;
            }
            
            Texture2D<float4> _MainTex;
            float _FieldSize;
            half _Scale;
            sampler2D _ParticleTex;
            float _ParticleSize;
            half _Intensity;

            half4 _Type0Color;
            half4 _Type1Color;
            half4 _Type2Color;
            half4 _Type3Color;
            
            #define CRT_DIM 256
			#define PARTICLE_COUNT ((CRT_DIM*CRT_DIM)>>1)-1
            
            #define particleType(idx) ((uint)(_MainTex[uint2((idx * 2 + 1) % CRT_DIM, (idx * 2 + 1) / CRT_DIM)].w * 4.0))
			#define particlePos(idx) (_MainTex[uint2((idx * 2) % CRT_DIM, (idx * 2) / CRT_DIM)].xyz)
			#define particleVel(idx) (_MainTex[uint2((idx * 2 + 1) % CRT_DIM, (idx * 2 + 1) / CRT_DIM)].xyz)
            
           #define PARTICLES_ON_EDGE 512

#define DELTA_TIME (unity_DeltaTime.z)
            
//#define USE_POINT_STREAM
#define USE_TRIANGLE_STREAM


			[maxvertexcount(6)]
			void geom(uint primitiveId : SV_PrimitiveID, point appdata IN[1], 
#ifdef USE_POINT_STREAM
				inout PointStream<fragIn> pointStream
#endif
#ifdef USE_TRIANGLE_STREAM
				inout TriangleStream<fragIn> triangleStream
#endif
			) {

				int particleIdx = primitiveId / 2;
				if(particleIdx >= PARTICLE_COUNT) return;
				
				float3 position = particlePos(particleIdx);
				//if(position.x > _FieldSize || position.x < 0 || position.y > _FieldSize || position.y < 0 || position.z > _FieldSize || position.z < 0) return;
				position = (position / _FieldSize - float3(0.5, 0.5, 0.5)) * _Scale;

				float4 posClip = mul(UNITY_MATRIX_VP, float4(position.xyz, 1));
				
				// early out check if particle is out of screen
				float2 earlyOut = posClip.xy / posClip.w;
				if (any(floor(abs(earlyOut.xy)))) return; // if x >= 1 || x <= -1 || y >= 1 || y <= -1

				float dist = distance(_WorldSpaceCameraPos, position.xyz);

				float3 color;
				uint type = particleType(particleIdx);
					switch(type) {
						case 0:
							color = _Type0Color;
							break;
						case 1:
							color = _Type1Color;
							break;
						case 2:
							color = _Type2Color;
							break;
						case 3:
							color = _Type3Color;
							break;
						default:
							color = fixed4(1, 1, 1, 1);
							break;
					}

				// fade out as particle aproaches camera near plane
				//color *= 1 - smoothstep(_ProjectionParams.y, _ProjectionParams.y + 0.01, posClip.z/posClip.w);

#ifdef USE_POINT_STREAM
				color /= max(0.9, dist);

				fragIn o;
				o.color = fixed4(color, 1);
				o.position = posClip;
				pointStream.Append(o);
#endif

#ifdef USE_TRIANGLE_STREAM
				//color /= max(0.9, dist / 10);

				float scale = _ParticleSize * (1 - smoothstep(_ProjectionParams.y, _ProjectionParams.y + 0.01, posClip.z/posClip.w));
				if(scale < 1e-3) return;
				float rotation = particleIdx * 0.01;
				float sinValue = sin(rotation) * scale;
				float cosValue = cos(rotation) * scale;
				float2x2 rotationMat = {
					cosValue, -sinValue,
					sinValue, cosValue
				};

				const float2 d2 = float2(0.814181, 0.580611); // cos(360/3), sin(360/3)
				const float2 d3 = float2(-0.814181, 0.580611); // -cos(360/3), sin(360/3)
				const float2 d4 = float2(-0.814181, -0.580611); // -cos(360/3), -sin(360/3)
				const float2 d5 = float2(0.814181, -0.580611); // -cos(360/3), -sin(360/3)

				float ratio = _ScreenParams.y / _ScreenParams.x;

				float2 coords;

				fragIn o;
				o.uv = 0;
				o.color = fixed4(color, 1);
				if(primitiveId & 1) {
					coords = mul(d5, rotationMat);
					o.position = posClip + float4(coords.x * ratio, coords.y, 0, 0);
					o.uv = half2(1, 0);
					triangleStream.Append(o);

					coords = mul(d2, rotationMat);
					o.position = posClip + float4(coords.x * ratio, coords.y, 0, 0);
					o.uv = half2(1, 1);
					triangleStream.Append(o);

					coords = mul(d3, rotationMat);
					o.position = posClip + float4(coords.x * ratio, coords.y, 0, 0);
					o.uv = half2(0, 1);
					triangleStream.Append(o);
				}else {
					coords = mul(d5, rotationMat);
					o.position = posClip + float4(coords.x * ratio, coords.y, 0, 0);
					o.uv = half2(1, 0);
					triangleStream.Append(o);

					coords = mul(d3, rotationMat);
					o.position = posClip + float4(coords.x * ratio, coords.y, 0, 0);
					o.uv = half2(0, 1);
					triangleStream.Append(o);

					coords = mul(d4, rotationMat);
					o.position = posClip + float4(coords.x * ratio, coords.y, 0, 0);
					o.uv = half2(0, 0);
					triangleStream.Append(o);
				}
#endif
			}

            fixed4 frag (fragIn i) : SV_Target
            {
							if(i.color.a < 0.5) discard;
							return i.color * tex2D(_ParticleTex, i.uv) * _Intensity;
            }
            ENDCG
        }
    }
}
