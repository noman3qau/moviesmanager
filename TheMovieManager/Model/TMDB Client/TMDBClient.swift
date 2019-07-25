//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    //9dd326f5d4d56b5719afb94cdf013234
    static let apiKey = "9dd326f5d4d56b5719afb94cdf013234"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        static let ImageUrlbase = "https://image.tmdb.org/t/p/w500"

        case getWatchlist
        case getRequestToken
        case login
        case session
        case webAuth
        case logout
        case getFavouriteList
        case search(String)
        case watchListAddRemove
        case favoriteListAddRemove
        case posterImageUrl(String)

        var stringValue: String {
            switch self {
                case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
                case.getRequestToken: return Endpoints.base + "/authentication/token/new"+Endpoints.apiKeyParam
                
                case.login: return Endpoints.base + "/authentication/token/validate_with_login"+Endpoints.apiKeyParam

                case.session: return Endpoints.base + "/authentication/session/new"+Endpoints.apiKeyParam

                case .logout: return Endpoints.base + "/authentication/session"+Endpoints.apiKeyParam

                case.webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
                
                case.getFavouriteList: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
                case.search(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                
                case .watchListAddRemove:
                    return Endpoints.base+"/account/\(Auth.accountId)/watchlist"+Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
                case .favoriteListAddRemove:
                    return Endpoints.base+"/account/\(Auth.accountId)/favorite"+Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            
                case .posterImageUrl(let path):
                        return Endpoints.ImageUrlbase+"/\(path)"
            
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    @discardableResult
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void)-> URLSessionTask {

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil,errorResponse)
                    }
                }catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
                
            }
        }
        task.resume()
        
        return task
    }
    
    class func taskForPostRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, body: RequestType, completion: @escaping (ResponseType?, Error?)-> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try! JSONEncoder().encode(body)
        
        let task = URLSession.shared.dataTask(with: request){
            (data, response, error) in
            
            guard let data = data else{
                DispatchQueue.main.async {
                    completion(nil,error)
                }
                return
            }

            let decoder = JSONDecoder()
            do{
                let jsonResponse = try decoder.decode(responseType.self, from: data)
                DispatchQueue.main.async {
                    completion(jsonResponse,nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                }catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
    }
    
    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) {
        
        taskForGetRequest(url: Endpoints.getRequestToken.url, responseType: RequestTokenResponse.self) { (response, error) in
            
            if let response = response {
                Auth.requestToken = response.requestToken
                completion(true, nil)
            }else{
                completion(false,error)
            }
        }
    }
    
    class func login(username: String, password: String, completion: @escaping (Bool, Error?)->Void) {
        
        let requestBody = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        
        taskForPostRequest(url: Endpoints.login.url, responseType: RequestTokenResponse.self, body: requestBody) { (response, error) in
            
            if let response = response {
                Auth.requestToken = response.requestToken
                completion(true,nil)
            }else{
                completion(false,error)
            }
        }
    }
    
    class func getSessionId(completion: @escaping (Bool, Error?)->Void) {
        
        let requestBody = PostSession(requestToken: Auth.requestToken)
        
        taskForPostRequest(url: Endpoints.session.url, responseType: SessionResponse.self, body: requestBody) { (response, error) in
            
            if let response = response {
                Auth.sessionId = response.sessionId
                completion(true,nil)
            }else{
                completion(false,error)
            }
        }
    }
    
    class func logout(completion: @escaping () -> Void) {
        
        var request = URLRequest(url: Endpoints.logout.url)
        request.httpMethod = "DELETE"
        
        let body = LogoutRequest(sessionId: Auth.sessionId)
        
        request.httpBody = try! JSONEncoder().encode(body)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request){
            data, response, error in
            
            Auth.requestToken = ""
            Auth.sessionId = ""
            
            completion()
        }
        task.resume()
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        
        taskForGetRequest(url: Endpoints.getWatchlist.url, responseType: MovieResults.self) { (response, error) in
            
            if let response = response {
                completion(response.results, nil)
            }else{
                completion([], error)
            }
        }
    }
    
    class func getFavouriteList(completion: @escaping ([Movie], Error?) -> Void) {
        
        taskForGetRequest(url: Endpoints.getFavouriteList.url, responseType: MovieResults.self) { (response, error) in
            
            if let response = response{
                completion(response.results, nil)
            }else{
                completion([], error)
            }
        }
    }
    
    class func search(query: String,completion: @escaping ([Movie], Error?) -> Void)-> URLSessionTask {
        
        let urlSessionTask = taskForGetRequest(url: Endpoints.search(query).url, responseType: MovieResults.self) { (response, error) in
            
            if let response = response {
                completion(response.results, nil)
            }else{
                completion([], error)
            }
        }
        
        return urlSessionTask
    }
    
    class func addRemoveWatchList(movieId: Int, isAddWatchList: Bool, completion: @escaping (Bool,Error?)->Void){
        
        let requestBody = MarkWatchlist(media_type: "movie", media_id: movieId, watchlist: isAddWatchList)
        
        taskForPostRequest(url: Endpoints.watchListAddRemove.url, responseType: TMDBResponse.self, body: requestBody) {
            (response, error) in
            
            if let response = response {
                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13 , nil)
            }else{
                completion(false, error)
            }
            
        }
    }
   
    
    class func addRemoveFavoriteList(movieId: Int, isAddFavoriteList: Bool, completion: @escaping (Bool,Error?)->Void){
        
        let requestBody = MarkFavorite(media_type: "movie", media_id: movieId, favorite: isAddFavoriteList)
        
        taskForPostRequest(url: Endpoints.favoriteListAddRemove.url, responseType: TMDBResponse.self, body: requestBody) {
            (response, error) in
            
            if let response = response {
                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13 , nil)
            }else{
                completion(false, error)
            }
            
        }
    }
    
    
    class func downloadPosterImage(posterPath: String, completion: @escaping (Data?, Error?) -> Void) {
        
        let imagePoster = Endpoints.posterImageUrl(posterPath).url
        
        let task = URLSession.shared.dataTask(with: imagePoster){
            data,response,error in
            
            guard let data = data else {
                completion(nil,error)
                return
            }
            DispatchQueue.main.async {
                completion(data,nil)
            }
        }
        task.resume()
        
    }
    
}
