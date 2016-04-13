//@author: vvvv group
//@help: Effect processing for skinned mesh with directional light.
//@tags: skeleton, bones, collada, shading
//@credits: SlimDX

float3 lDir <string uiname="Gourard Direction";> = {0, -5, 2}; 
float4 lAmb  : COLOR <String uiname="Ambient Color";>  = {0.15, 0.15, 0.15, 1};
float4 lDiff : COLOR <String uiname="Diffuse Color";>  = {0.85, 0.85, 0.85, 1};
float4 lSpec : COLOR <String uiname="Specular Color";> = {0.35, 0.35, 0.35, 1};

//shininess of specular highlight
float lPower <String uiname="Power"; float uimin=0.0;> = 25.0;  



static const int MaxMatrices = 60;
float4x4 SkinningMatrices[MaxMatrices];
float4x4 tW: WORLD;
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tWV: WORLDVIEW;
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (EX9)

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
	float4 Diffuse			: COLOR0;
	float2 TextureCoordinates	: TEXCOORD0;
    float4 Specular: COLOR1;

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
	
	//normal in view space
    float3 NormV = normalize(mul(norm2, tWV));
	//float3 NormV = norm;
	
    //view direction = inverse vertexposition in viewspace
	float4 PosV = mul(pos, tWV);
	float3 ViewDirV = normalize(-PosV);
	
	//halfvector
    float3 H = normalize(ViewDirV + LightDirV);
	
	//compute blinn lighting
    float3 shades = lit(dot(NormV, LightDirV), dot(NormV, H), lPower);
	
	float4 diff = lDiff * shades.y;
    diff.a = 1;
    float4 spec = lSpec * shades.z;
    spec.a = 1;
	
	//position (projected)
    output.Position  = mul(PosV, tP);
    //output.TextureCoordinates = mul(input.TextureCoordinates, tTex);
    output.Diffuse = diff + lAmb;
    output.Specular = spec;

	output.TextureCoordinates = input.TextureCoordinates.xy;

	return output;
}

float4 PS(VSOutput input)  : COLOR
{

    float4 col = tex2D(Samp, input.TextureCoordinates);
    col.rgb *= input.Diffuse + input.Specular;
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
