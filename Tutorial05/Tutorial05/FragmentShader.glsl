precision mediump float;

varying vec2 textureCoordsOut;

uniform sampler2D aTexture;

void main()
{
    vec4 colors = texture2D(aTexture,textureCoordsOut);
    gl_FragColor = vec4(colors.rgb,1.0);
}
