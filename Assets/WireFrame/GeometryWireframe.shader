//https://developer.download.nvidia.cn/SDK/10/direct3d/Source/SolidWireframe/Doc/SolidWireframe.pdf
//https://catlikecoding.com/unity/tutorials/advanced-rendering/flat-and-wireframe-shading/
//https://www.bilibili.com/read/cv3168157
//https://www.jianshu.com/p/e95e6507659c
Shader "Custom/GeometryWireframe"
{
    Properties
    {
        _Color("Main Color", Color) = (1,1,1,1)
        _WireFrameColor("WireFrame Color", Color) = (0,0,0,1)
        [Toggle(ENABLE_DRAWQUAD)]_DisplayQuad("DisplayQuad", Float) = 0
        [IntRange]_TessellationUniform("Tessellation Factor", Range(1, 10)) = 1
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

            // Tesselation
            #pragma hull hull
            #pragma domain domain
            
            // Geometry
            #pragma geometry geom

            #pragma fragment frag

            #pragma target 4.6
            
            #include "UnityCG.cginc"
            
            struct VS_IN
            {
                float4 vertex		: POSITION;
                float2 uv			: TEXCOORD0;    // xy:uv, z:length to edge
            };

            struct GS_IN
            {
                float2 uv			: TEXCOORD0;
                float4 pos			: TEXCOORD1;
            };

            struct FS_IN
            {
                float4 vertex		: SV_POSITION;
                float2 uv			: TEXCOORD0;
                float4 length2Edge		: TEXCOORD2;
            };

            struct TessellationFactors 
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            float _TessellationUniform;
            float4 _Color;
            float _DisplayQuad;
            float4 _WireFrameColor;
            float _WireFrameWidth;

            GS_IN vert(VS_IN v)
            {
                GS_IN o = (GS_IN)0;
                o.uv = v.uv;
                o.pos = v.vertex;
                return o;
            }

            TessellationFactors patchConstantFunction (InputPatch<GS_IN, 3> patch)
            {
                TessellationFactors f;
                f.edge[0] = _TessellationUniform;
                f.edge[1] = _TessellationUniform;
                f.edge[2] = _TessellationUniform;
                f.inside = _TessellationUniform;
                return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("integer")]
            [UNITY_patchconstantfunc("patchConstantFunction")]
            GS_IN hull (InputPatch<GS_IN, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
            patch[0].fieldName * barycentricCoordinates.x + \
            patch[1].fieldName * barycentricCoordinates.y + \
            patch[2].fieldName * barycentricCoordinates.z;

            [UNITY_domain("tri")]
            GS_IN domain(TessellationFactors factors, OutputPatch<GS_IN, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
            {
                GS_IN v;

                MY_DOMAIN_PROGRAM_INTERPOLATE(pos)
                MY_DOMAIN_PROGRAM_INTERPOLATE(uv)

                return v;
            }

            // calculate distance to edge in clip space;
            // is quad in world space
            [maxvertexcount(3)]
            void geom(triangle GS_IN input[3], inout TriangleStream<FS_IN> OutputStream)
            {
                FS_IN o = (FS_IN)0;

                // clip space
                float4 v0 = UnityObjectToClipPos(input[0].pos);
                float4 v1 = UnityObjectToClipPos(input[1].pos);
                float4 v2 = UnityObjectToClipPos(input[2].pos);
                float2 vxy0 = v0.xy/v0.w;
                float2 vxy1 = v1.xy/v1.w;
                float2 vxy2 = v2.xy/v2.w;
                float area = length(cross(float3(vxy1 - vxy0,0), float3(vxy2-vxy0, 0)))*0.5;
                
                float length2Edge0 = area/length(vxy2 - vxy1);
                float length2Edge1 = area/length(vxy2 - vxy0);
                float length2Edge2 = area/length(vxy1 - vxy0);

                float minid = 2;

                #ifdef ENABLE_DRAWQUAD
                    // world space
                    float4 w_v0 = mul(UNITY_MATRIX_M, input[0].pos);
                    float4 w_v1 = mul(UNITY_MATRIX_M, input[1].pos);
                    float4 w_v2 = mul(UNITY_MATRIX_M, input[2].pos);
                    w_v0 /= w_v0.w;
                    w_v1 /= w_v1.w;
                    w_v2 /= w_v2.w;
                    area = length(cross(w_v1.xyz - w_v0.xyz, w_v2.xyz - w_v0.xyz));
                    
                    float wlength2Edge0 = area*0.5/length(w_v2.xyz - w_v1.xyz);
                    float wlength2Edge1 = area*0.5/length(w_v2.xyz - w_v0.xyz);
                    float wlength2Edge2 = area*0.5/length(w_v1.xyz - w_v0.xyz);
                    
                    if(wlength2Edge0 < wlength2Edge1)
                    {
                        if(wlength2Edge0 < wlength2Edge2)
                            minid = 0;
                    }
                    else
                    {
                        if(wlength2Edge1 < wlength2Edge2)
                            minid = 1;
                    }
                #endif

                o.vertex = v0;
                o.uv = input[0].uv;
                o.length2Edge = float4(length2Edge0,0,0,minid);
                OutputStream.Append(o);

                o.vertex = v1;
                o.uv = input[1].uv;
                o.length2Edge = float4(0,length2Edge1,0,minid);
                OutputStream.Append(o);

                o.vertex = v2;
                o.uv = input[2].uv;
                o.length2Edge = float4(0,0,length2Edge2,minid);
                OutputStream.Append(o);
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
