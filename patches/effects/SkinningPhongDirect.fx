//@author: vvvv group
//@help: Effect processing for skinned mesh with directional light.
//@tags: skeleton, bones, collada, shading
//@credits: SlimDX



static const int MaxMatrices = 60;
float4x4 SkinningMatrices[MaxMatrices];
float4x4 tW: WORLD;
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tWV: WORLDVIEW;
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (EX9)

#include "PhongDirectional.fxh"

//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;
float4x4 tColor <string uiname="Color Transform";>;



struct VSInput
{
	float4 Position			: POSITION;
	float4 BlendWeights		: BLENDWEIGHT;
	int4   BlendIndices		: BLENDINDICES;
	float3 Normal			: NORMAL;
	float3 TextureCoordinates	: TEXCOORD0;
};

struct VSOutput
{
	float4 Position			: POSITION;
	float2 TextureCoordinates	: TEXCOORD0;
	float3 LightDirV: TEXCOORD1;
	float3 NormV: TEXCOORD2;
	float3 ViewDirV: TEXCOORD3;
	
};

VSOutput VS(VSInput input)
{
	VSOutput output = (VSOutput)0;

	float4 blendWeights = input.BlendWeights;
	int4 indices = input.BlendIndices;
	
	float4 pos = 0;
	float3 norm2 = 0;
	for (int i = 0; i < 4; i++)
        {
            pos = pos + mul(input.Position, SkinningMatrices[indices[i]]) * blendWeights[i];
	    norm2 = norm2 + mul(input.Normal, SkinningMatrices[indices[i]]) * blendWeights[i];
        }


    //inverse light direction in view space
	float3 LightDirV = normalize(-mul(lDir, tV));
	output.LightDirV = LightDirV;
	
	//normal in view space
    float3 NormV = normalize(mul(norm2, tWV));
	output.NormV = NormV;
	
    //view direction = inverse vertexposition in viewspace
	float4 PosV = normalize(mul(pos, tWV));
	float3 ViewDirV = PosV;
	output.ViewDirV = PosV*-1;
	
	//halfvector
    float3 H = normalize(ViewDirV + LightDirV);
	
	//compute blinn lighting
    float3 shades = lit(dot(NormV, LightDirV), dot(NormV, H), lPower);
	
	//position (projected)
    output.Position  = mul(PosV, tP);
	
	
	
	output.TextureCoordinates = input.TextureCoordinates.xy;

	return output;
}

float Alpha <float uimin=0.0; float uimax=1.0;> = 1;

float4 PS(VSOutput input)  : COLOR
{

    float4 col = tex2D(Samp, input.TextureCoordinates);
	col.rgb *= PhongDirectional(input.NormV, input.ViewDirV, input.LightDirV);
	col.a *= Alpha;
    return mul(col, tColor);
}

technique SkinnedMesh
{
	pass P0
	{
		VertexShader = compile vs_3_0 VS();
		PixelShader = compile ps_3_0 PS();
	}
}
