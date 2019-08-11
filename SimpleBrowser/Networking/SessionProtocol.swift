//
//  SessionProtocol.swift
//  SimpleBrowser
//
//  Created by Jozef Lipovsky on 2019-08-03.
//  Copyright © 2019 JoLi. All rights reserved.
//

import Foundation

protocol SessionProtocol {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: SessionProtocol { }
