//note: LDotH = VDotH;

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
	return (1 + (FD90 - 1)*Pow5(1 - LDotN))*(1 + (FD90 - 1)*Pow5(1 - VDotN))*baseColor;
}

//disney speculer BRDF
float3 DesineySpeculerBRDF(float3 speculerColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	//calculate D; desiney use two speculer lobes, here we use one // same to unreal
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float tmp = NDotH * NDotH*(alpha2 - 1) + 1;
	float D = alpha * alpha / (UNITY_PI*tmp*tmp);

	//calculate F
	float F = speculerColor + (1 - speculerColor)*Pow5(1 - VDotH);

	//calculate G
	alpha = (0.5 + roughness * 0.5)*(0.5 + roughness * 0.5);
	alpha2 = alpha * alpha;
	float GV = 2 * VDotN / (VDotN + sqrt(alpha2 + (1 - alpha2)*VDotN*VDotN));
	float GL = 2 * LDotN / (LDotN + sqrt(alpha2 + (1 - alpha2)*LDotN*LDotN));
	float G = GV * GL;

	return D * G / (4 * LDotN*VDotN)* F;
}

//unity speculer brdf
float3 UnitySpeculerBRDF(float3 speculerColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	//claculate D
	float alpha = roughness * roughness;
	alpha = max(alpha, 0.002);
	float alpha2 = alpha * alpha;
	float tmp = NDotH * NDotH*(alpha2 - 1) + 1;
	float D = alpha2 *UNITY_INV_PI / (tmp*tmp+1e-7f);

	//calculate F
	float F = speculerColor + (1 - speculerColor)*Pow5(1 - VDotH);

	//culate G
	float GV = VDotN * sqrt(VDotN*VDotN*(1 - alpha2) + alpha2);
	float GL = LDotN * sqrt(LDotN*LDotN*(1 - alpha2) + alpha2);
	float G = 0.5/(GV+GL+1e-5f);

	float specularTerm = D * G *UNITY_PI;
#   ifdef UNITY_COLORSPACE_GAMMA
	specularTerm = sqrt(max(1e-4h, specularTerm));
#   endif

	return specularTerm * F;
}

float3 UnityEnviromentBRDF(float3 speculerColor, float roughness, float VDotN)
{
	float surfaceReduction = 1.0 / (Pow4(roughness) + 1.0);
#ifdef UNITY_COLORSPACE_GAMMA
	surfaceReduction = 1.0 - 0.28*roughness*roughness*roughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#else
	surfaceReduction = = 1.0 / (Pow4(roughness) + 1.0);           // fade \in [0.5;1]
#endif
	float oneMinusReflectivity = 1 - SpecularStrength(speculerColor);
	half grazingTerm = saturate(1 - roughness + (1 - oneMinusReflectivity));
	half t = Pow4(1 - VDotN);
	half3 fresnel = lerp(speculerColor, grazingTerm, t);

	return surfaceReduction * fresnel;
}

//unreal reference:https://de45xmedrsdbp.cloudfront.net/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
//unreal diffuse brdf
float3 UnrealDiffuseBRDF(float3 baseColor)
{
	return baseColor * UNITY_INV_PI;
}

//unreal speculer brdf
float3 UnrealSpeculerBRDF(float3 speculerColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	//claculate D
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float tmp = NDotH * NDotH*(alpha2 - 1) + 1;
	float D = alpha * alpha / (UNITY_PI*tmp*tmp);

	//calculate F
	tmp = (-5.55473*VDotH - 6.98316)*VDotH;
	float F = speculerColor + (1 - speculerColor)*pow(2, tmp);

	//culate G
	float k = (roughness + 1)*(roughness + 1) / 8;
	float GV = 1.0 / (VDotN*(1 - k) + k);
	float GL = 1.0 / (LDotN*(1 - k) + k);
	float G = GV * GL;

	return 0.25 * D * G * F;
}

//unreal cloth brdf
float3 UnrealClothSpeculerBRDF(float3 fuzzColor, float cloth, float3 speculerColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	//claculate D
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float tmp = NDotH * NDotH*(alpha2 - 1) + 1;
	float D = alpha * alpha / (UNITY_PI*tmp*tmp);

	//calculate F
	tmp = (-5.55473*VDotH - 6.98316)*VDotH;
	float3 F = speculerColor + (1 - speculerColor)*pow(2, tmp);

	//culate G
	float k = (roughness + 1)*(roughness + 1) / 8;
	float GV = 1.0 / (VDotN*(1 - k) + k);
	float GL = 1.0 / (LDotN*(1 - k) + k);
	float G = GV * GL;

	float3 spec1 =0.25* D * G * F;

	//calculate cloth
	float d = (1 - alpha2)*NDotH*NDotH + alpha2;
	float D2 = rcp(UNITY_PI*(1 + 4 * alpha2))*(1 + 4 * alpha2*alpha2 / (d*d + 0.001));
	float Vis2 = rcp(4 * (LDotN + VDotN - LDotN * VDotN) + 0.001);
	float3 Fc = Pow5(1 - VDotH);
	float3 F2 = saturate(50.0*fuzzColor.g)*Fc + (1 - Fc)*fuzzColor;
	float3 spec2 = (D2 * Vis2)* F2;

	return lerp(spec1, spec2, cloth);
}

//unreal enviroment brdf
#ifndef PreIntegratedGF
sampler2D		_PreIntegratedGF;
float4 PreIntegratedGF_ST;
#endif

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
float3 OptimizingBRDF(float3 speculerColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	float roughness4 = roughness * roughness*roughness*roughness;
	float tmp = NDotH*NDotH*(roughness4 - 1) + 1;
	return roughness4 / (4 * UNITY_PI*tmp*tmp*VDotH*VDotH*(roughness + 0.5))*speculerColor;
}

float3 OptimizingEnviromentBRDF(float3 speculerColor, float roughness, float NDotH, float VDotH, float LDotN, float VDotN)
{
	float tmp = 1 - max(roughness, VDotN);
	return tmp * tmp*tmp + speculerColor;
}

//anisotropic ward brdf
uniform float _AlphaX;
uniform float _AlphaY;

float3 WardBRDF(float3 speculerColor, float dotHTAlphaX, float dotHBAlphaY, float NDotH, float VDotH, float LDotN, float VDotN)
{
	return sqrt(max(0.0, 1 / (LDotN * VDotN+0.001)))
		* exp(-2.0 * (dotHTAlphaX * dotHTAlphaX
			+ dotHBAlphaY * dotHBAlphaY) / (1.0 + NDotH));
}