Shader "Custom/Z"
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

					float4 propos : TEXCOORD2;
					float4 pos : SV_POSITION;		
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.propos = o.pos;

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					// 根据计算，结果应该为（-1，1），实际情况参考https://docs.unity3d.com/Manual/SL-DepthTextures.html
					float t = i.propos.z/ i.propos.w;

					#if UNITY_REVERSED_Z 
					t = 1 - t;
					#endif

					fixed3 color = fixed3(t,t,t);	

				return fixed4(color, 1);
			}
			ENDCG
		}

		}
}
