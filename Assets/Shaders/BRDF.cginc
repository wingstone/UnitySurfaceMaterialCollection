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
	float GV = VDotN / (VDotN*(1 - k) + k);
	float GL = LDotN / (LDotN*(1 - k) + k);
	float G = GV * GL;

	return D * G / (4 * LDotN*VDotN)* F;
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