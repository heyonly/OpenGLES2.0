varying lowp vec2 textureCoord;

uniform sampler2D texture1;
uniform sampler2D texture2;

void main()
{
    gl_FragColor = mix(texture2D(texture1,textureCoord),texture2D(texture2,textureCoord),0.6);
//    gl_FragColor = vec4(texture2D(texture1,textureCoord).rgb,1.0);
}
