attribute vec4 vPosition;

uniform mat4 modelView;
uniform mat4 projection;

attribute vec2 textureCoordsIn;

varying vec2 textureCoordsOut;



void main()
{
    gl_Position = projection * modelView * vPosition;
    textureCoordsOut = textureCoordsIn;
}




