/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A generic stack container that the app uses to maintain a navigation history.
*/

import Foundation

/// A generic stack data structure backed by an array.
open class Stack<T>: ExpressibleByArrayLiteral {
  
  /// Index `0` is the "bottom" of the stack, index `list.count-1` is the "top" of the stack.
  public private(set) var list: [T] = []
  
  /// The number of elements in the stack.
  public var count: Int { return list.count }
  
  public init() {}
  
  public required init(arrayLiteral elements: T...) {
    self.list = elements
  }
  
  /// Puts an element on the top of the stack.
  public func push(_ element: T) {
    list.append(element)
  }
  
  /// Removes an element from the top of the stack, and returns it.
  @discardableResult
  public func pop() -> T? {
    return list.popLast()
  }
  
  /// Returns the element at the top of the stack, without removing it.
  public func peek() -> T? {
    return list.last
  }

  public func removeAll() {
    list.removeAll()
  }
}
