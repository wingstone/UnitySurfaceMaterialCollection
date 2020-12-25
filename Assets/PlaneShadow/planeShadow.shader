Shader "ShadingModel/planeShadow"
{
    Properties
    {
        _Color("Main Color", Color) = (0,0,0,1)
        _Height("Height", Float) = 0.0
        _Delt("Delt", Float) = 0.001
    }
    SubShader
    {
        Tags { "RenderType"="Opaque+1" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal.xyz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 L = _WorldSpaceLightPos0.xyz;
                float3 N = normalize(i.normal);

                float NoL = saturate(dot(L, N));
                float3 col = _LightColor0.rgb * NoL;

                return float4(col, 1);
            }
            ENDCG
        }

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            float _Height;
            float _Delt;

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos = mul(UNITY_MATRIX_M, v.vertex);
                worldPos /= worldPos.w;
                float3 L = _WorldSpaceLightPos0.xyz;
                worldPos.xyz += (_Height - worldPos.y)*L*rcp(L.y);
                worldPos.y += _Delt;

                o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                return o;
            }

            half4 _Color;

            half4 frag (v2f i) : SV_Target
            {
                return _Color;
            }
            ENDCG
        }
    }
}
