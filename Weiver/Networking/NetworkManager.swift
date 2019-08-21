//
//  NetworkManager.swift
//  Weiver
//
//  Created by Nikita Elizarov on 02.07.2019.
//  Copyright © 2019 Nikita Elizarov. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON

struct NetworkManager: APIProtocol {

    var provider = MoyaProvider<API>(plugins: [NetworkLoggerPlugin(verbose: true)])
    static let shared = NetworkManager()

    func postAnswer(text: String, placeId: String, completion: @escaping (String) -> Void,  failure: @escaping () -> Void) {
        provider.request(.processReview(text: text, placeId: placeId)) { result in
            switch result {
            case let .success(moyaResponse):
                do {
                    let data = moyaResponse.data
                    let json = try JSON(data: data) // convert network data to json
                    let text = json[0].string as! String

                    let splittedText = String(text.split(separator: "%")[0]) 

                    print(splittedText)
                    completion(splittedText)
                    
                } catch let error {
                    print(error.localizedDescription)
                    failure()
                }

            case let .failure(error):
                print (error.localizedDescription)

            }
        }
    }

}

