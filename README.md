# LightFX-Shader
My first custom Shader written in HLSL for Unity

## What it does
This shader allows to swap textures based on the diffuse value on the fragment.  
It switches: Texture, Emissions and Metalness/Roughness

## Knows issues
It only works with up to 2 lights: Directional light (BasePass) + Any other light
