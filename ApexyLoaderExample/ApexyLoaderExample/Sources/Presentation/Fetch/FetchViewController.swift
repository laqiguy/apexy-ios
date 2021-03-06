//
//  FetchViewController.swift
//  ApexyLoaderExample
//
//  Created by Daniil Subbotin on 04.03.2021.
//

import ApexyLoader
import UIKit

final class FetchViewController: UIViewController {

    @IBOutlet private var downloadButton: UIButton!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var repoTextView: UITextView!
    
    private let repoLoader: RepoLoading
    private let orgLoader: OrganisationLoading
    
    private var observers = [LoaderObservation]()
    
    init(
        repoLoader: RepoLoading = ServiceLayer.shared.repoLoader,
        orgLoader: OrganisationLoading = ServiceLayer.shared.orgLoader) {
        
        self.repoLoader = repoLoader
        self.orgLoader = orgLoader
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observers.append(repoLoader.observe { [weak self] in
            self?.stateDidChange()
        })
        
        observers.append(orgLoader.observe { [weak self] in
            self?.stateDidChange()
        })
    }
    
    private func stateDidChange() {
        
        let state = orgLoader.state.merge(repoLoader.state) { org, repos in
            OrganisationRepositories(org: org, repos: repos)
        }
        
        if state.isLoading {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        
        switch state {
        case .failure(_, let content?),
             .loading(let content?),
             .success(let content):
            let repos = content.repos.map { $0.name }.joined(separator: "\n")
            repoTextView.text = "Repositories of the \(content.org.name) organisation:\n\n\(repos)"
        default:
            break
        }
    }
    
    @IBAction private func fetchFileURL() {
        repoLoader.load()
        orgLoader.load()
    }
    
}

