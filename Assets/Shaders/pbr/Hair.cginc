#ifndef _HAIR_
#define _HAIR_

#include "UnityCG.cginc"		//常用函数，宏，结构体
#include "Lighting.cginc"		//光源相关变量
#include "AutoLight.cginc"		//光照，阴影相关宏，函数

#include "BRDF.cginc"
#include "CommenVertex.cginc"
#include "CommenSurface.cginc"
#include "CommenEnviroment.cginc"

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _TangentShiftTex;
float4 _ShiftTangentTex_ST;

half4 _SpecularCol1;
half _SpecularPower1;
half _SpecularIntensity1;
half _SpecularShiftScale1;
half _SpecularShiftMove1;

half4 _SpecularCol2;
half _SpecularPower2;
half _SpecularIntensity2;
half _SpecularShiftScale2;
half _SpecularShiftMove2;

//no enviroment Specular
float _EnviromentSmoothness;
float _EnviromentIntensity;

half _AlphaRef;

half3 ShiftTangent(half3 T, half3 N, half shift)
{
	half3 shiftT =  T + N * shift;
	return normalize(shiftT);
}

fixed4 Hairfrag(v2f i, half vFace : VFACE) : SV_Target
{
	// sample the texture
	float3 color = 0;

	half4 value = tex2D(_MainTex, i.uv);
	half3 baseColor = value.rgb;
	half alpha = value.a;
	half3 normal = UnpackNormal( tex2D(_NormalTex, i.uv));
	half shift = tex2D(_TangentShiftTex, i.uv).r;
	half occlusion = 1;
	half roughness = 1 - _EnviromentSmoothness;

#ifdef ALPHATEST
	clip(alpha - _AlphaRef);
#endif

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, normal, vFace);

	//shadow
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	surfaceOtherData.lightCol *= atten * UNITY_PI;

	//surface data
	float LDotN = saturate(dot(surfaceOtherData.lightDir, surfaceOtherData.normal));
	float VDotN = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.normal));
	float VDotH = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.halfDir));
	float NDotH = saturate(dot(surfaceOtherData.normal, surfaceOtherData.halfDir));

	half texShift1 = _SpecularShiftScale1 * (shift - 0.5) + _SpecularShiftMove1;
	half3 T1 = ShiftTangent(surfaceOtherData.binormal, surfaceOtherData.normal, texShift1);
	half TDotH1 = dot(T1, surfaceOtherData.halfDir);
	half texShift2 = _SpecularShiftScale2 * (shift - 0.5) + _SpecularShiftMove2;
	half3 T2 = ShiftTangent(surfaceOtherData.binormal, surfaceOtherData.normal, texShift2);
	half TDotH2 = dot(T2, surfaceOtherData.halfDir);

	//indirect light
	half3 ambient = 0;
	half2 lightmapUV = 0;
#if defined(LIGHTMAP_ON)
	ambient = 0;
	lightmapUV = i.ambientOrLightmapUV;
#else
	ambient = i.ambientOrLightmapUV.rgb;
	lightmapUV = 0;
#endif

#if UNITY_SHOULD_SAMPLE_SH
	ambient = ShadeSHPerPixel(surfaceOtherData.normal, ambient, i.worldPos);
#ifdef UNITY_COLORSPACE_GAMMA
	ambient = GammaToLinearSpace(ambient);
#endif
#endif

#if defined(LIGHTMAP_ON)
	// Baked lightmaps
	half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapUV.xy);
	half3 bakedColor = DecodeLightmap(bakedColorTex);
#ifdef UNITY_COLORSPACE_GAMMA
	ambient += GammaToLinearSpace(bakedColor);
#else
	ambient += bakedColor;
#endif
#endif
	color += ambient * baseColor * occlusion * _EnviromentIntensity;

	//diffuse data
	float3 diffuseBRDF = DesineyDiffuseBRDF(baseColor, roughness, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*diffuseBRDF;

	//Specular data
	float3 SpecularBRDF = HairSpecularBRDF(TDotH1, _SpecularCol1, _SpecularPower1, _SpecularIntensity1,
		TDotH2, _SpecularCol2, _SpecularPower2, _SpecularIntensity2);
	color += LDotN * surfaceOtherData.lightCol*SpecularBRDF;

	#ifdef UNITY_COLORSPACE_GAMMA
	color = LinearToGammaSpace(color);
	#endif
	return fixed4(color, alpha);
}

#endif