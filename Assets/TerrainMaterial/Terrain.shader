Shader "ShadingModel/Terrain"
{
    Properties
    {
        _Color ("Main Color", Color) = (0.5,0.5,0.5,1)
        _Control ("Split Map", 2D) = "red" {}
        _Diffuse1 ("Diffuse_1: color:rgb height:a", 2D) = "red" {}
        _Diffuse2 ("Diffuse_2: color:rgb height:a", 2D) = "green" {}
        _Diffuse3 ("Diffuse_3: color:rgb height:a", 2D) = "blue" {}
        _Diffuse4 ("Diffuse_4: color:rgb height:a", 2D) = "white" {}
        _Weight("Blend Weight" , Range(0.001,1)) = 0.2
    }

    Subshader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
                o.normal = UnityObjectToWorldNormal(v.normal.xyz);
                return o;
            }

            float4 _Color;
            sampler2D _Control;
            sampler2D _Diffuse1;
            sampler2D _Diffuse2;
            sampler2D _Diffuse3;
            sampler2D _Diffuse4;
            float _Weight;

            float3 blend(float4 texture1, float a1, float4 texture2, float a2)
            {
                float depth = 0.2;
                float ma = max(texture1.a + a1, texture2.a + a2) - depth;

                float b1 = max(texture1.a + a1 - ma, 0);
                float b2 = max(texture2.a + a2 - ma, 0);

                return (texture1.rgb * b1 + texture2.rgb * b2) / (b1 + b2);
            }

            inline half4 Blend(half high1 ,half high2,half high3,half high4 , half4 control) 
            {
                half4 blend ;
                
                blend.r = high1 * control.r;
                blend.g = high2 * control.g;
                blend.b = high3 * control.b;
                blend.a = high4 * control.a;
                
                half ma = max(blend.r, max(blend.g, max(blend.b, blend.a)));
                blend = max(blend - ma + _Weight , 0) * control;
                return blend/(blend.r + blend.g + blend.b + blend.a);
            }

            float4 frag (VertexOutput i) : SV_Target
            {
                float3 L = _WorldSpaceLightPos0.xyz;
                float3 N = normalize(i.normal);

                float3 color = ShadeSH9(float4(N, 1));
                color += saturate(dot(L, N));

                //https://zhuanlan.zhihu.com/p/26383778
                half4 splat_control = tex2D (_Control, i.texcoord).rgba;
                
                half4 lay1 = tex2D (_Diffuse1, i.texcoord*10);
                half4 lay2 = tex2D (_Diffuse2, i.texcoord*10);
                half4 lay3 = tex2D (_Diffuse3, i.texcoord*10);
                half4 lay4 = tex2D (_Diffuse4, i.texcoord*10);

                half4 blend = Blend(lay1.a,lay2.a,lay3.a,lay4.a,splat_control);
                color *= blend.r * lay1.rgb + blend.g * lay2.rgb + blend.b * lay3.rgb + blend.a * lay4.rgb;

                return float4(color, 1.0);
            }
            ENDCG
        }
    }

}
