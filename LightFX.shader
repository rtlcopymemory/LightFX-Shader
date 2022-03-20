Shader "LightFX/LightFX"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _Normals("Normal Map (Common Light/Dark)", 2D) = "bump" {}
        [NoScaleOffset] _Gloss("Metallic-Smoothness", 2D) = "black" {}
        _MinLight("Minimum lighting", Range(0, 1)) = 0.2
        [NoScaleOffset] _Emissions("Emission Map", 2D) = "white" {}
        _EmissionColor ("Emission Color", Color) = (1,1,1,1)
        _EmissionIntensity ("Emission Intensity", Range(0, 10)) = 1

        _DarknessStart ("Darkness Start", Range(0, 1)) = 0.2
        _DarknessEnd ("Darkness End", Range(0, 1)) = 0.25
        [NoScaleOffset] _DarkTex("Dark Texture", 2D) = "white" {}
        [NoScaleOffset] _DarkGloss("Dark Metallic-Smoothness", 2D) = "black" {}
        [NoScaleOffset] _DarkEmissions("Dark Emission Map", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // Base pass
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define IS_IN_BASE_PASS
            #include "LightFX.cginc"
            ENDCG
        }

        // Add pass
        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One // src*1 + dst*1
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "LightFX.cginc"
            ENDCG
        }
    }
}
