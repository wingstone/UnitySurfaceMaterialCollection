Shader "Custom/BlurGlass"
{
    Properties
    {
		[NoScaleOffset]_MainTex("MainTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

			static half weights[3] = { 0.15, 0.1, 0.05 };

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv)*0.4;

				for (int n = 0; n < 3; n++)
				{
					col += tex2D(_MainTex, i.uv + half2(n + 1, 0) * _MainTex_TexelSize.x) * weights[n];
					col += tex2D(_MainTex, i.uv + half2(-n - 1, 0) * _MainTex_TexelSize.x)* weights[n];
				}

                return fixed4(col.rgb, 1);
            }
            ENDCG
        }

		Pass
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
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			static half weights[3] = { 0.15, 0.1, 0.05 };

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv)*0.4;

				for (int n = 0; n < 3; n++)
				{
					col += tex2D(_MainTex, i.uv + half2(0, n + 1) * _MainTex_TexelSize.y) * weights[n];
					col += tex2D(_MainTex, i.uv + half2(0, -n - 1) * _MainTex_TexelSize.y)* weights[n];
				}

				return fixed4(col.rgb, 1);
			}
			ENDCG
		}
    }
}
