#include "[assets]/Shaders/Language.shader"

#ifdef VERTEX
layout (location = 0) in vec3 Position;
layout (location = 1) in vec4 Color;
layout (location = 2) in vec3 Normal;
layout (location = 3) in vec3 Tangent;
layout (location = 4) in vec2 UV;

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

layout (location = 0) out vec3 Frag_Position;
layout (location = 1) out vec4 Frag_Color;
layout (location = 2) out vec3 Frag_Normal;
layout (location = 3) out vec3 Frag_Tangent;
layout (location = 4) out vec2 Frag_UV;
layout (location = 5) out vec3 Frag_View;
layout (location = 6) flat out ivec4 Frag_LightIndices;

void main()
{
    mat4 WorldMeshMtx = WorldMtx * MeshMtx;
    vec4 WorldPosition = WorldMeshMtx * vec4(Position, 1.0);

    Frag_Position = WorldPosition.xyz;
    Frag_Color = Color;
    Frag_Normal = (WorldMeshMtx * vec4(Normal, 0.0)).xyz;
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

const float INV_GAMMA_EXP  = 2.2;
const float GAMMA_EXP  = 0.45454545454;

vec3 FresnelSchlick(float cosTheta, vec3 F0)
{
    float a = pow(clamp(1.0 - cosTheta, 0.0, 1.0), 0.75);
    return F0 + (1.0 - F0) * a;
}

vec2 Swirl(vec2 uv, float strength)
{
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = uv - center;
    float angle = strength * length(offset);
    float s = sin(angle);
    float c = cos(angle);
    offset = mat2(c, -s, s, c) * offset;
    return center + offset;
}

void main()
{
    vec3 N = normalize(Frag_Normal);

    float cosTheta = max(dot(N, -Frag_View), 0.0);
    vec3 fresnel = FresnelSchlick(cosTheta, vec3(0.04));

    vec4 albedo = texture(Albedo, Frag_UV);
    vec3 albedoLinear = pow(albedo.rgb, vec3(INV_GAMMA_EXP));
    
    vec3 Lo = fresnel * albedoLinear;
    //Lo += fresnel * albedoLinear;

    vec3 kD = vec3(0.03);
    vec3 ambient = (kD * albedoLinear.rgb);// * ao;

    // Final irradiance
    vec3 I = ambient + Lo;

    // HDR tonemapping
    I = I / (I + vec3(1.0));

    // Gamma correct
    I = pow(I, vec3(GAMMA_EXP));

    Out_Color = vec4(I, 0.1 + albedo.a * fresnel);
}
#endif