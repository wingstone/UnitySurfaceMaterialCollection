Shader "Custom/CreateLut"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass    //create lut
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
            // Returns the default value for a given position on a 2D strip-format color lookup table
            // params = (lut_height, 0.5 / lut_width, 0.5 / lut_height, lut_height / lut_height - 1)
            //
            float3 GetLutStripValue(float2 uv, float4 params)
            {
                uv -= params.yz;
                float3 color;
                color.r = frac(uv.x * params.x);
                color.b = uv.x - color.r / params.x;
                color.g = uv.y;
                return color * params.w;
            } 

            float4 frag (v2f i) : SV_Target
            {
                float4 col = 0;
                col.rgb = GetLutStripValue(i.uv, _lut_pars);
                return col;
            }
            ENDCG
        }
    }
}
