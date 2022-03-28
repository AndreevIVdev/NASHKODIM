//
//  PhotoModel.swift
//  TestTaskMobileUP
//
//  Created by Илья Андреев on 27.03.2022.
//

import Foundation
import Combine

protocol PhotoModable: AnyObject {
    var photosCount: PassthroughSubject<Int, Never> { get }
    var initializationDone: PassthroughSubject<Void, Never> { get }
    var error: PassthroughSubject<Error, Never> { get }
    func getPhoto(with size: PhotoSize, for index: Int, with id: UUID, completion: @escaping (Data?, UUID) -> Void)
    func getTitle(for index: Int) -> Int?
    func initialize()
}

enum PhotoSize {
    case small
    case medium
    case large
}

class PhotoModel: PhotoModable {
    private let token: String
    private var smallPictures: [Data?] = []
    private var mediumPictures: [Data?] = []
    private var bigPictures: [Data?] = []
    private var bindings: Set<AnyCancellable> = .init()
    private(set) var photosCount: PassthroughSubject<Int, Never> = .init()
    private(set) var initializationDone: PassthroughSubject<Void, Never> = .init()
    private(set) var error: PassthroughSubject<Error, Never> = .init()
    private var album: Album?
    
    init(token: String) {
        self.token = token
    }
    
    func initialize() {
        loadAlbum { [weak self] in
            guard let self = self,
                  let album = self.album else { return }
            self.smallPictures = .init(repeating: nil, count: album.count)
            self.mediumPictures = .init(repeating: nil, count: album.count)
            self.bigPictures = .init(repeating: nil, count: album.count)
            self.photosCount.send(album.count)
            self.initializationDone.send()
        }
    }
    
    func getPhoto(with size: PhotoSize, for index: Int, with id: UUID, completion: @escaping (Data?, UUID) -> Void) {
        guard let album = album,
              index < album.count else {
            completion(nil, id)
            return
        }
        
        var dataSource: [Data?] = []
        switch size {
        case .small:
            dataSource = smallPictures
        case .medium:
            dataSource = mediumPictures
        case .large:
            dataSource = bigPictures
        }
        
        if let data = dataSource[index] {
            completion(data, id)
            return
        }
        
        loadPhoto(with: size, index: index) { [weak self] data in
            guard let self = self,
                  let data = data else {
                completion(nil, id)
                return
            }
            self.savePhoto(data, with: size, and: index)
            completion(data, id)
        }
    }
    
    private func savePhoto(_ photo: Data, with size: PhotoSize, and index: Int) {
        switch size {
            
        case .small:
            smallPictures[index] = photo
        case .medium:
            mediumPictures[index] = photo
        case .large:
            bigPictures[index] = photo
        }
    }
    
    func getTitle(for index: Int) -> Int? {
        guard let album = album,
              index < album.count  else { return nil }
        
        return album.photos[index].date
    }
    
    func loadAlbum(completed: @escaping () -> Void) {
        guard let url = VKClient.photosURL(with: self.token) else { return }
        NetworkingManager.shared.fetchData(from: url) { [weak self] result in
            defer {
                completed()
            }
            guard let self = self else { return }
            switch result {
            case .success(let data):
                do {
                    self.album = try JSONDecoder().decode(VKResponse.self, from: data).album
                } catch {
                    self.error.send(TTError.invalidResponse)
                }
            case .failure(let error):
                self.error.send(error)
            }
        }
    }
    
    private func loadPhoto(with size: PhotoSize, index: Int, completion: @escaping (Data?) -> Void) {
        guard let album = album else {
            completion(nil)
            return
        }
        var photoSize: Size?
        let screenWidth = Int(ScreenSize.width)
        switch size {
        case .small:
            photoSize = album.photos[index].sizes.min(by: { $0.width < $1.width })
        case .medium:
            photoSize = album.photos[index].sizes.min {
                abs($0.width - screenWidth / 2) < abs($1.width - screenWidth / 2)
            }
        case .large:
            photoSize = album.photos[index].sizes.min(by: { abs($0.width - screenWidth) < abs($1.width - screenWidth) })
        }
        
        guard let url = URL(string: photoSize!.url) else {
            completion(nil)
            return
        }
        
        NetworkingManager.shared.fetchDataWithOutErrorHandling(from: url) { data in
            completion(data)
        }
    }
}
