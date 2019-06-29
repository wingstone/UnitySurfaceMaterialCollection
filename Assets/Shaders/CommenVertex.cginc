#ifndef _COMMENVERTEX_
#define _COMMENVERTEX_


struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	float2 uv : TEXCOORD0;
	float3 worldPos : TEXCOORD1;

	UNITY_LIGHTING_COORDS(2, 3)

		float3 tangent : TEXCOORD4;
	float3 binormal : TEXCOORD5;
	float3 normal : TEXCOORD6;

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


	UNITY_TRANSFER_LIGHTING(o, v.uv);
	return o;
}


#endif