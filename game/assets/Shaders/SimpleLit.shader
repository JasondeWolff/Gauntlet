#ifdef VERTEX
layout (location = 0) in vec3 Position;
layout (location = 1) in vec4 Color;
layout (location = 2) in vec3 Normal;
layout (location = 3) in vec3 Tangent;
layout (location = 4) in vec2 UV;

layout (std140) uniform ConstantBuffer
{
    mat4 ViewMtx;
    mat4 ProjMtx;
    mat4 ViewProjMtx;
};

layout (std140) uniform ModelBuffer
{
    mat4 WorldMtx;
    mat4 MeshMtx;
    ivec4 LightIndices;
};

out vec3 Frag_Position;
out vec4 Frag_Color;
out vec3 Frag_Normal;
out vec3 Frag_Tangent;
out vec2 Frag_UV;
flat out ivec4 Frag_LightIndices;

void main()
{
    mat4 WorldMeshMtx = WorldMtx * MeshMtx;
    vec4 WorldPosition = WorldMeshMtx * vec4(Position, 1.0);

    Frag_Position = WorldPosition.xyz;
    Frag_Color = Color;
    Frag_Normal = (WorldMeshMtx * vec4(Normal, 0.0)).xyz;
    Frag_Tangent = Tangent;
    Frag_UV = UV;
    Frag_LightIndices = LightIndices;

    gl_Position = ViewProjMtx * WorldPosition;
}
#endif

#ifdef PIXEL
layout (location = 0) out vec4 Out_Color;

in vec3 Frag_Position;
in vec4 Frag_Color;
in vec3 Frag_Normal;
in vec3 Frag_Tangent;
in vec2 Frag_UV;
flat in ivec4 Frag_LightIndices;

uniform sampler2D Albedo;

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
layout (std140) uniform LightBuffer
{
    Light Lights[NUM_LIGHTS];
};
//uniform sampler2D ShadowMaps[NUM_LIGHTS];

const float INV_GAMMA_EXP  = 2.2;
const float GAMMA_EXP  = 0.45454545454;

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
        //ShadowMap shadowMap = shadowMaps[light.shadowMapIndex];
        
        //if (light.type == LIGHT_TYPE_DIRECTIONAL) {
        //    lightDir = normalize(light.position.xyz);
        //    diff = max(dot(Normal, lightDir), 0.0);
        //    vec3 diffuse = diff * light.color.rgb;
        //
        //    // Sample shadow maps for cascades
        //    for (int j = 0; j < shadowMap.cascadeCount; ++j) {
        //        // Perform shadow map sampling
        //        shadow *= sampleShadow2D(shadowMaps2D[shadowMap.cascadeStart + j], vec3(...));
        //    }
        //    result += diffuse * light.color.a * shadow;
        //}
        //else if (light.type == LIGHT_TYPE_POINT) {

            vec3 lightDir = normalize(light.position - Frag_Position);
            float diffuse = max(dot(N, lightDir), 0.0);

            // Attenuation
            float distance = length(light.position - Frag_Position);
            float attenuation = 1.0 / (light.constant + light.linear_cutoff * distance + light.quadratic_outerCutoff * (distance * distance));

            // Sample cubemap shadow map
            float shadow = 1; //sampleShadowCube(shadowCubeMaps[shadowMap.index], Frag_Position - light.position.xyz);
            
            Lo += albedoLinear.rgb * diffuse * light.color * light.intensity * attenuation * shadow;
        //}
        //else if (light.type == LIGHT_TYPE_SPOT) {
        //    lightDir = normalize(light.position.xyz - FragPos);
        //    diff = max(dot(Normal, lightDir), 0.0);
        //    vec3 diffuse = diff * light.color.rgb;
        //
        //    // Spotlight (soft edges)
        //    float theta = dot(lightDir, normalize(-light.direction.xyz));
        //    float epsilon = light.cutoff - light.outerCutoff;
        //    float intensity = clamp((theta - light.outerCutoff) / epsilon, 0.0, 1.0);
        //
        //    // Attenuation
        //    float distance = length(light.position.xyz - FragPos);
        //    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
        //
        //    // Sample 2D shadow map
        //    shadow = sampleShadow2D(shadowMaps2D[shadowMap.index], vec3(...));
        //    result += diffuse * light.color.a * attenuation * intensity * shadow;
        //}
    }

    vec3 kD = vec3(0.03);
    vec3 ambient = (kD * albedoLinear.rgb);// * ao;

    // Final irradiance
    vec3 I = ambient + Lo;

    // HDR tonemapping
    I = I / (I + vec3(1.0));

    // Gamma correct
    I = pow(I, vec3(GAMMA_EXP));

    Out_Color = vec4(I, albedo.a);
}
#endif