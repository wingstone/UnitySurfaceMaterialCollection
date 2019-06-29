Shader "Custom/Hair"
{
	Properties
	{
		[Header(Main Control Parameters)]
		[Gamma][NoScaleOffset]_MainTex("Texture", 2D) = "white" {}
		[NoScaleOffset]_NormalTex("NormalTex", 2D) = "bump"{}
		[NoScaleOffset]_TangentShiftTex("TangentShiftTex", 2D) = "gray"{}

		[Header(Specular1 Control Parameters)]
		_SpecularCol1("Specular Color1", Color) = (1,1,1,1)
		[PowerSlider(3.0)]_SpecularPower1("Specular Power1", Range(1, 300)) = 25
		_SpecularIntensity1("Specular Intensity1", Range(0, 1)) = 1
		_SpecularShiftScale1("Specular Shift Scale1", Range(0, 1)) = 0.5
		_SpecularShiftMove1("Specular Shift Move1", Range(0, 1)) = 0

		[Header(Specular2 Control Parameters)]
		_SpecularCol2("Specular Color2", Color) = (1,1,1,1)
		[PowerSlider(3.0)]_SpecularPower2("Specular Power2", Range(1, 300)) = 25
		_SpecularIntensity2("Specular Intensity2", Range(0, 1)) = 1
		_SpecularShiftScale2("Specular Shift Scale2", Range(0, 1)) = 0.5
		_SpecularShiftMove2("Specular Shift Move2", Range(0, 1)) = 0
			
		[Header(Other Control Parameters)]
		_AlphaRef("AlphaRef", Range(0, 1)) = 0.6
		_EnviromentSmoothness("EnviromentSmoothness", Range(0,1)) = 1
		_EnviromentIntensity("EnviromentIntensity", Range(0,1)) = 1
	}
		SubShader
		{
			Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}
			LOD 100

			Pass
			{
				Tags {"LightMode" = "ForwardBase"}
				Blend SrcAlpha OneMinusSrcAlpha


				CGPROGRAM
				#define ALPATEST
				#pragma vertex vert
				#pragma fragment Hairfrag

				#pragma multi_compile_fwdbase		//声明光照与阴影相关的宏
				#include "Hair.cginc"

				ENDCG
			}

			Pass
			{
				Tags {"LightMode" = "ForwardBase"}
				Blend SrcAlpha OneMinusSrcAlpha
				Cull Front

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment Hairfrag

				#pragma multi_compile_fwdbase		//声明光照与阴影相关的宏
				#pragma shader_feature ENABLE_SPECULAR_GLOSSNESS
				#include "Hair.cginc"

				ENDCG
			}

			Pass
			{
				Tags {"LightMode" = "ForwardBase"}
				Blend SrcAlpha OneMinusSrcAlpha
				Cull Back

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment Hairfrag

				#pragma multi_compile_fwdbase		//声明光照与阴影相关的宏
				#pragma shader_feature ENABLE_SPECULAR_GLOSSNESS
				#include "Hair.cginc"

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
