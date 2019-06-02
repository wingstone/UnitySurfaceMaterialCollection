Shader "Custom/PBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100

        Pass
        {
			Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase		//声明光照与阴影相关的宏

            #include "UnityCG.cginc"		//常用函数，宏，结构体
			#include "Lighting.cginc"		//光源相关变量
			#include "AutoLight.cginc"		//光照，阴影相关宏，函数

			#define _USESHADOW 0		//阴影启用宏

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;

				#if _USESHADOW
				SHADOW_COORDS(2)
				#endif

				float3 normal : NORMAL;
                float4 pos : SV_POSITION;		//shadow宏要求此处必须为pos变量，shit。。。
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float _Smoothness;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

				o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;

				#if _USESHADOW
				TRANSFER_SHADOW(o)
				#endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

				//light data
				float3 lightCol = _LightColor0.rgb;
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				//surface data
				float3 normal = normalize(i.normal);
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 reflectDir = reflect(-viewDir, normal);

				//ambient light and light probs
				fixed3 color = ShadeSH9(half4(normal, 1));

				//lambert
				float NDotL = saturate(dot(normal, lightDir));
				color += NDotL * col*lightCol;

				//ambient refection
				half4 reflectData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir);
				half3 reflectCol = DecodeHDR(reflectData, unity_SpecCube0_HDR);
				color = lerp(color, reflectCol, _Smoothness);

				//shadow
				#if _USESHADOW
				float shadow = SHADOW_ATTENUATION(i);
				color *= shadow;
				#endif

                return fixed4(color, 1);
            }
            ENDCG
        }

		Pass
		{
			Tags {"LightMode" = "FowardAdd"}

			
		}

		Pass
		{
			Tags {"LightMode" = "ShadowCaster"}

			
		}
    }
}
