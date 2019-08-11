//
//  SearchSuggestions.swift
//  SimpleBrowser
//
//  Created by Jozef Lipovsky on 2019-07-31.
//  Copyright © 2019 JoLi. All rights reserved.
//

import Foundation

struct SearchSuggestions: Decodable {
    let keyWord: String
    let suggestions: [String]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.keyWord = try container.decode(String.self)
        self.suggestions = try container.decode([String].self)
    }
}
