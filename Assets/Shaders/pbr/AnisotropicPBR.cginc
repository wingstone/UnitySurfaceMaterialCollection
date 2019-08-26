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

float _AlphaX;
float _AlphaY;

fixed4 Anisotropicfrag(v2f i, half vFace : FACE) : SV_Target
{

	float3 color = 0;
	SurfaceTexData surfaceTexData = GetSurfaceTexData(i.uv);

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, surfaceTexData.texNormal, vFace);

	//shadow
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	surfaceOtherData.lightCol *= atten * UNITY_PI;

	//surface data
	float LDotN = saturate(dot(surfaceOtherData.lightDir, surfaceOtherData.normal));
	float VDotN = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.normal));
	float VDotH = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.halfDir));
	float NDotH = saturate(dot(surfaceOtherData.normal, surfaceOtherData.halfDir));

	//indirect light
	half3 ambient = 0;
	half2 lightmapUV = 0;
	ambient = i.ambientOrLightmapUV.rgb;
	lightmapUV = 0;

#if UNITY_SHOULD_SAMPLE_SH
	ambient = ShadeSHPerPixel(surfaceOtherData.normal, ambient, i.worldPos);
#ifdef UNITY_COLORSPACE_GAMMA
	ambient = GammaToLinearSpace(ambient);
#endif
#endif

	color += ambient * surfaceTexData.diffColor * surfaceTexData.occlusion * _EnviromentIntensity;

	//diffuse data
	float3 diffuseBRDF = CommenDiffuseBRDF(surfaceTexData.diffColor);
	color += LDotN * surfaceOtherData.lightCol*diffuseBRDF;

	float dotHTAlphaX =
		dot(surfaceOtherData.halfDir, surfaceOtherData.tangent) / _AlphaX;
	float dotHBAlphaY =
		dot(surfaceOtherData.halfDir, surfaceOtherData.binormal) / _AlphaY;

	//Specular data
	float3 SpecularBRDF = WardSpecularBRDF(surfaceTexData.specularColor, dotHTAlphaX, dotHBAlphaY, NDotH, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*SpecularBRDF;

	//IBL reflection
	half3 IBLColor = GetIBLColor(surfaceTexData, surfaceOtherData);
	float3 enviromentBRDF = CommenEnviromentBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, VDotN);
	color += IBLColor * enviromentBRDF* _EnviromentSpecularIntensity;

	color += surfaceTexData.emission;

	#ifdef UNITY_COLORSPACE_GAMMA
	color = LinearToGammaSpace(color);
	#endif
	return fixed4(color, 1);
}

#endif