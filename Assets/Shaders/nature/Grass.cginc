struct VS_IN
{
	float4 vertex		: POSITION;
	float2 uv			:TEXCOORD0;
	float3 normal		: NORMAL;
	float4 tangent		: TANGENT;
};

struct GS_IN
{
	float2 uv			: TEXCOORD0;
	float4 pos			: TEXCOORD1;
	float3 normal		: NORMAL;
	float4 tangent		: TANGENT;
};

struct FS_IN
{
	float4 vertex		: SV_POSITION;
	float2 uv			: TEXCOORD0;
	float3 wPos			: TEXCOORD1;
	float3 wNor			: NORMAL;
	float3 wTan			: TANGENT;
	float3 color		: TEXCOORD2;
};

struct TessellationFactors 
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

GS_IN vert(VS_IN v)
{
	GS_IN o = (GS_IN)0;
	o.uv = v.uv;
	o.pos = v.vertex;
	o.normal = v.normal;
	o.tangent = v.tangent;
	return o;
}


float _TessellationUniform;

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
	MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
	MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)

	return v;
}

float _GrassHight;
float _GrassWidth;

half3 _WindDirection;
half _WindIntensity;

half4 _TopColor;
half4 _BottomColor;
sampler2D _RandomTex;

//stream 好像默认使用triangle strip来表示
[maxvertexcount(11)]
void geom(point GS_IN input[1], inout TriangleStream<FS_IN> OutputStream)
{
	FS_IN o = (FS_IN)0;

	half3 normal = input[0].normal;
	half3 tangent = input[0].tangent;
	half3 wpos = mul(unity_ObjectToWorld, input[0].pos).xyz;
	half3 windFactor = normalize(_WindDirection) * _WindIntensity * sin(_Time.y) * (sin(wpos.x + wpos.z + _Time.y)*0.5+0.5);

	o.wNor = UnityObjectToWorldNormal(normal);
	o.wTan = UnityObjectToWorldDir(tangent).xyz;
	o.uv = input[0].uv;

	for (int i = 0; i < 4; i++)
	{
		half hight = i * _GrassHight / 4;
		half width = _GrassWidth * 0.5 * (4 - i) / 4;

		half3 bottomOffset = hight * hight * windFactor;

		//triangle strip
		o.wPos = wpos + half3(-width, hight, 0) + bottomOffset;
		o.vertex = mul(UNITY_MATRIX_VP, half4(o.wPos, 1));
		o.color = lerp(_BottomColor.rgb, _TopColor.rgb, i / 4.0);
		OutputStream.Append(o);

		o.wPos = wpos + half3(width, hight, 0) + bottomOffset;
		o.vertex = mul(UNITY_MATRIX_VP, half4(o.wPos, 1));
		o.color = lerp(_BottomColor.rgb, _TopColor.rgb, i / 4.0);
		OutputStream.Append(o);
	}

	half bottomH = 3 * _GrassHight / 4;
	half upH = _GrassHight;
	half bottomW = _GrassWidth * 0.5 / 4;
	half upW = 0;
	half3 bottomOffset = bottomH * bottomH * windFactor;
	half3 upOffset = upH * upH * windFactor;

	//top triangle
	OutputStream.RestartStrip();
	o.wPos = wpos + half3(-bottomW, bottomH, 0) + bottomOffset;
	o.vertex = mul(UNITY_MATRIX_VP, half4(o.wPos, 1));
	o.color = lerp(_BottomColor.rgb, _TopColor.rgb, 3 / 4.0);
	OutputStream.Append(o);

	o.wPos = wpos + half3(bottomW, bottomH, 0) + bottomOffset;
	o.vertex = mul(UNITY_MATRIX_VP, half4(o.wPos, 1));
	o.color = lerp(_BottomColor.rgb, _TopColor.rgb, 3 / 4.0);
	OutputStream.Append(o);

	o.wPos = wpos + half3(-upW, upH, 0) + upOffset;
	o.vertex = mul(UNITY_MATRIX_VP, half4(o.wPos, 1));
	o.color = _TopColor.rgb;
	OutputStream.Append(o);
}

float4 frag(FS_IN i) : SV_Target
{
	return float4(i.color, 1);
}