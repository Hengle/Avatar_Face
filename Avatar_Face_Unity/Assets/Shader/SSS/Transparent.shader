﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "QQ/SSS/Transparent"
{
	Properties
	{
		_Color("color",Color) = (0.5,0.5,0.5,1)
		_Specular("specular color",Color) = (0.5,0.5,0.5,1)
		_Smoothness("smoothness",Range(0,1)) = 0.5
		_ViewColor("view color",Color) = (0.5,0.5,0.5,1)
		_EdgeColor("edge color",Color) = (0.5,0.5,0.5,0.5)
		_Emission("emission",Color) = (0,0,0,1)
		_MainTex("texture", 2D) = "white" {}
		_BumpPower("bump power",Range(-1,1)) = 0.5
		[NoScaleOffset]_BumpMap("bump",2D) = "bump" {}
		[NoScaleOffset]_AOMap("ao map",2D) = "white" {}
		_Cut("cut",Range(0,1)) = 0.5
		[Enum(Off, 0, On, 1)] _ZWrite("ZWrite", float) = 1
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", float) = 2
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", float) = 10
	}
		SubShader
		{
			Tags { 
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent" 
			"Queue" = "Transparent"
			}
			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]
			Cull[_Cull]
			LOD 100
			Pass
			{
			Tags{
			"LightMode" = "ForwardBase"
			}
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fwdbase_fullshadows
				#pragma multi_compile_fog
				#include "UnityCG.cginc"
				#include "AutoLight.cginc"
			struct a2v
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:TEXCOORD1;
				float4 wPos:TEXCOORD2;
				UNITY_FOG_COORDS(3)
				LIGHTING_COORDS(4, 5)
			};
			fixed4 _LightColor0;
			fixed4 _Color;
			fixed4 _Specular;
			fixed4 _ViewColor;
			fixed4 _EdgeColor;
			fixed4 _Emission;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			sampler2D _AOMap;
			float _Metallic;
			float _Smoothness;
			float _BumpPower;
			float _Cut;
			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//tex
				float4 tex = tex2D(_MainTex, i.uv);
				float3 _tex = (tex*_Color).rgb;
				float4 ao = tex2D(_AOMap, i.uv);
				//normal
				float3 nor = UnpackNormal(tex2D(_BumpMap, i.uv));
				nor = normalize(i.normal + nor.xxy*float3(2,0,2)*_BumpPower);
				//light
				float3 lightColor = LIGHT_ATTENUATION(i)*_LightColor0.rgb;
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos);
				//diffuse
				float diff = max(0, dot(nor, normalize(_WorldSpaceLightPos0.xyz)));
				float3 diffColor = diff * lightColor * _tex;
				//specular
				float lightDir = saturate(dot(nor, _WorldSpaceLightPos0.xyz));
				float smooth = _Smoothness * _Smoothness * pow(10,_Smoothness * 4);
				float spec = saturate(dot(nor, normalize(_WorldSpaceLightPos0.xyz + viewDir)));
				spec = pow(spec, smooth)*smooth*4e-2;
				float3 specColor = spec * lightColor * _Specular * lightDir * ao;
				//Camera
				float view = saturate(dot(nor, normalize(viewDir)));
				float viewSpec = pow(view, smooth)*smooth*4e-2;
				float3 viewColor = (view * _tex + viewSpec * ao) * _ViewColor * _ViewColor.a;
				//emission
				float3 emission = _tex * ao * _Emission;
				//final 
				tex.a = max(tex.a - _Cut,0)/ (1-_Cut);
				float4 col = tex * float4(UNITY_LIGHTMODEL_AMBIENT.rgb, 1);
				col.rgb += max(diffColor + specColor, viewColor) + emission;
				col.rgb += col.rgb * _EdgeColor.rgb * (1 - view) * (_EdgeColor.a * 4 - 2);
				col.rgb *= tex.a;
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
				Pass{
				Tags{
				"LightMode" = "ShadowCaster"
			}
				Offset 1, 1

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#define UNITY_PASS_SHADOWCASTER
				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#pragma multi_compile_shadowcaster
				#pragma multi_compile_fog
				#pragma target 3.0
				sampler2D _MainTex;
				float4 _MainTex_ST;
			struct a2v {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			struct v2f {
				V2F_SHADOW_CASTER;
				float2 uv : TEXCOORD1;
			};
			v2f vert(a2v v) {
				v2f o;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.pos = UnityObjectToClipPos(v.vertex);
				TRANSFER_SHADOW_CASTER(o)
					return o;
			}
			float4 frag(v2f i) : COLOR{
				float4 col = tex2D(_MainTex,i.uv);
				clip(col.a - 0.5);
				SHADOW_CASTER_FRAGMENT(i)
			}
				ENDCG
			}
		}
}
