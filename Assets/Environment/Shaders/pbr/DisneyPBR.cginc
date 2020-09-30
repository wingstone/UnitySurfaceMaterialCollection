#ifndef _COMMENPBR_
#define _COMMENPBR_

#include "UnityCG.cginc"		//常用函数，宏，结构体
#include "Lighting.cginc"		//光源相关变量
#include "AutoLight.cginc"		//光照，阴影相关宏，函数

#include "BRDF.cginc"
#include "CommenVertex.cginc"
#include "CommenSurface.cginc"
#include "CommenEnviroment.cginc"

float _SpecularFactor;
float _EnviromentIntensity;
float _EnviromentSpecularIntensity;

fixed4 Disneyfrag(v2f i, half vFace : FACE) : SV_Target
{
	// sample the texture
	float3 color = 0;
	SurfaceTexData surfaceTexData = GetSurfaceTexData(i.uv);

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, surfaceTexData.texNormal,
#ifdef USE_CLEARCOAT
		surfaceTexData.texNormal2,
#endif
	vFace);

	//shadow light
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	surfaceOtherData.lightCol *= UNITY_PI;

	//surface data
	float LDotN = saturate(dot(surfaceOtherData.lightDir, surfaceOtherData.normal));
	float VDotN = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.normal));
	float VDotH = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.halfDir));
	float NDotH = saturate(dot(surfaceOtherData.normal, surfaceOtherData.halfDir));


	//indirect light
	half3 ambient = GetAmbientColor(surfaceOtherData.normal,
		i.worldPos, i.ambientOrLightmapUV, atten, surfaceOtherData.lightCol);
	color += ambient * surfaceTexData.diffColor * surfaceTexData.occlusion * _EnviromentIntensity;

	//shadow light
	surfaceOtherData.lightCol *= atten;

	//diffuse data
	float3 diffuseBRDF = DesineyDiffuseBRDF(surfaceTexData.diffColor, surfaceTexData.roughness, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*diffuseBRDF;

	//Specular data
	float3 SpecularBRDF = DesineySpecularBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, NDotH, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*SpecularBRDF*_SpecularFactor;

	//clearcoat
#ifdef USE_CLEARCOAT
	float3 SpecularBRDF2 = DesineySpecularBRDF(surfaceTexData.specularColor, 1 - surfaceTexData.clearCoatGlossness, NDotH, VDotH, LDotN, VDotN);
	color += 0.25 * LDotN * surfaceOtherData.lightCol*SpecularBRDF2*surfaceTexData.clearCoat;
#endif

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