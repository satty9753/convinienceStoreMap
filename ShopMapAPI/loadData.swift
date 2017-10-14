//
//  loadData.swift
//  ShopMapAPI
//
//  Created by Michelle Chen on 2017/10/6.
//  Copyright © 2017年 Michelle Chen. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreLocation

let cities = [ "基隆市", "台北市", "新北市", "桃園市", "新竹市", "新竹縣",
         "苗栗縣", "台中市", "彰化縣", "雲林縣", "南投縣", "嘉義縣",
         "嘉義市", "台南市", "高雄市", "屏東縣", "台東縣", "花蓮縣",
         "宜蘭縣", "連江縣", "金門縣", "澎湖縣"]

func getURL(city:String)->String{
     var url = "http://satty9753.pythonanywhere.com/convinientStore/"
      if cities.contains(city){
        url = url + "city/" + city + "/JSON"
        url = url.urlEncoded()
        print(url)
    }
    return url
}
//download data
func loadData(url:String, completion: @escaping ([Shop]) -> Void) {
    var results = [Shop]()
    var myShop = Shop()
    Alamofire.request(url).responseJSON { response in
        if response.result.isSuccess {
            if let json = response.data{
                let data = JSON(data: json)
                print("downloading...")
                for index in 0...data["convinientStoreCity"].count-1{
                    var item = data["convinientStoreCity"][index]
                    myShop.title = item["name"].string
                    myShop.address = item["address"].string
                    myShop.category = item["shop"].string
                    let coordinateString = item["coordinate"].string
                    let coordinateDict = convertToDictionary(text: coordinateString)
                    myShop.coordinate = coordinateDict
                    results.append(myShop)
                }
                completion(results)
            }
          else{
                print("Connect Fail")
            }
        }
    }
}
//轉中文網址
extension String {
    
    //將原始的url轉成合法的url
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
    
    //将編碼的url轉回原始的url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
    


//covert string to dicitonary
func convertToDictionary(text: String?) -> [String: Any]? {
    if let data = text?.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}


