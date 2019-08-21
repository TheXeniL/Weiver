//
//  API.swift
//  Weiver
//
//  Created by Nikita Elizarov on 02.07.2019.
//  Copyright © 2019 Nikita Elizarov. All rights reserved.
//

import Foundation
import Moya

public enum API {
    case processReview(text: String, placeId: String)
}

extension API: TargetType {
    public var sampleData: Data {
        return Data.init()
    }

    public var baseURL: URL {
        guard let url = URL(string: "http://35.234.77.26:5000/reviewSystem/") else { fatalError("baseURL is not configured")}
        return url
    }

    public var path: String {
        switch self {
        case .processReview :
            return "processReview"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .processReview:
            return .post
        }
    }

    public var parameters: [String: Any] {
        switch self {
        case .processReview(let text, let placeId):
            var parameters: [String: Any] = [:]
            parameters["review"] = ["speech": text]
            parameters["place_id"] = placeId
            return parameters
        }
    }

    public var parameterEncoding: ParameterEncoding {
        switch self {
        default:
            return JSONEncoding.default
        }
    }

    public var task: Task {
        switch self {
        default: return .requestParameters(parameters: parameters, encoding: parameterEncoding)
        }
    }

    public var headers: [String : String]? {
        switch self {
        default:
            return [
                "Content-Type": "application/json",
                "Api-Version": "1.0"
            ]
        }
    }
}
