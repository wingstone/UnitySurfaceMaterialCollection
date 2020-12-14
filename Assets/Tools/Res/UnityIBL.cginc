#ifndef UNITY_IBL
#define UNITY_IBL

//-----------------------------------------------------------------------------
// Util
//-----------------------------------------------------------------------------

// generate an orthonormalBasis from 3d unit vector.
void GetLocalFrame(float3 N, out float3 tangentX, out float3 tangentY)
{
    float3 upVector     = abs(N.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(1.0f, 0.0f, 0.0f);
    tangentX            = normalize(cross(upVector, N));
    tangentY            = cross(N, tangentX);
}

/*
// http://orbit.dtu.dk/files/57573287/onb_frisvad_jgt2012.pdf
void GetLocalFrame(float3 N, out float3 tangentX, out float3 tangentY)
{
    if (N.z < -0.999f) // Handle the singularity
    {
        tangentX = Vec3f (0.0f, -1.0f, 0.0f);
        tangentY = Vec3f (-1.0f, 0.0f, 0.0f);
        return ;
    }

    float a     = 1.0f / (1.0f + N.z);
    float b     = -N.x * N.y * a ;
    tangentX    = float3(1.0f - N.x * N.x * a , b, -N.x);
    tangentY    = float3(b, 1.0f - N.y * N.y * a, -N.y);
}
*/

// ----------------------------------------------------------------------------
// Sampling
// ----------------------------------------------------------------------------

void ImportanceSampleCosDir(float2 u,
                            float3 N,
                            float3 tangentX,
                            float3 tangentY,
                            out float3 L)
{
    // Cosine sampling - ref: http://www.rorydriscoll.com/2009/01/07/better-sampling/
    float cosTheta = sqrt(max(0.0f, 1.0f - u.x));
    float sinTheta = sqrt(u.x);
    float phi = UNITY_TWO_PI * u.y;

    // Transform from spherical into cartesian
    L = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);
    // Local to world
    L = tangentX * L.x + tangentY * L.y + N * L.z;
}

//-------------------------------------------------------------------------------------
void ImportanceSampleGGXDir(float2 u,
                            float3 V,
                            float3 N,
                            float3 tangentX,
                            float3 tangentY,
                            float roughness,
                            out float3 H,
                            out float3 L)
{
    // GGX NDF sampling
    float cosThetaH = sqrt((1.0f - u.x) / (1.0f + (roughness * roughness - 1.0f) * u.x));
    float sinThetaH = sqrt(max(0.0f, 1.0f - cosThetaH * cosThetaH));
    float phiH      = UNITY_TWO_PI * u.y;

    // Transform from spherical into cartesian
    H = float3(sinThetaH * cos(phiH), sinThetaH * sin(phiH), cosThetaH);
    // Local to world
    H = tangentX * H.x + tangentY * H.y + N * H.z;

    // Convert sample from half angle to incident angle
    L = 2.0f * dot(V, H) * H - V;
}

// ----------------------------------------------------------------------------
// weightOverPdf return the weight (without the diffuseAlbedo term) over pdf. diffuseAlbedo term must be apply by the caller.
void ImportanceSampleLambert(
    float2 u,
    float3 N,
    float3 tangentX,
    float3 tangentY,
    out float3 L,
    out float NdotL,
    out float weightOverPdf)
{
    ImportanceSampleCosDir(u, N, tangentX, tangentY, L);

    NdotL = saturate(dot(N, L));

    // Importance sampling weight for each sample
    // pdf = N.L / PI
    // weight = fr * (N.L) with fr = diffuseAlbedo / PI
    // weight over pdf is:
    // weightOverPdf = (diffuseAlbedo / PI) * (N.L) / (N.L / PI)
    // weightOverPdf = diffuseAlbedo
    // diffuseAlbedo is apply outside the function

    weightOverPdf = 1.0f;
}

// ----------------------------------------------------------------------------
// weightOverPdf return the weight (without the Fresnel term) over pdf. Fresnel term must be apply by the caller.
void ImportanceSampleGGX(
    float2 u,
    float3 V,
    float3 N,
    float3 tangentX,
    float3 tangentY,
    float roughness,
    float NdotV,
    out float3 L,
    out float VdotH,
    out float NdotL,
    out float weightOverPdf)
{
    float3 H;
    ImportanceSampleGGXDir(u, V, N, tangentX, tangentY, roughness, H, L);

    float NdotH = saturate(dot(N, H));
    // Note: since L and V are symmetric around H, LdotH == VdotH
    VdotH = saturate(dot(V, H));
    NdotL = saturate(dot(N, L));

    // Importance sampling weight for each sample
    // pdf = D(H) * (N.H) / (4 * (L.H))
    // weight = fr * (N.L) with fr = F(H) * G(V, L) * D(H) / (4 * (N.L) * (N.V))
    // weight over pdf is:
    // weightOverPdf = F(H) * G(V, L) * (L.H) / ((N.H) * (N.V))
    // weightOverPdf = F(H) * 4 * (N.L) * V(V, L) * (L.H) / (N.H) with V(V, L) = G(V, L) / (4 * (N.L) * (N.V))
    // F is apply outside the function

    float Vis = SmithJointGGXVisibilityTerm(NdotL, NdotV, roughness);
    weightOverPdf = 4.0f * Vis * NdotL * VdotH / NdotH;
}

//-----------------------------------------------------------------------------
// Reference
// ----------------------------------------------------------------------------

// Ref: Moving Frostbite to PBR (Appendix A)
void IntegrateLambertDiffuseIBLRef( out float3 diffuseLighting,
                                    UNITY_ARGS_TEXCUBE(tex),
                                    float4 texHdrParam, // Multiplier to apply on hdr texture (in case of rgbm)
                                    float3 N,
                                    float3 diffuseAlbedo,
                                    uint sampleCount = 2048)
{
    float3 acc      = float3(0.0f, 0.0f, 0.0f);
    // Add some jittering on Hammersley2d
    float2 randNum  = InitRandom(N.xy * 0.5f + 0.5f);

    float3 tangentX, tangentY;
    GetLocalFrame(N, tangentX, tangentY);

    for (uint i = 0; i < sampleCount; ++i)
    {
        float2 u    = Hammersley2d(i, sampleCount);
        u           = frac(u + randNum + 0.5f);

        float3 L;
        float NdotL;
        float weightOverPdf;
        ImportanceSampleLambert(u, N, tangentX, tangentY, L, NdotL, weightOverPdf);

        if (NdotL > 0.0f)
        {
            float4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, L, 0).rgba;
            float3 val = DecodeHDR(rgbm, texHdrParam);

            // diffuse Albedo is apply here as describe in ImportanceSampleLambert function
            acc += diffuseAlbedo * weightOverPdf * val;
        }
    }

    diffuseLighting = acc / sampleCount;
}

// ----------------------------------------------------------------------------

void IntegrateDisneyDiffuseIBLRef(  out float3 diffuseLighting,
                                    UNITY_ARGS_TEXCUBE(tex),
                                    float4 texHdrParam, // Multiplier to apply on hdr texture (in case of rgbm)
                                    float3 N,
                                    float3 V,
                                    float roughness,
                                    float3 diffuseAlbedo,
                                    uint sampleCount = 2048)
{
    float NdotV = dot(N, V);
    float3 acc  = float3(0.0f, 0.0f, 0.0f);
    // Add some jittering on Hammersley2d
    float2 randNum  = InitRandom(N.xy * 0.5f + 0.5f);

    float3 tangentX, tangentY;
    GetLocalFrame(N, tangentX, tangentY);

    for (uint i = 0; i < sampleCount; ++i)
    {
        float2 u    = Hammersley2d(i, sampleCount);
        u           = frac(u + randNum + 0.5f);

        float3 L;
        float NdotL;
        float weightOverPdf;
        // for Disney we still use a Cosine importance sampling, true Disney importance sampling imply a look up table
        ImportanceSampleLambert(u, N, tangentX, tangentY, L, NdotL, weightOverPdf);

        if (NdotL > 0.0f)
        {
            float4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, L, 0).rgba;
            float3 val = DecodeHDR(rgbm, texHdrParam);

            float3 H = normalize(L + V);
            float LdotH = dot(L, H);
            // Note: we call DisneyDiffuse that require to multiply by Albedo / PI. Divide by PI is already taken into account
            // in weightOverPdf of ImportanceSampleLambert call.
            float disneyDiffuse = DisneyDiffuse(NdotV, NdotL, LdotH, RoughnessToPerceptualRoughness(roughness));

            // diffuse Albedo is apply here as describe in ImportanceSampleLambert function
            acc += diffuseAlbedo * disneyDiffuse * weightOverPdf * val;
        }
    }

    diffuseLighting = acc / sampleCount;
}

// ----------------------------------------------------------------------------
// Ref: Moving Frostbite to PBR (Appendix A)
void IntegrateSpecularGGXIBLRef(out float3 specularLighting,
                                UNITY_ARGS_TEXCUBE(tex),
                                float4 texHdrParam, // Multiplier to apply on hdr texture (in case of rgbm)
                                float3 N,
                                float3 V,
                                float roughness,
                                float3 f0,
                                float f90,
                                uint sampleCount = 2048)
{
    float NdotV     = saturate(dot(N, V));
    float3 acc      = float3(0.0f, 0.0f, 0.0f);
    // Add some jittering on Hammersley2d
    float2 randNum  = InitRandom(V.xy * 0.5f + 0.5f);

    float3 tangentX, tangentY;
    GetLocalFrame(N, tangentX, tangentY);

    for (uint i = 0; i < sampleCount; ++i)
    {
        float2 u    = Hammersley2d(i, sampleCount);
        u           = frac(u + randNum + 0.5f);

        float VdotH;
        float NdotL;
        float3 L;
        float weightOverPdf;

        // GGX BRDF
        ImportanceSampleGGX(u, V, N, tangentX, tangentY, roughness, NdotV,
                            L, VdotH, NdotL, weightOverPdf);

        if (NdotL > 0.0f)
        {
            // Fresnel component is apply here as describe in ImportanceSampleGGX function
            float3 FweightOverPdf = FresnelLerp(f0, f90, VdotH) * weightOverPdf;

            float4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, L, 0).rgba;
            float3 val = DecodeHDR(rgbm, texHdrParam);

            acc += FweightOverPdf * val;
        }
    }

    specularLighting = acc / sampleCount;
}

// ----------------------------------------------------------------------------
// Pre-integration
// ----------------------------------------------------------------------------

// Ref: Listing 18 in "Moving Frostbite to PBR" + https://knarkowicz.wordpress.com/2014/12/27/analytical-dfg-term-for-ibl/
float4 IntegrateDFG(float3 V, float3 N, float roughness, uint sampleCount)
{
    float NdotV     = saturate(dot(N, V));
    float4 acc      = float4(0.0f, 0.0f, 0.0f, 0.0f);
    // Add some jittering on Hammersley2d
    float2 randNum  = InitRandom(V.xy * 0.5f + 0.5f);

    float3 tangentX, tangentY;
    GetLocalFrame(N, tangentX, tangentY);

    for (uint i = 0; i < sampleCount; ++i)
    {
        float2 u    = Hammersley2d(i, sampleCount);
        u           = frac(u + randNum + 0.5f);

        float VdotH;
        float NdotL;
        float weightOverPdf;

        float3 L; // Unused
        ImportanceSampleGGX(u, V, N, tangentX, tangentY, roughness, NdotV,
                            L, VdotH, NdotL, weightOverPdf);

        if (NdotL > 0.0f)
        {
            // Integral is
            //   1 / NumSample * \int[  L * fr * (N.L) / pdf ]  with pdf =  D(H) * (N.H) / (4 * (L.H)) and fr = F(H) * G(V, L) * D(H) / (4 * (N.L) * (N.V))
            // This is split  in two part:
            //   A) \int[ L * (N.L) ]
            //   B) \int[ F(H) * 4 * (N.L) * V(V, L) * (L.H) / (N.H) ] with V(V, L) = G(V, L) / (4 * (N.L) * (N.V))
            //      = \int[ F(H) * weightOverPdf ]

            // Recombine at runtime with: ( f0 * weightOverPdf * (1 - Fc) + f90 * weightOverPdf * Fc ) with Fc =(1 - V.H)^5
            float Fc            = pow(1.0f - VdotH, 5.0f);
            acc.x               += (1.0f - Fc) * weightOverPdf;
            acc.y               += Fc * weightOverPdf;
        }

        // for Disney we still use a Cosine importance sampling, true Disney importance sampling imply a look up table
        ImportanceSampleLambert(u, N, tangentX, tangentY, L, NdotL, weightOverPdf);

        if (NdotL > 0.0f)
        {
            float3 H = normalize(L + V);
            float LdotH = dot(L, H);
            float disneyDiffuse = DisneyDiffuse(NdotV, NdotL, LdotH, RoughnessToPerceptualRoughness(roughness));

            acc.z += disneyDiffuse * weightOverPdf;
        }
    }

    return acc / sampleCount;
}

// ----------------------------------------------------------------------------
// Ref: Listing 19 in "Moving Frostbite to PBR"
// IntegrateLD will not work with RGBM cubemap. For now it is use with fp16 cubemap such as those use for real time cubemap.
float3 IntegrateLD( samplerCUBE tex,
                    float3 V,
                    float3 N,
                    float roughness,
                    float mipmapcount,  //src cubemap mipmapcount
                    float invOmegaP,
                    uint sampleCount,
                    bool prefilter = true) // static bool
{
    float3 acc          = float3(0.0f, 0.0f, 0.0f);
    float  accWeight    = 0;

    for (uint i = 0; i < sampleCount; ++i)
    {
        float2 Xi = Hammersley2d( i, sampleCount );
        float3 H = ImportanceSampleGGX( Xi, roughness, N );
        float3 L = 2 * dot( V, H ) * H - V;

        float NdotL = saturate(dot(N,L));

        float mipLevel;

        if (!prefilter) // BRDF importance sampling
        {
            mipLevel = 0.0f;
        }
        else // Prefiltered BRDF importance sampling
        {
            float NdotH = saturate(dot(N, H));
            // Note: since L and V are symmetric around H, LdotH == VdotH
            float LdotH = saturate(dot(L, H));

            // Use pre - filtered importance sampling (i.e use lower mipmap
            // level for fetching sample with low probability in order
            // to reduce the variance ).
            // ( Reference : GPU Gem3: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch20.html)
            //
            // Since we pre - integrate the result for normal direction ,
            // N == V and then NdotH == LdotH . This is why the BRDF pdf
            // can be simplifed from :
            // pdf = D * NdotH /(4* LdotH ) to pdf = D / 4;
            //
            // - OmegaS : Solid angle associated to a sample
            // - OmegaP : Solid angle associated to a pixel of the cubemap

            float pdf       = GGXTerm(NdotH, roughness) * NdotH / (4 * LdotH);
            float omegaS    = 1.0f / (sampleCount * pdf);                           // Solid angle associated to a sample
            // invOmegaP is precomputed on CPU and provide as a parameter of the function
            // float omegaP = UNITY_FOUR_PI / (6.0f * cubemapWidth * cubemapWidth); // Solid angle associated to a pixel of the cubemap
            // Clamp is not necessary as the hardware will do it.
            // mipLevel     = clamp(0.5f * log2(omegaS * invOmegaP), 0, mipmapcount);
            mipLevel        = 0.5f * log2(omegaS * invOmegaP); // Clamp is not necessary as the hardware will do it.
        }

        if (NdotL > 0.0f)
        {
            // No rgbm format here, only fp16
            #if UNITY_COLORSPACE_GAMMA
                float3 val = GammaToLinearSpace(texCUBElod(tex, float4(L, mipLevel)).rgb);
            #else
                float3 val = texCUBElod(tex, float4(L, mipLevel)).rgb;
            #endif

            // See p63 equation (53) of moving Frostbite to PBR v2 for the extra NdotL here (both in weight and value)
            acc             += val * NdotL;
            accWeight       += NdotL;
        }
    }

    #if UNITY_COLORSPACE_GAMMA
        return LinearToGammaSpace(acc * (1.0f / accWeight));
    #else
        return acc * (1.0f / accWeight);
    #endif
}

#endif // UNITY_IMAGE_BASED_LIGHTING_INCLUDED
