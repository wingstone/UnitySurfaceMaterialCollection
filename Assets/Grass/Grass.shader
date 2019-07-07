Shader "Custom/Grass"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_TessellationUniform ("Tessellation Uniform", Range(1, 15)) = 1
		_GrassHeight("Grass Height", Range(0, 1)) = 0.5
		_GrassWidth("Grass Wifth", Range(0,0.5)) = 0.2
	}
	SubShader
	{
		Pass
		{
			Cull Off

			CGPROGRAM
			#pragma vertex vert

			#pragma hull hull
			#pragma domain domain
			
			#pragma geometry geom

			#pragma fragment frag
			#pragma target 4.6
			
			#include "UnityCG.cginc"
			#include "Grass.cginc"

			ENDCG
		}
	}
}
