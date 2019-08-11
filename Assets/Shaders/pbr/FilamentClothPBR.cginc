#ifndef _COMMENPBR_
#define _COMMENPBR_

#include "UnityCG.cginc"		//常用函数，宏，结构体
#include "Lighting.cginc"		//光源相关变量
#include "AutoLight.cginc"		//光照，阴影相关宏，函数

#include "BRDF.cginc"
#include "CommenVertex.cginc"
#include "CommenSurface.cginc"
#include "CommenEnviroment.cginc"

float4 _SheenColor;
float4 _SubsurfaceColor;

float _SpecularFactor;
float _EnviromentIntensity;
float _EnviromentSpecularIntensity;

float _Cloth;

fixed4 FilamentClothfrag(v2f i, half vFace : FACE) : SV_Target
{
	// sample the texture
	float3 color = 0;
	SurfaceTexData surfaceTexData = GetSurfaceTexData(i.uv);

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, surfaceTexData.texNormal, vFace);

	//shadow
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	surfaceOtherData.lightCol *= atten * UNITY_PI;

	//surface data
	float oldLDotN = dot(surfaceOtherData.lightDir, surfaceOtherData.normal);
	float LDotN = saturate(oldLDotN);
	float VDotN = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.normal));
	float VDotH = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.halfDir));
	float NDotH = saturate(dot(surfaceOtherData.normal, surfaceOtherData.halfDir));


	//indirect light
#if UNITY_SHOULD_SAMPLE_SH
	color += ShadeSHPerPixel(surfaceOtherData.normal, i.vLight, i.worldPos)* surfaceTexData.diffColor* surfaceTexData.occlusion * _EnviromentIntensity;

#ifdef UNITY_COLORSPACE_GAMMA
	color = GammaToLinearSpace(color);
#endif

#endif

	//diffuse data
	float3 diffuseBRDF = FilamentDiffuseBRDF(surfaceTexData.diffColor, surfaceTexData.roughness, VDotH, oldLDotN, VDotN);
	float3 wrapLDotN = _SubsurfaceColor + LDotN;
	color += wrapLDotN * surfaceOtherData.lightCol*diffuseBRDF;

	//Specular data
	float3 SpecularBRDF = FilamentSpecularBRDF(_SheenColor, _SubsurfaceColor, _Cloth, surfaceTexData.specularColor, surfaceTexData.roughness, NDotH, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*SpecularBRDF*_SpecularFactor;

	//IBL reflection
	half3 IBLColor = GetIBLColor(surfaceTexData, surfaceOtherData);
	float3 enviromentBRDF = UnityEnviromentBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, VDotN);
	color += IBLColor * enviromentBRDF* _EnviromentSpecularIntensity;

	color += surfaceTexData.emission;

	#ifdef UNITY_COLORSPACE_GAMMA
	color = LinearToGammaSpace(color);
	#endif
	return fixed4(color, 1);
}

#endif