//
//  MediaNetworkService.swift
//  SwiftyPress
//
//  Created by Basem Emara on 2019-05-17.
//  Copyright © 2019 Zamzam Inc. All rights reserved.
//

import Foundation
import ZamzamCore

public struct MediaNetworkService: MediaService {
    private let networkRepository: NetworkRepository
    private let jsonDecoder: JSONDecoder
    private let constants: Constants
    private let log: LogRepository
    
    public init(
        networkRepository: NetworkRepository,
        jsonDecoder: JSONDecoder,
        constants: Constants,
        log: LogRepository
    ) {
        self.networkRepository = networkRepository
        self.jsonDecoder = jsonDecoder
        self.constants = constants
        self.log = log
    }
}

public extension MediaNetworkService {
    
    func fetch(id: Int, completion: @escaping (Result<Media, SwiftyPressError>) -> Void) {
        let urlRequest: URLRequest = .readMedia(id: id, constants: constants)
        
        networkRepository.send(with: urlRequest) {
            // Handle errors
            guard case .success = $0 else {
                // Handle no existing data
                if $0.error?.statusCode == 404 {
                    completion(.failure(.nonExistent))
                    return
                }
                
                self.log.error("An error occured while fetching the media: \(String(describing: $0.error)).")
                completion(.failure(SwiftyPressError(from: $0.error ?? .init(request: urlRequest))))
                return
            }
            
            // Ensure available
            guard case let .success(item) = $0, let data = item.data else {
                completion(.failure(.nonExistent))
                return
            }
            
            DispatchQueue.transform.async {
                do {
                    // Type used for decoding the server payload
                    struct ServerResponse: Decodable {
                        let media: Media
                    }
                    
                    // Parse response data
                    let payload = try self.jsonDecoder.decode(ServerResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        completion(.success(payload.media))
                    }
                } catch {
                    self.log.error("An error occured while parsing the media: \(error).")
                    DispatchQueue.main.async { completion(.failure(.parseFailure(error))) }
                    return
                }
            }
        }
    }
}

// MARK: - Requests

private extension URLRequest {
    
    static func readMedia(id: Int, constants: Constants) -> URLRequest {
        URLRequest(
            url: constants.baseURL
                .appendingPathComponent(constants.baseREST)
                .appendingPathComponent("media/\(id)"),
            method: .get
        )
    }
}
