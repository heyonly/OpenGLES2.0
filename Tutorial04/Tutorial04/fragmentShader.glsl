precision mediump float;

// 纹理坐标
varying vec2 textureCoordsOut;

// 要传的纹理
uniform sampler2D imageTexture;

void main()
{
    vec4 colors = texture2D(imageTexture, textureCoordsOut);
    gl_FragColor = vec4(colors.rgb, 1.0);
}





