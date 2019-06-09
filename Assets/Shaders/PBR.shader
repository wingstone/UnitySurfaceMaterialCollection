Shader "Custom/PBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_SpeculerTex("SpeculerTex", 2D) = "white"{}
		_NormalTex("NormalTex", 2D) = "bump"{}
		_OcclusionTex("OcclusionTex", 2D) = "white"{}
		_EmissionTex("EmissionTex", 2D) = "black"{}

		_SmoothnessScale("SmoothnessScale", Range(0,1)) = 1
		_EnviromentIntensity("EnviromentIntensity", Range(0,1)) = 1
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
            #pragma fragment frag

            #pragma multi_compile_fwdbase		//声明光照与阴影相关的宏

            #include "UnityCG.cginc"		//常用函数，宏，结构体
			#include "Lighting.cginc"		//光源相关变量
			#include "AutoLight.cginc"		//光照，阴影相关宏，函数

			#include "BRDF.cginc"

			#define _USESHADOW 1		//阴影启用宏
			#define MIPMAP_STEP_COUNT 6
			#define SPECULER_GLOSSNESS

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;

				#if _USESHADOW
				UNITY_LIGHTING_COORDS(2,3)
				#endif

				float3 tangent : TEXCOORD4;
				float3 binormal : TEXCOORD5;
				float3 normal : TEXCOORD6;

                float4 pos : SV_POSITION;		//shadow宏要求此处必须为pos变量，shit。。。
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _SpeculerTex;
			float4 _SpeculerTex_ST;
			sampler2D _NormalTex;
			float4 _NormalTex_ST;
			sampler2D _OcclusionTex;
			float4 _OcclusionTex_ST;
			sampler2D _EmissionTex;
			float4 _EmissionTex_ST;

			float _SmoothnessScale;
			float _EnviromentIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.normal = UnityObjectToWorldNormal(v.normal);
				o.tangent = UnityObjectToWorldDir(v.tangent.xyz);

				half3x3 tangentToWorld = CreateTangentToWorldPerVertex(o.normal, o.tangent, v.tangent.w);
				o.tangent = tangentToWorld[0];
				o.binormal = tangentToWorld[1];
				o.normal = tangentToWorld[2];
				

				#if _USESHADOW
				UNITY_TRANSFER_LIGHTING(o, v.uv);
				#endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
				float3 color = 0;
				//#ifdef UNITY_COLORSPACE_GAMMA
    //            fixed3 baseColor = GammaToLinearSpace(tex2D(_MainTex, i.uv));
				//fixed3 speculerColor = GammaToLinearSpace(tex2D(_SpeculerTex, i.uv));
				//fixed3 texNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
				//fixed3 occlusion = GammaToLinearSpace(tex2D(_OcclusionTex, i.uv));
				//fixed3 emission = GammaToLinearSpace(tex2D(_EmissionTex, i.uv));
				//#else
				fixed3 baseColor = tex2D(_MainTex, i.uv);
				fixed3 speculerColor = tex2D(_SpeculerTex, i.uv);
				fixed3 texNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
				fixed3 occlusion = tex2D(_OcclusionTex, i.uv);
				fixed3 emission = tex2D(_EmissionTex, i.uv);
				//#endif

				//light data
				float3 lightCol = _LightColor0.rgb;
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				//shadow
				#if _USESHADOW
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				lightCol *= atten;
				#endif

				//surface data
				float3 normal = normalize(texNormal.x*i.tangent + texNormal.y*i.binormal + texNormal.z*i.normal);
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 reflectDir = reflect(-viewDir, normal);
				float3 halfDir = normalize(viewDir + lightDir);

				float LDotN = saturate(dot(lightDir, normal));
				float VDotN = saturate(dot(viewDir, normal));
				float VDotH = saturate(dot(viewDir, halfDir));
				float NDotH = saturate(dot(normal, halfDir));

				float glossness = _SmoothnessScale;
				#ifdef SPECULER_GLOSSNESS
				glossness *= tex2D(_SpeculerTex, i.uv).a;
				#endif

				float roughness = 1 - glossness;

				//indirect light
				color += ShadeSH9(half4(normal, 1))* baseColor* occlusion;

				//diffuse data
				float3 diffuseBRDF = DesineyDiffuseBRDF(baseColor, roughness, VDotH, LDotN, VDotN);
				color += LDotN * lightCol*diffuseBRDF;

				//speculer data
				float3 speculerBRDF = UnitySpeculerBRDF(speculerColor, roughness, NDotH, VDotH, LDotN, VDotN);
				color += LDotN * lightCol*speculerBRDF;

				//IBL reflection from unity
				//half4 reflectData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir);
				//half3 reflectCol = DecodeHDR(reflectData, unity_SpecCube0_HDR);
				//IBL reflection IBLColor
				half3 IBLColor;
				#ifdef _GLOSSYREFLECTIONS_OFF
				IBLColor = unity_IndirectSpecColor.rgb;

				#else
				half mip = roughness*(1.7-0.7*roughness)*UNITY_SPECCUBE_LOD_STEPS;
				half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, mip);
				IBLColor = DecodeHDR(rgbm, unity_SpecCube0_HDR)*occlusion;

				#endif
				
				//IBL reflection fresnel and surfaceReduction
				float surfaceReduction = 1.0 / (Pow4(roughness) + 1.0);
				#ifdef UNITY_COLORSPACE_GAMMA
					surfaceReduction = 1.0 - 0.28*roughness*roughness*roughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
				#else
					surfaceReduction = = 1.0 / (Pow4(roughness) + 1.0);           // fade \in [0.5;1]
				#endif
				float oneMinusReflectivity = 1 - SpecularStrength(speculerColor);
				half grazingTerm = saturate(glossness + (1 - oneMinusReflectivity));
				half t = Pow4(1 - VDotN);
				half3 fresnel = lerp(speculerColor, grazingTerm, t);
				color += surfaceReduction * IBLColor *fresnel* _EnviromentIntensity;

				color += emission;
				//#ifdef UNITY_COLORSPACE_GAMMA
				//color = LinearToGammaSpace(color);
				//#endif
                return fixed4(color, 1);
            }
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
