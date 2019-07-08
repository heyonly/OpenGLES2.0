attribute vec3 vPosition;
attribute vec2 textCoordinate;
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec2 varyTextCoord;

void main()
{
    varyTextCoord = textCoordinate;
    gl_Position = projectionMatrix * viewMatrix * modelViewMatrix * vec4(vPosition,1.0);
}
