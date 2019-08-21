//
//  APIProtocol.swift
//  Weiver
//
//  Created by Nikita Elizarov on 02.07.2019.
//  Copyright © 2019 Nikita Elizarov. All rights reserved.
//

import Foundation
import Moya

protocol APIProtocol {
    var provider: MoyaProvider<API> { get }

    func postAnswer(text: String, placeId: String, completion: @escaping (String) -> Void, failure: @escaping () -> Void)
}
