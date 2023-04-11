Shader "Particles/VertexSpikeDissolve"
{
	Properties
	{
		_Noise("尖刺噪声", 2D) = "white" {}
		_Scale("尖刺噪声读取范围", Range(0,10)) = 0.5
		_NoiseFrag("底噪", 2D) = "white" {}	
		_FragScale("底噪尺寸", Range(0,2)) = 0.5
		_ExtraNoise("顶噪", 2D) = "white" {}
		_ExtraScale("顶噪尺寸", Range(0,2)) = 0.5
		[HDR]_Color("顶噪颜色", Color) = (1,0.5,0,0)
		[HDR]_Tint("高光色", Color) = (1,1,0,0) // Color of the dissolve Line
		[HDR]_EdgeColor("底色", Color) = (1,0.5,0,0) // Color of the dissolve Line)
		_Fuzziness("作用周期范围", Range(0,2)) = 0.3
		_Stretch("作用周期定位", Range(0,4)) = 2
		//_Growth("Growth", Range(0,2)) = 0
		_Spike("膨胀距离", Range(0,2)) = 1
		_Cutoff("切断阀值", Range(0,1)) = 0.9
		_Delay("生成时间", Range(0,2)) = 0
		//[Toggle(SOFT)] _SOFT("没尖刺", Float) = 0
		
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
			Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "PreviewType" = "Plane" "RenderPipeline"="UniversalRenderPipeline" }
			Blend One OneMinusSrcAlpha
			ColorMask RGB
			Cull Off Lighting Off ZWrite Off
			ZTest Always			
			Pass
			{
            HLSLPROGRAM
		

				struct a2v
				{
					float4 vertex : POSITION;
					float3 uv : TEXCOORD0;
					float4 color : COLOR;
					float4 normal :NORMAL;
				};

				struct v2f
				{
					float3 uv : TEXCOORD0; 
					float4 vertex : SV_POSITION;
					float4 color: COLOR;
					float4 normal:NORMAL;
					
				};
				sampler2D _Noise, _NoiseFrag, _ExtraNoise;
				float4 _Noise_ST, _Tint, _EdgeColor, _Color;
				float _Scale, _Cutoff, _Fuzziness, _Stretch, _EdgeWidth, _Spike;
				float _Delay, _ExtraScale, _FragScale;
				//_Growth
				v2f vert(a2v v)
				{
					v2f o;				
					o.uv.xy = TRANSFORM_TEX(v.uv.xy, _Noise);//读取一定范围的噪声作为UV
					float3 noise = tex2Dlod(_Noise, float4(v.uv.xy * _Scale, 1, 1));// 尖刺噪声（控制后）样子
					
/* #if SOFT
					v.vertex.xyz +=  (noise.r* v.normal) * _Spike;//顶点加上法线方向的膨胀距离，数值由尖刺噪声决定
#else */
					v.vertex.xyz += step(_Cutoff, noise.r) * (v.normal * _Spike);// 顶点加上法线上碰撞距离乘以0/1；这个由是否超过切断阈值决定
//#endif		
					//v.vertex.xyz += (v.normal *  (v.uv.z)) * _Growth;// increase overall size over particle age
					//TODO:为啥一定要转到裁剪空间
					o.vertex = TransformObjectToHClip(v.vertex.xyz);
					o.uv.z = v.uv.z - _Delay;//减去一定的生命周期，总之就是开放给美术控制的
					o.color = v.color;			
					return o;
				}

				half4 frag(v2f i) : SV_Target
				{
					half4 noise = tex2D(_NoiseFrag, i.uv.xy  * _FragScale);// 叠第一层溶解底噪
					half4 extraTexture = tex2D(_ExtraNoise, i.uv.xy * _ExtraScale);// 叠第二层溶解顶噪
					float combinedNoise = (noise.r + extraTexture.r) / 2; // 两层底噪混合
					float dissolve = smoothstep( i.uv.z, _Stretch * i.uv.z + _Fuzziness, combinedNoise);//自然过渡噪声
					float4 color = lerp(_EdgeColor,_Tint, dissolve.r);//高光到基本颜色的附着
					color += (extraTexture * _Color); // 增加顶噪以及颜色
					color *= dissolve; //控制形状
					color *= i.color;// 读取颜色				
					return color;

				}
				ENDHLSL
			}
		}
}