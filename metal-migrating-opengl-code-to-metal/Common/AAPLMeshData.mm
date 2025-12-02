/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of mesh and submesh objects used for managing model data.
*/

#import "AAPLMeshData.h"
#import <vector>
#import <unordered_map>


// Implement `operator==` to use `AAPLVertexData` as a hash key in an unordered map.
bool operator==(const AAPLVertexData & lhs, const AAPLVertexData & rhs)
{
    return(simd::all(lhs.position == rhs.position) &&
           simd::all(lhs.normal == rhs.normal) &&
           simd::all(lhs.texcoord == rhs.texcoord));
}

// Implement a hash function for `AAPLVertexData` to use it as a key in an unordered map.
template<> struct std::hash<AAPLVertexData>
{
    std::size_t operator()(const AAPLVertexData& k) const
    {
        std::size_t hash = 0;
        for (uint w = 0; w < sizeof(AAPLVertexData) / sizeof(std::size_t); w++)
            hash ^= (((std::size_t*)&k)[w] ^ (hash << 8) ^ (hash >> 8));
        return hash;
    }
};

@implementation AAPLSubmeshData
{
    std::vector<uint32_t> _indexVector;
}

- (void)addIndex:(uint32_t)index
{
    _indexVector.push_back(index);
}

- (void)setBaseColorMapURL:(nullable NSURL *)baseColorMapURL
{
    _baseColorMapURL = baseColorMapURL;
}

- (uint32_t*) indexData
{
    return &_indexVector[0];
}

- (NSUInteger) indexCount
{
    return _indexVector.size();
}
@end

@implementation AAPLMeshData
{
    NSMutableDictionary<NSString*, AAPLSubmeshData *> *_submeshes;
    AAPLSubmeshData *_currentSubmesh;

    std::vector<vector_float3>  _positions;
    std::vector<vector_float3>  _normals;
    std::vector<vector_float2>  _texcoords;
    std::vector<AAPLVertexData> _vertices;

    std::unordered_map<AAPLVertexData, uint32_t> _vertexMap;

    NSURL *_OBJURL;
}

- (NSDictionary<NSString*, AAPLSubmeshData *>*)submeshes
{
    return _submeshes;
}

- (NSUInteger)vertexCount
{
   return _vertices.size();
}

- (nonnull AAPLVertexData*)vertexData
{
    return &_vertices[0];
}

- (void)parseMaterialFile:(NSURL*)materialURL
{
    NSError *error;
    NSString *fileString = [[NSString alloc] initWithContentsOfURL:materialURL
                                                          encoding:NSUTF8StringEncoding
                                                             error:&error];

    if(!fileString)
    {
        NSLog(@"Failed to open .mtl file, error: %@.", error);
        assert(!"Failed to open .mtl file.");
    }

    NSArray<NSString*> *lines = [fileString componentsSeparatedByString:@"\n"];

    fileString = nil;

    AAPLSubmeshData * currentSubmesh;

    char scannedString[256];

    for(NSString* line in lines)
    {
        if (sscanf(line.UTF8String, " newmtl %255s", scannedString) == 1)
        {
            NSString *materialNameString = [[NSString alloc] initWithUTF8String:scannedString];

            currentSubmesh = [AAPLSubmeshData new];

            _submeshes[materialNameString] = currentSubmesh;
        }
        else if (sscanf(line.UTF8String, " map_Kd %255s", scannedString) == 1)
        {
            assert(currentSubmesh);

            NSString *textureString = [[NSString alloc] initWithUTF8String:scannedString];
            NSURL *URL = [_OBJURL URLByDeletingLastPathComponent];
            URL = [URL URLByAppendingPathComponent:textureString];
            [currentSubmesh setBaseColorMapURL:URL];
        }
    }
}

- (uint32_t) findIndexOrPushVertex:(const AAPLVertexData &)vertex
{
    auto ref = _vertexMap.find(vertex);

    if(ref == _vertexMap.end())
    {
        _vertexMap.insert(std::pair<AAPLVertexData,uint32_t>(vertex, _vertices.size()));
        _vertices.push_back(vertex);
        return (uint32_t)(_vertices.size() - 1);
    }
    else
    {
        return ref->second;
    }
}

- (void)readLine:(NSString*)line
{
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    uint ivp[4];  // Position Index
    uint ivn[4]; // Normal Index
    uint ivt[4]; // Texture Coordinate Index

    char scannedString[256];

    if (sscanf(line.UTF8String, " v %f %f %f", &x, &y, &z) == 3)
    {
        // If a position is specified
        _positions.push_back( (vector_float3) {x,y,z} );
    }
    else if (sscanf(line.UTF8String, " vt %f %f %f", &x, &y, &z) == 3)
    {
        // A texture coordinate is specified
        _texcoords.push_back( (vector_float2) {x,y} );
    }
    else if (sscanf(line.UTF8String, " vn %f %f %f", &x, &y, &z) == 3)
    {
        // A normal is specified
        _normals.push_back( (vector_float3) {x,y,z} );
    }
    else if (sscanf(line.UTF8String, " f %d/%d/%d %d/%d/%d %d/%d/%d %d/%d/%d",
                    &ivp[0], &ivt[0], &ivn[0], &ivp[1],
                    &ivt[1], &ivn[1], &ivp[2], &ivt[2],
                    &ivn[2], &ivp[3], &ivt[3], &ivn[3]) == 12)
    {
        // If a quad is specified
        uint32_t indices[4];
        for (uint v = 0; v < 4; v++)
        {
            AAPLVertexData vertex;
            vertex.position = _positions[ivp[v]-1];
            vertex.normal   = _normals  [ivn[v]-1];
            vertex.texcoord = _texcoords[ivt[v]-1];
            indices[v] = [self findIndexOrPushVertex:vertex];
        }
        [_currentSubmesh addIndex:indices[0]];
        [_currentSubmesh addIndex:indices[1]];
        [_currentSubmesh addIndex:indices[2]];
        [_currentSubmesh addIndex:indices[0]];
        [_currentSubmesh addIndex:indices[2]];
        [_currentSubmesh addIndex:indices[3]];
    }
    else if (sscanf(line.UTF8String, " f %d/%d/%d %d/%d/%d %d/%d/%d",
                    &ivp[0], &ivt[0], &ivn[0],
                    &ivp[1], &ivt[1], &ivn[1],
                    &ivp[2], &ivt[2], &ivn[2]) == 9) // triangle
    {
        // If a triangle is specified
        uint32_t indices[3];
        for (uint v = 0; v < 3; v++)
        {
            AAPLVertexData vertex;
            vertex.position = _positions[ivp[v]-1];
            vertex.normal   = _normals  [ivn[v]-1];
            vertex.texcoord = _texcoords[ivt[v]-1];
            indices[v] = [self findIndexOrPushVertex:vertex];
        }
        [_currentSubmesh addIndex:indices[0]];
        [_currentSubmesh addIndex:indices[1]];
        [_currentSubmesh addIndex:indices[2]];
    }
    else if (sscanf(line.UTF8String, " mtllib %255s", scannedString) == 1)
    {
        NSString *materialFileNameString = [[NSString alloc] initWithUTF8String:scannedString];
        NSURL *materialFileURL = [_OBJURL URLByDeletingLastPathComponent];
        materialFileURL = [materialFileURL URLByAppendingPathComponent:materialFileNameString];
        [self parseMaterialFile:materialFileURL];
    }
    else if (sscanf(line.UTF8String, " usemtl %255s", scannedString) == 1)
    {
        NSString *materialNameString = [[NSString alloc] initWithUTF8String:scannedString];
        _currentSubmesh = _submeshes[materialNameString];
        assert(_currentSubmesh);
    }
}

- (void)parseOBJFile
{
    NSError *error;

    NSString *fileString = [[NSString alloc] initWithContentsOfURL:_OBJURL
                                                          encoding:NSUTF8StringEncoding
                                                             error:&error];

    if(!fileString)
    {
        NSLog(@"Failed to open .obj file, error: %@.", error);
        assert(!"Failed to open .obj file.");
    }

    NSArray<NSString*> *lines = [fileString componentsSeparatedByString:@"\n"];

    fileString = nil;

    for(NSString* line in lines)
    {
        [self readLine:line];
    }

    lines = nil;

    _positions.clear();
    _texcoords.clear();
    _normals.clear();
    _vertexMap.clear();
}

- (nullable instancetype)initWithURL:(nonnull NSURL*)URL
                               error:(NSError * __nullable * __nullable)error;
{
    self = [super init];
    if(self)
    {
        _OBJURL = URL;

        _submeshes = [NSMutableDictionary new];

        [self parseOBJFile];
    }
    return self;
}

@end
