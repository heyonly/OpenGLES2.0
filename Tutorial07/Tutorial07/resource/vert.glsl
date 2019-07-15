attribute vec3 vPosition;
attribute vec2 textureCoordsIn;

varying vec2 vTexcoord;

void main()
{
    gl_Position = vec4(vPosition, 1.0);
    vTexcoord = textureCoordsIn;
}
