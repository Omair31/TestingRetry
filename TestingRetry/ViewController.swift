//
//  ViewController.swift
//  TestingRetry
//
//  Created by Omeir Ahmed on 18/06/2022.
//

import UIKit

struct Item {
    let id = UUID().uuidString
}

protocol ItemsService {
    func loadItems(completion: @escaping (Result<[Item], Error>) -> Void)
}

class HTTPItemsService: ItemsService {
    
    func loadItems(completion: @escaping (Result<[Item], Error>) -> Void) {
        URLSession.shared.dataTask(with: URL(string: "htts://www.google.com")!) { data, response, error in
            if error != nil {
                completion(.failure(error!))
            } else {
                completion(.success([Item()]))
            }
        }.resume()
    }
    
}

class CacheItemsService: ItemsService {
    
    func loadItems(completion: @escaping (Result<[Item], Error>) -> Void) {
        completion(.success([Item(),Item()]))
    }
    
}

class ItemsServiceComposite: ItemsService {
    
    let primary: ItemsService
    let fallback: ItemsService
    
    init(primary: ItemsService, fallback: ItemsService) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func loadItems(completion: @escaping (Result<[Item], Error>) -> Void) {
        primary.loadItems { result in
            switch result {
            case .success(let items):
                completion(.success(items))
            case .failure(_):
                self.fallback.loadItems(completion: completion)
            }
        }
    }
    
}

extension ItemsService {
    func fallback(_ fallback: ItemsService) -> ItemsService {
        return ItemsServiceComposite(primary: self, fallback: fallback)
    }
    
    func retry(_ retryCount: UInt) -> ItemsService {
        var service: ItemsService = self
        for _ in 0..<retryCount {
            service = service.fallback(self)
        }
        return service
    }
}

class ViewController: UIViewController {
    
    let itemsService: ItemsService = HTTPItemsService()
    let cache: ItemsService = CacheItemsService()

    override func viewDidLoad() {
        super.viewDidLoad()
        itemsService.retry(1).fallback(cache).loadItems { result in
            print(result)
        }
        // Do any additional setup after loading the view.
    }


}

