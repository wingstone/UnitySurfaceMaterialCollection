Shader "Custom/Sky"
{
    Properties
    {
        _SkyColor ("Sky Color", Color) = (1,1,1,1)
		_GroundColor ("Ground Color", Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags {"Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
		Cull Off 
		ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#define SKY_GROUND_THRESHOLD 0.2

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
				float3 viewDir : TEXCOORD0;
            };

			half4 _SkyColor;
			half4 _GroundColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.viewDir = normalize(mul(unity_ObjectToWorld, v.vertex).xyz);		//由于该点太远，可以这样使用
                return o;
            }

			half4 frag (v2f i) : SV_Target
            {
				half3 col = 0;
				half3 view = normalize(i.viewDir);

#ifdef UNITY_COLORSPACE_GAMMA
				half3 skyColor = GammaToLinearSpace(_SkyColor);
				half3 groundColor = GammaToLinearSpace(_GroundColor);
#endif

				col = lerp(skyColor, groundColor, saturate(-view.y / SKY_GROUND_THRESHOLD));

#ifdef UNITY_COLORSPACE_GAMMA
				col = LinearToGammaSpace(col);
#endif
                return half4(col, 1);
            }
            ENDCG
        }
    }
}
