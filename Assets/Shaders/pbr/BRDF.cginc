#ifndef _BRDF_
#define _BRDF_
//note: LDotH = VDotH;

#define CommenDiffuseBRDF UnrealDiffuseBRDF
#define CommenSpecularBRDF DesineySpecularBRDF
#define CommenEnviromentBRDF UnityEnviromentBRDF


float Pow4(float t)
{
	return t * t*t*t;
}

float Pow5(float t)
{
	return t * t*t*t*t;
}

//desiney reference:https://disney-animation.s3.amazonaws.com/library/s2012_pbs_disney_brdf_notes_v2.pdf
//desiney diffuse brdf
float3 DesineyDiffuseBRDF(float3 baseColor, float roughness, float LDotH, float LDotN, float VDotN)
{
	float FD90 = 0.5 + 2 * LDotH*LDotH*roughness;
	return (1 + (FD90 - 1)*Pow5(1 - LDotN))*(1 + (FD90 - 1)*Pow5(1 - VDotN))*baseColor*UNITY_INV_PI;
}

//disney Specular BRDF
float3 DesineySpecularBRDF(float3 SpecularColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	//calculate D; desiney use two Specular lobes, here we use one // same to unreal
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float tmp = NDotH * NDotH*(alpha2 - 1) + 1;
	float D = alpha * alpha / max(UNITY_PI*tmp*tmp, 1e-7);

	//calculate F
	float F = SpecularColor + (1 - SpecularColor)*Pow5(1 - VDotH);

	//calculate G
	alpha = (0.5 + roughness * 0.5)*(0.5 + roughness * 0.5);
	alpha2 = alpha * alpha;
	float GV = 2 * VDotN / (VDotN + sqrt(alpha2 + (1 - alpha2)*VDotN*VDotN));
	float GL = 2 * LDotN / (LDotN + sqrt(alpha2 + (1 - alpha2)*LDotN*LDotN));
	float G = GV * GL;

	return D * G / max(4 * LDotN*VDotN, 1e-7)* F;
}

//unity diffuse brdf
float3 UnityDiffuseBRDF(float3 baseColor, float roughness, float LDotH, float LDotN, float VDotN)
{
	float FD90 = 0.5 + 2 * LDotH*LDotH*roughness;
	return (1 + (FD90 - 1)*Pow5(1 - LDotN))*(1 + (FD90 - 1)*Pow5(1 - VDotN))*baseColor*UNITY_INV_PI;
}

float3 UnityEnviromentBRDF(float3 SpecularColor, float roughness, float VDotN)
{
	float surfaceReduction = 1.0 / (Pow4(roughness) + 1.0);
#ifdef UNITY_COLORSPACE_GAMMA
	surfaceReduction = 1.0 - 0.28*roughness*roughness*roughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#else
	surfaceReduction = = 1.0 / (Pow4(roughness) + 1.0);           // fade \in [0.5;1]
#endif
	float oneMinusReflectivity = 1 - SpecularStrength(SpecularColor);
	half grazingTerm = saturate(1 - roughness + (1 - oneMinusReflectivity));
	half t = Pow4(1 - VDotN);
	half3 fresnel = lerp(SpecularColor, grazingTerm, t);

	return surfaceReduction * fresnel;
}

//unreal reference:https://de45xmedrsdbp.cloudfront.net/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
//unreal diffuse brdf
float3 UnrealDiffuseBRDF(float3 baseColor)
{
	return baseColor * UNITY_INV_PI;
}

//unreal Specular brdf
float3 UnrealSpecularBRDF(float3 SpecularColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	//claculate D
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float tmp = NDotH * NDotH*(alpha2 - 1) + 1;
	float D = alpha * alpha / (UNITY_PI*tmp*tmp);

	//calculate F
	tmp = (-5.55473*VDotH - 6.98316)*VDotH;
	float F = SpecularColor + (1 - SpecularColor)*pow(2, tmp);

	//culate G
	float k = (roughness + 1)*(roughness + 1) / 8;
	float GV = 1.0 / (VDotN*(1 - k) + k);
	float GL = 1.0 / (LDotN*(1 - k) + k);
	float G = GV * GL;

	return 0.25 * D * G * F;
}

//unreal cloth brdf
float3 UnrealClothSpecularBRDF(float3 fuzzColor, float cloth, float3 SpecularColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	//claculate D
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float tmp = NDotH * NDotH*(alpha2 - 1) + 1;
	float D = alpha * alpha / max(UNITY_PI*tmp*tmp, 1e-7);

	//calculate F
	tmp = (-5.55473*VDotH - 6.98316)*VDotH;
	float3 F = SpecularColor + (1 - SpecularColor)*pow(2, tmp);

	//culate G
	float k = (roughness + 1)*(roughness + 1) / 8;
	float GV = 1.0 / max(VDotN*(1 - k) + k, 1e-7);
	float GL = 1.0 / max(LDotN*(1 - k) + k, 1e-7);
	float G = GV * GL;

	float3 spec1 =0.25* D * G * F;

	//calculate cloth
	float d = (1 - alpha2)*NDotH*NDotH + alpha2;
	float D2 = rcp(UNITY_PI*(1 + 4 * alpha2))*(1 + 4 * alpha2*alpha2 / max(d*d, 1e-7));
	float Vis2 = rcp(4 * (LDotN + VDotN - LDotN * VDotN) + 0.001);
	float3 Fc = Pow5(1 - VDotH);
	float3 F2 = saturate(50.0*fuzzColor.g)*Fc + (1 - Fc)*fuzzColor;
	float3 spec2 = (D2 * Vis2)* F2;

	return lerp(spec1, spec2, cloth);
}

//unreal enviroment brdf
sampler2D		_PreIntegratedGF;
float4 _PreIntegratedGF_ST;

half3 UnrealEnviromentBRDF(half3 SpecularColor, half Roughness, half VDotN)
{
	// Importance sampled preintegrated G * F
	float2 AB = tex2D(_PreIntegratedGF, float2(VDotN, Roughness)).rg;

	// Anything less than 2% is physically impossible and is instead considered to be shadowing 
	float3 GF = SpecularColor * AB.x + saturate(50.0 * SpecularColor.g) * AB.y;
	return GF;
}

half3 UnrealEnviromentBRDFApprox(half3 SpecularColor, half Roughness, half VDotN)
{
	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	// Adaptation to fit our G term.
	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
	half4 r = Roughness * c0 + c1;
	half a004 = min(r.x * r.x, exp2(-9.28 * VDotN)) * r.x + r.y;
	half2 AB = half2(-1.04, 1.04) * a004 + r.zw;

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	// Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
	AB.y *= saturate(50.0 * SpecularColor.g);

	return SpecularColor * AB.x + AB.y;
}

//Optimizing BRDF for morbile, reference:https://community.arm.com/developer/tools-software/graphics/b/blog/posts/moving-mobile-graphics#siggraph2015
float3 OptimizedSpecularBRDF(float3 SpecularColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	float roughness4 = roughness * roughness*roughness*roughness;
	float tmp = NDotH*NDotH*(roughness4 - 1) + 1;
	return roughness4 / (4 * UNITY_PI*tmp*tmp*VDotH*VDotH*(roughness + 0.5)+0.001)*SpecularColor;
}

float3 OptimizedEnviromentBRDF(float3 SpecularColor, float roughness, float VDotN)
{
	float tmp = 1 - max(roughness, VDotN);
	return tmp * tmp*tmp + SpecularColor;
}

//anisotropic ward brdf
float3 WardSpecularBRDF(float3 SpecularColor, float dotHTAlphaX, float dotHBAlphaY, float NDotH, float VDotH, float LDotN, float VDotN)
{
	return sqrt(max(0.0, 1 / (LDotN * VDotN+0.001)))
		* exp(-2.0 * (dotHTAlphaX * dotHTAlphaX
			+ dotHBAlphaY * dotHBAlphaY) / (1.0 + NDotH));
}

//kajia hair model
half StrandSpecular(half TDotH, half specPower)
{
	half sinTH = sqrt(1 - TDotH* TDotH);
	half dirAtten = smoothstep(-1, 0, TDotH);
	return dirAtten * pow(sinTH, specPower);
}

half3 HairSpecularBRDF(half TDotH1, half3 specCol1, half specPower1, half specFactor1,
	half TDotH2, half3 specCol2, half specPower2, half specFactor2)
{
	half3 BRDF1 = StrandSpecular(TDotH1, specPower1) * specCol1 * specFactor1;
	half3 BRDF2 = StrandSpecular(TDotH2, specPower2) * specCol2 * specFactor2;
	return BRDF1 + BRDF2;
}


//cloth model
//https://google.github.io/filament/Filament.md.html#about
float D_Ashikhmin(float roughness, float NoH) {
	// Ashikhmin 2007, "Distribution-based BRDFs"
	float a = roughness * roughness;
	float a2 = a * a;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	float sin4h = sin2h * sin2h;
	float cot2 = -cos2h / (a2 * sin2h);
	return 1.0 / (UNITY_PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h);
}

float D_Charlie(float roughness, float NoH) {
	// Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
	float a = roughness ;
	float invAlpha = 1.0 / a;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * UNITY_PI);
}

float3 FilamentDiffuseBRDF(float3 baseColor, float roughness, float LDotH, float LDotN, float VDotN)
{
	float FD90 = 0.5 + 2 * LDotH*LDotH*roughness;
	float diffBRDF = (1 + (FD90 - 1)*Pow5(1 - LDotN))*(1 + (FD90 - 1)*Pow5(1 - VDotN))*baseColor*UNITY_INV_PI;
	diffBRDF *= saturate(LDotN + 0.5 / 1.5);
	return diffBRDF;
}


float3 FilamentSpecularBRDF(float3 sheenColor, float3 subsurfaceColor, float cloth, float3 SpecularColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	//claculate D
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float tmp = NDotH * NDotH*(alpha2 - 1) + 1;
	float D = alpha * alpha / max(UNITY_PI*tmp*tmp, 1e-7);

	//calculate F
	tmp = (-5.55473*VDotH - 6.98316)*VDotH;
	float3 F = SpecularColor + (1 - SpecularColor)*pow(2, tmp);

	//culate G
	float k = (roughness + 1)*(roughness + 1) / 8;
	float GV = 1.0 / max(VDotN*(1 - k) + k, 1e-7);
	float GL = 1.0 / max(LDotN*(1 - k) + k, 1e-7);
	float G = GV * GL;

	float3 spec1 = 0.25* D * G * F;

	//calculate cloth
	float D2 = D_Charlie(roughness, NDotH);
	float Vis2 = rcp(4 * (LDotN + VDotN - LDotN * VDotN) + 0.001);
	float3 spec2 = (D2 * Vis2)* sheenColor;

	return lerp(spec1, spec2, cloth);
}

#endif