Shader "Custom/GuideMask"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _Color;
            float4 _MainTex_ST;
            float4 _RectParmeters;
            float _Radius;

            v2f vert(appdata_t v)
            {
                v2f OUT;

                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.texcoord.x *= _ScreenParams.x/_ScreenParams.y;
                OUT.color = v.color * _Color;
                return OUT;
            }

            float4 frag(v2f IN) : SV_Target
            {
                half4 color = tex2D(_MainTex, IN.texcoord) * IN.color;

                float mask = 1;
                float2 uv = IN.texcoord;
                uv = abs(uv - _RectParmeters.xy);
                float dist = length(max(uv - 0.5*_RectParmeters.zw, 0));
                mask = smoothstep(0, _Radius, dist);
                color.a *= mask;

                return color;
            }
            ENDCG
        }
    }
}
