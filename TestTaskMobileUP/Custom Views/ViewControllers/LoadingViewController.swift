//
//  LoadingViewController.swift
//  TestTaskMobileUP
//
//  Created by Илья Андреев on 27.03.2022.
//

import UIKit

// MARK: - Protocol LoadingViewController
/// View controller with activity indacator
class LoadingViewController: UIViewController {
    
    // MARK: - Private Properties
    /// Holds activity indicator
    private let containerView: UIView = .init()
    /// Shows download status
    private let activityIndicator: UIActivityIndicatorView = .init(style: .large)
    
    // MARK: - Public Methods
    /// Starts loading animation
    func showLoadingView() {
        DispatchQueue.main.async {
            self.containerView.backgroundColor = .systemBackground
            self.containerView.alpha = 0
            self.view.addSubViews(self.containerView)
            self.containerView.frame = self.view.bounds
            
            
            UIView.animate(withDuration: 0.75) {
                self.containerView.alpha = 0.8
            }
            
            self.activityIndicator.color = .label
            self.containerView.addSubViews(self.activityIndicator)
            self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.activityIndicator.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor),
                self.activityIndicator.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor)
            ])
            self.view.bringSubviewToFront(self.containerView)
            self.activityIndicator.startAnimating()
        }
    }
    
    /// Stops loading animation
    func dismissLoadingView() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
            self.containerView.removeFromSuperview()
        }
    }
}
