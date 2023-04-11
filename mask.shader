Shader "Particles/hit/mask"
{
    Properties
    {
        _Mask("Mask", 2D) = "white" {}
        _Noise1("Noise1", 2D) = "white" {}
        _Noise2("Noise2", 2D) = "white" {}
        _Scale1("缩放噪声1", Range(0,2)) = 0.5
        _Scale2("缩放噪声2", Range(0,2)) = 0.5
        _Color("2噪声颜色", Color) = (1,0.5,0,0)
        _Tint("最亮颜色", Color) = (1,1,0,0)
        _EdgeColor("基础颜色", Color) = (1,0.5,0,0) 
        _Fuzziness("平滑距离", Range(0,2)) = 0.6
        _Stretch("平滑位置", Range(0,4)) = 0.4
		_Delay("延迟溶解", Range(0,1)) = 0
       [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("Blend Op", Int) = 0// 0 = add, 4 = max, other ones probably won't look good
    }
     HLSLINCLUDE
    #pragma vertex vert
    #pragma fragment frag
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"	
    ENDHLSL
    SubShader
    {
       
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "PreviewType" = "Plane" "RenderPipeline"="UniversalRenderPipeline"}
			Blend One OneMinusSrcAlpha
			ColorMask RGB
			Cull Off Lighting Off ZWrite Off
			ZTest Always
			BlendOp[_BlendOp]

        Pass
        {
            HLSLPROGRAM
            struct a2v
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
                float4 color:COLOR;
                float4 normal:NORMAL;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 color:COLOR;
           
            };

            sampler2D  _Mask, _Noise1,  _Noise2;
            float4 _Mask_ST, _Tint, _EdgeColor, _Color, _Noise1_ST,_Noise2_ST;
            float  _Scale1, _Fuzziness, _Stretch;
            float  _Delay, _Scale2;

            v2f vert (a2v v)
            {
                v2f o;			
				o.uv.xy = TRANSFORM_TEX(v.uv.xy, _Mask);
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv.z = v.uv.z - _Delay;// subtract a number to delay the dissolve
				o.color = v.color;	
              	return o;

            }

            half4 frag (v2f i) : SV_Target
            {
            half4 mask = tex2D(_Mask, i.uv.xy);//tex2D读取遮罩
			half4 noise1 = tex2D(_Noise1, i.uv.xy  * -_Scale1);//控制噪声1的大小
			half4 noise2 = tex2D(_Noise2, i.uv.xy * _Scale2);//...
			float combinedNoise = (noise1.r + noise2.r) / 1.65; //读取r通道并且混合
		    float dissolve = smoothstep(i.uv.z, _Stretch * i.uv.z + _Fuzziness, combinedNoise);// 溶解的不等数值在生命周期平滑变化
			float4 color = lerp(_EdgeColor,_Tint, dissolve) ;// E+（E-T）*溶解数值算出一个不同值需要映射的颜色
            
			color += (noise2 * _Color); //噪声2有颜色叠加上
			color *= dissolve; //叠加溶解数值
			color *= i.color; //进入颜色通道				
			color *= mask.a; //乘以遮罩
			return color;
            }
            ENDHLSL
        }
    }
}
