Shader "Human/LookupTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        CGINCLUDE
        #include "UnityCG.cginc"        //常用函数，宏，结构体
        
        float Gaussian (float v, float r)
        {
            return 1.0/sqrt(2.0*UNITY_PI*v)*exp(-(r*r)/(2*v));
        }

        float3 Scatter(float r)
        {
            return Gaussian(0.0064*1.414, r)*float3(0.233,0.455,0.649)+
            Gaussian(0.0484*1.414, r)*float3(0.100,0.336,0.344)+
            Gaussian(0.1870*1.414, r)*float3(0.118,0.198,0.000)+
            Gaussian(0.5670*1.414, r)*float3(0.113,0.007,0.007)+
            Gaussian(1.9900*1.414, r)*float3(0.358,0.004,0.000)+
            Gaussian(7.4100*1.414, r)*float3(0.078,0.000,0.000);
        }

        float newPenumbra(float pos)
        {
            return saturate(pos*2-1);
        }

        float3 integrateShadowScattering(float penumbraLocation, float penumbraWidth)
        {
            float3 totalWeights = 0;
            float3 totalLight = 0;
            float PROFILE_WIDTH = UNITY_PI*4;   //应该为测量数据，没找到资料，这里取个差不多的数值，在保证运行效率下尽量大
            float inc = 0.001;

            float a = -PROFILE_WIDTH;
            while(a <= PROFILE_WIDTH)
            {
                float light = newPenumbra(penumbraLocation+a/penumbraWidth);
                float sampleDist = abs(a);
                float3 weights = Scatter(sampleDist);
                totalWeights += weights;
                totalLight += light*weights;
                a+=inc;
            }

            return totalLight/totalWeights;
        }

        float3 integrateDiffuseScatteringOnRing(float cosTheta , float skinRadius)
        {
            // Angle from lighting direction.
            float theta = acos(cosTheta);
            float3 totalWeights = 0;
            float3 totalLight = 0;
            float a= -UNITY_PI/2;
            float inc = 0.001;

            while(a <= UNITY_PI/2)
            {
                float sampleAngle = theta + a;
                float diffuse= saturate(cos(sampleAngle));
                float sampleDist = abs(2.0*skinRadius*sin(a*0.5));
                // Distance.
                float3 weights = Scatter(sampleDist);
                // Profile Weight.
                totalWeights += weights;
                totalLight += diffuse*weights;
                a+=inc;
            }
            return totalLight/totalWeights;
        }
        ENDCG

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

            float4 frag(v2f i) : SV_Target
            {
                float3 col = 0;
                float penumbraLocation = i.uv.x;
                float penumbraWidth = 1/i.uv.y;
                col = integrateShadowScattering(penumbraLocation, penumbraWidth);
                return float4(col, 1);
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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            float4 frag(v2f i) : SV_Target
            {
                float3 col = 0;
                float cosTheta = i.uv.x*2-1;
                float skinRadius = 1/i.uv.y;
                col = integrateDiffuseScatteringOnRing(cosTheta, skinRadius);
                return float4(col, 1);
            }
            ENDCG
        }
    }
}
