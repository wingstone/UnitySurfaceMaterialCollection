Shader "Custom/BlurGlass"
{
    Properties
    {
		[HideInInspector][NoScaleOffset]_MainTex("MainTex", 2D) = "white" {}
		_MainColor("MainColor", Color) = (1,1,1,1)
        _Alpha("Alpha", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100

        Pass
        {
			Blend One Zero

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
				float2 screenUV : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

			sampler2D _MainTex;
			float4 _MainTex_ST;
			half4 _MainColor;
			half _Alpha;

			sampler2D _BlurGrabTex;
			float4 _BlurGrabTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.screenUV = o.vertex.xy / o.vertex.w*0.5 + 0.5;
#if UNITY_UV_STARTS_AT_TOP
				o.screenUV.y = 1 - o.screenUV.y;
#endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_BlurGrabTex, i.screenUV);
				col = _MainColor * _Alpha + col * (1 - _Alpha);

                return fixed4(col.rgb, 1);
            }
            ENDCG
        }
    }
}
