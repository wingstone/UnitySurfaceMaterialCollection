Shader "Custom/ShaderGUITest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Alpha("Alpha", Range(0,1)) = 1.0
		_SurfaceType("SurfaceType", Int) = 0
		_BlendMode ("BlendMode", Int) = 0
		_Cull("__cull", Int) = 0
		_ZWrite("__zwrite", Int) = 1
		_SrcBlend("__srcblend", Int) = 1
		_DstBlend("__dstblend", Int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

		Cull [_Cull]
		ZWrite [_ZWrite]
		Blend [_SrcBlend] [_DstBlend]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			half _Alpha;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
				col.a = _Alpha;
                return col;
            }
            ENDCG
        }
    }

	CustomEditor "ShaderGUITest"
}
