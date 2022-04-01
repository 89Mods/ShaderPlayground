#ifndef POI_SPAWN_IN_FRAG
    #define POI_SPAWN_FRAG
    #ifndef SPAWN_IN_VARIABLES
        #define SPAWN_IN_VARIABLES
        float3 _SpawnInGradientStart;
        float3 _SpawnInGradientFinish;
        fixed _SpawnInAlpha;
        fixed _SpawnInNoiseIntensity;
        float3 _SpawnInEmissionColor;
        float _SpawnInEmissionOffset;
        float _SpawnInVertOffset;
        float _SpawnInVertOffsetOffset;
        float _EnableScifiSpawnIn;
    #endif
    float calculateGradientValueVert(float3 start, float3 finish, float3 localPos)
    {
        return inverseLerp3(start, finish, localPos);
    }
    void applySpawnInVert(inout float4 worldPos, inout float4 localPos, float2 uv)
    {
        
        if (float(0))
        {
            float noise = 0;
            float gradient = calculateGradientValueVert(float4(0,2,0,1), float4(0,-2,0,1), localPos.xyz);
            float inverseGradient = 1 - gradient;
            float alpha = gradient - float(0) - noise;
            worldPos.xyz += saturate(inverseGradient + float(0) + float(0.1) -1) * float3(0, float(10), 0);
            localPos.xyz = mul(unity_WorldToObject, worldPos).xyz;
        }
    }
#endif
