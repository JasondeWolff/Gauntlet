#ifdef PARAMS
{
    "properties": {
        "Albedo": { "Color": [0, 0, 0, 0] },
        "Metallic": { "Float": 1 },
        "Roughness": { "Float": [0, 0, 0, 0] },
        "Ao": { "Float": [0, 0, 0, 0] },
        "AlbedoMap": { "Texture2D": "White" },
        "NormalMap": { "Texture2D": "Blue" },
        "EmissionMap": { "Texture2D": "Black" },
        "MetallicMap": { "Texture2D": "White" },
        "RoughnessMap": { "Texture2D": "White" },
        "AoMap": { "Texture2D": "White" },
    }
}
#endif

#ifdef GLSL
#ifdef VERT_SHADER

layout (location = 0) in vec4 a_position;
layout (location = 1) in vec4 a_normal;
layout (location = 2) in vec4 a_tangent;
layout (location = 3) in vec4 a_bitangent;
layout (location = 4) in vec4 a_texcoord01;
layout (location = 5) in vec4 a_texcoord12;
layout (location = 6) in vec4 a_bones;
layout (location = 7) in vec4 a_weights;

layout (location = 8) in mat4 a_model;
layout (location = 12) in vec4 a_diffuse;
layout (location = 13) in vec4 a_pbr;
layout (location = 14) in ivec4 a_maps;
layout (location = 15) in ivec4 a_maps_pbr;

layout (location = 0) uniform mat4 u_view_proj;
layout (location = 2) uniform vec3 u_camera_pos;

#if defined GL_ES || defined EMULATE_GL_ES
out vec3 v_tangent_fragpos;
out vec3 v_tangent_campos;
out mat3 v_tbn;
out vec2 v_texcoord0;
out flat vec4 v_albedo;
out flat vec4 v_pbr;
out flat ivec4 v_maps;
out flat ivec4 v_maps_pbr;

#else
layout (std430, binding = 1) buffer ub_lights { mat4 u_lights[]; };

out vec3 v_tangent_fragpos;
out vec3 v_tangent_campos;
out vec3 v_tangent_lightdir;
out vec2 v_texcoord0;
out flat vec4 v_albedo;
out flat vec4 v_pbr;
out flat ivec4 v_maps;
out flat ivec4 v_maps_pbr;
#endif

void main()
{
	vec4 position = a_model * vec4(a_position.xyz, 1.0);
	gl_Position = u_view_proj * position;

    mat3 normalMatrix = transpose(inverse(mat3(a_model)));
    vec3 T = normalize(normalMatrix * a_tangent.xyz);
    vec3 B = normalize(normalMatrix * a_bitangent.xyz);
    vec3 N = normalize(normalMatrix * a_normal.xyz);
    mat3 TBN = transpose(mat3(T, B, N));

    v_tangent_fragpos = TBN * position.xyz;
    v_tangent_campos = TBN * u_camera_pos;

#if defined GL_ES || defined EMULATE_GL_ES
    v_tbn = TBN;
#else
    v_tangent_lightdir = TBN * u_lights[0][0].xyz;
#endif
    
	v_texcoord0 = a_texcoord01.xy;
	v_albedo = a_diffuse;
    v_pbr = a_pbr;
	v_maps = a_maps;
    v_maps_pbr = a_maps_pbr;
}
#endif

#ifdef FRAG_SHADER

#if defined GL_ES
#extension GL_EXT_texture_query_lod : enable
precision mediump float;
precision lowp sampler2DArray;

#elif defined EMULATE_GL_ES
#extension GL_ARB_texture_query_lod : enable
precision mediump float;
precision lowp sampler2DArray;

#else
#extension GL_ARB_bindless_texture : enable
#endif

out vec4 p_fragcolor;

#if defined GL_ES || defined EMULATE_GL_ES
in vec3 v_tangent_fragpos;
in vec3 v_tangent_campos;
in mat3 v_tbn;
in vec2 v_texcoord0;
in flat vec4 v_albedo;
in flat vec4 v_pbr;
in flat ivec4 v_maps;
in flat ivec4 v_maps_pbr;

#else
in vec3 v_tangent_fragpos;
in vec3 v_tangent_campos;
in vec3 v_tangent_lightdir;
in vec2 v_texcoord0;
in flat vec4 v_albedo;
in flat vec4 v_pbr;
in flat ivec4 v_maps;
in flat ivec4 v_maps_pbr;
#endif

#if defined GL_ES || defined EMULATE_GL_ES
layout (binding = 1) uniform sampler2DArray u_textures;
#else
layout (std430, binding = 0) buffer ub_textures { uvec2 u_textures[]; };
#endif

layout (location = 3) uniform samplerCube u_irr_map;
layout (location = 4) uniform samplerCube u_pf_map;
layout (location = 5) uniform sampler2D u_brdf_lut;

layout (std430, binding = 1) buffer ub_lights { mat4 u_lights[]; };

float DistributionGGX(vec3 N, vec3 H, float roughness);
float GeometrySchlickGGX(float NdotV, float roughness);
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness);
vec3 FresnelSchlick(float cosTheta, vec3 F0);
vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness);
vec3 Irradiance(vec3 albedo, float metallic, float roughness, float ao, vec3 F0, vec3 N, vec3 V, vec3 L, vec3 R);

vec4 sampleTexture(int mapId, vec2 texcoord)
{
#if defined GL_ES || defined EMULATE_GL_ES
	float level = textureQueryLOD(u_textures, texcoord).x;
	return textureLod(u_textures, vec3(texcoord.x, texcoord.y, mapId), level);
#else
	return texture(sampler2D(u_textures[mapId]), texcoord);
#endif
}

const float GAMMA_EXP  = 0.45454545454;

void main()
{
	vec4 albedoMap = sampleTexture(v_maps.x, v_texcoord0);
	vec3 albedo = v_albedo.rgb * albedoMap.rgb;
	float alpha = v_albedo.a * albedoMap.a;

    vec4 metallicMap = sampleTexture(v_maps_pbr.x, v_texcoord0);
    float metallic = v_pbr.x * metallicMap.r;

    vec4 roughnessMap = sampleTexture(v_maps_pbr.y, v_texcoord0);
    float roughness =  v_pbr.y * roughnessMap.r;

    vec4 aoMap = vec4(1);//sampleTexture(v_maps_pbr.z, v_texcoord0);
    float ao = v_pbr.z * aoMap.r;

    // Calculate reflectance at normal incidence; if dia-electric (like plastic) use F0 
    // of 0.04 and if it's a metal, use the albedo color as F0 (metallic workflow)  
    vec3 F0 = mix(vec3(0.04), albedo, metallic);

    vec4 normalMap = sampleTexture(v_maps.y, v_texcoord0);
    vec3 N = normalize(normalMap.rgb * 2.0 - 1.0); 

    vec3 V = normalize(v_tangent_campos - v_tangent_fragpos);
    vec3 R = reflect(-V, N); 

    // Reflectance equation
    vec3 Lo = vec3(0.0);

    // Directional light irradiance
#if defined GL_ES || defined EMULATE_GL_ES
    vec3 Ld = -normalize(v_tbn * u_lights[0][0].xyz); // xyz, dir w = 0 or point w = 1
#else
    vec3 Ld = -normalize(v_tangent_lightdir); // xyz, dir w = 0 or point w = 1
#endif
	vec3 Rd = u_lights[0][1].rgb * u_lights[0][1].a; // color * intensity
    Lo += Irradiance(albedo, metallic, roughness, ao, F0, N, V, Ld, Rd);

    // ambient lighting (we now use IBL as the ambient term)
    vec3 F = FresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness);
    vec3 kS = F;
    vec3 kD = 1.0 - kS;
    kD *= 1.0 - metallic;

    vec3 irradiance = texture(u_irr_map, N).rgb;
    vec3 diffuse = irradiance * albedo;
    
    // Old ambient lighting
    //vec3 kD = vec3(0.03);
    //vec3 diffuse = albedo;
    //vec3 ambient = (kD * diffuse) * ao;

    // sample both the pre-filter map and the BRDF lut and combine them together as per the Split-Sum approximation to get the IBL specular part.
    const float MAX_REFLECTION_LOD = 4.0;
    vec3 pfColor = textureLod(u_pf_map, R,  roughness * MAX_REFLECTION_LOD).rgb;    
    vec2 brdf = texture(u_brdf_lut, vec2(max(dot(N, V), 0.0), roughness)).rg;
    vec3 specular = pfColor * (F * brdf.x + brdf.y);

    vec3 ambient = (kD * diffuse + specular) * ao;

    // Final irradiance
    vec3 I = ambient + Lo;

    // HDR tonemapping
    I = I / (I + vec3(1.0));

    // Gamma correct
    I = pow(I, vec3(GAMMA_EXP));

    // Final color
    p_fragcolor = vec4(I, alpha);
}

// Based on: // https://learnopengl.com/code_viewer_gh.php?code=src/6.pbr/1.2.lighting_textured/1.2.pbr.fs
const float PI          = 3.14159265359;
const float ONE_OVER_PI = 0.31830988618;
const float ONE_OVER_8  = 0.125;

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return nom / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = roughness + 1.0;
    float k = (r * r) * ONE_OVER_8;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

vec3 FresnelSchlick(float cosTheta, vec3 F0)
{
    //float a = pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
    float a = clamp(1.0 - cosTheta, 0.0, 1.0);
    a = a * a * a * a * a;

    return F0 + (1.0 - F0) * a;
}

vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness)
{
    //float a = pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
    float a = clamp(1.0 - cosTheta, 0.0, 1.0);
    a = a * a * a * a * a;

    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * a;
} 

vec3 Irradiance(vec3 albedo, float metallic, float roughness, float ao, vec3 F0, vec3 N, vec3 V, vec3 L, vec3 R)
{
    // Calculate light radiance
    vec3 H = normalize(V + L);

    // Cook-Torrance BRDF
    float NDF = DistributionGGX(N, H, roughness);
    float G = GeometrySmith(N, V, L, roughness);
    vec3 F = FresnelSchlick(max(dot(H, V), 0.0), F0);

    vec3 numerator = NDF * G * F;
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001; // + 0.0001 to prevent divide by zero
    vec3 specular = numerator / denominator;

    // kS is equal to Fresnel
    vec3 kS = F;
    
    // For energy conservation, the diffuse and specular light can't
    // be above 1.0 (unless the surface emits light); to preserve this
    // relationship the diffuse component (kD) should equal 1.0 - kS.
    vec3 kD = vec3(1.0) - kS;
    
    // Multiply kD by the inverse metalness such that only non-metals 
    // have diffuse lighting, or a linear blend if partly metal (pure metals
    // have no diffuse light).
    kD *= 1.0 - metallic;

    // Scale light by NdotL
    float NdotL = max(dot(N, L), 0.0);

    // Outgoing radiance (irradiance)
    //vec3 I = (kD * albedo / PI + specular) * R * NdotL;
    vec3 I = (kD * albedo * ONE_OVER_PI + specular) * R * NdotL;  // Note that we already multiplied the BRDF by the Fresnel (kS) so we won't multiply by kS again
    
    return I;
}
#endif
#endif // GLSL