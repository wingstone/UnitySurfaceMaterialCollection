#ifndef _COMMENSURFACE_
#define _COMMENSURFACE_

struct SurfaceTexData
{
	float3 diffColor;
	float3 specularColor;
	float3 texNormal;
	float3 occlusion;
	float3 emission;
	float roughness;
};

struct SurfaceOtherData
{
	float3 lightCol;
	float3 lightDir;
	float3 normal;
	float3 tangent;
	float3 binormal;
	float3 viewDir;
	float3 reflectDir;
	float3 halfDir;
};

float4 _DiffuseColor;
float4 _SpecularColor;

#if USE_TEX
sampler2D _DiffuseTex;
sampler2D _SpecularTex;
#endif

float _Glossness;
sampler2D _NormalTex;
float4 _NormalTex_ST;
sampler2D _OcclusionTex;
float4 _OcclusionTex_ST;
sampler2D _EmissionTex;
float4 _EmissionTex_ST;


SurfaceTexData GetSurfaceTexData(half2 uv)
{
	SurfaceTexData o;
#ifdef UNITY_COLORSPACE_GAMMA
	o.diffColor = GammaToLinearSpace(_DiffuseColor.rgb);		//属性颜色为gamma空间，不适用HDR标签
	o.specularColor = GammaToLinearSpace(_SpecularColor.rgb);
#else
	o.diffColor = _DiffuseColor.rgb;
	o.specularColor = _SpecularColor.rgb;
#endif

	o.texNormal = UnpackNormal(tex2D(_NormalTex, uv));
	o.occlusion = tex2D(_OcclusionTex, uv).r;
	o.emission = tex2D(_EmissionTex, uv);

	float glossness = _Glossness;
	o.roughness = 1 - glossness;

#if USE_TEX
#ifdef UNITY_COLORSPACE_GAMMA
	o.diffColor = GammaToLinearSpace(tex2D(_DiffuseTex, uv).rgb);		//纹理颜色为gamma空间，使用sRGB
	o.specularColor = GammaToLinearSpace(tex2D(_SpecularTex, uv).rgb);
#else
	o.diffColor = tex2D(_DiffuseTex, uv).rgb;
	o.specularColor = tex2D(_SpecularTex, uv).rgb;
#endif
	o.roughness = 1 - tex2D(_SpecularTex, uv).a;
#endif


	return o;
}

SurfaceOtherData GetSurfaceOtherData(v2f i, float3 texNormal, half vFace)
{
	SurfaceOtherData o;
#ifdef UNITY_COLORSPACE_GAMMA
	o.lightCol = GammaToLinearSpace(_LightColor0.rgb);		//光源颜色为gamma空间
#else
	o.lightCol = _LightColor0.rgb;
#endif
	o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
	o.normal = normalize(texNormal.x*i.tangent + texNormal.y*i.binormal + texNormal.z*i.normal);
	o.normal = lerp(-o.normal, o.normal, step(0, vFace));
	o.tangent = normalize(i.tangent);
	o.binormal = normalize(cross(o.normal, o.tangent));
	o.tangent = cross(o.binormal, o.normal);
	o.viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	o.reflectDir = reflect(-o.viewDir, o.normal);
	o.halfDir = normalize(o.viewDir + o.lightDir);
	return o;
}

#endif