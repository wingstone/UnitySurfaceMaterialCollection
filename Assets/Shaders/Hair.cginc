#ifndef _HAIR_
#define _HAIR_

#include "UnityCG.cginc"		//常用函数，宏，结构体
#include "Lighting.cginc"		//光源相关变量
#include "AutoLight.cginc"		//光照，阴影相关宏，函数

#include "BRDF.cginc"
#include "CommenVertex.cginc"

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _TangentShiftTex;
float4 _ShiftTangentTex_ST;
sampler2D _NormalTex;
float4 _NormalTex_ST;

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

struct SurfaceOtherData
{
	fixed3 lightCol;
	float3 lightDir;
	float3 normal;
	float3 tangent;
	float3 binormal;
	float3 viewDir;
	float3 reflectDir;
	float3 halfDir;
};


SurfaceOtherData GetSurfaceOtherData(v2f i, float3 texNormal)
{
	SurfaceOtherData o;
#ifdef UNITY_COLORSPACE_GAMMA
	o.lightCol = GammaToLinearSpace(_LightColor0.rgb);
#else
	o.lightCol = _LightColor0.rgb;
#endif
	o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
	o.normal = normalize(texNormal.x*i.tangent + texNormal.y*i.binormal + texNormal.z*i.normal);
	o.tangent = normalize(i.tangent);
	o.binormal = normalize(cross(o.normal, o.tangent));
	o.tangent = cross(o.binormal, o.normal);
	o.viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	o.reflectDir = reflect(-o.viewDir, o.normal);
	o.halfDir = normalize(o.viewDir + o.lightDir);
	return o;
}

half3 GetIBLColor( half roughness, half occlusion, SurfaceOtherData surfaceOtherData)
{
	half3 IBLColor;
#ifdef _GLOSSYREFLECTIONS_OFF
	IBLColor = unity_IndirectSpecColor.rgb;

#else
	half mip = roughness * (1.7 - 0.7*roughness)*UNITY_SPECCUBE_LOD_STEPS;
	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, surfaceOtherData.reflectDir, mip);
	IBLColor = DecodeHDR(rgbm, unity_SpecCube0_HDR)*occlusion;
#endif

#ifdef UNITY_COLORSPACE_GAMMA
	return GammaToLinearSpace(IBLColor);
#else
	return IBLColor*occlusion;
#endif
}

half3 GetEnviromentColor(half3 normal)
{
	half3 col = SHEvalLinearL0L1(half4(normal, 1));
	col += SHEvalLinearL2(half4(normal, 1));
#ifdef UNITY_COLORSPACE_GAMMA
	return GammaToLinearSpace(col);
#else
	return col;
#endif
}

half3 ShiftTangent(half3 T, half3 N, half shift)
{
	half3 shiftT =  T + N * shift;
	return normalize(shiftT);
}

fixed4 Hairfrag(v2f i) : SV_Target
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
	//clip(alpha - _AlphaRef);
#endif

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, normal);

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
	color += GetEnviromentColor(surfaceOtherData.normal)* baseColor* occlusion;

	//diffuse data
	float3 diffuseBRDF = DesineyDiffuseBRDF(baseColor, roughness, VDotH, LDotN, VDotN);
	//color += LDotN * surfaceOtherData.lightCol*diffuseBRDF;

	//Specular data
	float3 SpecularBRDF = HairSpecularBRDF(TDotH1, _SpecularCol1, _SpecularPower1, _SpecularIntensity1,
		TDotH2, _SpecularCol2, _SpecularPower2, _SpecularIntensity2);
	//color += LDotN * surfaceOtherData.lightCol*SpecularBRDF;

	#ifdef UNITY_COLORSPACE_GAMMA
	color = LinearToGammaSpace(color);
	#endif
	return fixed4(color, alpha);
}

#endif