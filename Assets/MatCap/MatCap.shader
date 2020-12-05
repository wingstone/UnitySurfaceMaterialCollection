// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "ShadingModel/MatCap"
{
    Properties
    {
        _Color ("Main Color", Color) = (0.5,0.5,0.5,1)
        _MatCap ("MatCap (RGB)", 2D) = "white" {}
    }

    Subshader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos	: SV_POSITION;
                float2 cap	: TEXCOORD0;
                float3 model_normal : TEXCOORD1;
                float3 world_normal : TEXCOORD2;
                float3 view_normal : TEXCOORD3;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos (v.vertex);

                // this is model normals
                o.model_normal = v.normal;

                // transform normal vectors from model space to world space
                float3 worldNorm =
                normalize(
                unity_WorldToObject[0].xyz * v.normal.x +
                unity_WorldToObject[1].xyz * v.normal.y +
                unity_WorldToObject[2].xyz * v.normal.z
                );

                // this is world normals
                o.world_normal = worldNorm;

                // transform normal vectors from world space to view space
                float3 viewNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
                // or use built-in UNITY_MATRIX_V

                // this is viewspace normals
                o.view_normal = viewNorm;

                // this is in the context of view space
                // get the coordinate on XY plane, ignore z coordinate
                o.cap.xy = viewNorm.xy * 0.5 + 0.5; // clamp (-1,1) to (0, 1)

                return o;
            }

            uniform float4 _Color;
            uniform sampler2D _MatCap;

            float4 frag (v2f i) : COLOR
            {
                float4 mc = tex2D(_MatCap, i.cap);
                return  _Color * mc;
            }
            ENDCG
        }
    }

}
