#ifdef VERT_SHADER

layout (location = 0) in vec3 a_position;

layout (location = 0) uniform mat4 u_view;
layout (location = 1) uniform mat4 u_proj;

out vec3 v_texcoord;

void main()
{
    v_texcoord = a_position;
    mat4 view = mat4(mat3(u_view));
    vec4 pos = u_proj * view * vec4(a_position, 1.0);
    gl_Position = pos.xyww;
}
#endif

#ifdef FRAG_SHADER
#ifdef GL_ES
precision mediump float;
precision mediump samplerCube;
#endif

out vec4 p_fragcolor;

in vec3 v_texcoord;

layout (location = 2) uniform samplerCube u_skybox;

void main()
{
    p_fragcolor = vec4(texture(u_skybox, v_texcoord).rgb, 1);
}
#endif