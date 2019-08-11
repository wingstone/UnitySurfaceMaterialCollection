Shader "Custom/Grass"
{
	Properties
	{
		_TopColor("Top Color", Color) = (0,1,0,0)
		_BottomColor("Bottom Color", Color) = (0,1,0,0)
		_TessellationUniform("Tessellation Uniform", Range(1, 15)) = 1

		_GrassHight("Grass Hight", Range(0, 1)) = 0.5
		_GrassWidth("Grass Wifth", Range(0,0.5)) = 0.2

		_WindDirection("Wind Direction", Vector) = (1,0,0,0)
		_WindIntensity("Wind Intensity", Range(0, 10)) = 1

		_RandomTex("RandomTex", 2D) = "gray" {}
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
