Shader "Custom/test1"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
		SubShader
		{

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"		//常用函数，宏，结构体

				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					half2 uv_depth : TEXCOORD1;

					float4 pos : SV_POSITION;		
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;
				half4 _MainTex_TexelSize;
				sampler2D _CameraDepthTexture;

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);

					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.uv_depth = v.uv;
			
					#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
						o.uv_depth.y = 1 - o.uv_depth.y;
					#endif

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					float t = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
					fixed3 color = fixed3(t,t,t);	

				return fixed4(color, 1);
			}
			ENDCG
		}

		}
}
