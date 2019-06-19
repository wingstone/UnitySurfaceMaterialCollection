#include "UnityCG.cginc"		//常用函数，宏，结构体
#include "Lighting.cginc"		//光源相关变量
#include "AutoLight.cginc"		//光照，阴影相关宏，函数

#include "BRDF.cginc"

struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	float2 uv : TEXCOORD0;
	float3 worldPos : TEXCOORD1;

	UNITY_LIGHTING_COORDS(2, 3)

	float3 tangent : TEXCOORD4;
	float3 binormal : TEXCOORD5;
	float3 normal : TEXCOORD6;

	float4 pos : SV_POSITION;		//shadow宏要求此处必须为pos变量，shit。。。
};

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

float3 _FuzzColor;
float _Cloth;

float _AlphaX;
float _AlphaY;


v2f vert(appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);

	o.normal = UnityObjectToWorldNormal(v.normal);
	o.tangent = UnityObjectToWorldDir(v.tangent.xyz);

	half3x3 tangentToWorld = CreateTangentToWorldPerVertex(o.normal, o.tangent, v.tangent.w);
	o.tangent = tangentToWorld[0];
	o.binormal = tangentToWorld[1];
	o.normal = tangentToWorld[2];


	UNITY_TRANSFER_LIGHTING(o, v.uv);
	return o;
}

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
	return IBLColor*surfaceTexData.occlusion;
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

fixed4 Unrealfrag(v2f i) : SV_Target
{
	// sample the texture
	float3 color = 0;
	SurfaceTexData surfaceTexData = GetSurfaceTexData(i.uv);

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, surfaceTexData.texNormal);

	//shadow
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	surfaceOtherData.lightCol *= atten * UNITY_PI;

	//surface data
	float LDotN = saturate(dot(surfaceOtherData.lightDir, surfaceOtherData.normal));
	float VDotN = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.normal));
	float VDotH = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.halfDir));
	float NDotH = saturate(dot(surfaceOtherData.normal, surfaceOtherData.halfDir));


	//indirect light
	color += GetEnviromentColor(surfaceOtherData.normal)* surfaceTexData.baseColor* surfaceTexData.occlusion;

	//diffuse data
	float3 diffuseBRDF = UnrealDiffuseBRDF(surfaceTexData.baseColor);
	color += LDotN * surfaceOtherData.lightCol*diffuseBRDF;

	//Specular data
	float3 SpecularBRDF = UnrealSpecularBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, NDotH, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*SpecularBRDF;

	//IBL reflection
	half3 IBLColor = GetIBLColor(surfaceTexData, surfaceOtherData);
#ifdef ENABLE_PREINTEGRATED
	float3 enviromentBRDF = UnrealEnviromentBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, VDotN);
#else
	float3 enviromentBRDF = UnrealEnviromentBRDFApprox(surfaceTexData.specularColor, surfaceTexData.roughness, VDotN);
#endif
	color += IBLColor * enviromentBRDF* _EnviromentIntensity;

	color += surfaceTexData.emission;

	#ifdef UNITY_COLORSPACE_GAMMA
	color = LinearToGammaSpace(color);
	#endif
	return fixed4(color, 1);
}

fixed4 UnrealClothfrag(v2f i) : SV_Target
{
	// sample the texture
	float3 color = 0;
	SurfaceTexData surfaceTexData = GetSurfaceTexData(i.uv);

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, surfaceTexData.texNormal);

	//shadow
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	surfaceOtherData.lightCol *= atten * UNITY_PI;

	//surface data
	float LDotN = saturate(dot(surfaceOtherData.lightDir, surfaceOtherData.normal));
	float VDotN = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.normal));
	float VDotH = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.halfDir));
	float NDotH = saturate(dot(surfaceOtherData.normal, surfaceOtherData.halfDir));


	//indirect light
	color += GetEnviromentColor(surfaceOtherData.normal)* surfaceTexData.baseColor* surfaceTexData.occlusion;

	//diffuse data
	float3 diffuseBRDF = UnrealDiffuseBRDF(surfaceTexData.baseColor);
	color += LDotN * surfaceOtherData.lightCol*diffuseBRDF;

	//Specular data
	float3 SpecularBRDF = UnrealClothSpecularBRDF(_FuzzColor, _Cloth, surfaceTexData.specularColor, surfaceTexData.roughness, NDotH, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*SpecularBRDF;

	//IBL reflection
	half3 IBLColor = GetIBLColor(surfaceTexData, surfaceOtherData);
#ifdef ENABLE_PREINTEGRATED
	float3 enviromentBRDF = UnrealEnviromentBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, VDotN);
#else
	float3 enviromentBRDF = UnrealEnviromentBRDFApprox(surfaceTexData.specularColor, surfaceTexData.roughness, VDotN);
#endif
	color += IBLColor * enviromentBRDF* _EnviromentIntensity;

	color += surfaceTexData.emission;

	#ifdef UNITY_COLORSPACE_GAMMA
	color = LinearToGammaSpace(color);
	#endif
	return fixed4(color, 1);
}

fixed4 Optimizedfrag(v2f i) : SV_Target
{
	// sample the texture
	float3 color = 0;
	SurfaceTexData surfaceTexData = GetSurfaceTexData(i.uv);

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, surfaceTexData.texNormal);

	//shadow
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	surfaceOtherData.lightCol *= atten * UNITY_PI;

	//surface data
	float LDotN = saturate(dot(surfaceOtherData.lightDir, surfaceOtherData.normal));
	float VDotN = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.normal));
	float VDotH = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.halfDir));
	float NDotH = saturate(dot(surfaceOtherData.normal, surfaceOtherData.halfDir));


	//indirect light
	color += GetEnviromentColor(surfaceOtherData.normal)* surfaceTexData.baseColor* surfaceTexData.occlusion;

	//diffuse data
	float3 diffuseBRDF = DesineyDiffuseBRDF(surfaceTexData.baseColor, surfaceTexData.roughness, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*diffuseBRDF;

	//Specular data
	float3 SpecularBRDF = OptimizedSpecularBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, NDotH, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*SpecularBRDF;

	//IBL reflection
	half3 IBLColor = GetIBLColor(surfaceTexData, surfaceOtherData);
	float3 enviromentBRDF = OptimizedEnviromentBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, VDotN);
	color += IBLColor * enviromentBRDF* _EnviromentIntensity;

	color += surfaceTexData.emission;

	#ifdef UNITY_COLORSPACE_GAMMA
	color = LinearToGammaSpace(color);
	#endif
	return fixed4(color, 1);
}

fixed4 Unityfrag(v2f i) : SV_Target
{
	
	float3 color = 0;

	// sample the texture
	SurfaceTexData surfaceTexData;
	surfaceTexData.baseColor = tex2D(_MainTex, i.uv);
	surfaceTexData.specularColor = tex2D(_SpecularTex, i.uv);
	surfaceTexData.texNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
	surfaceTexData.occlusion = tex2D(_OcclusionTex, i.uv).r;
	surfaceTexData.emission = tex2D(_EmissionTex, i.uv);
	float glossness = _SmoothnessScale;
#ifdef ENABLE_SPECULAR_GLOSSNESS
	glossness *= tex2D(_SpecularTex, i.uv).a;
#endif
	surfaceTexData.roughness = 1 - glossness;

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, surfaceTexData.texNormal);
	surfaceOtherData.lightCol = _LightColor0.rgb;

	//shadow
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	surfaceOtherData.lightCol *= atten;

	//surface data
	float LDotN = saturate(dot(surfaceOtherData.lightDir, surfaceOtherData.normal));
	float VDotN = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.normal));
	float VDotH = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.halfDir));
	float NDotH = saturate(dot(surfaceOtherData.normal, surfaceOtherData.halfDir));


	//indirect light
	color += ShadeSH9(half4(surfaceOtherData.normal, 1))* surfaceTexData.baseColor* surfaceTexData.occlusion;

	//diffuse data
	float3 diffuseBRDF = UnityDiffuseBRDF(surfaceTexData.baseColor, surfaceTexData.roughness, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*diffuseBRDF;

	//Specular data
	float3 SpecularBRDF = UnitySpecularBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, NDotH, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*SpecularBRDF;

	//IBL reflection
	half3 IBLColor;
#ifdef _GLOSSYREFLECTIONS_OFF
	IBLColor = unity_IndirectSpecColor.rgb;
#else
	half mip = surfaceTexData.roughness * (1.7 - 0.7*surfaceTexData.roughness)*UNITY_SPECCUBE_LOD_STEPS;
	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, surfaceOtherData.reflectDir, mip);
	IBLColor = DecodeHDR(rgbm, unity_SpecCube0_HDR)*surfaceTexData.occlusion;
#endif
	float3 enviromentBRDF = UnityEnviromentBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, VDotN);
	color += IBLColor * enviromentBRDF* _EnviromentIntensity* surfaceTexData.occlusion;

	color += surfaceTexData.emission;
	return fixed4(color, 1);
}

fixed4 Anisotropicfrag(v2f i) : SV_Target
{

	float3 color = 0;
	SurfaceTexData surfaceTexData = GetSurfaceTexData(i.uv);

	SurfaceOtherData surfaceOtherData = GetSurfaceOtherData(i, surfaceTexData.texNormal);

	//shadow
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
	surfaceOtherData.lightCol *= atten * UNITY_PI;

	//surface data
	float LDotN = saturate(dot(surfaceOtherData.lightDir, surfaceOtherData.normal));
	float VDotN = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.normal));
	float VDotH = saturate(dot(surfaceOtherData.viewDir, surfaceOtherData.halfDir));
	float NDotH = saturate(dot(surfaceOtherData.normal, surfaceOtherData.halfDir));


	//indirect light
	color += GetEnviromentColor(surfaceOtherData.normal)* surfaceTexData.baseColor* surfaceTexData.occlusion;

	//diffuse data
	float3 diffuseBRDF = DesineyDiffuseBRDF(surfaceTexData.baseColor, surfaceTexData.roughness, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*diffuseBRDF;

	float dotHTAlphaX =
		dot(surfaceOtherData.halfDir, surfaceOtherData.tangent) / _AlphaX;
	float dotHBAlphaY =
		dot(surfaceOtherData.halfDir, surfaceOtherData.binormal) / _AlphaY;

	//Specular data
	float3 SpecularBRDF = WardBRDF(surfaceTexData.specularColor, dotHTAlphaX, dotHBAlphaY, NDotH, VDotH, LDotN, VDotN);
	color += LDotN * surfaceOtherData.lightCol*SpecularBRDF;

	//IBL reflection
	half3 IBLColor = GetIBLColor(surfaceTexData, surfaceOtherData);
	float3 enviromentBRDF = OptimizedEnviromentBRDF(surfaceTexData.specularColor, surfaceTexData.roughness, VDotN);
	color += IBLColor * enviromentBRDF* _EnviromentIntensity;

	color += surfaceTexData.emission;

	#ifdef UNITY_COLORSPACE_GAMMA
	color = LinearToGammaSpace(color);
	#endif
	return fixed4(color, 1);
}