
//https://www.shadertoy.com/view/ll2GD3
Shader "ShadingModel/IridescenceNPR"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NormalTex ("Normal Texture", 2D) = "bump" {}
        _OcclusionTex ("Occlusion Texture", 2D) = "white" {}
        _Roughness("Roughness", Range(0, 1)) = 1
        _Metallic("Metallic", Range(0, 1)) = 0
        _IridescenceInten("IridescenceInten", Range(0, 1.0)) = 0
        _IridescenceBand("IridescenceBand", Range(0.2, 5.0)) = 1.0
        _IridescenceOffset("IridescenceOffset", Range(0, 2)) = 0
        _IridescenceAniso("IridescenceAniso", Range(0, 1)) = 0
        _IridescenceTint("IridescenceTint", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"        //常用函数，宏，结构体
            #include "Lighting.cginc"		//光源相关变量
            #include "AutoLight.cginc"		//光照，阴影相关宏，函数

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 binormal : TEXCOORD3;
                float3 normal : TEXCOORD4;
                UNITY_LIGHTING_COORDS(5, 6)
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _NormalTex;
            sampler2D _OcclusionTex;
            float _Roughness;
            float _Metallic;
            float _IridescenceInten;
            float _IridescenceBand;
            float _IridescenceOffset;
            float _IridescenceAniso;
            float4 _IridescenceTint;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
                o.uv = v.uv;

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldDir(v.tangent.xyz);

                float3x3 tangentToWorld = CreateTangentToWorldPerVertex(o.normal, o.tangent, v.tangent.w);
                o.tangent = tangentToWorld[0];
                o.binormal = tangentToWorld[1];
                o.normal = tangentToWorld[2];

                UNITY_TRANSFER_LIGHTING(o, v.uv);
                return o;
            }

            float3 UnityEnviromentBRDF(float3 SpecularColor, float roughness, float VDotN)
            {
                float surfaceReduction = 1.0 / (Pow4(roughness) + 1.0);
                surfaceReduction = 1.0 / (Pow4(roughness) + 1.0);
                float oneMinusReflectivity = 1 - SpecularStrength(SpecularColor);
                half grazingTerm = saturate(1 - roughness + (1 - oneMinusReflectivity));
                half t = Pow4(1 - VDotN);
                half3 fresnel = lerp(SpecularColor, grazingTerm, t);

                return surfaceReduction * fresnel;
            }

            float3 pal( in float t, in float3 a, in float3 b, in float3 c, in float3 d )
            {
                return a + b*cos( 6.28318*(c*t+d) );
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 albedo = tex2D(_MainTex, i.uv);
                float3 diffcolor = unity_ColorSpaceDielectricSpec.a*(1.0 - _Metallic)*albedo;
                float3 speccolor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, _Metallic);
                float3 texNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
                float occlusion = tex2D(_OcclusionTex, i.uv).r;
                
                float3 N = normalize(texNormal.x*i.tangent + texNormal.y*i.binormal + texNormal.z*i.normal);
                float3 L = _WorldSpaceLightPos0.xyz;
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 H = normalize(V + L);
                float3 R = reflect(-V, N);

                float ndl = saturate(dot(N, L));
                float ndv = saturate(dot(N, V));
                float ndh = saturate(dot(N, H));
                float ldh = saturate(dot(L, H));

                float3 col = 0;

                //shadow light
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                float3 lightcolor = _LightColor0.rgb;
                
                float3 diffuse = lightcolor * ndl*atten;
                col += diffcolor * diffuse;

                //Iridescence
                float zoom = _IridescenceBand * lerp(ndv, dot(V, i.binormal), _IridescenceAniso) + _IridescenceOffset;
                float3 Iridescence = pal(zoom, float3(0.5,0.5,0.5),float3(0.5,0.5,0.5),float3(1.0,1.0,1.0),float3(0.0,0.33,0.67) );
                speccolor = lerp(speccolor, speccolor*Iridescence*_IridescenceTint.rgb, _IridescenceInten);

                //specular
                float roughness = max(_Roughness, 0.002);
                float G = SmithJointGGXVisibilityTerm (ndl, ndv, roughness);
                float D = GGXTerm (ndh, roughness);
                float3 F = FresnelTerm (speccolor, ldh);
                float3 specular = ndl * lightcolor * G * D * F * atten;
                col += specular;

                //ambient
                float3 ambient = 0;
                #if UNITY_SHOULD_SAMPLE_SH
                    ambient = ShadeSHPerPixel(N, ambient, i.worldPos)*occlusion;
                #endif
                col += diffcolor * ambient;

                //ibl
                half mip = roughness * (1.7 - 0.7*roughness)*UNITY_SPECCUBE_LOD_STEPS;
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, R, mip);
                float3 IBLColor = DecodeHDR(rgbm, unity_SpecCube0_HDR)*occlusion;
                col += UnityEnviromentBRDF(speccolor, roughness, ndv) * IBLColor;

                return float4(col, 1);
            }
            ENDCG
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
