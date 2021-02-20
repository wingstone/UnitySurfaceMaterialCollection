Shader "Custom/AreaLight"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _Roughness("Roughness", Range(0, 1)) = 1
        _Metallic("Metallic", Range(0, 1)) = 0
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD4;
                float4 pos : SV_POSITION;
            };

            float4 _Color;
            float _Roughness;
            float _Metallic;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            // area light parameter
            float4 _SphereLightColor;
            float _SphereLightRedius;
            float4 _SphereLightPos;
            float4 _TubeLightColor;
            float _TubeLightRedius;
            float4 _TubeLightPos0;
            float4 _TubeLightPos1;
            
            // Adapted from https://www.shadertoy.com/view/ldfGWs
            // no fade
            half3 CalcSphereLightToLight(float3 pos, float3 lightPos, float3 eyeVec, half3 normal, float sphereRad)
            {
                half3 viewDir = -eyeVec;
                half3 r = reflect (viewDir, normal);

                float3 L = lightPos - pos;
                float3 centerToRay	= dot (L, r) * r - L;
                float3 closestPoint	= L + centerToRay * saturate(sphereRad / length(centerToRay));
                return normalize(closestPoint);
            }


            half3 CalcTubeLightToLight(float3 pos, float3 tubeStart, float3 tubeEnd, float3 eyeVec, half3 normal, float tubeRad)
            {
                half3 N = normal;
                half3 viewDir = -eyeVec;
                half3 r = reflect (viewDir, normal);

                float3 L0		= tubeStart - pos;
                float3 L1		= tubeEnd - pos;
                float distL0	= length( L0 );
                float distL1	= length( L1 );
                
                float NoL0		= dot( L0, N ) / ( 2.0 * distL0 );
                float NoL1		= dot( L1, N ) / ( 2.0 * distL1 );
                float NoL		= ( 2.0 * clamp( NoL0 + NoL1, 0.0, 1.0 ) ) 
                / ( distL0 * distL1 + dot( L0, L1 ) + 2.0 );
                
                float3 Ld			= L1 - L0;
                float RoL0		= dot( r, L0 );
                float RoLd		= dot( r, Ld );
                float L0oLd 	= dot( L0, Ld );
                float distLd	= length( Ld );
                float t			= ( RoL0 * RoLd - L0oLd ) 
                / ( distLd * distLd - RoLd * RoLd );
                
                float3 closestPoint	= L0 + Ld * clamp( t, 0.0, 1.0 );
                float3 centerToRay	= dot( closestPoint, r ) * r - closestPoint;
                closestPoint		= closestPoint + centerToRay * clamp( tubeRad / length( centerToRay ), 0.0, 1.0 );
                float3 l				= normalize( closestPoint );
                return l;
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

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 albedo = _Color;
                float3 diffcolor = unity_ColorSpaceDielectricSpec.a*(1.0 - _Metallic)*albedo;
                float3 speccolor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, _Metallic);
                
                float3 N = normalize(i.normal);
                float3 L = 1;
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 R = reflect(-V, N);


                //===========sphere
                L = CalcSphereLightToLight(i.worldPos, _SphereLightPos.xyz, -V, N, _SphereLightRedius);
                float3 H = normalize(V + L);

                float ndl = saturate(dot(N, L));
                float ndv = saturate(dot(N, V));
                float ndh = saturate(dot(N, H));
                float ldh = saturate(dot(L, H));

                float3 col = 0;

                float3 lightcolor = _SphereLightColor.rgb;
                float atten = 1;
                
                float3 diffuse = lightcolor * ndl*atten;
                col += diffcolor * diffuse;

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
                    ambient = ShadeSHPerPixel(N, ambient, i.worldPos);
                #endif
                col += diffcolor * ambient;

                //ibl
                half mip = roughness * (1.7 - 0.7*roughness)*UNITY_SPECCUBE_LOD_STEPS;
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, R, mip);
                float3 IBLColor = DecodeHDR(rgbm, unity_SpecCube0_HDR);
                col += UnityEnviromentBRDF(speccolor, roughness, ndv) * IBLColor;

                
                //===========tube

                L = CalcTubeLightToLight(i.worldPos, _TubeLightPos0.xyz, _TubeLightPos1.xyz, -V, N, _TubeLightRedius);
                H = normalize(V + L);

                ndl = saturate(dot(N, L));
                ndv = saturate(dot(N, V));
                ndh = saturate(dot(N, H));
                ldh = saturate(dot(L, H));

                lightcolor = _TubeLightColor.rgb;
                atten = 1;
                
                diffuse = lightcolor * ndl*atten;
                col += diffcolor * diffuse;

                //specular
                roughness = max(_Roughness, 0.002);
                G = SmithJointGGXVisibilityTerm (ndl, ndv, roughness);
                D = GGXTerm (ndh, roughness);
                F = FresnelTerm (speccolor, ldh);
                specular = ndl * lightcolor * G * D * F * atten;
                col += specular;

                return float4(col, 1);
            }
            ENDCG
        }
    }
}
