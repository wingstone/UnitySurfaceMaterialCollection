Shader "Custom/OutlineFadeEffect"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0

		_OutlineColor("OutlineColor", Color) = (1,1,1,1)
		_OutlineWidth("OutlineWidth", Float) = 0.01
		_OutlinePower("OutlinePower", Range(0, 10)) = 1
    }
    SubShader
    {
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}
		LOD 200

		Pass
		{
			Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}
			Tags {"LightingMode" = "ForwardBase"}

			ZWrite Off
			Cull Front
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f {
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 V : TEXCOORD1;
				float3 N : TEXCOORD2;
			};

			fixed4 _OutlineColor;
			float _OutlineWidth;
			float _OutlinePower;

			v2f vert(appdata_base i)
			{
				v2f o = (v2f)0;

				float3 norm = normalize(i.normal);
				float3 vertex = i.vertex.xyz + norm * _OutlineWidth;
				float3 wPos = mul(unity_ObjectToWorld, i.vertex);
				o.vertex = UnityObjectToClipPos(float4(vertex, 1));

				o.uv = i.texcoord;
				o.N = UnityObjectToWorldNormal(i.normal);
				o.V = normalize(_WorldSpaceCameraPos.xyz - wPos);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 color = 0;
				color.rgb = _OutlineColor.rgb;

				float3 N = normalize(i.N);
				float3 V = normalize(i.V);
				float alpha = 1.0 - dot(-N, V);
				color.a = saturate(1- pow(alpha, _OutlinePower));
				return color;
			}


			ENDCG

		}

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
