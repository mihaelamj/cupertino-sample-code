/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the renderer class that uses mesh shaders to draw bicubic Bezier patches.
*/

#pragma once

#include <stdio.h>
#include <vector>

#include <Metal/Metal.hpp>
#include <MetalKit/MetalKit.hpp>

#include "AAPLShaderTypes.h"

class AAPLRenderer
{
public:
    AAPLRenderer(MTK::View& view);
    ~AAPLRenderer();
    
    void draw(MTK::View *pView);
    void buildShaders();
    void drawableSizeWillChange(CGSize size);
    float rotationSpeed{0};
    float offsetY{0};
    float offsetZ{0};
    int lodChoice{0};
    int topologyChoice{2};
    
private:
    static constexpr size_t AAPLMaxFramesInFlight = 3;
    size_t _curFrameInFlight{0};
    
    MTL::Device* _pDevice;
    MTL::CommandQueue* _pCommandQueue;
    MTL::RenderPipelineState* _pRenderPipelineState[3];
    MTL::DepthStencilState* _pDepthStencilState;
    MTL::Buffer* _pTransformsBuffer[AAPLMaxFramesInFlight];

    MTL::Buffer* _pMeshColorsBuffer;
    MTL::Buffer* _pMeshVerticesBuffer;
    MTL::Buffer* _pMeshIndicesBuffer;
    MTL::Buffer* _pMeshInfoBuffer;

    matrix_float4x4 _projectionMatrix;
    float degree;
    
    std::vector<AAPLVertex> meshVertices;
    std::vector<AAPLIndexType> meshIndices;
    std::vector<AAPLMeshInfo> meshInfo;
    
    void updateStage();
    void makeMeshlets();
    void makeMeshletColors();
};
