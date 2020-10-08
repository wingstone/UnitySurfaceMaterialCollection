Shader "ShadowMap/RenderShadowMap"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" "RenderType"="Opaque" }
        // No culling or depth
        Cull Off 
        ZWrite On 
        ZTest LEqual

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float depth : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.xyz -= v.normal*0.0001;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.depth = o.vertex.z / o.vertex.w;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = i.depth;
                #if UNITY_REVERSED_Z 
                    col = 1 - col;
                #endif

                col = exp(80*col);

                return col;
            }
            ENDCG
        }
    }
}
