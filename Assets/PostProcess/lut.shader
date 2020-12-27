Shader "Custom/lut"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass    //apply lut
        {
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

            sampler2D _MainTex;
            sampler2D _lut;
            float4 _lut_pars;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            //
            // 2D LUT grading
            // scaleOffset = (1 / lut_width, 1 / lut_height, lut_height - 1)
            //
            half3 ApplyLut2D(sampler2D tex, float3 uvw, float3 scaleOffset)
            {
                // Strip format where `height = sqrt(width)`
                uvw.z *= scaleOffset.z;
                float shift = floor(uvw.z);
                uvw.xy = uvw.xy * scaleOffset.z * scaleOffset.xy + scaleOffset.xy * 0.5;
                uvw.x += shift * scaleOffset.y;
                uvw.xyz = lerp(
                tex2D(tex, uvw.xy).rgb,
                tex2D(tex, uvw.xy + float2(scaleOffset.y, 0.0)).rgb,
                uvw.z - shift
                );
                return uvw;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                col.rgb = ApplyLut2D(_lut, col.rgb, _lut_pars.xyz);
                return col;
            }
            ENDCG
        }
    }
}