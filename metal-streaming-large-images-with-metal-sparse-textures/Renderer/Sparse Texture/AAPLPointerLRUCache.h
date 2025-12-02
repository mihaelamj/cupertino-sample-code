/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the class that manages the least-recently used list of pointers.
*/
#pragma once

#include <list>
#include <unordered_map>

/// AAPLPointerLRUCache manages the least-recently used list of pointers.
template <typename PointerType>
class AAPLPointerLRUCache
{
public:
    AAPLPointerLRUCache() {}
    
    ~AAPLPointerLRUCache()
    {
        _lru.clear();
        _lruNodes.clear();
    }
    
    /// Gets the pointer (if it exists) from the cache and moves it to the front of the LRU cache.
    PointerType get(PointerType dataPtr)
    {
        auto nodeIter = _lruNodes.find(dataPtr);
        if (nodeIter == _lruNodes.end())
            return nullptr;
        moveDataNodeToHead(nodeIter->second);
        return *(nodeIter->second);
    }
    
    /// Adds the pointer to the LRU cache.
    void put(PointerType dataPtr)
    {
        if (_lruNodes.count(dataPtr))
            return;
        _lru.push_front(dataPtr);
        _lruNodes[dataPtr] = _lru.begin();
    }
    
    /// Returns and removes the least recently used element from the LRU cache.
    PointerType discardLeastRecentlyUsed()
    {
        if (_lru.empty())
            return nullptr;
        PointerType dataPtr = _lru.back();
        _lru.pop_back();
        _lruNodes.erase(dataPtr);
        return dataPtr;
    }
    
    /// Discards the pointer from the LRU cache.
    void discard(PointerType dataPtr)
    {
        if (_lru.empty())
            return;
        auto nodeIter = _lruNodes.find(dataPtr);
        if (nodeIter == _lruNodes.end())
            return;
        _lru.erase(nodeIter->second);
        _lruNodes.erase(nodeIter);
    }
    
    /// Returns the size of the cache.
    size_t size() const
    {
        return _lruNodes.size();
    }
    
private:
    using NodeIter = typename std::list<PointerType>::iterator;

    std::list<PointerType> _lru;
    std::unordered_map<PointerType, NodeIter> _lruNodes;
    
    /// Moves nodeIter to the front of the list.
    void moveNodeToHead(NodeIter nodeIter)
    {
        _lru.push_front(*nodeIter);
        _lru.erase(nodeIter);
    }
};
