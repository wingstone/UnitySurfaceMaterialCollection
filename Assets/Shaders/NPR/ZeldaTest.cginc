#ifndef ZELDA_TEST
#define ZELDA_TEST

#include "UnityCG.cginc"		//常用函数，宏，结构体
#include "Lighting.cginc"		//光源相关变量
#include "AutoLight.cginc"		//光照，阴影相关宏，函数

#include "CommenVertex.cginc"

sampler2D _DiffuseAoTex;
float4 _DiffuseTint;
float _DiffuseSmooth;
sampler2D _SpecularGlossnessTex;
float _SpecularSmooth;
sampler2D _EmissionTex;
float4 _Ambient;	//二次元需要的简单环境光模拟
float4 _Rim;
float _RimPos;
float _RimOffsetDiff;

//塞尔达+崩坏3？
fixed4 frag(v2f i, half vFace : FACE) : SV_Target
{
	//vector
	float3 N = normalize(i.normal);
	float3 T = normalize(i.tangent);
	float3 B = normalize(i.binormal);
	float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
	float3 L = normalize(_WorldSpaceLightPos0.xyz);
	float3 H = normalize(L + V);

	//color,二次元不需要法线,Alpha，二次元需要Specular  以及AO,这些都需要是卡通化处理的色块
#ifdef UNITY_COLORSPACE_GAMMA
	float3 lightCol = GammaToLinearSpace(_LightColor0.rgb);		//光源颜色为gamma空间
	float4 val = 0;

	float3 diffTint = GammaToLinearSpace(_DiffuseTint.rgb);
	val = tex2D(_DiffuseAoTex, i.uv);
	float3 diffColor = GammaToLinearSpace(val.rgb) * diffTint;
	float ao = val.a;

	val = tex2D(_SpecularGlossnessTex, i.uv);
	float3 specColor = GammaToLinearSpace(val.rgb);
	float smoothness = val.a;

	val = tex2D(_EmissionTex, i.uv);
	float3 emission = GammaToLinearSpace(val.rgb);

	float3 ambient = GammaToLinearSpace(_Ambient.rgb);
	float3 rim = GammaToLinearSpace(_Rim.rgb);
#else
	float3 lightCol = _LightColor0.rgb;
	float4 val = 0;

	float3 diffTint = _DiffuseTint.rgb;
	val = tex2D(_DiffuseAoTex, i.uv);
	float3 diffColor = val.rgb * diffuseTint;
	float ao = val.a;

	val = tex2D(_SpecularGlossnessTex, i.uv);
	float3 specColor = val.rgb;
	float smoothness = val.a;

	val = tex2D(_EmissionTex, i.uv);
	float3 emission = val.rgb;

	float3 ambient = _Ambient.rgb;
	float3 rim = _Rim.rgb;
#endif

	//二次元角色不需要阴影，因为阴影质量不二次元，而且精度质量不行，塞尔达好像是有阴影的==
	//算了，还是加上阴影吧==
	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

	//二次元不需要复杂间接光，以及环境反射
	fixed3 color = ambient * diffColor;

	//diffuse data	//可将AO与diff同时画暗，来减弱角落处的颜色，从而增加二次元体积感
	float diffFactor = smoothstep(0.5 - _DiffuseSmooth, 0.5 + _DiffuseSmooth, (dot(L, N)*0.5 + 0.5)*ao*atten);
	color += diffFactor * diffColor * lightCol;

	//specular颜色好像不太需要要，一个固有色就够了
	float specFactor1 = smoothstep(0.4 - _SpecularSmooth, 0.4 + _SpecularSmooth, pow(dot(N, H), smoothness * 100));
	float specFactor2 = smoothstep(0.6 - _SpecularSmooth, 0.6 + _SpecularSmooth, pow(dot(N, H), smoothness * 100));
	float specFactor = (specFactor1 + specFactor2) * 0.5;
	color += specFactor * diffColor * lightCol;

	//二次元边缘光
	float rimFactor = diffFactor + 1.0 - smoothstep(0.5 - _DiffuseSmooth - _RimOffsetDiff, 0.5 - _DiffuseSmooth, (dot(L, N)*0.5 + 0.5)*ao);	//漫反射调整
	rimFactor *= smoothstep(_RimPos - 0.01, _RimPos, 1.0 - dot(V, N));	//边缘光
	color += rimFactor * diffColor * rim;

	//二次元需要自发光
	color += emission;

	#ifdef UNITY_COLORSPACE_GAMMA
	color = LinearToGammaSpace(color);
	#endif

	return fixed4(color, 1);
}


#endif