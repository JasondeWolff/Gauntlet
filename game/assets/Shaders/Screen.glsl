#ifdef VERT_SHADER

layout (location = 0) in vec3 a_position;
layout (location = 1) in vec2 a_texcoord;

out vec2 v_texcoord;

void main()
{
    v_texcoord = a_texcoord;
	gl_Position = vec4(a_position, 1.0);
}
#endif

#ifdef FRAG_SHADER

#if defined GL_ES || defined EMULATE_GL_ES
precision mediump float;
precision mediump samplerCube;
#endif

out vec4 p_fragcolor;
in vec2 v_texcoord;
layout (location = 0) uniform sampler2D u_texture;

void main() 
{
    p_fragcolor = texture(u_texture, v_texcoord);
}
#endif