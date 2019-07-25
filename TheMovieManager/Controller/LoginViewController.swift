//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = "noman3qau"
        passwordTextField.text = "noman3qau"
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        loggingIn(true)
        TMDBClient.getRequestToken(completion: handleRequestTokenResponse(success: error:))
    }
    
    @IBAction func loginViaWebsiteTapped() {
        loggingIn(true)
        TMDBClient.getRequestToken{
            (success, error) in
            self.loggingIn(false)
            if success {
                UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func handleRequestTokenResponse(success: Bool, error: Error?)  {
        if(success){
            print(TMDBClient.Auth.requestToken)
            
            TMDBClient.login(username: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "", completion: loginResponseHandler(success:error:))
        }else{
            loggingIn(false)
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }
    
    func loginResponseHandler(success: Bool, error: Error?) {
        print(TMDBClient.Auth.requestToken)
        loggingIn(false)
        if(success){
            TMDBClient.getSessionId(completion: sessionResponseHandler(success:error:))
        }else{
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }

    func sessionResponseHandler(success: Bool, error: Error?) {
        if(success){
            self.performSegue(withIdentifier: "completeLogin", sender: nil)
        }else{
            loggingIn(false)
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }

    func loggingIn(_ loggingIn: Bool){
        if loggingIn {
            self.activityIndicator.startAnimating()
        }else{
            self.activityIndicator.stopAnimating()
        }
        
        emailTextField.isEnabled = !loggingIn
        passwordTextField.isEnabled = !loggingIn
        loginButton.isEnabled = !loggingIn
        loginViaWebsiteButton.isEnabled = !loggingIn

    }
    
    func showLoginFailure(message: String) {
        let alertVC = UIAlertController(title: "Login Failed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
    
}
