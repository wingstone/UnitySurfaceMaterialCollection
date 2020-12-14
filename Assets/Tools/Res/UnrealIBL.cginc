#ifndef UNREAL_IBL
#define UNREAL_IBL

// float3 SpecularIBL(samplerCUBE EnvMap, float3 SpecularColor , float Roughness, float3 N, float3 V )
// {
//     float3 SpecularLighting = 0;
//     const uint NumSamples = 1024;
//     for( uint i = 0; i < NumSamples; i++ )
//     {
//         float2 Xi = Hammersley2d( i, NumSamples );
//         float3 H = ImportanceSampleGGX( Xi, Roughness, N );
//         float3 L = 2 * dot( V, H ) * H - V;
//         float NoV = saturate( dot( N, V ) );
//         float NoL = saturate( dot( N, L ) );
//         float NoH = saturate( dot( N, H ) );
//         float VoH = saturate( dot( V, H ) );
//         if( NoL > 0 )
//         {
//             float3 SampleColor = texCUBElod(EnvMap, float4(L, 0) ).rgb;
//             float G = G_Smith( Roughness, NoV, NoL );
//             float Fc = pow( 1 - VoH, 5 );
//             float3 F = (1 - Fc) * SpecularColor + Fc;
//             // Incident light = SampleColor * NoL
//             // Microfacet specular = D*G*F / (4*NoL*NoV)
//             // pdf = D * NoH / (4 * VoH)
//             SpecularLighting += SampleColor * F * G * VoH / (NoH * NoV);
//         }
//     }
//     return SpecularLighting / NumSamples;
// }


float3 PrefilterEnvMap(samplerCUBE EnvMap, float Roughness, float3 R )
{
    float3 N = R;
    float3 V = R;

    float3 PrefilteredColor = 0;
    float TotalWeight = 0;

    const uint NumSamples = 1024;
    for( uint i = 0; i < NumSamples; i++ )
    {
        float2 Xi = Hammersley2d( i, NumSamples );
        float3 H = ImportanceSampleGGX( Xi, Roughness, N );
        float3 L = 2 * dot( V, H ) * H - V;
        float NoL = saturate( dot( N, L ) );
        if( NoL > 0 )
        {
            #if UNITY_COLORSPACE_GAMMA
                PrefilteredColor += GammaToLinearSpace(texCUBElod(EnvMap, float4(L, 0) ).rgb )* NoL;
            #else
                PrefilteredColor += texCUBElod(EnvMap, float4(L, 0) ).rgb * NoL;
            #endif

            TotalWeight += NoL;
        }
    }
    #if UNITY_COLORSPACE_GAMMA
        return LinearToGammaSpace(PrefilteredColor / TotalWeight);
    #else
        return PrefilteredColor / TotalWeight;
    #endif
}

#endif
