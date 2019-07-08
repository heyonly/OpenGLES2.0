precision mediump float;

varying lowp vec2 textureCoordsOut;
uniform sampler2D inputImageTexture;
const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    lowp vec4 colors = texture2D(inputImageTexture,textureCoordsOut);
    float luminance = dot(colors.rgb,W);
    gl_FragColor = vec4(vec3(luminance),colors.a);
}
