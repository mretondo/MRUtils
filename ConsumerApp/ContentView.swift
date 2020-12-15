//
//  ContentView.swift
//  ConsumerApp of the SortDescriptor library
//
//  Created by Mike Retondo on 11/24/20.
//  Copyright © 2020 Mike Retondo. All rights reserved.
//

import SwiftUI
import MRUtils

//
// sort array of people with different names and birth years (asending/desending)
//
@objcMembers
final class Person: NSObject
{
    let first: String
    let last: String
    let yearOfBirth: Int

    init(first: String, last: String, yearOfBirth: Int)
    {
        self.first = first
        self.last = last
        self.yearOfBirth = yearOfBirth
        // super.init() implicitly called here
    }

    override var debugDescription: String {
        return first + " " + last + " " + String(yearOfBirth)
    }

    override var description: String { "\(first) \(last) \(yearOfBirth)" }
}

// Define an array of people with different names and birth years
let people = [
    Person(first: "Emily",  last: "Young",  yearOfBirth: 2002),
    Person(first: "David",  last: "Gray",   yearOfBirth: 1991),
    Person(first: "Robert", last: "Barnes", yearOfBirth: 1985),
    Person(first: "Ava",    last: "Barnes", yearOfBirth: 2000),
    Person(first: "Joanne", last: "Miller", yearOfBirth: 1994),
    Person(first: "Ava",    last: "Barnes", yearOfBirth: 1998),
]

let sortByYear: SortDescriptor<Person> = sortDescriptor(key: { $0.yearOfBirth })
let sortByFirstName: SortDescriptor<Person> = sortDescriptor(key: { $0.first }, by: String.localizedStandardCompare)
let sortByLastName: SortDescriptor<Person> = sortDescriptor(key: { $0.last }, by: String.localizedStandardCompare)
let sortByYearDesending: SortDescriptor<Person> = sortDescriptor(key: { $0.yearOfBirth }, by: >)

var combinedSortDescriptors: SortDescriptor<Person> = combineSortDescriptors (using: [sortByLastName, sortByFirstName, sortByYear])
var asendingPeople = people.sorted(by: combinedSortDescriptors)
var desendingPeople = people.sorted(by: combineSortDescriptors (using: [sortByLastName, sortByFirstName, sortByYearDesending]))

//
// Sort Finder filenames only by their extensions
// Missing extensions come first i.e. "file", then by empty extensions i.e. "file.” and finally by extensions
//
extension String {
    var fileExtension: String? {
        guard let period = lastIndex(of: ".") else { return nil }

        let extensionStart = index(after: period)
        return String(self[extensionStart...])
    }
}

var files = ["file.swift", "one", "two", "test.h", "three", "file.h", "file.", "file.c"]

let compare = lift(String.localizedStandardCompare)
let filesAsending = files.sorted(by: sortDescriptor(key: { $0.fileExtension }, by: compare))
// ["one", "two", "three", "file.", "file.c", "test.h", "file.h", "file.swift"]

var filesDescending: String {
    files.sort { e0, e1 in
        // don't swap items if both don't have extensions
        if e1.fileExtension == nil && e0.fileExtension == nil {
            return false
        }

        // if file on the right has no extension it comes first
        if e0.fileExtension == nil {
            return true
        }

        // if file on the left has no extension it comes first
        if e1.fileExtension == nil {
            return false
        }

        return e1.fileExtension.flatMap { e0.fileExtension?.localizedStandardCompare($0) } == .orderedDescending
    }
    // files ["one", "two", "three", "file.swift", "test.h", "file.h", "file.c", "file."]
    return files.description
}

    var filename = "file.swift"

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text(asendingPeople.description).padding()
            Text(desendingPeople.description).padding()
            Text(files.description).padding()
            Text(filesAsending.description).padding()
            Text(filesDescending).padding()
            Text(filename)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
