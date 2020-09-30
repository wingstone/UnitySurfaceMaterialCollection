Shader "Environment/ParallaxMapping"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NormalTex ("Normal Texture", 2D) = "bump" {}
        _DepthTex ("Height Texture", 2D) = "black" {}
        _Roughness("Roughness", Range(0, 1)) = 1
        _Metallic("Metallic", Range(0, 1)) = 0
        _ParallaxHeight("Parallax Height", Range(0, 1)) = 0.5
        [KeywordEnum(ParallaxMapping, SteepParallaxMapping, ParallaxOcclusionMapping, ReliefMapping)] _Parallax ("Parallax mode", Float) = 0

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
            
            #pragma multi_compile _PARALLAX_PARALLAXMAPPING _PARALLAX_STEEPPARALLAXMAPPING _PARALLAX_PARALLAXOCCLUSIONMAPPING _PARALLAX_RELIEFMAPPING

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
            sampler2D _DepthTex;
            float _Roughness;
            float _Metallic;
            float _ParallaxHeight;

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

            float2 Parallax(float2 uv, float3 TV)
            {
                #ifdef _PARALLAX_PARALLAXMAPPING
                    uv -= tex2D(_DepthTex, uv).x*_ParallaxHeight*TV.xy;
                #endif

                #ifdef _PARALLAX_STEEPPARALLAXMAPPING
                    float numLayers = 10;
                    float depthStep = 1.0 / numLayers;
                    float currentDepth = 0.0;
                    float2 uvStep = TV.xy * _ParallaxHeight/ numLayers; 
                    float currentDepthMapValue = tex2D(_DepthTex, uv).r;

                    for(int i = 0; i< 10; i++)
                    {
                        if(currentDepth > currentDepthMapValue)
                        {
                            break;
                        }
                        uv -= uvStep;
                        currentDepthMapValue = tex2D(_DepthTex, uv).r;
                        currentDepth += depthStep;  
                    }
                #endif

                #ifdef _PARALLAX_PARALLAXOCCLUSIONMAPPING
                    float numLayers = 10;
                    float depthStep = 1.0 / numLayers;
                    float currentDepth = 0.0;
                    float2 uvStep = TV.xy * _ParallaxHeight/ numLayers; 
                    float currentDepthMapValue = tex2D(_DepthTex, uv).r;
                    float preDiff = 1e-5;
                    for(int i = 0; i< 10; i++)
                    {
                        if(currentDepth >= currentDepthMapValue)
                        {
                            float curDiff = currentDepth-currentDepthMapValue;
                            uv -= uvStep*preDiff/(curDiff+preDiff);
                            break;
                        }
                        else
                        {
                            preDiff = currentDepthMapValue - currentDepth;
                        }
                        uv -= uvStep;
                        currentDepthMapValue = tex2D(_DepthTex, uv).r;
                        currentDepth += depthStep; 
                    }
                #endif

                #ifdef _PARALLAX_RELIEFMAPPING
                    //linear rematching
                    float numLayers = 10;
                    float depthStep = 1.0 / numLayers;
                    float currentDepth = 0.0;
                    float2 uvStep = TV.xy * _ParallaxHeight/ numLayers; 
                    float currentDepthMapValue = tex2D(_DepthTex, uv).r;

                    for(int i = 0; i< 10; i++)
                    {
                        if(currentDepth > currentDepthMapValue)
                        {
                            break;
                        }
                        uv -= uvStep;
                        currentDepthMapValue = tex2D(_DepthTex, uv).r;
                        currentDepth += depthStep;  
                    }

                    //binary rematching
                    for(int i = 0; i< 8; i++)
                    {
                        uvStep *= 0.5;
                        depthStep *= 0.5;
                        currentDepthMapValue = tex2D(_DepthTex, uv).r;
                        if(currentDepth < currentDepthMapValue)
                        {
                            uv -= uvStep;
                            currentDepth += depthStep;
                        }
                        else
                        {
                            uv += uvStep;
                            currentDepth -= depthStep;
                        }
                        
                    }
                #endif

                return uv;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3x3 mat = float3x3(i.tangent, i.binormal, i.normal);   //估计通过这种方式构建的刚好是world2tangent矩阵
                float3 TV = mul(mat, V);
                float2 uv = Parallax(i.uv, normalize(TV));

                // sample the texture
                float4 albedo = tex2D(_MainTex, uv);
                float3 diffcolor = unity_ColorSpaceDielectricSpec.a*(1.0 - _Metallic)*albedo;
                float3 speccolor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, _Metallic);
                float3 texNormal = UnpackNormal(tex2D(_NormalTex, uv));
                float occlusion = 1;
                
                float3 oldN = normalize(i.normal);
                float3 N = normalize(texNormal.x*i.tangent + texNormal.y*i.binormal + texNormal.z*i.normal);
                float3 L = _WorldSpaceLightPos0.xyz;
                float3 H = normalize(V + L);
                float3 R = reflect(-V, N);

                float ndl = saturate(dot(N, L));
                float ndv = saturate(dot(N, V));
                float ndh = saturate(dot(N, H));
                float ldh = saturate(dot(L, H));

                float3 col = 0;

                //shadow light
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                float3 lightcolor = _LightColor0.rgb*UNITY_PI*atten;
                
                //diffuse
                float3 diffuse = lightcolor * ndl;
                col += diffcolor * diffuse;

                //specular
                float roughness = max(_Roughness, 0.002);
                float G = SmithJointGGXVisibilityTerm (ndl, ndv, roughness);
                float D = GGXTerm (ndh, roughness);
                float3 F = FresnelTerm (speccolor, ldh);
                float3 specular = ndl * lightcolor * G * D * F * atten;
                col += speccolor * specular;

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
                col += speccolor * IBLColor;

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
