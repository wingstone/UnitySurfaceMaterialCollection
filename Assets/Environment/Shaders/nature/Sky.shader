Shader "Environment/Sky"
{
    Properties
    {
        _SkyColor ("Sky Color", Color) = (1,1,1,1)
        _GroundColor ("Ground Color", Color) = (0,0,0,0)
        _AtmosphereThicknessR("AtmosphereThicknessR", Range(0,10)) = 1
        _AtmosphereThicknessM("AtmosphereThicknessM", Range(0,10)) = 1
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
                float3 skyColor : TEXCOORD1;
                float3 groundColor : TEXCOORD2;
            };

            half4 _SkyColor;
            half4 _GroundColor;
            float _AtmosphereThicknessR;
            float _AtmosphereThicknessM;

            static const float EarthRadius = 6360e3;
            static const float EarthRadius2 = 6360e3*6360e3;
            static const float AtmosphereRadius = 6420e3;
            static const float AtmosphereRadius2 = 6420e3*6420e3;
            static const float AtmosphereThicknessR = 7994;
            static const float AtmosphereThicknessM = 1200;
            static const float3 ScatterR = float3(5.8e-6f, 13.5e-6f, 33.1e-6f);     //海平面散射系数
            static const float3 ScatterM = 21e-6f;
            static const int NumSample = 16;
            static const int NumSampleLight = 8;


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
                float3 camerapos = float3(0, EarthRadius+1, 0);
                float3 eyeRay = normalize(i.viewDir);
                float3 sunDirection = _WorldSpaceLightPos0.xyz;

                float atmosphereThicknessR = AtmosphereThicknessR*_AtmosphereThicknessR;
                float atmosphereThicknessM = AtmosphereThicknessM*_AtmosphereThicknessM;


                float rayLength = sqrt(AtmosphereRadius2 + camerapos.y*camerapos.y * (eyeRay.y * eyeRay.y - 1)) - camerapos.y * eyeRay.y;

                //在地球表面以上
                if(eyeRay.y>0 || camerapos.y*camerapos.y * (1-eyeRay.y * eyeRay.y) >EarthRadius2)
                {
                    int numSamples = 16; 
                    int numSamplesLight = 8; 
                    float segmentLength = rayLength / numSamples; 
                    float tCurrent = 0; 
                    float3 sumR = 0; //rayleigh contribution 
                    float3 sumM = 0; // mie contribution 
                    float opticalDepthR = 0, opticalDepthM = 0; //transmittance 
                    float mu = dot(eyeRay, sunDirection); // mu in the paper which is the cosine of the angle between the sun direction and the ray direction 
                    float phaseR = 3.f / (16.f * UNITY_PI) * (1 + mu * mu); 
                    float g = 0.76f; 
                    float phaseM = 3.f / (8.f * UNITY_PI) * ((1.f - g * g) * (1.f + mu * mu)) / ((2.f + g * g) * pow(1.f + g * g - 2.f * g * mu, 1.5f)); 
                    for (int i = 0; i < numSamples; ++i) { 
                        float3 samplePosition = camerapos + (tCurrent + segmentLength * 0.5f) * eyeRay; 
                        float height = length(samplePosition) - EarthRadius; 
                        // compute optical depth for light
                        float hr = exp(-height / atmosphereThicknessR) * segmentLength; 
                        float hm = exp(-height / atmosphereThicknessM) * segmentLength; 
                        opticalDepthR += hr; 
                        opticalDepthM += hm; 
                        // light optical depth
                        float lightLength = sqrt(AtmosphereRadius2 + samplePosition.y*samplePosition.y * (sunDirection.y * sunDirection.y - 1)) - samplePosition.y * sunDirection.y;
                        if(sunDirection.y>0 || samplePosition.y*samplePosition.y * (1-sunDirection.y * sunDirection.y) >EarthRadius2)
                        {

                            float segmentLengthLight = lightLength / numSamplesLight;
                            float tCurrentLight = 0; 
                            float opticalDepthLightR = 0, opticalDepthLightM = 0; 
                            int j; 
                            for (j = 0; j < numSamplesLight; ++j) { 
                                float3 samplePositionLight = samplePosition + (tCurrentLight + segmentLengthLight * 0.5f) * sunDirection; 
                                float heightLight = length(samplePositionLight) - EarthRadius; 
                                if (heightLight < 0) break; 
                                opticalDepthLightR += exp(-heightLight / atmosphereThicknessR) * segmentLengthLight; 
                                opticalDepthLightM += exp(-heightLight / atmosphereThicknessM) * segmentLengthLight; 
                                tCurrentLight += segmentLengthLight; 
                            } 
                            float3 tau = ScatterR * (opticalDepthR + opticalDepthLightR) + ScatterM * 1.1f * (opticalDepthM + opticalDepthLightM); 
                            float3 attenuation = float3(exp(-tau.x), exp(-tau.y), exp(-tau.z)); 
                            sumR += attenuation * hr; 
                            sumM += attenuation * hm; 
                        }
                        tCurrent += segmentLength; 
                    } 
                    
                    col = (sumR * ScatterR * phaseR + sumM * ScatterM * phaseM) * 20;
                }

                return half4(col, 1);
            }
            ENDCG
        }
    }
}
