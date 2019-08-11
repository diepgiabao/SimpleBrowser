//
//  APIClient.swift
//  SimpleBrowser
//
//  Created by Jozef Lipovsky on 2019-08-03.
//  Copyright © 2019 JoLi. All rights reserved.
//

import Foundation


class APIClient<T: Decodable> {
    private let session: SessionProtocol
    
    init(session: SessionProtocol) {
        self.session = session
    }
    
    convenience init() {
        self.init(session: URLSession.shared)
    }
    
    @discardableResult func request(with url: URL?, completion: @escaping (T?, Error?) -> ()) -> URLSessionDataTask? {
        guard let url = url else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "", code: 99999, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            }
            return nil
        }
        
        let task = session.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "", code: 888888, userInfo: [NSLocalizedDescriptionKey: "Service Error"]))
                }
                return
            }
            
            do {
                let searchSuggestion = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(searchSuggestion, nil)
                }
                
            } catch let error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
        return task
    }
}
