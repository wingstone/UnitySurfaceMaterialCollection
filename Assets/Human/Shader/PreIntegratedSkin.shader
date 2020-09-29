Shader "Human/PreIntegratedShader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NormalTex ("Normal Texture", 2D) = "bump" {}
        _OcclusionTex ("Occlusion Texture", 2D) = "white" {}
        _PreIntegratedSkinTex ("PreIntegrated Skin Texture", 2D) = "gray" {}
        _PreIntegratedShadowTex ("PreIntegrated Shadow Texture", 2D) = "gray" {}
        _Roughness("Roughness", Range(0, 1)) = 1
        _Metallic("Metallic", Range(0, 1)) = 0
        _TuneCurvature("tuneCurvature-调整曲率", Range(0.001,0.1)) = 1
        _TuneNormalBlur("tuneNormalBlur-调整法线模糊", Color) = (1,1,1,1)
        _TunePenumbraWidth("tunePenumbraWidth-调整半影宽度", Range(0, 1)) = 0.5
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
            sampler2D _PreIntegratedSkinTex;
            sampler2D _PreIntegratedShadowTex;
            float _Roughness;
            float _Metallic;
            float _TuneCurvature;
            float4 _TuneNormalBlur;
            float _TunePenumbraWidth;

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

            //wrapndl:0-1
            //curvature:曲率
            //http://simonstechblog.blogspot.com/2015/02/pre-integrated-skin-shading.html
            float3 SimonInterpolate(float3 wrapndl, float curvature)
            {
                float3 NdotL = wrapndl;
                float curva = (1.0/mad(curvature, 0.5 - 0.0625, 0.0625) - 2.0) / (16.0 - 2.0); // curvature is within [0, 1] remap to normalized r from 2 to 16
                float oneMinusCurva = 1.0 - curva;
                float3 curve0;
                {
                    float3 rangeMin = float3(0.0, 0.3, 0.3);
                    float3 rangeMax = float3(1.0, 0.7, 0.7);
                    float3 offset = float3(0.0, 0.06, 0.06);
                    float3 t = saturate( mad(NdotL, 1.0 / (rangeMax - rangeMin), (offset + rangeMin) / (rangeMin - rangeMax)  ) );
                    float3 lowerLine = (t * t) * float3(0.65, 0.5, 0.9);
                    lowerLine.r += 0.045;
                    lowerLine.b *= t.b;
                    float3 m = float3(1.75, 2.0, 1.97);
                    float3 upperLine = mad(NdotL, m, float3(0.99, 0.99, 0.99) -m );
                    upperLine = saturate(upperLine);
                    float3 lerpMin = float3(0.0, 0.35, 0.35);
                    float3 lerpMax = float3(1.0, 0.7 , 0.6 );
                    float3 lerpT = saturate( mad(NdotL, 1.0/(lerpMax-lerpMin), lerpMin/ (lerpMin - lerpMax) ));
                    curve0 = lerp(lowerLine, upperLine, lerpT * lerpT);
                }
                float3 curve1;
                {
                    float3 m = float3(1.95, 2.0, 2.0);
                    float3 upperLine = mad( NdotL, m, float3(0.99, 0.99, 1.0) - m);
                    curve1 = saturate(upperLine);
                }
                float oneMinusCurva2 = oneMinusCurva * oneMinusCurva;
                float3 brdf = lerp(curve0, curve1, mad(oneMinusCurva2, -1.0 * oneMinusCurva2, 1.0) );
                return brdf;
            }

            float3 SkinDiffuse(float3 ndl, float curvature)
            {
                float3 lookup = ndl*0.5+0.5;
                float3 diffuse;
                diffuse.r = tex2D(_PreIntegratedSkinTex, float2(lookup.r, curvature)).r;
                diffuse.g = tex2D(_PreIntegratedSkinTex, float2(lookup.g, curvature)).g;
                diffuse.b = tex2D(_PreIntegratedSkinTex, float2(lookup.b, curvature)).b;
                return diffuse;
            }

            float3 SkinShadow(float atten, float width)
            {
                return tex2D(_PreIntegratedShadowTex, float2(atten, width)).rgb;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 albedo = tex2D(_MainTex, i.uv);
                float3 diffcolor = unity_ColorSpaceDielectricSpec.a*(1.0 - _Metallic)*albedo;
                float3 speccolor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, _Metallic);
                float3 texNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
                float occlusion = tex2D(_OcclusionTex, i.uv).r;
                
                float3 oldN = normalize(i.normal);
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
                float3 lightcolor = _LightColor0.rgb*UNITY_PI;
                lightcolor *= SkinShadow(atten, _TunePenumbraWidth);

                //ambient
                float3 ambient = 0;
                #if UNITY_SHOULD_SAMPLE_SH
                    ambient = ShadeSHPerPixel(N, ambient, i.worldPos)*occlusion;
                #endif
                col += diffcolor * ambient;
                
                //pre integrated diffuse
                float dn = length(fwidth(oldN));
                float dp = length(fwidth(i.worldPos));
                float curvature = saturate(dn/dp*_TuneCurvature);
                float3 rN = lerp(N, oldN, _TuneNormalBlur.r);   //此处用oldN代替blur normalmap use Diffusion profile
                float3 gN = lerp(N, oldN, _TuneNormalBlur.g);
                float3 bN = lerp(N, oldN, _TuneNormalBlur.b);
                float3 ndl3 = float3(dot(rN, L), dot(gN, L), dot(bN, L));
                
                float3 diffuse = lightcolor.rgb * SkinDiffuse(ndl3, curvature);
                // float3 diffuse = lightcolor.rgb * SimonInterpolate(ndl3, curvature);
                col += diffcolor * diffuse;

                //specular
                float roughness = max(_Roughness, 0.002);
                float G = SmithJointGGXVisibilityTerm (ndl, ndv, roughness);
                float D = GGXTerm (ndh, roughness);
                float3 F = FresnelTerm (speccolor, ldh);
                float3 specular = ndl * lightcolor.rgb * G * D * F;
                col += speccolor * specular;

                //ibl
                half mip = roughness * (1.7 - 0.7*roughness)*UNITY_SPECCUBE_LOD_STEPS;
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, R, mip);
                float3 IBLColor = DecodeHDR(rgbm, unity_SpecCube0_HDR)*occlusion;
                col += speccolor * IBLColor;

                // col = atten;
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
