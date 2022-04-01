# CRT Input Layer
Getting expression menu parameters into a Custom Render Texture is notoriously difficult, because the animator cannot access the CRT material.
This is my solution. Filling the entire screen with a single color and executing a grab pass right after, all before the skybox renders. CRT shaders can access Grab Pass textures, allowing this system to hand values into a CRT shader.

Known Issue: it is difficult to feed through exact values, as world post-processing effects apply to the screenspace shader. I don't know how to circumvent this, so for now, this is only good for passing through booleans.

# Setup
Drag the "GenericInputLayer" prefab onto the root GO of your avatar. From there, you can use animations to modify the float values "_IN1", "_IN2" and "_IN3" of the material at `GenericInputLayer/InputLayer/MeshRenderer`.
Add a uniform variable of `uniform sampler2D _CRTInputGrabPass` into any of your CRT shaders, and sample at uv 0.5, 0.5 to get the current input value. _IN1 -> R, _IN2 -> G, _IN3 -> B
