#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#define TAU 6.28318530718

struct MeshData {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT; // xyz = tangent direction, w = tangent sign
    float2 uv : TEXCOORD0;
};

struct Interpolators {
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 tangent : TEXCOORD2;
    float3 bitangent : TEXCOORD3;
    float3 wPos : TEXCOORD4;
    LIGHTING_COORDS(5,6)
};

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _Normals;
sampler2D _Gloss;
float4 _Color;
float _MinLight;
sampler2D _Emissions;
float4 _EmissionColor;
float _EmissionIntensity;

float _DarknessStart;
float _DarknessEnd;
sampler2D _DarkTex;
sampler2D _DarkGloss;
sampler2D _DarkEmissions;

texture _LightMap;

Interpolators vert (MeshData v) {
    Interpolators o;
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);

    o.vertex = UnityObjectToClipPos(v.vertex);
    
    o.normal = UnityObjectToWorldNormal( v.normal );
    o.tangent = UnityObjectToWorldDir( v.tangent.xyz );
    o.bitangent = cross( o.normal, o.tangent );
    o.bitangent *= v.tangent.w * unity_WorldTransformParams.w; // correctly handle flipping/mirroring
    
    o.wPos = mul( unity_ObjectToWorld, v.vertex );
    TRANSFER_VERTEX_TO_FRAGMENT(o); // lighting, actually
    return o;
}

float InverseLerp(float a, float b, float v) {
	return (v - a) / (b - a);
}

float4 SampleGloss(float2 uv, float t) {
	return lerp(tex2D(_DarkGloss, uv), tex2D(_Gloss, uv), t);
}

float4 SampleColor(float2 uv, float t) {
	return lerp(tex2D(_DarkTex, uv), tex2D(_MainTex, uv), t);
}

float4 SampleEmission(float2 uv, float t) {
	return lerp(tex2D(_DarkEmissions, uv), tex2D(_Emissions, uv), t);
}

float4 frag(Interpolators i) : SV_Target {
	float3 V = normalize(_WorldSpaceCameraPos - i.wPos);
    
	float3 tangentSpaceNormal = UnpackNormal(tex2D(_Normals, i.uv));
    
	float3x3 mtxTangToWorld =
	{
		i.tangent.x, i.bitangent.x, i.normal.x,
        i.tangent.y, i.bitangent.y, i.normal.y,
        i.tangent.z, i.bitangent.z, i.normal.z
	};

    float3 N = normalize(mul(mtxTangToWorld, tangentSpaceNormal));
    
    // diffuse lighting
	float3 L = normalize(UnityWorldSpaceLightDir(i.wPos));
	float attenuation = LIGHT_ATTENUATION(i);
    float3 lambert = saturate(dot(N, L) * 0.5 + 0.5);
	float3 diffuseLight = max(_MinLight, lambert * attenuation) * _LightColor0.xyz;
    
    // Diffuse Wrap
    float NightT = saturate( InverseLerp(_DarknessStart, _DarknessEnd, (dot(N, L) * 0.5 + 0.5) * _LightColor0.w) );
    
    // specular lighting
	float3 H = normalize(L + V);
	float3 specularLight = saturate(dot(H, N)) * (lambert > 0); // Blinn-Phong

	float4 gloss = SampleGloss(i.uv, NightT);
    float specularExponent = exp2(gloss.a * 11) + 2;
	specularLight = pow(specularLight, specularExponent) * gloss.a * attenuation; // specular exponent
    specularLight *= _LightColor0.xyz * gloss.rgb;
        
    // Emissions
	float3 emissions = SampleEmission(i.uv, NightT).rgb * _EmissionColor.rgb;
    
    // Color
	float3 color = SampleColor(i.uv, NightT).rgb;
	float3 surfaceColor = color * _Color.rgb;
        
	return float4(max(diffuseLight * surfaceColor + specularLight, emissions * _EmissionIntensity), 1);
}