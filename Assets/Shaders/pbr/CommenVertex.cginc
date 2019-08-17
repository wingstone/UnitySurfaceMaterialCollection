#ifndef _COMMENVERTEX_
#define _COMMENVERTEX_


struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;	//for lightmap
};

struct v2f
{
	float2 uv : TEXCOORD0;

	float3 worldPos : TEXCOORD1;
	float3 tangent : TEXCOORD2;
	float3 binormal : TEXCOORD3;
	float3 normal : TEXCOORD4;
	float4 ambientOrLightmapUV : TEXCOORD5;
	LIGHTING_COORDS(6, 7)

	float4 pos : SV_POSITION;		//shadow宏要求此处必须为pos变量，shit。。。
};


v2f vert(appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
	o.uv = v.uv;

	o.normal = UnityObjectToWorldNormal(v.normal);
	o.tangent = UnityObjectToWorldDir(v.tangent.xyz);

	half3x3 tangentToWorld = CreateTangentToWorldPerVertex(o.normal, o.tangent, v.tangent.w);
	o.tangent = tangentToWorld[0];
	o.binormal = tangentToWorld[1];
	o.normal = tangentToWorld[2];

	//unity reference
//	inline half4 VertexGIForward(VertexInput v, float3 posWorld, half3 normalWorld)
//	{
//		half4 ambientOrLightmapUV = 0;
//		// Static lightmaps
//#ifdef LIGHTMAP_ON
//		ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
//		ambientOrLightmapUV.zw = 0;
//		// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
//#elif UNITY_SHOULD_SAMPLE_SH
//#ifdef VERTEXLIGHT_ON
//	// Approximated illumination from non-important point lights
//		ambientOrLightmapUV.rgb = Shade4PointLights(
//			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
//			unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
//			unity_4LightAtten0, posWorld, normalWorld);
//#endif
//
//		ambientOrLightmapUV.rgb = ShadeSHPerVertex(normalWorld, ambientOrLightmapUV.rgb);
//#endif
//
//#ifdef DYNAMICLIGHTMAP_ON
//		ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
//#endif
//
//		return ambientOrLightmapUV;
//	}
	o.ambientOrLightmapUV = 0;
#ifdef LIGHTMAP_ON
	ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	ambientOrLightmapUV.zw = 0;
	// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
#elif UNITY_SHOULD_SAMPLE_SH

	half4 ambientOrLightmapUV = 0;
#ifdef VERTEXLIGHT_ON

	// Approximated illumination from non-important point lights
	ambientOrLightmapUV.rgb = Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, posWorld, normalWorld);
#endif

	ambientOrLightmapUV.rgb = ShadeSHPerVertex(o.normal, ambientOrLightmapUV.rgb);
	o.ambientOrLightmapUV.rgb = ambientOrLightmapUV.rgb;
#endif

	//We need this for shadow receving
	UNITY_TRANSFER_LIGHTING(o, v.uv);
	return o;
}


#endif