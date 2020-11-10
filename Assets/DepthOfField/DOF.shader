Shader "Environment/DOF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CoCTex ("CoC Texture", 2D) = "white" {}
        _DoFTex ("DoF Texture", 2D) = "white" {}
        _FocusDistance ("_FocusDistance", Float) = 5.0
        _FocusRange ("_FocusRange", Float) = 2.0
        _BokehRadius ("_BokehRadius", Float) = 1.0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass    //0
        {
            Name "CoC Calculation"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float _FocusDistance;
            float _FocusRange;
            float _BokehRadius;

            float4 frag (v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
                float coc = (depth - _FocusDistance) / _FocusRange;
                coc = clamp(coc, -1, 1)*_BokehRadius;
                return coc;
            }
            ENDCG
        }

        Pass    //1
        {
            Name "pre filter"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            sampler2D _CoCTex;

            float4 frag (v2f i) : SV_Target
            {
                float3 col = tex2D(_MainTex, i.uv).rgb;
                float4 o = _MainTex_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;
                half coc0 = tex2D(_CoCTex, i.uv + o.xy).r;
                half coc1 = tex2D(_CoCTex, i.uv + o.zy).r;
                half coc2 = tex2D(_CoCTex, i.uv + o.xw).r;
                half coc3 = tex2D(_CoCTex, i.uv + o.zw).r;
                
                half cocMin = min(min(min(coc0, coc1), coc2), coc3);
                half cocMax = max(max(max(coc0, coc1), coc2), coc3);
                half coc = max(abs(cocMin), abs(cocMax));

                return float4(col, coc);
            }
            ENDCG
        }

        Pass    //2
        {
            Name "bokeh blur"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float _BokehRadius;

            
            //from DiskKernels.hlsl
            // rings = 3
            // points per ring = 7
            static const int kSampleCount = 22;
            static const float2 kDiskKernel[kSampleCount] = {
                float2(0,0),
                float2(0.53333336,0),
                float2(0.3325279,0.4169768),
                float2(-0.11867785,0.5199616),
                float2(-0.48051673,0.2314047),
                float2(-0.48051673,-0.23140468),
                float2(-0.11867763,-0.51996166),
                float2(0.33252785,-0.4169769),
                float2(1,0),
                float2(0.90096885,0.43388376),
                float2(0.6234898,0.7818315),
                float2(0.22252098,0.9749279),
                float2(-0.22252095,0.9749279),
                float2(-0.62349,0.7818314),
                float2(-0.90096885,0.43388382),
                float2(-1,0),
                float2(-0.90096885,-0.43388376),
                float2(-0.6234896,-0.7818316),
                float2(-0.22252055,-0.974928),
                float2(0.2225215,-0.9749278),
                float2(0.6234897,-0.7818316),
                float2(0.90096885,-0.43388376),
            };

            half Weigh (half coc, half radius) {
                return saturate((coc - radius + 2) / 2);
            }

            float4 frag (v2f i) : SV_Target
            {
                half3 color = 0;

                half weight = 0;
                for (int k = 0; k < kSampleCount; k++) {
                    float2 o = kDiskKernel[k] * _BokehRadius;
                    half radius = length(o);
                    o *= _MainTex_TexelSize.xy;
                    half4 s = tex2D(_MainTex, i.uv + o);

                    half sw = Weigh(abs(s.a), radius);
                    color += s.rgb * sw;
                    weight += sw;
                }
                color *= 1.0 / weight;

                return half4(color, 1);
            }
            ENDCG
        }

        Pass    //3
        {
            Name "post filter"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            float4 frag (v2f i) : SV_Target
            {
                float4 o = _MainTex_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;
                half4 s =
                tex2D(_MainTex, i.uv + o.xy) +
                tex2D(_MainTex, i.uv + o.zy) +
                tex2D(_MainTex, i.uv + o.xw) +
                tex2D(_MainTex, i.uv + o.zw);
                return s * 0.25;
            }
            ENDCG
        }

        Pass    //4
        {
            Name "combine"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            sampler2D _CoCTex;
            sampler2D _DoFTex;

            float4 frag (v2f i) : SV_Target
            {
                half4 source = tex2D(_MainTex, i.uv);
                half coc = tex2D(_CoCTex, i.uv).r;
                half4 dof = tex2D(_DoFTex, i.uv);

                half dofStrength = smoothstep(0.1, 1, abs(coc));
                half3 color = lerp(source.rgb, dof.rgb, dofStrength);
                return half4(color, source.a );
            }
            ENDCG
        }

    }
}
