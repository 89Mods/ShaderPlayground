# Tholin's plasma shader

This shader is a animated, emissive "plasma" effect using distorted perlin noise. It is also maskable with a base texture, meaning it can be used as an emissive effect on avatars and props.
The shader does require three noise textures to function. These are included, and have to be provided to every material using the shader. **The import settings on those textures must not be modified!** If you don't want to include 9MB of noise texture with your avatar, use the "LivePerlin" variant of the shader (see below).

Two versions of the shader exist:

"PlasmaShader" - Base version using noise textures.
"PlasmaShader-LivePerlin" - This version does not need the noise textures, instead using a RNG to generate the noise fields live in software. This is a lot more GPU performance intensive though.
