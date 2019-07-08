attribute vec3 vPosition;
attribute vec2 textureCoordIn;


varying lowp vec2 textureCoord;
void main()
{
    textureCoord = textureCoordIn;
    gl_Position = vec4(vPosition,1.0);
}
