//
//  PhotoView.swift
//  TestTaskMobileUP
//
//  Created by Илья Андреев on 27.03.2022.
//

import UIKit
import Combine

// MARK: - Class PhotoViewController
/// Full screen photo
final class FullScreenPhotoViewController: UIViewController {
    
    // MARK: - Publishers
    /// Publisher that throws possible errors
    private(set) var error: PassthroughSubject<Error, Never> = .init()
    
    // MARK: - Private Properties
    /// Main datasource
    private let viewModel: FullScreenPhotoViewModable
    /// Subscriptions storage
    private var bindings: Set<AnyCancellable> = .init()
    /// Lets zoom and move photo on the screen
    private let scrollView: UIScrollView = .init()
    /// Large photo container
    private let photoImageView: LoadingImageView = .init()
    /// Collection view for photo showing
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UIHelper.createHorizontalFlowLayout()
    )
    /// Shows success of the action
    private let checkmarkImageView: UIImageView = .init(image: Images.success)
    
    // MARK: - Initializers
    init(token: String, initialIndex: Int) {
        viewModel = FullScreenPhotoViewModel.init(
            token: token,
            currentindex: initialIndex
        )
        super.init(nibName: nil, bundle: nil)
        print("\(String(describing: type(of: self))) INIT")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Deinitializers
    deinit {
        print("\(String(describing: type(of: self))) DEINIT")
    }
    
    // MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewController()
        configureScrollView()
        configureCollectionView()
        configurePhotoImageView()
        configureSuccsessImageView()
        setupBindingsViewModelToView()
    }
    
    // MARK: - Private Methods
    /// Primary screen configuration
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        view.addSubViews(scrollView, checkmarkImageView, collectionView)
        navigationItem.rightBarButtonItem = .init(
            image: Images.share,
            style: .plain,
            target: self,
            action: #selector(share)
        )
    }
    
    /// Primary zooming view configuration
    private func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        scrollView.addSubViews(photoImageView)
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    /// Primary collection view configuration
    private func configureCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.register(
            GalleryCollectionViewCell.self,
            forCellWithReuseIdentifier: GalleryCollectionViewCell.description()
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: view.frame.width / 6),
            collectionView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: DeviceTypes.isiPhoneSE || DeviceTypes.isiPhone8Zoomed
                ? -Design.padding : -Design.bottomPadding
            )
        ])
        
        collectionView.showsHorizontalScrollIndicator = false
    }
    /// Primary photo container configuration
    private func configurePhotoImageView() {
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            photoImageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            photoImageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            photoImageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
        
        photoImageView.clipsToBounds = true
        photoImageView.contentMode = .scaleAspectFit
    }
    /// Primary success checkmark configuration
    private func configureSuccsessImageView() {
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 100),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 100),
            checkmarkImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        checkmarkImageView.tintColor = .systemGreen
        checkmarkImageView.alpha = 0
    }
    /// Initializes reactive connections
    private func setupBindingsViewModelToView() {
        viewModel.photo
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] data in
                self.photoImageView.setImage(data)
            }
            .store(in: &bindings)
        
        viewModel.title
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] title in
                self.title = title
            }
            .store(in: &bindings)
        
        viewModel.cellCount
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                self.collectionView.reloadData()
            }
            .store(in: &bindings)
        
        viewModel.error
            .sink { [unowned self] error in
                self.error.send(error)
            }
            .store(in: &bindings)
    }
    /// Handles the attempt to share large photo
    @objc private func share() {
        let shareController: UIActivityViewController = .init(
            activityItems: [photoImageView.image ?? Images.placeholder],
            applicationActivities: nil
        )
        
        shareController.completionWithItemsHandler = { activity, success, _, error in
            if !success {
                return
            }
            
            guard let activity = activity else { return }
            
            switch activity {
            case .saveToCameraRoll:
                if let error = error {
                    print(error)
                } else {
                    self.checkmarkImageView.alpha = 0.8
                    UIView.animate(withDuration: 0.3) {
                        self.checkmarkImageView.transform = .init(scaleX: 0.7, y: 0.7)
                    } completion: { _ in
                        UIView.animate(withDuration: 0.4) {
                            self.checkmarkImageView.transform = .init(scaleX: 1, y: 1)
                        } completion: { _ in
                            UIView.animate(withDuration: 0.2, delay: 1) {
                                self.checkmarkImageView.alpha = 0
                            }
                        }
                    }
                }
            default:
                return
            }
        }
        present(shareController, animated: true, completion: nil)
    }
}

// MARK: - Extension UICollectionViewDataSource
extension FullScreenPhotoViewController: UICollectionViewDataSource {
    
    /// Returns number of cells in current section of collection view
    /// - Parameters:
    ///   - collectionView: current collection view
    ///   - section: current section
    /// - Returns: count of cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.getCellCount()
    }
    
    /// Configurates propper cell for given position
    /// - Parameters:
    ///   - collectionView: current collection view
    ///   - indexPath: current position
    /// - Returns: properly configurated cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GalleryCollectionViewCell.description(),
            for: indexPath) as! GalleryCollectionViewCell
        viewModel.getCell(for: indexPath.row, with: cell.id) { [weak cell] data, id in
            guard let cell = cell else { return }
            if cell.id == id {
                cell.set(by: data)
            }
        }
        return cell
    }
}

// MARK: - Extension UICollectionViewDelegate
extension FullScreenPhotoViewController: UICollectionViewDelegate {
    /// Handles tap on the element of collection view
    /// - Parameters:
    ///   - collectionView: current collection view
    ///   - indexPath: tap position
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.setNewIndex(indexPath.row)
    }
}

// MARK: - Extension UIScrollViewDelegate
extension FullScreenPhotoViewController: UIScrollViewDelegate {
    /// Selects view for zooming
    /// - Parameter scrollView: current scroll view
    /// - Returns: view for zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        photoImageView
    }
    
    /// Handles and configures zoom options
    /// - Parameter scrollView: current scroll view
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            if let image = photoImageView.image {
                let ratioW = photoImageView.frame.width / image.size.width
                let ratioH = photoImageView.frame.height / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                let conditionLeft = newWidth * scrollView.zoomScale > photoImageView.frame.width
                let left = 0.5 *
                (conditionLeft ? newWidth - photoImageView.frame.width
                 : (scrollView.frame.width - scrollView.contentSize.width))
                let conditioTop = newHeight * scrollView.zoomScale > photoImageView.frame.height
                
                let top = 0.5 *
                (conditioTop ? newHeight - photoImageView.frame.height
                 : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
            }
        } else {
            scrollView.contentInset = .zero
        }
    }
}
