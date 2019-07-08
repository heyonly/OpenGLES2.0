attribute vec4 vPosition;
attribute vec2 textureCoordsIn;
varying lowp vec2 textureCoordsOut;

void main()
{
    gl_Position = vPosition;
    textureCoordsOut = textureCoordsIn;
}
