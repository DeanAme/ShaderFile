Shader "Shader/3Col" {
    
    Properties {
        [Header(Texture)]
        _MainTex ("RGB：MainTex A：EnvOccusion", 2D) = "white"{}
        _NormalTex("RGB:Normal", 2D) = "bump"{}
        _CubeMap("RGB:Env", CUBE) = "_skybox"{}
        _SpecTex("RGB:SpecularTex A：SpecularPower", 2D) = "gray"{}
        _EmitTex("RGB:Emission", 2D) =  "black"{}
        [Header(Diffuse)]
        _MainCol("MainCol", color) = (0.5, 0.5, 0.5, 1.0)
        _EnvDiffInt("EnvDiffInt", range(0,1)) = 0.2
        _EnvUpCol("EnvUpCol", color) = (1.0, 1.0, 1.0, 1.0)
        _EnvSideCol("EnvSideCol", color) =(0.5, 0.5, 0.5, 0.5)
        _EnvDownCol("EnvDownCol", color) =(0.0, 0.0, 0.0, 0.0)
        [Header(Specular)]
        _SpecPow("SpecularPow", range(0,90)) = 30
        _FresnelPow("FresnelPow", range(0,5)) = 1
        _CubemapMip("CubemapMip", range(1,7)) = 1
        _EnvSpecInt("EnvSpecInt", range(0,5)) = 0.2
        [Header(Emission)]
        _EmitInt ("EmitInt", range(1,10)) = 1
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
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
            
            uniform sampler2D  _MainTex;
            uniform sampler2D _NormalTex;
            uniform sampler2D _SpecTex;
            uniform sampler2D _EmitTex;
            uniform samplerCUBE _CubeMap;
            
            uniform float3  _MainCol;
            uniform float3  _EnvUpCol;
            uniform float3  _EnvSideCol;
            uniform float _EnvDiffInt;
            uniform float3 _EnvDownCol;
            
            uniform float _SpecPow;
            uniform float _FresnelPow;
            uniform float _CubemapMip;
            uniform float _EnvSpecInt;
            
            uniform float _EmitInt; 
             
             
            struct VertexInput {   
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 uv0 : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWS : TEXCOORD1;
                float3 tDirWS: TEXCOORD2;
                float3 bDirWS: TEXCOORD3;
                float3 nDirWS: TEXCOORD4;
                LIGHTING_COORDS(5, 6)    
            };
            
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos( v.vertex );
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.tDirWS = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS)*v.tangent.w);
                o.uv0 = v.uv0;
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
               
               float3 nDirTS = UnpackNormal(tex2D( _NormalTex, i.uv0)).rgb;
               float3x3 TBN =  float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
               float3 nDirWS = normalize(mul(nDirTS, TBN));
               float3 lDirWS = _WorldSpaceLightPos0.xyz;
               float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz -i.posWS.xyz);
               float3 rDirWS = reflect(-lDirWS, nDirWS);
               float3 vrDirWS = reflect(-vDirWS, nDirWS);
               
               float ndotl = dot(nDirWS,  lDirWS );
               float vdotr = dot(vDirWS,  rDirWS );
               float vdotn = dot(vDirWS,  nDirWS );
               
               float4 var_MainTex = tex2D(_MainTex, i.uv0);
               float4 var_SpecTex = tex2D(_SpecTex, i.uv0);
               float3 var_EmitTex = tex2D(_EmitTex, i.uv0).rgb;
          
               
               float3 var_Cubemap = texCUBElod(_CubeMap,float4(vrDirWS, lerp(_CubemapMip, 1.0, var_SpecTex.a))).rgb;
               
                
                 
                 float lambert = max(0.0, ndotl);
                 float3 baseCol = var_MainTex.rgb * _MainCol;
                 
                 float specCol = var_SpecTex.rgb;
                 float specPow = lerp(1.0, _SpecPow, var_SpecTex.a);
                 float phong = max((0.0, vdotr), specPow);
                 
                 float shadow = LIGHT_ATTENUATION(i);
                 float3 dirLighting = (baseCol * lambert + specCol *phong) * _LightColor0 * shadow;
                 
                 float upMask = max(0.0, nDirWS.g);
                 float sideMask = max(0.0, -nDirWS.g);
                 float downMask = 1.0 - sideMask -upMask;
                 float envCol = _EnvUpCol * upMask + _EnvSideCol *  sideMask + downMask *_EnvDownCol;
                 float3 envDiff = baseCol * envCol *  _EnvDiffInt;           
                 
                float fresnel = pow(max(0.0, 1.0-vdotn), _FresnelPow);
                float3 envSpec = var_Cubemap * fresnel *  _EnvSpecInt;
                 
                 float occlusion =   var_MainTex.a;
                 float3 envlighting = (envSpec + envDiff) * occlusion;
                 
                 float3 emission = var_EmitTex * _EmitInt;
                 
                 float3 finalRGB = dirLighting + envlighting + emission;
                
                 return float4(finalRGB, 1.0) ;
            }
            ENDCG
            
        }
    }
    FallBack "Diffuse"
    
}
