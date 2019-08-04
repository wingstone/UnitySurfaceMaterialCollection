Shader "Custom/DisneyPBR"
{
    Properties
    {
		_DiffuseColor("DiffuseColor", Color) = (1,1,1,1)
		_SpecularColor("SpecularColor", Color) = (1,1,1,1)
		_Glossness("Glossness", Range(0, 1)) = 0.5
		[NoScaleOffset]_NormalTex("NormalTex", 2D) = "bump"{}
		[NoScaleOffset]_OcclusionTex("OcclusionTex", 2D) = "white"{}
		[NoScaleOffset]_EmissionTex("EmissionTex", 2D) = "black"{}

		_SpecularFactor("SpecularFactor", Range(0,5)) = 1
		[HiddenInInspector]_EnviromentIntensity("EnviromentIntensity", Range(0,1)) = 1
		[HiddenInInspector]_EnviromentSpecularIntensity("EnviromentIntensity", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100

        Pass
        {
			Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment Disneyfrag

            #pragma multi_compile_fwdbase		//声明光照与阴影相关的宏
			#include "DisneyPBR.cginc"

            ENDCG
        }

		Pass
		{
			Tags {"LightMode" = "FowardAdd"}

			//待做
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
