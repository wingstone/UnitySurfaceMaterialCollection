Shader "Custom/EdgeDetect" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "" {}
	}


	CGINCLUDE

	#include "UnityCG.cginc"

	uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
	uniform float4 _MainTex_TexelSize;
	sampler2D_float _CameraDepthTexture;
	sampler2D _CameraDepthNormalsTexture;

	uniform float4 _Sensitivity;
	uniform float4 _EdgeColor;
	uniform float _SampleDistance;
	uniform float _EdgeIntensity;
	uniform float _Threshold;

	//Definitions of sructure, Vertex shader and fragment shader for Sobel Color

	float SobelFilter(float dx, float dy, sampler2D tex, float2 uv) {
		float2 delta = float2(dx, dy);

		float4 hr = float4(0, 0, 0, 0);
		float4 vt = float4(0, 0, 0, 0);

		hr += tex2D(tex, (uv + float2(-1.0, -1.0) * delta)) *  1.0;
		hr += tex2D(tex, (uv + float2(0.0, -1.0) * delta)) *  0.0;
		hr += tex2D(tex, (uv + float2(1.0, -1.0) * delta)) * -1.0;
		hr += tex2D(tex, (uv + float2(-1.0, 0.0) * delta)) *  2.0;
		hr += tex2D(tex, (uv + float2(0.0, 0.0) * delta)) *  0.0;
		hr += tex2D(tex, (uv + float2(1.0, 0.0) * delta)) * -2.0;
		hr += tex2D(tex, (uv + float2(-1.0, 1.0) * delta)) *  1.0;
		hr += tex2D(tex, (uv + float2(0.0, 1.0) * delta)) *  0.0;
		hr += tex2D(tex, (uv + float2(1.0, 1.0) * delta)) * -1.0;

		vt += tex2D(tex, (uv + float2(-1.0, -1.0) * delta)) *  1.0;
		vt += tex2D(tex, (uv + float2(0.0, -1.0) * delta)) *  2.0;
		vt += tex2D(tex, (uv + float2(1.0, -1.0) * delta)) *  1.0;
		vt += tex2D(tex, (uv + float2(-1.0, 0.0) * delta)) *  0.0;
		vt += tex2D(tex, (uv + float2(0.0, 0.0) * delta)) *  0.0;
		vt += tex2D(tex, (uv + float2(1.0, 0.0) * delta)) *  0.0;
		vt += tex2D(tex, (uv + float2(-1.0, 1.0) * delta)) * -1.0;
		vt += tex2D(tex, (uv + float2(0.0, 1.0) * delta)) * -2.0;
		vt += tex2D(tex, (uv + float2(1.0, 1.0) * delta)) * -1.0;

		return sqrt(hr * hr + vt * vt);
	}

	struct VertIn {
		float4 vertex : POSITION;
		float2 texcoord0 : TEXCOORD0;
	};

	struct VertOut {
		float4 pos : SV_POSITION;
		float2 uv0 : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	};

	VertOut vert(VertIn v) {
		VertOut o = (VertOut)0;
		o.uv0 = v.texcoord0;
		o.uv1 = v.texcoord0;
		o.pos = UnityObjectToClipPos(v.vertex);

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv1.y = 1 - o.uv1.y;
#endif
		return o;
	}

	float4 fragColor(VertOut i) : COLOR{
		half alpha = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex)).a;

		float dx = _SampleDistance * _MainTex_TexelSize.x;
		float dy = _SampleDistance * _MainTex_TexelSize.y;
		float edgeValue = saturate(lerp(0.0,SobelFilter(dx , dy , _MainTex , i.uv0),_Threshold));

		float3 edgeMask = float3(edgeValue, edgeValue, edgeValue); // EdgesMask	

		float4 sceneColor = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
		float3 finalColor = saturate((edgeMask*_EdgeColor.rgb) + (sceneColor.rgb - edgeMask));
		finalColor = lerp(sceneColor, finalColor, _EdgeIntensity);

		return float4(finalColor,alpha);
	}

	float4 fragDepth(VertOut i) : SV_Target
	{
		half alpha = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex)).a;
		// inspired by borderlands implementation of popular "sobel filter"

		float centerDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv1));
		float4 depthsDiag;
		float4 depthsAxis;

		float2 uvDist = _SampleDistance * _MainTex_TexelSize.xy;

		depthsDiag.x = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv1 + uvDist)); // TR
		depthsDiag.y = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv1 + uvDist * float2(-1,1))); // TL
		depthsDiag.z = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv1 - uvDist * float2(-1,1))); // BR
		depthsDiag.w = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv1 - uvDist)); // BL

		depthsAxis.x = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv1 + uvDist * float2(0,1))); // T
		depthsAxis.y = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv1 - uvDist * float2(1,0))); // L
		depthsAxis.z = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv1 + uvDist * float2(1,0))); // R
		depthsAxis.w = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv1 - uvDist * float2(0,1))); // B

		// make it work nicely with depth based image effects such as depth of field:
		depthsDiag = (depthsDiag > centerDepth.xxxx) ? depthsDiag : centerDepth.xxxx;
		depthsAxis = (depthsAxis > centerDepth.xxxx) ? depthsAxis : centerDepth.xxxx;

		depthsDiag -= centerDepth;
		depthsAxis /= centerDepth;

		const float4 HorizDiagCoeff = float4(1,1,-1,-1);
		const float4 VertDiagCoeff = float4(-1,1,-1,1);
		const float4 HorizAxisCoeff = float4(1,0,0,-1);
		const float4 VertAxisCoeff = float4(0,1,-1,0);

		float4 SobelH = depthsDiag * HorizDiagCoeff + depthsAxis * HorizAxisCoeff;
		float4 SobelV = depthsDiag * VertDiagCoeff + depthsAxis * VertAxisCoeff;

		float SobelX = dot(SobelH, float4(1,1,1,1));
		float SobelY = dot(SobelV, float4(1,1,1,1));
		float Sobel = sqrt(SobelX * SobelX + SobelY * SobelY);

		float edgeValue = Sobel;

		float3 edgeMask = float3(edgeValue, edgeValue, edgeValue); // EdgesMask	

		float4 sceneColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
		//float3 finalColor = saturate((edgeMask*_EdgeColor.rgb) + (sceneColor.rgb - edgeMask));
		float4 finalCol = lerp(sceneColor, _EdgeColor * sceneColor, edgeValue);
		finalCol = lerp(sceneColor, finalCol, _EdgeIntensity);
		
		return float4(finalCol.rgb, alpha);
	}

	//depth normal detect

	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv[5] : TEXCOORD0;
	};

	v2f vertRobert(appdata_img v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);

		float2 uv = v.texcoord.xy;
		o.uv[0] = uv;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			uv.y = 1 - uv.y;
#endif

		// calc coord for the X pattern
		// maybe nicer TODO for the future: 'rotated triangles'

		o.uv[1] = uv + _MainTex_TexelSize.xy * float2(1, 1) * _SampleDistance;
		o.uv[2] = uv + _MainTex_TexelSize.xy * float2(-1, -1) * _SampleDistance;
		o.uv[3] = uv + _MainTex_TexelSize.xy * float2(-1, 1) * _SampleDistance;
		o.uv[4] = uv + _MainTex_TexelSize.xy * float2(1, -1) * _SampleDistance;

		return o;
	}

	inline float CheckSame(float2 centerNormal, float centerDepth, float4 theSample)
	{
		// difference in normals
		// do not bother decoding normals - there's no need here
		float2 diff = abs(centerNormal - theSample.xy) * _Sensitivity.y;
		int isSameNormal = (diff.x + diff.y) * _Sensitivity.y < 0.1;
		// difference in depth
		float sampleDepth = DecodeFloatRG(theSample.zw);
		float zdiff = abs(centerDepth - sampleDepth);
		// scale the required threshold by the distance
		int isSameDepth = zdiff * _Sensitivity.x < 0.09 * centerDepth;

		// return:
		// 1 - if normals and depth are similar enough
		// 0 - otherwise

		return isSameNormal * isSameDepth ? 1.0 : 0.0;
	}

	half4 fragRobert(v2f i) : SV_Target
	{
		half alpha = tex2D(_MainTex, TRANSFORM_TEX(i.uv[0], _MainTex)).a;
		half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1].xy);
		half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2].xy);
		half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3].xy);
		half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4].xy);

		half same = 1.0;
		same *= CheckSame(sample1.xy, DecodeFloatRG(sample1.zw), sample2);
		same *= CheckSame(sample3.xy, DecodeFloatRG(sample3.zw), sample4);
		half edge = 1 - same;

		float4 mainCol = tex2D(_MainTex, i.uv[0].xy);
		float4 finalCol = lerp(mainCol, _EdgeColor * mainCol, edge);
		finalCol = lerp(mainCol, finalCol, _EdgeIntensity);

		return float4(finalCol.rgb, alpha);
	}

	ENDCG

	Subshader {
		Tags{
			"IgnoreProjector" = "True"
			"Queue" = "Overlay+1"
			"RenderType" = "Overlay"
		}

		//Sobel Depth
		Pass{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma target 3.0   
			#pragma vertex vert
			#pragma fragment fragDepth
			ENDCG
		}

		//Roberts Cross Depth Normals
		Pass{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vertRobert
			#pragma fragment fragRobert
			ENDCG
		}


		//Sobel Color
		Pass{
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma target 3.0   
			#pragma vertex vert
			#pragma fragment fragColor
			ENDCG
		}

	}

	Fallback off

} // shader
