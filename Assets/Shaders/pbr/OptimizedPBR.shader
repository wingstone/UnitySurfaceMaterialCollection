Shader "Custom/OptimizedPBR"
{
	Properties
	{
		//颜色
		//经过测试，shader property的颜色也是gamma空间的==
		//带[HDR]标签的shader 颜色位于线性空间
		//使用自定义GUI不影响上面的性质==
		//从外界脚本传入的颜色值都是线性的
		//纹理
		//纹理要根据使用纹理来判断，sRGB表示是否位于gamma空间
		//纹理的a通道不进行空间转换，按照位于线性空间进行计算
		[Toggle(USE_TEX)]use_tex("Use Tex", Int) = 0
		_DiffuseTex("Diffuse Tex", 2D) = "white"{}
		_SpecularTex("Specular Tex", 2D) = "gray"{}

		_DiffuseColor("DiffuseColor", Color) = (1,1,1,1)
		_SpecularColor("SpecularColor", Color) = (1,1,1,1)
		_Glossness("Glossness", Range(0, 1)) = 0.5
		[NoScaleOffset]_NormalTex("NormalTex", 2D) = "bump"{}
		[NoScaleOffset]_OcclusionTex("OcclusionTex", 2D) = "white"{}
		[NoScaleOffset]_EmissionTex("EmissionTex", 2D) = "black"{}

		_SpecularFactor("SpecularFactor", Range(0,5)) = 1
		[HideInInspector]_EnviromentIntensity("EnviromentIntensity", Range(0,1)) = 1
		[HideInInspector]_EnviromentSpecularIntensity("EnviromentIntensity", Range(0,1)) = 1
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}
			LOD 100

			Pass
			{
				Tags {"LightMode" = "ForwardBase"}

				CGPROGRAM

				#pragma shader_feature USE_TEX

				#pragma vertex vert
				#pragma fragment Optimizedfrag

				#pragma multi_compile_fwdbase		//声明光照与阴影相关的宏
				#include "OptimizedPBR.cginc"

				ENDCG
			}

			Pass
			{
				Tags {"LightMode" = "FowardAdd"}


			}

			Pass
			{
			//copy from unity standard shadowcaster
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual

			CGPROGRAM
			#pragma target 3.0

			// -------------------------------------


			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _SPECGLOSSMAP
			#pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _PARALLAXMAP
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			// Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
			//#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#include "UnityStandardShadow.cginc"

			ENDCG
		}
		}
}
