//
//  AuthorNetworkRemote.swift
//  SwiftyPress
//
//  Created by Basem Emara on 2019-05-17.
//  Copyright © 2019 Zamzam Inc. All rights reserved.
//

import Foundation
import ZamzamCore

public struct AuthorNetworkRemote: AuthorRemote {
    private let networkRepository: NetworkRepositoryType
    private let jsonDecoder: JSONDecoder
    private let constants: ConstantsType
    private let log: LogRepositoryType
    
    public init(
        networkRepository: NetworkRepositoryType,
        jsonDecoder: JSONDecoder,
        constants: ConstantsType,
        log: LogRepositoryType
    ) {
        self.networkRepository = networkRepository
        self.jsonDecoder = jsonDecoder
        self.constants = constants
        self.log = log
    }
}

public extension AuthorNetworkRemote {
    
    func fetch(id: Int, completion: @escaping (Result<AuthorType, DataError>) -> Void) {
        let urlRequest: URLRequest = .readAuthor(id: id, constants: constants)
        
        networkRepository.send(with: urlRequest) {
            // Handle errors
            guard case .success = $0 else {
                // Handle no existing data
                if $0.error?.statusCode == 404 {
                    completion(.failure(.nonExistent))
                    return
                }
                
                self.log.error("An error occured while fetching the author: \(String(describing: $0.error)).")
                completion(.failure(DataError(from: $0.error)))
                return
            }
            
            // Ensure available
            guard case .success(let value) = $0, let data = value.data else {
                completion(.failure(.nonExistent))
                return
            }
            
            DispatchQueue.transform.async {
                do {
                    // Type used for decoding the server payload
                    struct ServerResponse: Decodable {
                        let author: Author
                    }
                    
                    // Parse response data
                    let payload = try self.jsonDecoder.decode(ServerResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        completion(.success(payload.author))
                    }
                } catch {
                    self.log.error("An error occured while parsing the author: \(error).")
                    DispatchQueue.main.async { completion(.failure(.parseFailure(error))) }
                    return
                }
            }
        }
    }
}

// MARK: - Requests

private extension URLRequest {
    
    static func readAuthor(id: Int, constants: ConstantsType) -> URLRequest {
        URLRequest(
            url: constants.baseURL
                .appendingPathComponent(constants.baseREST)
                .appendingPathComponent("author/\(id)"),
            method: .get
        )
    }
} 
