//UNITY_SHADER_NO_UPGRADE
#ifndef MYHLSLINCLUDE_INCLUDED
#define MYHLSLINCLUDE_INCLUDED

float3 doTransform(float4x4 transform, float3 pt)
{
    return mul(transform, float4(pt.x, pt.y, pt.z, 1)).xyz;
}

float4 loadBoneMatrixTexture(Texture2D<float4> animatedBoneMatrices, int frameIndex, int boneIndex, int i)
{
    return animatedBoneMatrices.Load(int3((boneIndex * 3) + i, frameIndex, 0));
}

float4x4 extractRotationMatrix(float4x4 m)
{
    float sx = length(float3(m[0][0], m[0][1], m[0][2]));
    float sy = length(float3(m[1][0], m[1][1], m[1][2]));
    float sz = length(float3(m[2][0], m[2][1], m[2][2]));

    // if determine is negative, we need to invert one scale
    float det = determinant(m);
    if (det < 0) {
        sx = -sx;
    }

    float invSX = 1.0 / sx;
    float invSY = 1.0 / sy;
    float invSZ = 1.0 / sz;

    m[0][0] *= invSX;
    m[0][1] *= invSX;
    m[0][2] *= invSX;
    m[0][3] = 0;

    m[1][0] *= invSY;
    m[1][1] *= invSY;
    m[1][2] *= invSY;
    m[1][3] = 0;

    m[2][0] *= invSZ;
    m[2][1] *= invSZ;
    m[2][2] *= invSZ;
    m[2][3] = 0;

    m[3][0] = 0;
    m[3][1] = 0;
    m[3][2] = 0;
    m[3][3] = 1;

    return m;
}

void calculateFrameValues(float3 position, float3 normal, float3 tangent,
    Texture2D<float4> animatedBoneMatrices, 
    float2 boneWeights[6], int frameIndex, 
    out float3 positionOut, out float3 normalOut, out float3 tangentOut)
{
    positionOut = normalOut = tangentOut = float3(0, 0, 0);
    for(int i = 0; i < 6; i++)
    {
        float boneWeight = boneWeights[i].y;
        if(boneWeight == 0) break;
        float boneIndex = boneWeights[i].x;

        float4 m0 = loadBoneMatrixTexture(animatedBoneMatrices, frameIndex, boneIndex, 0); 
        float4 m1 = loadBoneMatrixTexture(animatedBoneMatrices, frameIndex, boneIndex, 1); 
        float4 m2 = loadBoneMatrixTexture(animatedBoneMatrices, frameIndex, boneIndex, 2); 
        float4 m3 = float4(0,0,0,1);
        
        float4x4 animatedBoneMatrix = float4x4(m0, m1, m2, m3);
        float4x4 rotationMatrix = extractRotationMatrix(animatedBoneMatrix);

        positionOut += boneWeight * doTransform(animatedBoneMatrix, position);
        
        normalOut += boneWeight * doTransform(rotationMatrix, normal);
        tangentOut += boneWeight * doTransform(rotationMatrix, tangent);
    }
}

void AnimateBlend_float(float3 position, float3 normal, float3 tangent,
    float3x4 uvs, Texture2D<float4> animatedBoneMatrices, float4x3 animationState,
    out float3 positionOut, out float3 normalOut, out float3 tangentOut) 
{
    positionOut = float3(0, 0, 0);
    normalOut = float3(0, 0, 0);
    tangentOut = float3(0, 0, 0);
    float2 boneWeights[6] = {
        float2(uvs._m00, uvs._m01),  float2(uvs._m02, uvs._m03),
        float2(uvs._m10, uvs._m11),  float2(uvs._m12, uvs._m13),
        float2(uvs._m20, uvs._m21),  float2(uvs._m22, uvs._m23) };
    
    for(int blendIndex = 0; blendIndex < 4; blendIndex++)
    {
        float blendFactor = animationState[blendIndex][0]; 
        if(blendFactor > 0)
        {
            float transitionNextFrame = animationState[blendIndex][1];
            float prevFrameFrac = 1.0 - transitionNextFrame;
            float frameIndex = animationState[blendIndex][2];
            float3 posOutBefore, posOutAfter, normalOutBefore, normalOutAfter, tangentOutBefore, tangentOutAfter;
            calculateFrameValues(position, normal, tangent, animatedBoneMatrices, boneWeights, frameIndex, 
                posOutBefore, normalOutBefore, tangentOutBefore);
            calculateFrameValues(position, normal, tangent, animatedBoneMatrices, boneWeights, frameIndex + 1,
                posOutAfter, normalOutAfter, tangentOutAfter);
            positionOut += blendFactor * (prevFrameFrac * posOutBefore + transitionNextFrame * posOutAfter);
            normalOut += blendFactor * (prevFrameFrac * normalOutBefore + transitionNextFrame * normalOutAfter);
            tangentOut += blendFactor * (prevFrameFrac * tangentOutBefore + transitionNextFrame * tangentOutAfter);
        }        
    }
}
#endif //MYHLSLINCLUDE_INCLUDED