#ifndef IBL_COMMON
#define IBL_COMMON

#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityStandardBRDF.cginc"


//-----------------------------------------------------------------------------
// Sample generator
//-----------------------------------------------------------------------------
// Ref: http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
uint ReverseBits32(uint bits)
{
#if 0 // Shader model 5
    return reversebits(bits);
#else
    bits = ( bits << 16) | ( bits >> 16);
    bits = ((bits & 0x00ff00ff) << 8) | ((bits & 0xff00ff00) >> 8);
    bits = ((bits & 0x0f0f0f0f) << 4) | ((bits & 0xf0f0f0f0) >> 4);
    bits = ((bits & 0x33333333) << 2) | ((bits & 0xcccccccc) >> 2);
    bits = ((bits & 0x55555555) << 1) | ((bits & 0xaaaaaaaa) >> 1);
    return bits;
#endif
}

float RadicalInverse_VdC(uint bits)
{
    return float(ReverseBits32(bits)) * 2.3283064365386963e-10; // 0x100000000
}

float2 Hammersley2d(uint i, uint maxSampleCount)
{
    return float2(float(i) / float(maxSampleCount), RadicalInverse_VdC(i));
}

float Hash(uint s)
{
    s = s ^ 2747636419u;
    s = s * 2654435769u;
    s = s ^ (s >> 16);
    s = s * 2654435769u;
    s = s ^ (s >> 16);
    s = s * 2654435769u;
    return float(s) / 4294967295.0f;
}

float2 InitRandom(float2 input)
{
    float2 r;
    r.x = Hash(uint(input.x * 4294967295.0f));
    r.y = Hash(uint(input.y * 4294967295.0f));

    return r;
}

half perceptualRoughnessToMipmapLevel(half perceptualRoughness)
{
    return perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;
}

half mipmapLevelToPerceptualRoughness(half mipmapLevel)
{
    return mipmapLevel / UNITY_SPECCUBE_LOD_STEPS;
}

float3 ImportanceSampleGGX( float2 Xi, float Roughness, float3 N )
{
    float a = Roughness * Roughness;
    float Phi = 2 * UNITY_PI * Xi.x;
    float CosTheta = sqrt( (1 - Xi.y) / ( 1 + (a*a - 1) * Xi.y ) );
    float SinTheta = sqrt( 1 - CosTheta * CosTheta );
    float3 H;
    H.x = SinTheta * cos( Phi );
    H.y = SinTheta * sin( Phi );
    H.z = CosTheta;
    float3 UpVector = abs(N.z) < 0.999 ? float3(0,0,1) : float3(1,0,0);
    float3 TangentX = normalize( cross( UpVector, N ) );
    float3 TangentY = cross( N, TangentX );
    // Tangent to world space
    return TangentX * H.x + TangentY * H.y + N * H.z;
}


#endif
