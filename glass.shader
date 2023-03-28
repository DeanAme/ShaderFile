Shader "Shader/Glass"
{
	Properties
	{	
		_BumpMap("NormalMap", 2D) = "bump" {}						
		_Distortion("Distortion",Range(0,2)) = 1				//control the degree of distortion of the image during refraction
		_RefractAmount("RefractAmount", Range(0.0,1.0)) = 1.0	//Balance of reflection and refraction values
	}
	SubShader
	{ 
		Tags { "RenderType" = "Opaque" "Queue" = "Transparent"}
		GrabPass{"_RefractionTex"}		//Define a screen grab image via GrabPass
		LOD 100
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			sampler2D _RefractionTex;
			sampler2D _BumpMap;
			
			float _Distortion;
			float _RefractAmount;


            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
            };

            struct VertexOutput
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
				float4 posWS :TEXCOOND5;
				float4 scrPos: TEXCOORD1;
				float3 nDirWS :TEXCOORD2;	
				float3 tDirWS :TEXCOORD3;
				float3 bDirWS :TEXCOORD4;	
            sampler2D _MainTex;
            float4 _MainTex_ST;
			half4 _Color;
			VertexOutput vert (VertexInput v)
            {
				VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.scrPos = ComputeGrabScreenPos(o.pos);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (VertexOutput i) : SV_Target
            {
				float3 nDirTS = UnpackNormal(tex2D(_BumpMap,i.uv));
				float2 offset = nDirTS.xy*_Distortion;
				i.scrPos.xy += offset;
				fixed4 RefractionCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w);
				float3 finalCol = RefractionCol;
                return fixed4(finalCol,1.0);
            }
            ENDCG
        }
    }
}