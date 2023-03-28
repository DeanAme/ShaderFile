Shader "Shader/Water" {
    
    Properties {
        _MainTex("MainTex", 2D) = "white"{}
        _WrapTex("WrapTex", 2D) = "gray"{}
        _Speed("X:SpeedX Y：SpeedY", range(0, 10)) = 5
        _Wrap1Params("X：Size Y：SpeedX Z:SpeedY W：Intensity", vector) = (1.0, 0.2, 0.2, 1.0)
        _Wrap2Params("X：Size Y：SpeedX Z:SpeedY W：Intensity", vector) = (1.0, 0.2, 0.2, 1.0)
    }
    SubShader {
        Tags {
            
            "RenderType"="Opaque"
            
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
           
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
            uniform sampler2D  _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D  _WrapTex;
            uniform half  _Speed;
            uniform half4 _Wrap1Params;
            uniform half4 _Wrap2Params;
           struct VertexInput {
                float4 vertex : POSITION;
                float2 uv :TEXCOORD0 ;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 :TEXCOORD0 ;
                float2 uv1 :TEXCOORD1 ;
                float2 uv2 :TEXCOORD2 ;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos( v.vertex );
                o.uv0 = v.uv - frac(_Time.x * _Speed);
                o.uv1 = v.uv * _Wrap1Params .x + frac(_Time.x * _Wrap1Params.yz);
                o.uv2 = v.uv * _Wrap2Params. x + frac(_Time.x * _Wrap2Params.yz);
                return o;
            }
            half4 frag(VertexOutput i) : COLOR {

                 half3 var_Wrap1= tex2D( _WrapTex, i.uv1).rgb;
                 half3 var_Wrap2= tex2D( _WrapTex, i.uv2).rgb;
                 half2 warp =(var_Wrap1.xy - 0.5) * _Wrap1Params.w +(var_Wrap2.xy - 0.5) * _Wrap2Params.w;
                 float2 wrapUV = i.uv0 + warp ;
                 half4 var_MainTex = tex2D( _MainTex, wrapUV );
                 return half4(var_MainTex.xyz, 1.0);
            }
            ENDCG
            
        }
    }
    FallBack "Diffuse"
    
}
