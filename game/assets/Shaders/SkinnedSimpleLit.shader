#include "[assets]/Shaders/Language.shader"

#ifdef VERTEX
layout (location = 0) in vec3 Position;
layout (location = 1) in vec4 Color;
layout (location = 2) in vec3 Normal;
layout (location = 3) in vec3 Tangent;
layout (location = 4) in vec2 UV;
layout (location = 5) in ivec4 Bones;
layout (location = 6) in vec4 Weights;

layout (BINDING(0, 0), std140) uniform ConstantBuffer
{
    mat4 ViewMtx;
    mat4 ProjMtx;
    mat4 ViewProjMtx;
};

layout (BINDING(0, 1), std140) uniform ModelBuffer
{
    mat4 WorldMtx;
    mat4 MeshMtx;
    ivec4 LightIndices;
};

#define NUM_BONES 100
layout (BINDING(0, 2), std140) uniform Animation
{
    mat4 BoneMtx[NUM_BONES];
};

layout (location = 0) out vec3 Frag_Position;
layout (location = 1) out vec4 Frag_Color;
layout (location = 2) out vec3 Frag_Normal;
layout (location = 3) out vec3 Frag_Tangent;
layout (location = 4) out vec2 Frag_UV;
layout (location = 5) out vec3 Frag_View;
layout (location = 6) flat out ivec4 Frag_LightIndices;

void main()
{
    mat4 boneMtx = mat4(0);
    for (int i = 0; i < 4; i++)
    {
        if (Bones[i] == -1 || Bones[i] >= 100)
            continue;
        boneMtx += Weights[i] * BoneMtx[Bones[i]];
    }
    
    mat4 WorldBoneMeshMtx = WorldMtx * boneMtx * MeshMtx;
    vec4 WorldPosition = WorldBoneMeshMtx * vec4(Position, 1.0);
    
    Frag_Position = WorldPosition.xyz;
    Frag_Color = Color;
    Frag_Normal = (WorldBoneMeshMtx * vec4(Normal, 0.0)).xyz;
    Frag_Tangent = Tangent;
    Frag_UV = UV;
    Frag_View = -vec3(ViewMtx[0].z, ViewMtx[1].z, ViewMtx[2].z);

    Frag_LightIndices = LightIndices;

    gl_Position = ViewProjMtx * WorldPosition;
}
#endif

#ifdef PIXEL
layout (location = 0) out vec4 Out_Color;

layout (location = 0) in vec3 Frag_Position;
layout (location = 1) in vec4 Frag_Color;
layout (location = 2) in vec3 Frag_Normal;
layout (location = 3) in vec3 Frag_Tangent;
layout (location = 4) in vec2 Frag_UV;
layout (location = 5) in vec3 Frag_View;
layout (location = 6) flat in ivec4 Frag_LightIndices;

layout (BINDING(1, 3)) uniform sampler2D Albedo;

struct Light
{
    uint type;
    float intensity;

    int shadowMapIndex;
    uint cascadeCount;

    vec3 position;
    float constant;
    
    vec3 direction;
    float linear_cutoff;
    
    vec3 color;
    float quadratic_outerCutoff;
};

#define NUM_LIGHTS 10
layout (BINDING(0, 4), std140) uniform LightBuffer
{
    Light Lights[NUM_LIGHTS];
};
//uniform sampler2D ShadowMaps[NUM_LIGHTS];

const float INV_GAMMA_EXP  = 2.2;
const float GAMMA_EXP  = 0.45454545454;

vec3 FresnelSchlick(float cosTheta, vec3 F0)
{
    float a = pow(clamp(1.0 - cosTheta, 0.0, 1.0), 0.5);
    a = a * a * a * a * a;
    return F0 + (1.0 - F0) * a;
}

void main()
{
    vec3 N = normalize(Frag_Normal);

    vec4 albedo = texture(Albedo, Frag_UV);
    vec3 albedoLinear = pow(albedo.rgb, vec3(INV_GAMMA_EXP));

    vec3 Lo = vec3(0.0);
    for (int i = 0; i < 4; i++)
    {
        if (Frag_LightIndices[i] == -1 || Frag_LightIndices[i] >= 100)
            continue;

        Light light = Lights[Frag_LightIndices[i]];

        vec3 lightDir = normalize(light.position - Frag_Position);
        float diffuse = max(dot(N, lightDir), 0.0);

        // Attenuation
        float distance = length(light.position - Frag_Position);
        float attenuation = 1.0 / (light.constant + light.linear_cutoff * distance + light.quadratic_outerCutoff * (distance * distance));

        // Sample cubemap shadow map
        float shadow = 1; //sampleShadowCube(shadowCubeMaps[shadowMap.index], Frag_Position - light.position.xyz);
        
        Lo += albedoLinear.rgb * diffuse * light.color * light.intensity * attenuation * shadow;
    }

    vec3 kD = vec3(0.03);
    vec3 ambient = (kD * albedoLinear.rgb);// * ao;

    // Final irradiance
    vec3 I = ambient + Lo;

    // HDR tonemapping
    I = I / (I + vec3(1.0));

    // Gamma correct
    I = pow(I, vec3(GAMMA_EXP));

    float cosTheta = max(dot(N, -Frag_View), 0.0);
    vec3 fresnel = FresnelSchlick(cosTheta, vec3(0.04));
    vec3 glow = 0.5 * fresnel * vec3(1, 1, 0);
    Out_Color = vec4(I + glow, albedo.a);
}
#endif