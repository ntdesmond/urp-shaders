Shader "Custom/Blinn-Phong"
{
    Properties
    {
        [MainTexture]
        _BaseMap("Texture", 2D) = "white" {}
        [MainColor]
        _DiffuseColor("Diffuse Color", Color) = (1, 1, 1, 1)
        _SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
        _Intensity("Specular Intensity", Range(1, 10)) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vertex
            #pragma fragment fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct vertex_input
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct fragment_input
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal_ws : TEXCOORD1;
                float3 object_pos : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _BaseMap_ST;
            float4 _DiffuseColor;
            float4 _SpecularColor;
            float _Intensity;
            
            CBUFFER_END

            fragment_input vertex (vertex_input vertex_data)
            {
                fragment_input fragment_data;
                float3 pos_os = vertex_data.vertex.xyz;
                
                fragment_data.vertex = TransformObjectToHClip(pos_os);
                fragment_data.uv = TRANSFORM_TEX(vertex_data.uv, _BaseMap);
                fragment_data.normal_ws = TransformObjectToWorldNormal(vertex_data.normal);
                fragment_data.object_pos = mul(unity_ObjectToWorld, vertex_data.vertex).xyz;
                return fragment_data;
            }

            float light_attenuation(const Light light, const fragment_input fragment_data)
            {
                return max(0, dot(fragment_data.normal_ws, light.direction));
            }
            
            float4 fragment (fragment_input fragment_data) : SV_Target
            {
                // Get albedo
                const float4 albedo = _DiffuseColor * SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, fragment_data.uv);

                // Get the light attenuation
                const Light light = GetMainLight();
                const float attenuation = light_attenuation(light, fragment_data);

                // Add the specular light
                float specular_intensity = 0;
                if (attenuation > 0)
                {
                    const float3 view_direction = normalize(_WorldSpaceCameraPos - fragment_data.object_pos);
                    const float3 half_vector = normalize(view_direction + light.direction);
                    specular_intensity = pow(
                        max(0, dot(fragment_data.normal_ws, half_vector)),
                        pow(2, 10 - _Intensity)
                    );
                }

                return max(
                    albedo * attenuation + _SpecularColor * specular_intensity,
                    albedo * attenuation
                );
            }
            ENDHLSL
        }
    }
}