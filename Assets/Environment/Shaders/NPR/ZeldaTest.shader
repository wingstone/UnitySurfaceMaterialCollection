Shader "Custom/ZeldaTest"
{
    Properties
    {
        _DiffuseAoTex ("Diffuse Ao Tex", 2D) = "white" {}
		_DiffuseTint("Diffuse Tint", Color) = (0.5, 0.5, 0.5, 1)
		_DiffuseSmooth("Diffuse Smooth", Range(0, 1)) = 0.01
		_SpecularGlossnessTex("Specular Glossness Tex", 2D) = "white" {}
		_SpecularSmooth("Specular Smooth", Range(0, 1)) = 0.01
		_EmissionTex("EmissionTex", 2D) = "black" {}
		_Ambient("Ambient", Color) = (0.1,0.1,0.1,1)
		_Rim("Rim", Color) = (0.1,0.1,0.1,1)
		_RimPos("Rim Pos", Range(0, 1)) = 0.8
		_RimOffsetDiff("Rim Offset Diff", Range(0, 0.5)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100

        Pass
        {
			Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
			#pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

			#include "ZeldaTest.cginc"

            ENDCG
        }
    }
}
