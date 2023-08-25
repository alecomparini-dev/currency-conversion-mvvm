//
//  HTTPPost.swift
//  currency-conversion-mvvm
//
//  Created by Alessandro Comparini on 19/08/23.
//

import Foundation

protocol HTTPGetClient {
    func get(url: URL, parameters: Dictionary<String, String>) async throws -> Data
}

