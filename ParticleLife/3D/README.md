# PARTICLE LIFE
A CRT shader implement of the simulation shown in [this video](https://www.youtube.com/watch?v=0Kx4Y9TVMGg).

The Idea of the simulation is that it is capable of creating complex emergent behaviour by simulating particles that simply attract or repulse each other (where repulsion is actually just attraction of a negative strength).
Every particle has one of four colors, and for each color, a interaction force of it to each other color is defined. On every step of the simulation, the velocities of the particles are updated by computing the attraction forces of each particle to all others, and then their positions are updated using their velocities.

"ParticleSim3D" is the actual simulation shader, and "SimCRT3D" the CRT it runs in. The "ParticleRenderer" shader is derived from [Neitri's GPU particles shader](https://github.com/netri/Neitri-Unity-Shaders/tree/master/GPU%20Particles), and render the simulation state using textures quads as particles. To use it, set up a mesh renderer for the "512x512" mesh, and use the ParticleMat material with it.

Also included are U# scripts to set up the simulation material (required).

More info + video demo: https://tholin.dev/misc_shaders#particle-life
