//
// SortDescriptor.swift
//
// Swift APIs to mimic Foundations NSSortDescriptor but with Type safety
//
// Copyright © 11/24/20 Mike Retondo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

/// A sorting predicate that returns `true` if the first value should be ordered before the second.
public typealias SortDescriptor<Root> = (Root, Root) -> Bool

/// Returns a Bool value, because that's the standard library's convention for comparison predicates
/// - Parameter key: (Root) -> Value
/// - Parameter areInIncreasingOrder: (Value, Value) -> Bool
public func sortDescriptor<Root, Value> (
    key: @escaping (Root) -> Value,
    by areInIncreasingOrder: @escaping (Value, Value) -> Bool) -> SortDescriptor<Root>
{
    return { areInIncreasingOrder(key($0), key($1)) }
}

///
/// Function that works for all Comparable types.
///
/// Overloaded variant of function:
///
///     public func sortDescriptor<Root, Value> (
///         key: @escaping (Root) -> Value,
///         by areInIncreasingOrder: @escaping (Value, Value) -> Bool) -> SortDescriptor<Root>
/// - Parameter key: (Root) -> Value
public func sortDescriptor<Root, Value>( key: @escaping (Root) -> Value) -> SortDescriptor<Root>
    where Value: Comparable
{
    return { key($0) < key($1) }
}

// Overloaded variant of above functions for Foundation APIs like String:localizedStandardCompare(_:)
// which expect a three-way ComparisonResult value instead (ordered ascending, descending, or equal)

///
/// Function for Foundation APIs like String:localizedStandardCompare(_:) which expect a three-way
/// enum ComparisonResult (.orderedAscending, .orderedDescending, .orderedSame)
///
/// Overloaded variant of function:
///
///     public func sortDescriptor<Root, Value> (
///         key: @escaping (Root) -> Value,
///         by areInIncreasingOrder: @escaping (Value, Value) -> Bool) -> SortDescriptor<Root>
/// - Parameter key: (Root) -> Value
/// - Parameter ascending: true if ascending else false
/// - Parameter comparator: (Value) -> (Value) -> ComparisonResult
public func sortDescriptor<Root, Value> (
    key: @escaping (Root) -> Value,
    ascending: Bool = true,
    by comparator: @escaping (Value) -> (Value) -> ComparisonResult) -> SortDescriptor<Root>
{
    return { lhs, rhs in
        let order: ComparisonResult = ascending ? .orderedAscending : .orderedDescending
        return comparator(key(lhs))(key(rhs)) == order
    }
}

/// Combines multiple sort descriptors into a single sort descriptor.
/// First it tries the first descriptor and uses that comparison result.
/// However, if the result is equal, it uses the second descriptor, and
/// so on, until we run out of descriptors.
///
///     let sortByFirstName: SortDescriptor<Person> = sortDescriptor(key: { $0.first }, by: String.localizedStandardCompare)
///     let sortByLastName: SortDescriptor<Person> = sortDescriptor(key: { $0.last }, by: String.localizedStandardCompare)
///     var combinedSortDescriptors: SortDescriptor<Person> = combine(sortDescriptors: [sortByLastName, sortByFirstName])
///
/// - Parameter sortDescriptors: [SortDescriptor]
public func combineSortDescriptors<Root> (using sortDescriptors: [SortDescriptor<Root>]) -> SortDescriptor<Root>
{
    return { lhs, rhs in
        for areInIncreasingOrder in sortDescriptors {
            if areInIncreasingOrder(lhs, rhs) {
                return true
            }

            // flip lhs and rhs order
            if areInIncreasingOrder(rhs, lhs) {
                return false
            }
        }

        return false
    }
}

///
/// lift() allows you to “lift” a regular comparison function into the domain of optionals, and
/// it can be used together with our sortDescriptor function.
///
/// It takes a regular comparison function such as String:localizedStandardCompare(_:),
/// which works on two objects, 'self' and the object passed to it. It then turns it into a
/// function that takes two optional objects e.g. (lhs: String?, rhs: String?) -> ComparisonResult.
///
///     extension String {
///         var fileExtension: String? {
///             guard let period = lastIndex(of: ".") else { return nil }
///
///             let extensionStart = index(after: period)
///             return String(self[extensionStart...])
///         }
///     }
///
///     var files = ["file.swift", "one", "two", "test.h", "three", "file.h", "file.", "file.c"]
///
///     // compare(lhs: String?, rhs: String?) -> ComparisonResult
///     let compare = lift(String.localizedStandardCompare)
///
///     // return ["one", "two", "three", "file.", "file.c", "test.h", "file.h", "file.swift"]
///     let result = files.sorted(by: sortDescriptor(key: { $0.fileExtension }, by: compare))
///
/// - Parameter compare: a regular comparison compare function such as String:localizedStandardCompare(_:)
/// - Returns: A ComparisonResult.
public func lift<A> (_ compare: @escaping (A) -> (A) -> ComparisonResult) -> (A?) -> (A?) -> ComparisonResult
{
    return { lhs in { rhs in
        switch (lhs, rhs) {
        case (nil, nil): return .orderedSame
        case (nil, _): return .orderedAscending
        case (_, nil): return .orderedDescending
        case let (l?, r?): return compare(l)(r)
        }
    }}
}
