Shader "Custom/DetailBlend"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _DiffuseAlphaTex ("DiffuseAlphaTex", 2D) = "white" {}
        _SpecularSmoothTex ("SpecularSmoothTex", 2D) = "white" {}
		_ColorDetailTex("ColorDetailTex", 2D) = "white" {}
		_GrayDetailTex("GrayDetailTex", 2D) = "gray" {}
		_DetailWeight("DetailWeight", Range(0, 1)) = 0.5
		[KeywordEnum(USECOLOR, USEGRAY)] _Detail("Detail mode", Int) = 0
		[KeywordEnum(MULTIPLY , SCREEN, OVERLAY)] _METHOD("Detail Color Method", Int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardSpecular fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

		#pragma multi_compile _DETAIL_USECOLOR _DETAIL_USEGRAY
		#pragma multi_compile _METHOD_MULTIPLY _METHOD_SCREEN _METHOD_OVERLAY

        sampler2D _DiffuseAlphaTex;
		sampler2D _SpecularSmoothTex;
		fixed4 _Color;

		sampler2D _ColorDetailTex;
		sampler2D _GrayDetailTex;
		half _DetailWeight;
        
		struct Input
        {
            float2 uv_DiffuseAlphaTex;
			float2 uv_SpecularSmoothTex;
			float2 uv_GrayDetailTex;
			float2 uv_ColorDetailTex;
        };

		//struct SurfaceOutputStandardSpecular
		//{
		//	fixed3 Albedo;      // diffuse color
		//	fixed3 Specular;    // specular color
		//	fixed3 Normal;      // tangent space normal, if written
		//	half3 Emission;
		//	half Smoothness;    // 0=rough, 1=smooth
		//	half Occlusion;     // occlusion (default 1)
		//	fixed Alpha;        // alpha for transparencies
		//};


        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

		half3 GrayBlend(half3 mainCol, half grayCol)
		{
			return mainCol + (grayCol - 0.5)*_DetailWeight;
		}

		half3 ColorBlend(half3 mainCol, half3 detailCol)
		{
			half3 oppoMain = 1 - mainCol;
			half3 oppoDetail = 1 - detailCol;
#ifdef _METHOD_MULTIPLY
			return mainCol * detailCol;
#endif

#ifdef _METHOD_SCREEN
			return 1 - oppoMain * oppoDetail;
#endif

#ifdef _METHOD_OVERLAY
			return lerp(2 * mainCol*detailCol, 1 - 2 * oppoMain*oppoDetail, step(0.5, oppoMain));
#endif
		}

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
			half4 value = tex2D(_DiffuseAlphaTex, IN.uv_DiffuseAlphaTex);
            o.Albedo = value.rgb*_Color.rgb;
			o.Alpha = value.a;
#ifdef _DETAIL_USEGRAY
			half grayCol = tex2D(_GrayDetailTex, IN.uv_GrayDetailTex).r;
			o.Albedo = GrayBlend(o.Albedo, grayCol);
#endif

#ifdef _DETAIL_USECOLOR
			half3 detailCol = tex2D(_ColorDetailTex, IN.uv_ColorDetailTex).rgb;
			o.Albedo = ColorBlend(o.Albedo, detailCol);
#endif

			value = tex2D(_SpecularSmoothTex, IN.uv_SpecularSmoothTex);
			o.Specular = value.rgb;
			o.Smoothness = value.a;;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
