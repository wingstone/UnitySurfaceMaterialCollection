Shader "Custom/VolumeLight"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white"{}
        _SkyBacklight ("Sky Backlight", 2D) = "white" {}
        _NoiseTex ("Noise Tex", 2D) = "gray"{}
        _LightSourcePos ("LightSourcePos", Vector) = (0.5,0.5,0.5,0.5)
        _VolumeScale ("VolumeScale", Range(0, 2)) = 0.1
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _SkyBacklight;
            sampler2D _NoiseTex;
            float4 _LightSourcePos;
            float _VolumeScale;

            float4 frag (v2f i) : SV_Target
            {
                float4 col = 0;
                for( int m = 0; m < 35; m++)
                {
                    float2 offset = i.uv - _LightSourcePos.xy;
                    float2 uv = _LightSourcePos.xy + offset*_VolumeScale*m;
                    col.rgb += tex2D(_SkyBacklight, uv).rgb;
                }

                col.rgb /= 36;

                return col;
            }
            ENDCG
        }
    }
}
