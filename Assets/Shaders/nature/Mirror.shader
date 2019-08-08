Shader "Custom/Mirror"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}
        LOD 100

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
				float2 screenUV : TEXCOORD1;
				float3 normal : NORMAL;
                float4 vertex : SV_POSITION;
            };

            float4 _BaseColor;
			//float4x4 _ReflectionMatrix;
			sampler2D _ReflectionTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.screenUV = o.vertex.xy / o.vertex.w*0.5 + 0.5;
				o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed3 col = 0;
				col = tex2D(_ReflectionTex, i.screenUV)*_BaseColor;

                return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
