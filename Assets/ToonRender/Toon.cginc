#ifndef _TOON_
#define _TOON_

#include "UnityCG.cginc"		//常用函数，宏，结构体
#include "Lighting.cginc"		//光源相关变量
#include "AutoLight.cginc"		//光照，阴影相关宏，函数

#include "ToonVertex.cginc"

struct SurfaceTexData
{
	fixed3 baseColor;
	fixed3 specularColor;
	fixed3 texNormal;
	fixed occlusion;
	fixed3 emission;
	float roughness;
};

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

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _SpecularTex;
float4 _SpecularTex_ST;
sampler2D _NormalTex;
float4 _NormalTex_ST;
sampler2D _OcclusionTex;
float4 _OcclusionTex_ST;
sampler2D _EmissionTex;
float4 _EmissionTex_ST;

float _SmoothnessScale;
float _EnviromentIntensity;
float _EnviromentSpecularIntensity;

float3 _FuzzColor;
float _Cloth;

float _AlphaX;
float _AlphaY;

SurfaceTexData GetSurfaceTexData(half2 uv)
{
	SurfaceTexData o;
#ifdef UNITY_COLORSPACE_GAMMA
	o.baseColor = GammaToLinearSpace(tex2D(_MainTex, uv));
	o.specularColor = GammaToLinearSpace(tex2D(_SpecularTex, uv));
	o.texNormal = UnpackNormal(tex2D(_NormalTex, uv));
	o.occlusion = tex2D(_OcclusionTex, uv).r;
	o.emission = tex2D(_EmissionTex, uv);
#else
	o.baseColor = tex2D(_MainTex, uv);
	o.specularColor = tex2D(_SpecularTex, uv);
	o.texNormal = UnpackNormal(tex2D(_NormalTex, uv));
	o.occlusion = tex2D(_OcclusionTex, uv).r;
	o.emission = tex2D(_EmissionTex, uv);
#endif

	float glossness = _SmoothnessScale;
#ifdef ENABLE_SPECULAR_GLOSSNESS
	glossness *= tex2D(_SpecularTex, uv).a;
#endif

	o.roughness = 1 - glossness;

	return o;
}

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

#ifdef UNITY_COLORSPACE_GAMMA
	return GammaToLinearSpace(IBLColor);
#else
	return IBLColor * surfaceTexData.occlusion;
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

fixed4 frag(v2f i) : SV_Target
{
	return fixed4(1,1,1,1);
}

#endif