//
//  File.swift
//
// from https://stackoverflow.com/questions/51822718/xcode-unit-testing-add-a-common-function-to-be-used-across-all-test-classes
//
//  Created by stephan mantler on 22.12.2020.
//

import Foundation

struct CSVTestUtility {

    static func csv(data: String) ->  [[Double]] {

        return data.components(separatedBy: "\n")
            .dropFirst()
            .map { row in row.components(separatedBy: ",").map { value in Double(value) ?? .nan } }
    }

    static func cleanRows(file:String)->String{
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        return cleanFile
    }

    static func readDataFromCSV(named filename: String)-> String!{

        let baseUrl = URL(fileURLWithPath: #filePath, isDirectory: false)
        let path = baseUrl.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(filename)

        do {
            let contents = try String(contentsOf: path, encoding: .utf8)
            return contents
        } catch {
            print("File Read Error for file \(path)")
            return nil
        }
    }
}
