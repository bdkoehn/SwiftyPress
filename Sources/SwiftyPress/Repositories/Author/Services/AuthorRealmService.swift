//
//  AuthorRealmService.swift
//  SwiftyPress
//
//  Created by Basem Emara on 2018-10-20.
//  Copyright © 2019 Zamzam Inc. All rights reserved.
//

import Foundation
import RealmSwift
import ZamzamCore

public struct AuthorRealmService: AuthorService {}

public extension AuthorRealmService {
    
    func fetch(id: Int, completion: @escaping (Result<Author, SwiftyPressError>) -> Void) {
        DispatchQueue.database.async {
            let realm: Realm
            
            do {
                realm = try Realm()
            } catch {
                DispatchQueue.main.async { completion(.failure(.databaseFailure(error))) }
                return
            }
            
            guard let object = realm.object(ofType: AuthorRealmObject.self, forPrimaryKey: id) else {
                DispatchQueue.main.async { completion(.failure(.nonExistent)) }
                return
            }
            
            let item = Author(from: object)
            
            DispatchQueue.main.async {
                completion(.success(item))
            }
        }
    }
}

public extension AuthorRealmService {
    
    func createOrUpdate(_ request: Author, completion: @escaping (Result<Author, SwiftyPressError>) -> Void) {
        DispatchQueue.database.async {
            let realm: Realm
            
            do {
                realm = try Realm()
            } catch {
                DispatchQueue.main.async { completion(.failure(.databaseFailure(error))) }
                return
            }
            
            do {
                try realm.write {
                    realm.add(AuthorRealmObject(from: request), update: .modified)
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(.databaseFailure(error))) }
                return
            }
            
            // Get refreshed object to return
            guard let object = realm.object(ofType: AuthorRealmObject.self, forPrimaryKey: request.id) else {
                DispatchQueue.main.async { completion(.failure(.nonExistent)) }
                return
            }
            
            let item = Author(from: object)
            
            DispatchQueue.main.async {
                completion(.success(item))
            }
        }
    }
}
