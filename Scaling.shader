Shader "Shader/Scaling" {
    
    Properties {
       _MainTex("RGB：MainTex，A:TransparentTex", 2D) = "gray"{}
       _Opacity("Opacity", range(0,1)) = 0.5
       _ScaleSpeed("ScaleSpeed", range(0, 10)) = 0.5
       _ScaleRange("ScaleRange", range(0, 1)) = 0.5
    }
    SubShader {
        Tags {
            "Queue" = "Transparent"
            "RenderType"="Transparent"
            "ForceNoShadowCasting" = "True"
            "IgnoreProjector" = "True"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend One OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float     _ScaleSpeed;
            uniform float     _ScaleRange;
            uniform half      _Opacity;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 uv :TEXCOORD0 ;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv :TEXCOORD0 ;
            };
            #define TWO_PI 6.283185
            void Scaling(inout float3 vertex ){
                vertex*= 1.0 + _ScaleRange * sin(frac(_Time.z*_ScaleSpeed)* TWO_PI);
            }
            
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                Scaling(v.vertex.xyz);
                o.pos = UnityObjectToClipPos( v.vertex );
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            half4 frag(VertexOutput i) : COLOR {
                 half4 var_MainTex = tex2D(_MainTex, i.uv);
                 half3 finalRGB = var_MainTex.rgb;
                 half opacity = var_MainTex.a *  _Opacity;
                 return half4( finalRGB *opacity, opacity);
            }
            ENDCG
            
        }
    }
    
}
