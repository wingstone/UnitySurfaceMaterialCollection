struct vsInput
{
	float4 vertex		: POSITION;
	float2 uv			:TEXCOORD0;
	float3 normal		: NORMAL;
	float4 tangent		: TANGENT;
};

struct gsInOutput
{
	float4 vertex		: SV_POSITION;
	float2 uv			: TEXCOORD0;
	float4 wpos			: TEXCOORD1;
	float3 normal		: NORMAL;
	float4 tangent		: TANGENT;
};

struct TessellationFactors 
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

gsInOutput vert(vsInput v)
{
	gsInOutput o = (gsInOutput)0;
	o.vertex = v.vertex;
	o.uv = v.uv;
	o.wpos = mul(unity_ObjectToWorld, v.vertex);
	o.normal = v.normal;
	o.tangent = v.tangent;
	return o;
}


float _TessellationUniform;

TessellationFactors patchConstantFunction (InputPatch<gsInOutput, 3> patch)
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
gsInOutput hull (InputPatch<gsInOutput, 3> patch, uint id : SV_OutputControlPointID)
{
	return patch[id];
}

#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
	patch[0].fieldName * barycentricCoordinates.x + \
	patch[1].fieldName * barycentricCoordinates.y + \
	patch[2].fieldName * barycentricCoordinates.z;

[UNITY_domain("tri")]
gsInOutput domain(TessellationFactors factors, OutputPatch<gsInOutput, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
	gsInOutput v;

	MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
	MY_DOMAIN_PROGRAM_INTERPOLATE(wpos)
	MY_DOMAIN_PROGRAM_INTERPOLATE(uv)
	MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
	MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)

	return v;
}

float _GrassHeight;
float _GrassWidth;

[maxvertexcount(3)]
void geom(point gsInOutput input[1], inout TriangleStream<gsInOutput> OutputStream)
{
	gsInOutput test = (gsInOutput)0;

	test.normal = UnityObjectToWorldNormal(input[0].normal);
	test.vertex = mul(UNITY_MATRIX_VP, input[0].wpos + half4(-_GrassWidth * 0.5, 0, 0, 0));
	test.uv = input[0].uv;
	OutputStream.Append(test);
	test.normal = UnityObjectToWorldNormal(input[0].normal);
	test.vertex = mul(UNITY_MATRIX_VP, input[0].wpos + half4(_GrassWidth * 0.5, 0, 0, 0));
	test.uv = input[0].uv;
	OutputStream.Append(test);
	test.normal = UnityObjectToWorldNormal(input[0].normal);
	test.vertex = mul(UNITY_MATRIX_VP, input[0].wpos + half4(0, _GrassHeight, 0, 0));
	test.uv = input[0].uv;
	OutputStream.Append(test);

}


float4 _Color;

float4 frag(gsInOutput i) : SV_Target
{
	return _Color;
}