/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An implementation of a single producer/single consumer queue.
*/

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <vector>
#include <optional>

template <typename T>
class SingleProducerSingleConsumerQueue {
public:
    explicit SingleProducerSingleConsumerQueue(size_t maxNumOfElements)
    : elements(maxNumOfElements) {
    }

    bool push(T obj) {
        using namespace std;
        const auto readPos = _readPos.load(memory_order_acquire);

        if (_writePos == readPos && numElements.load(memory_order_acquire) > 0)
            return false;   // The queue is exhausted.

        elements[_writePos] = std::move(obj);
        std::atomic_thread_fence(std::memory_order_release);
        
        if (++_writePos >= elements.size())
            _writePos = 0;

        numElements.fetch_add(1, memory_order_acq_rel);
        return true;
    }

    std::optional<T> pop() {
        using namespace std;
        if (numElements.load(memory_order_acquire) == 0)
            return {};

        size_t readPos = _readPos.load(memory_order_relaxed);
        T obj = std::move(elements[readPos]);
        _readPos.store((++readPos >= elements.size()) ? 0 : readPos);
        numElements.fetch_sub(1, memory_order_acq_rel);
        return obj;
    }

private:

    std::vector<T>       elements;
    size_t               _writePos = 0;
    std::atomic<size_t>  _readPos = {0};
    alignas(64)  // Prevents false sharing.
    std::atomic<size_t>  numElements = {0};
};
