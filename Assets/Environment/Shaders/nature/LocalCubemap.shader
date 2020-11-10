// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/LocalCubemap"
{
    Properties
    {
        _BBoxMax ("_BBoxMax", Vector) = (1,1,1,1)
        _BBoxMin ("_BBoxMin", Vector) = (0,0,0,0)
        _EnviCubeMapPos("_EnviCubeMapPos", Vector) = (0.5,0.5,0.5,0.5)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct vertexInput
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct vertexOutput
            {
                float2 tex : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 vertexInWorld : TEXCOORD1;
                float3 viewDirInWorld : TEXCOORD2;
                float3 normalInWorld : TEXCOORD3;
            };

            sampler2D _MainTex;
            half3 _BBoxMax;
            half3 _BBoxMin;
            half3 _EnviCubeMapPos;

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;
                output.tex = input.texcoord;
                // Transform vertex coordinates from local to world.
                float4 vertexWorld = mul(unity_ObjectToWorld, input.vertex);
                // Transform normal to world coordinates.
                float4 normalWorld = mul(float4(input.normal, 0.0), unity_WorldToObject);
                // Final vertex output position.
                output.pos = UnityObjectToClipPos(input.vertex);
                // ----------- Local correction ------------
                output.vertexInWorld = vertexWorld.xyz;
                output.viewDirInWorld = vertexWorld.xyz - _WorldSpaceCameraPos;
                output.normalInWorld = normalWorld.xyz;
                return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                float4 reflColor = float4(1, 1, 0, 0);
                // Find reflected vector in WS.
                float3 viewDirWS = normalize(input.viewDirInWorld);
                float3 normalWS = normalize(input.normalInWorld);
                float3 reflDirWS = reflect(viewDirWS, normalWS);
                // Working in World Coordinate System.
                float3 localPosWS = input.vertexInWorld;
                float3 intersectMaxPointPlanes = (_BBoxMax - localPosWS) / reflDirWS;
                float3 intersectMinPointPlanes = (_BBoxMin - localPosWS) / reflDirWS;
                // Looking only for intersections in the forward direction of the ray.
                float3 largestRayParams = max(intersectMaxPointPlanes, intersectMinPointPlanes);
                // Smallest value of the ray parameters gives us the intersection.
                float distToIntersect = min(min(largestRayParams.x, largestRayParams.y), largestRayParams.z);
                // Find the position of the intersection point.
                float3 intersectPositionWS = localPosWS + reflDirWS * distToIntersect;
                // Get local corrected reflection vector.
                reflDirWS = intersectPositionWS - _EnviCubeMapPos;
                // Lookup the environment reflection texture with the right vector.
                // reflColor = texCUBE(_Cube, reflDirWS);
                // Lookup the texture color.
                // float4 texColor = tex2D(_MainTex, float2(input.tex));
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDirWS, 0);
                half3 color = DecodeHDR(rgbm, unity_SpecCube0_HDR);
                return half4(color, 1);
            }
            ENDCG
        }
    }
}
