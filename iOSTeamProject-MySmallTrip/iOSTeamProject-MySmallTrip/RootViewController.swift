//
//  RootViewController.swift
//  iOSTeamProject-MySmallTrip
//
//  Created by sungnni on 2018. 4. 10..
//  Copyright © 2018년 ohteam. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit

class RootViewController: UIViewController {
    
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var signUpButton: UIButton!
    
    @IBOutlet private weak var facebookLoginButton: FBSDKLoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLayout()
        facebookLoginButton.delegate = self
        
        
        if FBSDKAccessToken.current() != nil {
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If being still logged in
        if FBSDKAccessToken.current() != nil || UserData.user.isLoggedIn {
            self.moveToMainVC()
        }
    }
    
    
    // Button CornerRadius & border 적용
    private func updateLayout() {
        loginButton.layer.cornerRadius = 10
        signUpButton.layer.cornerRadius = 10
        
        signUpButton.layer.borderWidth = 2
        signUpButton.layer.borderColor = UIColor.Custom.mainColor.cgColor
    }
    
    private func moveToMainVC() {
        let storyBoard = UIStoryboard(name: "Root", bundle: nil)
        let mainVC = storyBoard.instantiateViewController(withIdentifier: "MainTabBarController") as! MainTabBarController
        self.present(mainVC, animated: true, completion: nil)
    }
    
    // YS
    private func setUserData(userLoggedIn: EmailLogIn) {
        UserData.user.isLoggedIn = true
        UserData.user.setToken(token: userLoggedIn.token)
        UserData.user.setPrimaryKey(primaryKey: userLoggedIn.user.primaryKey)
        UserData.user.setUserName(userName: userLoggedIn.user.userName)
        UserData.user.setEmail(email: userLoggedIn.user.email)
        UserData.user.setFirstName(firstName: userLoggedIn.user.firstName)
        UserData.user.setPhoneNumber(phoneNumber: userLoggedIn.user.phoneNumber)
        UserData.user.setImgProfile(imgProfile: userLoggedIn.user.imgProfile)
        UserData.user.setIsFacebookUser(isFacebookUser: userLoggedIn.user.isFacebookUser)
        
        // Load Wish List
        self.loadWishList()
    }
    
    // MARK: - Load Wish List Primary Keys
    private func loadWishList() {
        guard let token = UserData.user.token else { return }
        let header: Dictionary<String, String> = ["Authorization": "Token " + token]
        let wishListLink: String = "http://myrealtrip.hongsj.kr/reservation/wishlist/"
        
        importLibraries.connectionOfServerForJSONWith(wishListLink, method: .get, parameters: nil, headers: header, success: { (json, code) in
            if let datas = json as? [[String:Any]] {
                for data in datas {
                    let pkInt = data["pk"] as! Int
                    UserData.user.setWishListPrimaryKeys(wishListPrimaryKey: pkInt)
                }
            }
        }) { (error, code) in
            print(error.localizedDescription)
        }
    }
    
    private func fetchProfile() {
        let url = UrlData.standards.basic + UrlData.standards.facebookLogin
        
        guard let token = FBSDKAccessToken.current().tokenString else { return }
        let params = ["access_token":token]
        
        importLibraries.connectionOfSeverForDataWith(url, method: .post, parameters: params, headers: nil, success: { (data, code) in
            do {
                let userData = try JSONDecoder().decode(EmailLogIn.self, from: data)
                self.setUserData(userLoggedIn: userData)
                self.moveToMainVC()
                
            } catch(let error) {
                print("\n---------- [ JSON Decoder error ] -----------\n")
                print(error)
            }
        }) { (error, code) in
            print("\n---------- [ Alamofire request error ] -----------\n")
            print(error.localizedDescription)
        }
    }
}

// MARK:  - FBSDK LoginButton Delegate
extension RootViewController: FBSDKLoginButtonDelegate {
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if result.isCancelled {
            print("login cancle: \(result.isCancelled)")
        } else {
            loginButton.readPermissions = ["public_profile", "email"]
            fetchProfile()
            //            moveToMainVC()
        }
        
        // 읽기 권한 불러오기. 이게 제대로 안되는 것 같은..느낌인데..t.t..
        // 읽기 권한 취소 / 거부하면 fail 되야함.
        
        // + 다른 아이디로 로그인하기가 있어야 할 것 같은데.......
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("\n---------- [ logout ] -----------\n")
        
        
    }
    
    //    @IBAction private func logoutFunc() {
    //        let fbLoginManager = FBSDKLoginManager()
    //        fbLoginManager.logOut()
    //    }
}
