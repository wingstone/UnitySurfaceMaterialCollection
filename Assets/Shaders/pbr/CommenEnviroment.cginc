#ifndef _COMMEN_ENVIROMENT_
#define _COMMEN_ENVIROMENT_

#include "CommenSurface.cginc"

half3 GetAmbientColor(half3 normal,
	half3 wPos, half4 ambientOrLightmapUV, inout half atten, inout half3 lightCol)
{
	//indirect light
	half3 ambient = 0;
	half2 lightmapUV = 0;
#if defined(LIGHTMAP_ON)
	ambient = 0;
	lightmapUV = ambientOrLightmapUV.xy;
#else
	ambient = ambientOrLightmapUV.rgb;
	lightmapUV = 0;
#endif

	// handling ShadowMask / blending here for performance reason
#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
	half bakedAtten = UnitySampleBakedOcclusion(lightmapUV.xy, i.worldPos);
	float zDist = dot(_WorldSpaceCameraPos - i.worldPos, UNITY_MATRIX_V[2].xyz);
	float fadeDist = UnityComputeShadowFadeDistance(i.worldPos, zDist);
	atten = UnityMixRealtimeAndBakedShadows(atten, bakedAtten, UnityComputeShadowFade(fadeDist));
#endif

#if UNITY_SHOULD_SAMPLE_SH
	ambient = ShadeSHPerPixel(normal, ambient, wPos);
#endif

#if defined(LIGHTMAP_ON)
	// Baked lightmaps
	half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapUV.xy);
	half3 bakedColor = DecodeLightmap(bakedColorTex);

#ifdef DIRLIGHTMAP_COMBINED
	fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, lightmapUV.xy);
	ambient += DecodeDirectionalLightmap(bakedColor, bakedDirTex, normalWorld);

#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
	lightCol = 0;
	ambient = SubtractMainLightWithRealtimeAttenuationFromLightmap(ambient, atten, bakedColorTex, surfaceOtherData.normal);
#endif

#else // not directional lightmap
	ambient += bakedColor;
#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
	lightCol = 0;
	ambient = SubtractMainLightWithRealtimeAttenuationFromLightmap(ambient, atten, bakedColorTex, surfaceOtherData.normal);
#endif

#endif

#endif

#ifdef UNITY_COLORSPACE_GAMMA
	ambient = GammaToLinearSpace(ambient);
#endif

	return ambient;
}

half3 GetIBLColor(SurfaceTexData surfaceTexData, SurfaceOtherData surfaceOtherData)
{
	half3 IBLColor;
#ifdef _GLOSSYREFLECTIONS_OFF
	IBLColor = unity_IndirectSpecColor.rgb;

#else
	half mip = surfaceTexData.roughness * (1.7 - 0.7*surfaceTexData.roughness)*UNITY_SPECCUBE_LOD_STEPS;
	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, surfaceOtherData.reflectDir, mip);
	IBLColor = DecodeHDR(rgbm, unity_SpecCube0_HDR)*surfaceTexData.occlusion;
#endif

	//已经验证！获取的IBLColor确实是Gamma空间的！如果使用gamma空间的话
	//注意如果使用自定义的skybox，需要手动标记skybox是否在gamma空间
	//gamma空间的skybox显示的颜色就是，理论正确计算后输出的颜色

	//这就有个问题，如果使用线性空间的box，就必须使用线性空间流程，
	//若使用gamma空间流程就只能改代码不进行下面的转换了，但这样就不能使用gamm空间的box了，所以说最好使用gamma空间的box

#ifdef UNITY_COLORSPACE_GAMMA
	return GammaToLinearSpace(IBLColor)*surfaceTexData.occlusion;
#else
	return IBLColor * surfaceTexData.occlusion;
#endif
}


#endif