Shader "Unlit/BakeWireframe"
{
    Properties
    {
        _Color("Main Color", Color) = (1,1,1,1)
        _WireFrameColor("WireFrame Color", Color) = (0,0,0,1)
        [Toggle(ENABLE_DRAWQUAD)]_DisplayQuad("DisplayQuad", Float) = 0
        [PowerSlider(3.0)]_WireFrameWidth("WireFrameWidth", Range(0, 1)) = 0.001
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma multi_compile _ ENABLE_DRAWQUAD
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 3.0
            
            #include "UnityCG.cginc"
            
            struct VS_IN
            {
                float4 vertex		: POSITION;
                float2 uv1			: TEXCOORD0;
                float2 uv2			: TEXCOORD1;
                float2 uv3			: TEXCOORD2;        //uv3 uv4: xyz, length to edge, w, minid
                float2 uv4			: TEXCOORD3;    
            };

            struct FS_IN
            {
                float4 vertex		: SV_POSITION;
                float2 uv1			: TEXCOORD0;
                float2 uv2			: TEXCOORD1;
                float4 length2Edge			: TEXCOORD2;        //uv3 uv4: xyz, length to edge, w, minid
            };

            float4 _Color;
            float _DisplayQuad;
            float4 _WireFrameColor;
            float _WireFrameWidth;

            FS_IN vert(VS_IN v)
            {
                FS_IN o = (FS_IN)0;
                o.uv1 = v.uv1;
                o.uv2 = v.uv2;
                o.length2Edge = float4(v.uv3, v.uv4);
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag(FS_IN i) : SV_Target
            {
                float len = 1;
                
                #ifdef ENABLE_DRAWQUAD
                    if(i.length2Edge.w < 0.5)
                    len = min(i.length2Edge.y, i.length2Edge.z);
                    else if(i.length2Edge.w < 1.5)
                    len = min(i.length2Edge.x, i.length2Edge.z);
                    else
                    len = min(i.length2Edge.x, i.length2Edge.y);
                #else
                    len = min(i.length2Edge.x, min(i.length2Edge.y, i.length2Edge.z));
                #endif

                // aa use smooth step;
                float factor = smoothstep(0, _WireFrameWidth, len);
                // aa use sdf
                // factor = smoothstep(0, 1.5, len/fwidth(len));

                float4 color = lerp(_WireFrameColor, _Color, factor);
                return color;
            }

            ENDCG
        }
    }
}
