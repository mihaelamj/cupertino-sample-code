/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the class that streams a sparse texture.
*/

#import "AAPLSparseTexture.h"
#import "AAPLStreamedTextureDataBacking.h"
#import "AAPLConfig.h"
#import "AAPLShaderTypes.h"
#import "AAPLPointerLRUCache.h"

#import <vector>
#import <map>
#import <mutex>
#import <thread>

#pragma mark - Helper Functions
//------------------------------------------------------------------//

/// Return the number of compressed blocks spanning the width of the texture or tile region.
static NSUInteger calculateBlocksWidth(NSUInteger size, NSUInteger blockSize, NSUInteger mipmapLevel)
{
    NSUInteger blocksWide = MAX(size / blockSize, 1U);
    return MAX(blocksWide >> mipmapLevel, 1u);
}

/// Return the array index base for the origin of the tile.
static NSUInteger calculateIndexFromTileOrigin(MTLOrigin tileOrigin, MTLSize sparseTextureSizeInTiles)
{
    sparseTextureSizeInTiles.width = sparseTextureSizeInTiles.width >> tileOrigin.z;
    return (tileOrigin.y * sparseTextureSizeInTiles.width) + tileOrigin.x;
}

/// Return the tile origin for mipmap level zero.
static MTLOrigin calculateTileOriginToLevel0Origin(MTLOrigin tileOrigin)
{
    tileOrigin.x = tileOrigin.x << tileOrigin.z;
    tileOrigin.y = tileOrigin.y << tileOrigin.z;
    tileOrigin.z = 0;
    return tileOrigin;
}

/// Copy a tile region of block-compressed texture data to a Metal buffer.
/// This function only works for a block-compressed texture format.
static void copyTileRegionBlockTexture(uint8_t* sourceData, id<MTLBuffer> outBuffer, MTLSize sourceTextureSize, MTLOrigin copyOrigin, MTLSize destSize, NSUInteger blocksSize)
{
    MTLOrigin blockCopyOrigin = MTLOriginMake(copyOrigin.x, copyOrigin.y / blocksSize, copyOrigin.z);
    
    NSUInteger totalDestWidth = destSize.width * blocksSize;
    NSUInteger sourceYLimit   = blockCopyOrigin.y + (destSize.height / blocksSize);
    NSUInteger sourceXOffset  = blockCopyOrigin.x * blocksSize;
    NSUInteger sourceYOffset  = sourceTextureSize.width * blocksSize;
    
    NSUInteger destY = 0;
    for (NSUInteger sourceY = blockCopyOrigin.y; sourceY < sourceYLimit; ++sourceY)
    {
        uint8_t* sourceRawBytes = sourceData + sourceXOffset + (sourceY * sourceYOffset);
        uint8_t* destDataBytes  = ((uint8_t*)(outBuffer.contents)) + (destY * totalDestWidth);
        memcpy(destDataBytes, sourceRawBytes, totalDestWidth);
        ++destY;
    }
}

#pragma mark - Declarations
//------------------------------------------------------------------//

enum class TileState
{
    /// The tile isn't mapped; no data is assigned to this texture region yet.
    TileStateUnmapped,
    /// The tile isn't mapped; data is assigned to this texture region.
    TileStateMapped,
    /// The tile is in the process of being mapped.
    TileStateQueueForMapping,
    /// The tile is in the process of being unmapped.
    TileStateQueueForUnmapping,
    /// The tile is mapped, but the GPU isn't sampling this tile region.
    TileStateStoredInLRUCache,
};

struct TextureTile
{
    /// The x and y components represent the tile origin in the tile coordinate (not in the pixel coordinate).
    /// The z component represents the mipmap level to which this tile belongs.
    MTLOrigin origin;

    /// The state describes the status of the tile in terms of whether it's unmapped or mapped,
    /// or if it's undergoing the process of mapping or unmapping.
    TileState state;

    /// The frames count variable makes sure a tile used by a previous frame isn't unmapped.
    int8_t framesCount;
};

#pragma mark - Class Implementation
//------------------------------------------------------------------//

@implementation AAPLSparseTexture
{
    /// Metal objects used by this data structure.
    
    // Protocol to MTLDevice.
    id<MTLDevice>       _device;
    // Command queue used to create command buffers for blitting and resource state.
    id<MTLCommandQueue> _commandQueue;
    // The heap that contains all the allocated sparse texture tiles.
    id<MTLHeap>         _sparseTextureHeap;
    // The heap that contains all the temporary streaming buffers.
    id<MTLHeap>         _stagingBuffersHeap;
    // The Metal texture that contains the sparse texture.
    id<MTLTexture>      _sparseTexture;
    
    /// Internal implementation details.
    
    // This is the KTX data backing that utilizes `mmap`.
    AAPLStreamedTextureDataBacking* _sparseTextureBacking;
    
    // LRU cache that holds the texture tile pointer data for tiles that are mapped but aren't sampled by the GPU.
    AAPLPointerLRUCache<TextureTile*> _notUsedMappedTilesLRUCache;
    
    // The size of one sparse texture tile in bytes.
    NSUInteger              _sparseTileSizeInBytes;
    // The size of the one texture tile in pixel coordinates.
    MTLSize                 _tileSize;
    // The access counters buffer stores the number of times the GPU sampled each tile region.
    id<MTLBuffer>           _accessCountersBuffer[AAPLMaxFramesInFlight];
    // The size of the access counter buffer.
    NSUInteger              _accessCountersSize;
    // Stores the offsets for each mipmap level into the access counter buffer.
    std::vector<NSUInteger> _accessCountersMipmapOffsets;

    /// Stores the residency buffers that the shader uses to sample the sparse texture.
    id<MTLBuffer>           _residencyBuffers[AAPLMaxFramesInFlight + 1];
    /// Stores the current residency buffer to use when blitting to the one the shader uses.
    NSUInteger              _residencyBufferIndex;
    
    // Holds all the texture tile data for each mipmap level.
    std::vector<std::vector<TextureTile>> _tiles;
    // This vector represents how many parent tiles reference each tile of sparse texture.
    // It only applies for mipmap index one to mipmap firstMipmapTail - 1.
    std::vector<std::vector<NSUInteger>> _countRefParentTiles;
    // This vector tracks the finest mipmaps resident on the GPU for each tile region.
    std::vector<int8_t> _tileRegionsFinestMipmap;
    
    // Holds the number of failed map tile requests because the sparse heap is full.
    NSUInteger _numTilesToDiscardFromLRU;
    // Holds the current unmap tile request list.
    std::vector<TextureTile*> _unmapTilesRequest;
    // Holds the current map tile request list.
    std::vector<TextureTile*> _mapTilesRequest;

    // Update mutex to allow only one update at a time.
    std::mutex _updateMutex;
}

/// Initializes the sparse texture by creating a data backing using `mmap`, and automatically populates the lowest mipmap levels.
/// The path is expected to be a KTX file.
- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                                  path:(NSURL*)path
                          commandQueue:(nonnull id<MTLCommandQueue>)commandQueue
                              heapSize:(NSUInteger)heapSize
{
    if (self = [super init])
    {
        _device     = device;
        _commandQueue = commandQueue;

        _numTilesToDiscardFromLRU = 0;
        _sparseTextureBacking = [[AAPLStreamedTextureDataBacking alloc] initWithKTXPath:path];
        [self createHeaps:heapSize];
        [self mapMipmapTails];
        [self blitMipmapTails];
        [self createAccessCountersBuffer];
        [self updateResidencyBuffer];
    }
    
    return self;
}

#pragma mark - Utility Functions
//------------------------------------------------------------------//

/// Returns a string describing the sparse texture heap size in MiB.
- (NSString*)infoString
{
    NSMutableString* output = [NSMutableString new];
    const float mbScale     = 1.0f / (1024 * 1024);
    float usedMemory        = [_sparseTextureHeap usedSize] * mbScale;
    float allocatedMemory   = [_sparseTextureHeap currentAllocatedSize] * mbScale;
    NSString* baseInfo      = [NSString stringWithFormat:@"Used Sparse Texture Heap Size: %.1f/%.1f MiB", usedMemory, allocatedMemory];
    [output appendString:baseInfo];
    return output;
}

/// Update residency data so that it always reflects the finest available mipmap region.
- (void)setTextureTileRegionFinestMipmap:(MTLOrigin)tileOrigin
                               newMipmap:(NSUInteger)newMipmap
                           minMipmapFlag:(bool)minMipmapFlag;
{
    MTLOrigin level0Origin = calculateTileOriginToLevel0Origin(tileOrigin);
    NSUInteger index = calculateIndexFromTileOrigin(level0Origin, _sizeInTiles);
    NSUInteger finalMipmap = minMipmapFlag ? fmin(_tileRegionsFinestMipmap[index], newMipmap) : newMipmap;

    _tileRegionsFinestMipmap[index] = finalMipmap;
}

/// Update the specific texture entry residency data.
- (void)updateTextureEntryResidency:(TextureTile*)tile
                      minMipmapFlag:(bool)minMipmapFlag
{
    // When a tile region is mapped or unmapped from the sparse texture, update its residency data.
    NSUInteger w = 1lu << tile->origin.z;
    NSUInteger h = 1lu << tile->origin.z;
    MTLOrigin level0Origin = calculateTileOriginToLevel0Origin(tile->origin);
    for (NSUInteger x = 0; x < w; ++x)
    {
        for (NSUInteger y = 0; y < h; ++y)
        {
            MTLOrigin currentOrigin = MTLOriginMake(level0Origin.x + x, level0Origin.y + y, 0);
            NSUInteger newFinestMipmap = minMipmapFlag ? tile->origin.z : tile->origin.z + 1;
            [self setTextureTileRegionFinestMipmap:currentOrigin newMipmap:newFinestMipmap minMipmapFlag:minMipmapFlag];
        }
    }
}

/// Depending on the `higherMipmapQuality` Boolean, the argument tile increases or decreases its children tile reference count value.
/// This ensures a continuous sequence of tile regions in the mipmap chain.
/// This reference counter ensures tiles won't be unmapped when the GPU only accesses a parent tile in the mipmap chain.
- (void)setTextureTileRefCounterParent:(TextureTile*)tile
                   higherMipmapQuality:(bool)higherMipmapQuality
{
    MTLOrigin childTileOrigin{};
    childTileOrigin.x = tile->origin.x >> 1lu;
    childTileOrigin.y = tile->origin.y >> 1lu;
    childTileOrigin.z = tile->origin.z + 1;
    
    if (childTileOrigin.z < _sparseTexture.firstMipmapInTail)
    {
        NSUInteger tileIndex = calculateIndexFromTileOrigin(childTileOrigin, _sizeInTiles);
        NSUInteger arrayZOrigin = childTileOrigin.z - 1;
        if (higherMipmapQuality)
        {
            ++_countRefParentTiles[arrayZOrigin][tileIndex];
        }
        else
        {
            --_countRefParentTiles[arrayZOrigin][tileIndex];
        }
    }
}

/// Encode the command to map or unmap the sparse texture tile region.
- (void)updateTileMappingMode:(const TextureTile*)tile
                  mappingMode:(MTLSparseTextureMappingMode)mappingMode
                    onEncoder:(id<MTLResourceStateCommandEncoder>)encoder
{
    MTLRegion pixelRegion = MTLRegionMake2D(tile->origin.x * _tileSize.width,
                                            tile->origin.y * _tileSize.height,
                                            _tileSize.width,
                                            _tileSize.height);
    MTLRegion tileRegion;
    [_device convertSparsePixelRegions:&pixelRegion
                         toTileRegions:&tileRegion
                          withTileSize:_tileSize
                         alignmentMode:MTLSparseTextureRegionAlignmentModeOutward
                            numRegions:1];
    
    [encoder updateTextureMapping:_sparseTexture
                             mode:mappingMode
                           region:tileRegion
                         mipLevel:tile->origin.z
                            slice:0];
}

/// Create a new add tile request when mapping a tile in the sparse texture.
- (bool)newMapTileRequest:(TextureTile*)tile
{
    // Only create an add tile request for tiles that are unmapped.
    if (tile->state != TileState::TileStateUnmapped)
    {
        return true;
    }
    
    // Check if the incoming request exceeds the maximum size of the temporary staging buffer heap.
    // If it exceeds the maximum size, it doesn't create the request.
    NSUInteger incomingUsedSize = ((_mapTilesRequest.size() + 1) * _sparseTileSizeInBytes);
    NSUInteger incomingTempBuffersHeapUsedSize = incomingUsedSize + _stagingBuffersHeap.usedSize;
    if (incomingTempBuffersHeapUsedSize > _stagingBuffersHeap.currentAllocatedSize)
    {
        return false;
    }
    
    // Check if the incoming request exceeds the maximum size of the sparse texture heap.
    // If it exceeds the maximum size, increment the number of tiles to discard from the LRU cache.
    // Those tiles are unmapped later.
    NSUInteger incomingSparseTextureHeapUsedSize = incomingUsedSize + _sparseTextureHeap.usedSize;
    if (incomingSparseTextureHeapUsedSize > _sparseTextureHeap.currentAllocatedSize)
    {
        ++_numTilesToDiscardFromLRU;
    }
    
    tile->state = TileState::TileStateQueueForMapping;
    _mapTilesRequest.push_back(tile);
    return true;
}

/// Create a new unmap tile request when unmapping a tile in the sparse texture.
- (void)newUnmapTileRequest:(TextureTile*)tile
{
    if (tile->state != TileState::TileStateMapped && tile->state != TileState::TileStateStoredInLRUCache)
    {
        return;
    }
    tile->state = TileState::TileStateQueueForUnmapping;
    
    // Update the staging residency buffer for this tile.
    [self updateTextureEntryResidency:tile minMipmapFlag:NO];
    
    _unmapTilesRequest.push_back(tile);
}

/// Create a shared temporary buffer to stage a buffer copy later.
/// The main functionality is to copy texture data from main memory to shared temp buffer.
- (id<MTLBuffer>)streamTileToStagingBuffer:(TextureTile*)tile
{
    id<MTLBuffer> tempBuffer = [_stagingBuffersHeap newBufferWithLength:_sparseTileSizeInBytes options:MTLResourceStorageModeShared];
    
    // The class checks for enough buffers in the heap in `newMapTileRequest` so this is an extra check.
    assert(tempBuffer != nil);
    
    // Block compressed formats require knowledge of the size of the block and bytes per block.
    // The data backing class stores this information in two properties.
    @autoreleasepool
    {
        MTLSize sourceTextureSize = [_sparseTextureBacking calculateMipmapRegion:tile->origin.z].size;
        NSUInteger mipDataOffset  = _sparseTextureBacking.mipmapOffsets[tile->origin.z];
        MTLOrigin copyOrigin = MTLOriginMake(tile->origin.x * _tileSize.width,
                                             tile->origin.y * _tileSize.height,
                                             tile->origin.z);
        copyTileRegionBlockTexture((uint8_t *)_sparseTextureBacking.textureData.bytes + mipDataOffset,
                                   tempBuffer,
                                   sourceTextureSize,
                                   copyOrigin,
                                   _tileSize,
                                   _sparseTextureBacking.blockSize);
    }
    
    return tempBuffer;
}

#pragma mark - Update methods
//------------------------------------------------------------------//

/// Update the sparse texture for the current frameIndex.
- (void)update:(NSUInteger)frameIndex
{
    const std::lock_guard<std::mutex> lock(_updateMutex);

    [self updateAccessCountersBuffer:frameIndex];
    [self processAccessCounters:frameIndex];
    [self discardTilesFromLRU];
    [self mapAndBlitTiles];
}

/// Update the access counter buffer value using the `getTextureAccessCounters` API.
- (void)updateAccessCountersBuffer:(NSUInteger)frameIndex
{
    id<MTLCommandBuffer> cmdBuffer      = [_commandQueue commandBuffer];
    cmdBuffer.label                     = @"Update access counters cmd buffer";
    id<MTLBlitCommandEncoder> encoder   = [cmdBuffer blitCommandEncoder];
    encoder.label                       = @"Update access counters bit encoder";

    for (NSUInteger mipmap = 0; mipmap < _sparseTexture.firstMipmapInTail; ++mipmap)
    {
        NSUInteger accessCountersOffset = _accessCountersMipmapOffsets[mipmap];
        MTLRegion pixelRegion           = [_sparseTextureBacking calculateMipmapRegion:mipmap];
        MTLRegion tileRegion;
        
        [_device convertSparsePixelRegions:&pixelRegion
                             toTileRegions:&tileRegion
                              withTileSize:_tileSize
                             alignmentMode:MTLSparseTextureRegionAlignmentModeOutward
                                numRegions:1];
        
        [encoder getTextureAccessCounters:_sparseTexture region:tileRegion mipLevel:mipmap slice:0
                            resetCounters:YES
                           countersBuffer:_accessCountersBuffer[frameIndex]
                     countersBufferOffset:sizeof(uint) * accessCountersOffset];
    }
    
    [encoder endEncoding];
    [cmdBuffer commit];
}

/// Examine all the texture tile access counters to determine the tiles to stream, the tiles to keep,
/// the tiles to unmap, and the tiles to keep in the LRU cache.
- (void)processAccessCounters:(NSUInteger)frameIndex
{
    const uint* const frameAccessCounters = (uint*)(_accessCountersBuffer[frameIndex].contents);
    for (NSUInteger mipmap = 0; mipmap < _sparseTexture.firstMipmapInTail; ++mipmap)
    {
        // Create a pointer for the counters for this mipmap level. This was
        // determined earlier in the `createAccessCountersBuffer` method.
        const uint* const counters = frameAccessCounters + _accessCountersMipmapOffsets[mipmap];
        for (NSUInteger tileIndex = 0; tileIndex < (NSUInteger) _tiles[mipmap].size(); ++tileIndex)
        {
            TextureTile* tile = &_tiles[mipmap][tileIndex];
            // If the counter value is larger than zero, the GPU accessed the tile region during the previous frame.
            if (counters[tileIndex] > 0)
            {
                // Create a map tile request for all the tile regions in the mipmap chain that
                // correspond to the current tile region.
                for (NSInteger iterMipmap = _sparseTexture.firstMipmapInTail - 1; iterMipmap >= (NSInteger)mipmap; --iterMipmap)
                {
                    MTLOrigin iterOrigin{};
                    iterOrigin.x = tile->origin.x >> (iterMipmap - mipmap);
                    iterOrigin.y = tile->origin.y >> (iterMipmap - mipmap);
                    iterOrigin.z = iterMipmap;
                    
                    NSUInteger iterTileIndex = calculateIndexFromTileOrigin(iterOrigin, _sizeInTiles);
                    TextureTile* iterTile    = &_tiles[iterMipmap][iterTileIndex];
                    iterTile->framesCount    = AAPLMaxFramesInFlight;

                    // Add a new request and stop if it isn't succesful.
                    if (![self newMapTileRequest:iterTile])
                        break;
                    
                    // If the GPU tried to read from an unmapped tile that's in the LRU cache,
                    // re-map the tile from the LRU cache.
                    if (iterTile->state == TileState::TileStateStoredInLRUCache)
                    {
                        _notUsedMappedTilesLRUCache.discard(iterTile);
                        iterTile->state = TileState::TileStateMapped;
                        [self setTextureTileRefCounterParent:iterTile higherMipmapQuality:YES];
                    }
                }
            }
            else
            {
                // Only consider putting a tile in the LRU cache if it's mapped and isn't needed
                // by a parent tile in its mipmap chain.
                bool isTileNotMapped = (tile->state != TileState::TileStateMapped);
                bool isTileUsedByParentTile = (mipmap > 0 && (_countRefParentTiles[mipmap - 1][tileIndex] > 0));
                
                if (isTileNotMapped || isTileUsedByParentTile)
                {
                    continue;
                }
                
                // Only put a texture tile in the LRU cache when the GPU hasn't sampled it
                // in a recent frame.
                tile->framesCount = std::max(0, tile->framesCount - 1);
                if (tile->framesCount <= 0)
                {
                    tile->state = TileState::TileStateStoredInLRUCache;
                    _notUsedMappedTilesLRUCache.put(tile);
                    [self setTextureTileRefCounterParent:tile higherMipmapQuality:NO];
                }
            }
        }
    }
}

/// Check if the sparse texture heap is full or not.
/// If yes, the function discards tiles from LRU cache and creates unmap tile requests.
- (void)discardTilesFromLRU
{
    if (_numTilesToDiscardFromLRU == 0)
        return;
    
    NSUInteger index = 0;
    for (; index < _numTilesToDiscardFromLRU; ++index)
    {
        TextureTile* tile = _notUsedMappedTilesLRUCache.discardLeastRecentlyUsed();
        if (!tile)
        {
            break;
        }
        [self newUnmapTileRequest:tile];
    }
    
    // If the sparse texture heap doesn't have enough memory to accomodate
    // additional mapping requests, remove them from the map tiles list.
    NSUInteger numTileRequestsToRemove = _numTilesToDiscardFromLRU - index;
    NSUInteger mapTilesRequestLength    = (NSUInteger)_mapTilesRequest.size();
    for (NSUInteger failedIndex = 0; failedIndex < numTileRequestsToRemove && failedIndex < mapTilesRequestLength; ++failedIndex)
    {
        TextureTile* tile           = _mapTilesRequest.back();
        tile->state                 = TileState::TileStateUnmapped;
        tile->framesCount           = 0;
        
        _mapTilesRequest.pop_back();
    }

    _numTilesToDiscardFromLRU = 0;
}

/// Map all the tiles that need residency in the sparse texture and blit the corresponding tiles.
- (void)mapAndBlitTiles
{
    if (_mapTilesRequest.empty() && _unmapTilesRequest.empty())
    {
        return;
    }
    
    id<MTLCommandBuffer> cmdBuffer        = [self->_commandQueue commandBuffer];
    cmdBuffer.label                       = @"Tile mapping and blitting cmd buffer";

    // Swap these out with the requests in the main class because the app may run the mapping function asynchronously.
    std::vector<TextureTile*> unmapTilesRequest;
    std::vector<TextureTile*> mapTilesRequest;
    std::swap(unmapTilesRequest, _unmapTilesRequest);
    std::swap(mapTilesRequest, _mapTilesRequest);
    
    // Start by unmapping unused tiles.
    {
        id<MTLResourceStateCommandEncoder> rsEncoder = [cmdBuffer resourceStateCommandEncoder];
        rsEncoder.label = @"Tile mapping resource state encoder";

        for (TextureTile* tile : unmapTilesRequest)
        {
            [self updateTileMappingMode:tile mappingMode:MTLSparseTextureMappingModeUnmap onEncoder:rsEncoder];
            tile->state = TileState::TileStateUnmapped;
        }
        
        for (const auto tile: mapTilesRequest)
        {
            [self updateTileMappingMode:tile
                            mappingMode:MTLSparseTextureMappingModeMap
                              onEncoder:rsEncoder];
        }
        
        [rsEncoder endEncoding];
    }
    // Blit Encoding
    {
        id<MTLBlitCommandEncoder> blitEncoder = [cmdBuffer blitCommandEncoder];
        blitEncoder.label = @"Tile mapping blit encoder";

        // Stream the tiles from the source texture file into the sparse texture heap tiles.
        for (const auto& tile: mapTilesRequest)
        {
            id<MTLBuffer> tempStreamingBuffer = [self streamTileToStagingBuffer:tile];
            
            // `blocksWide` holds the number of blocks of compressed pixels spanning the width of the tile.
            NSUInteger blocksWide       = calculateBlocksWidth(_tileSize.width, _sparseTextureBacking.blockSize, 0);
            NSUInteger bytesPerRow      = blocksWide * _sparseTextureBacking.bytesPerBlock;
            MTLOrigin destinationOrigin = MTLOriginMake(tile->origin.x * _tileSize.width,
                                                        tile->origin.y * _tileSize.height,
                                                        0);
            
            [blitEncoder copyFromBuffer:tempStreamingBuffer
                           sourceOffset:0
                      sourceBytesPerRow:bytesPerRow
                    sourceBytesPerImage:0
                             sourceSize:_tileSize
                              toTexture:_sparseTexture
                       destinationSlice:0
                       destinationLevel:tile->origin.z
                      destinationOrigin:destinationOrigin];
        }

        // Finish the tile requests to update the residency information.
        for (auto& tile: mapTilesRequest)
        {
            tile->state = TileState::TileStateMapped;
            [self updateTextureEntryResidency:tile minMipmapFlag:YES];
            [self setTextureTileRefCounterParent:tile higherMipmapQuality:YES];
        }

        [blitEncoder endEncoding];
    }

    // Update the current state of the mapped tiles in the residency buffer.
    // Do this to allow the shader to access the mapped tiles.
    [cmdBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {
        [self updateResidencyBuffer];
    }];
    [cmdBuffer commit];
}

/// Update the residency data buffer from CPU to GPU to ensure that the
/// fallback sampling will always access the finest available mipmap region.
- (void)updateResidencyBuffer
{
    // Copy the current information into the staging residency buffer.
    memcpy((int8_t*)_residencyBuffers[_residencyBufferIndex].contents,
           &_tileRegionsFinestMipmap[0],
           _tileRegionsFinestMipmap.size());

    // Set the current residency buffer that the renderer uses to sample the sparse texture.
    _residencyBuffer = _residencyBuffers[_residencyBufferIndex];

    // Advance the index to the next staging residency buffer.
    _residencyBufferIndex = (_residencyBufferIndex + 1) % (AAPLMaxFramesInFlight + 1);
}

#pragma mark - Initialization methods
//------------------------------------------------------------------//

/// Creates the sparse texture heap and temporary staging buffer heap.
- (void)createHeaps:(NSUInteger)heapSize
{
    // Create a heap for the sparse texture tiles that are used for rendering.
    {
        _sparseTileSizeInBytes  = _device.sparseTileSizeInBytes;
        // Limit the heap size to device limits.
        heapSize = MIN(heapSize, _device.maxBufferLength);
        // Align the heap size based on the size of sparse tile.
        NSUInteger alignedHeapSize = ((heapSize + _sparseTileSizeInBytes - 1) / _sparseTileSizeInBytes) * _sparseTileSizeInBytes;
        
        MTLHeapDescriptor* heapDescriptor = [MTLHeapDescriptor new];
        heapDescriptor.type               = MTLHeapTypeSparse;
        heapDescriptor.cpuCacheMode       = MTLCPUCacheModeDefaultCache;
        heapDescriptor.storageMode        = MTLStorageModePrivate;
        heapDescriptor.size               = alignedHeapSize;
        heapDescriptor.hazardTrackingMode = MTLHazardTrackingModeUntracked;
        
        _sparseTextureHeap                = [_device newHeapWithDescriptor:heapDescriptor];
        _sparseTextureHeap.label          = @"Sparse texture heap";
        NSAssert(_sparseTextureHeap, @"Failed to create the sparse texture heap.");
    }
    
    // Create a heap for temporary buffers used for blitting data to tiles in the sparse texture heap.
    {
        MTLHeapDescriptor* heapDescriptor = [[MTLHeapDescriptor alloc] init];
        heapDescriptor.type               = MTLHeapTypeAutomatic;
        heapDescriptor.cpuCacheMode       = MTLCPUCacheModeDefaultCache;
        heapDescriptor.storageMode        = MTLStorageModeShared;
        heapDescriptor.size               = _sparseTileSizeInBytes * AAPLMaxStreamingBufferHeapInstCount;
        
        _stagingBuffersHeap               = [_device newHeapWithDescriptor:heapDescriptor];
        _stagingBuffersHeap.label         = @"Staging buffer heap";
        NSAssert(_stagingBuffersHeap, @"Failed to create the staging buffer heap.");
    }
}

/// Map the minimum mipmap level (the first mipmap tail level) for the sparse texture.
- (void)mapMipmapTails
{
    id<MTLCommandBuffer> cmdBuffer                       = [_commandQueue commandBuffer];
    cmdBuffer.label                                      = @"Mipmap tail cmd buffer";
    id<MTLResourceStateCommandEncoder> rsCommandEncoder  = [cmdBuffer resourceStateCommandEncoder];
    rsCommandEncoder.label                               = @"Mipmap tail resource state encoder";
    @autoreleasepool
    {
        // Create the MTLTexture descriptor and allocate sparse texture from _sparseTexturesHeap.
        MTLTextureDescriptor *sparseTexDesc = [[MTLTextureDescriptor alloc] init];
        sparseTexDesc.width                 = _sparseTextureBacking.width;
        sparseTexDesc.height                = _sparseTextureBacking.height;
        sparseTexDesc.mipmapLevelCount      = _sparseTextureBacking.mipmapLevelCount;
        sparseTexDesc.pixelFormat           = _sparseTextureBacking.pixelFormat;
        sparseTexDesc.textureType           = MTLTextureType2D;
        sparseTexDesc.storageMode           = MTLStorageModePrivate;
        
        _sparseTexture = [_sparseTextureHeap newTextureWithDescriptor:sparseTexDesc];
        assert(_sparseTexture != nil);
        _sparseTexture.label = [[NSString alloc] initWithFormat:@"%@ in Heap", _sparseTextureBacking.path];
        
        MTLSize tileSize = [_device sparseTileSizeWithTextureType:MTLTextureType2D
                                                      pixelFormat:_sparseTextureBacking.pixelFormat
                                                      sampleCount:1];
        // Map sparse texture's first mipmap in tail. A tail is the collection
        // of higher index mipmaps that fit inside a memory block. For
        // instance, a 16384 x 16384 texture has 15 mipmap levels and the mipmap
        // tail may start at level 8 (counting from 0) which is 64 x 64.
        // Therefore the mipmap tail contains the 64 x 64, 32 x 32, 16 x 16, 8 x 8,
        // 4 x 4, 2 x 2, and 1 x 1 mipmaps. The memory requirement for this may be
        // 16384 bytes depending on the data format of the texture map.
        {
            MTLRegion pixelRegion = [_sparseTextureBacking calculateMipmapRegion:_sparseTexture.firstMipmapInTail];
            MTLRegion tileRegion;
            
            [_device convertSparsePixelRegions:&pixelRegion
                                 toTileRegions:&tileRegion
                                  withTileSize:tileSize
                                 alignmentMode:MTLSparseTextureRegionAlignmentModeOutward
                                    numRegions:1];
            
            [rsCommandEncoder updateTextureMapping:_sparseTexture
                                              mode:MTLSparseTextureMappingModeMap
                                            region:tileRegion
                                          mipLevel:_sparseTexture.firstMipmapInTail
                                             slice:0];
        }
        MTLRegion pixelRegion = MTLRegionMake2D(0, 0, _sparseTextureBacking.width, _sparseTextureBacking.height);
        
        MTLRegion tileRegion;
        [_device convertSparsePixelRegions:&pixelRegion
                             toTileRegions:&tileRegion
                              withTileSize:tileSize
                             alignmentMode:MTLSparseTextureRegionAlignmentModeOutward
                                numRegions:1];
        
        // The sample texture is 16384x16384. The tile size may by 128x128 and
        // the size in tiles may be 128x128 because 128*128 = 16384.
        _tileSize    = tileSize;
        _sizeInTiles = tileRegion.size;
    }
    
    // Create two arrays: parent mipmap reference counts and the tiles. The
    // parent reference count stores a WxH array of unsigned integers
    // containing the number of parent tiles that reference this mipmap level.
    // The sample doesn't create a parent reference count for mipmap level 0.
    // The tile array contains a WxH array of `TextureTile` which contains the
    // tile origins, state, and use count.
    for (NSUInteger mipmap = 0; mipmap < _sparseTexture.firstMipmapInTail; ++mipmap)
    {
        NSUInteger totalH = (_sizeInTiles.height >> mipmap);
        NSUInteger totalW = (_sizeInTiles.width  >> mipmap);
        // Since mipmap level zero doesnt't have a parent mipmap, allocate a tile container
        // for levels one to mipmap Level `first mipmap tail - 1`
        if (mipmap > 0)
        {
            _countRefParentTiles.push_back(std::vector<NSUInteger>(totalW * totalH, 0));
        }
        _tiles.push_back(std::vector<TextureTile>(totalW * totalH));
        NSUInteger tileIndex = 0;
        for (NSUInteger h = 0; h < totalH; ++h)
        {
            for (NSUInteger w = 0; w < totalW; ++w, ++tileIndex)
            {
                TextureTile& tile   = _tiles[mipmap][tileIndex];
                tile.origin         = MTLOriginMake(w, h, mipmap);
                tile.state          = TileState::TileStateUnmapped;
                tile.framesCount    = 0;
            }
        }
    }
    
    // Create an array to store the finest mipmap level for each tile.
    // Initially, it contains the level of the first mipmap in the tail.
    // This number will go up and down as the app maps and unmaps tiles.
    _tileRegionsFinestMipmap = std::vector<int8_t>(_sizeInTiles.width * _sizeInTiles.height, (int8_t)_sparseTexture.firstMipmapInTail);
    
    // Create residency buffers.
    // They are triple buffered for synchronization.
    NSUInteger residencyBufferLength = _sizeInTiles.width * _sizeInTiles.height * sizeof(int8_t);
    for (int i = 0; i < AAPLMaxFramesInFlight + 1; i++) {
        _residencyBuffers[i] = [_device newBufferWithLength:residencyBufferLength options:MTLResourceStorageModeShared];
        _residencyBuffers[i].label = [[NSString alloc] initWithFormat:@"Residency buffer %@", @(i)];
    }

    [rsCommandEncoder endEncoding];
    [cmdBuffer commit];
    [cmdBuffer waitUntilCompleted];
}

/// Copies the bottom mipmap tail from the KTX to the last mipmap level of the sparse texture and
/// ensures there there is the minimum amount of data for rendering with the sparse texture.
- (void)blitMipmapTails
{
    id<MTLCommandBuffer> cmdBuffer        = [_commandQueue commandBuffer];
    cmdBuffer.label                       = @"Mipmap tail cmd buffer";
    id<MTLBlitCommandEncoder> blitEncoder = [cmdBuffer blitCommandEncoder];
    blitEncoder.label                     = @"Mipmap tail blit encoder";
    
    // Load the mipmap tail, that is always resident, into the sparse texture.
    @autoreleasepool
    {
        // The mipmap count holds the number of mipmaps from the first mipmap tail to
        // the last mipmap level of the sparse texture.
        NSUInteger mipmapCount = _sparseTextureBacking.mipmapLevelCount - _sparseTexture.firstMipmapInTail;
        NSUInteger baseMipmap = _sparseTexture.firstMipmapInTail;
        MTLRegion tempRegion = [_sparseTextureBacking calculateMipmapRegion:_sparseTexture.firstMipmapInTail];
        
        MTLTextureDescriptor *tempTextureDesc = [[MTLTextureDescriptor alloc] init];
        tempTextureDesc.width                 = tempRegion.size.width;
        tempTextureDesc.height                = tempRegion.size.height;
        tempTextureDesc.mipmapLevelCount      = mipmapCount;
        tempTextureDesc.pixelFormat           = _sparseTexture.pixelFormat;
        tempTextureDesc.textureType           = MTLTextureType2D;
        tempTextureDesc.storageMode           = MTLStorageModeShared;
        
        // Create a temporary texture to copy data from first mipmap tail to the last level of the texture.
        // Since this copy is only done once during app initialization, it is okay performance wise to allocate
        // from device instead of from the heap.
        id<MTLTexture> tempTexture = [_device newTextureWithDescriptor:tempTextureDesc];
        // Hold the number of blocks of compressed pixels spanning the width of the tile.
        NSUInteger blocksWide = calculateBlocksWidth(_sparseTextureBacking.width, _sparseTextureBacking.blockSize, baseMipmap);
        
        // Copy the mipmap levels from the sparse texture data backing into the temporary texture.
        // For example, if the texture at baseMipmap is 64 x 64, then the sample will copy the
        // 64 x 64, 32 x 32, ..., 2 x 2, and 1 x 1 mips into the temporary texture.
        for (NSUInteger mipmap = baseMipmap; mipmap < baseMipmap + mipmapCount; ++mipmap)
        {
            NSUInteger bytesPerRow = blocksWide * _sparseTextureBacking.bytesPerBlock;
            NSUInteger mipmapDataOffset = _sparseTextureBacking.mipmapOffsets[mipmap];
            NSUInteger mipmapDataSize = _sparseTextureBacking.mipmapLengths[mipmap];
            NSData *mipmapData = [NSData dataWithBytesNoCopy:((uint8_t *)_sparseTextureBacking.textureData.bytes + mipmapDataOffset) length:mipmapDataSize freeWhenDone:NO];
            MTLRegion region = [_sparseTextureBacking calculateMipmapRegion:mipmap];
            blocksWide = MAX(blocksWide >> 1u, 1);
            [tempTexture replaceRegion:region
                           mipmapLevel:(mipmap - baseMipmap)
                             withBytes:mipmapData.bytes
                           bytesPerRow:bytesPerRow];
        }
        
        // Copy the temporary texture into the sparse texture starting at `baseMipmap` for `mipmapCount` levels.
        [blitEncoder copyFromTexture:tempTexture
                         sourceSlice:0
                         sourceLevel:0
                           toTexture:_sparseTexture
                    destinationSlice:0
                    destinationLevel:baseMipmap
                          sliceCount:1
                          levelCount:mipmapCount];
    }
    
    [blitEncoder endEncoding];
    [cmdBuffer commit];
    [cmdBuffer waitUntilCompleted];
}

/// Create the access counter buffers for each frame in flight.
- (void)createAccessCountersBuffer
{
    _accessCountersSize = 0;
    
    for (NSUInteger mipmap = 0; mipmap < _sparseTexture.firstMipmapInTail; ++mipmap)
    {
        // Offset to the mipmap level access counter buffer you're looking for.
        _accessCountersMipmapOffsets.push_back(_accessCountersSize);
        
        MTLRegion pixelRegion = [_sparseTextureBacking calculateMipmapRegion:mipmap];
        MTLRegion tileRegion;
        // The GPU's counts the number of times the GPU samples each texture region.
        // But it counts by texture region instead of pixel coordates.
        // Use convertSparsePixelRegions to convert the pixel coordinate region to a tile coordinate region.
        [_device convertSparsePixelRegions:&pixelRegion
                             toTileRegions:&tileRegion
                              withTileSize:_tileSize
                             alignmentMode:MTLSparseTextureRegionAlignmentModeOutward
                                numRegions:1];
        
        NSUInteger numCountersInMipmap = tileRegion.size.width * tileRegion.size.height;
        _accessCountersSize         = _accessCountersSize + numCountersInMipmap;
    }
    
    // Create the access counter buffers. For a 16384 x 16384 texture with
    // 128 x 128 tiles, the sample may create each access array of type `uint`
    // to be (16384+4096+1024+256+64+16+4+1)*sizeof(uint) ≈ 87,380 bytes.
    for (NSUInteger i = 0; i < AAPLMaxFramesInFlight; i++)
    {
        _accessCountersBuffer[i] = [_device newBufferWithLength:sizeof(uint) * _accessCountersSize
                                                        options:MTLResourceStorageModeShared];
        _accessCountersBuffer[i].label = [[NSString alloc] initWithFormat:@"Texture access counters buffer %luu", i];
    }
}

@end
