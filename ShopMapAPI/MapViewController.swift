//
//  ViewController.swift
//  ShopMapAPI
//
//  Created by Michelle Chen on 2017/9/14.
//  Copyright © 2017年 Michelle Chen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager = CLLocationManager()
    var isFirstLocationReceived = false
    var shopList = [Shop]()
    var address = ""
    
    @IBOutlet weak var mapView: MKMapView!
    
    func checkNetworkConnection(){
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
        }else{
            let alert = UIAlertController(title: "嗚呼", message: "沒有網路連線", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }

    }
    
    @IBAction func selectShop(_ sender: UISegmentedControl) {
        switch sender.tag {
        case 0:
            print("show all locations")
        case 1:
            print("show 7-11")
        case 2:
            print("show 全家")
        case 3:
            print("show 萊爾富")
        case 4:
            print("show OK")
        default:
            print("show all locations")
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.requestWhenInUseAuthorization()
        
        //prepare locationManager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .automotiveNavigation
        locationManager.startUpdatingLocation()
        checkNetworkConnection()
       
        
    }

    //地址轉經緯度
    func AddressToCoordinate(address:String, completion: @escaping(CLLocationCoordinate2D) ->()){
        let geocoder = CLGeocoder()
        var result:CLLocationCoordinate2D!
        geocoder.geocodeAddressString(address) { (placemarks, error) in
        
            guard error == nil else{
                print("geocoder:\(String(describing: error))")
                return
            }
            guard let placemarks = placemarks , placemarks.count > 0 else {
                print("placemarks is nil")
                return
            }
            guard let targetPlacemark = placemarks.first else{
                print("Invalid first placemark.")
                return
            }            
            guard let coordinate = targetPlacemark.location?.coordinate else{
                print("Invalid coordinate")
                return
            }
            result = coordinate
            completion(result)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //guard判斷式成立之後才去做 currentLocation   拿到最新的位置
        guard let currentLocation = locations.last else{
            return
        }
        let coordinate = currentLocation.coordinate
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            print(currentLocation)
        }
        
        //顯示出緯經度  coordinate 存放緯經度
        NSLog("Lat:\(coordinate.latitude),Lon:\(coordinate.longitude)")
        //轉中文地址
        DispatchQueue.once(token: "locateYourCity"){
        getAddressFromCoordinate(pdblLatitude: String(coordinate.latitude), withLongitude: String(coordinate.longitude)) { (address) in
            self.address = address
            
            loadData(url: getURL(city: address), completion: { (shopList) in
                self.addShopAnnotation(list: shopList)
            })
          }
        }
        
        DispatchQueue.once(token: "MoveAndZoomMap"){
            let span = MKCoordinateSpanMake(0.001,0.001)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            mapView.setRegion(region, animated: true)
           
          }
        }
    
    //coordinate to address
    func getAddressFromCoordinate(pdblLatitude: String, withLongitude pdblLongitude: String, completion: @escaping (String) -> Void){
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let lat = Double("\(pdblLatitude)")!
        let lon = Double("\(pdblLongitude)")!
        let ceo = CLGeocoder()
        center.latitude = lat
        center.longitude = lon
        //change device language
        let defaults = UserDefaults.standard
        
        let lans = defaults.object(forKey: "AppleLanguages")
        
        defaults.set(["zh-CHT"], forKey: "AppleLanguages")
        
        let loc = CLLocation(latitude:center.latitude, longitude: center.longitude)
        var address = ""
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
            {(placemarks, error) in
                if (error != nil)
                {
                    print("reverse geodcode fail: \(error!.localizedDescription)")
                }
                let pm = placemarks! as [CLPlacemark]
                
                if pm.count > 0 {
                    let pm = placemarks![0]
                        if pm.subAdministrativeArea != nil{
                            address += pm.subAdministrativeArea!
                        }
                    
                }
                completion(address)
                //restore device language
                defaults.set(lans, forKey: "AppleLanguages")
        })
        
    }
    
    func addShopAnnotation(list:Array<Shop>){
        for shop in list{
            let annotation = MKPointAnnotation()
            let address = shop.address
            AddressToCoordinate(address: address!, completion: { (coordinate) in
                annotation.coordinate = coordinate
                annotation.title = shop.title
                annotation.subtitle = shop.address
                self.mapView.addAnnotation(annotation)
            })
            
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print(annotation)
        if annotation is MKUserLocation {
            return nil
        }
        let identifier = "store"
        var result = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if result == nil{
            result = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            print("something here!")
        }else{
            result?.annotation = annotation

        }
        result?.canShowCallout = true
        let annotationView = UIImage(named:"pointRed")
        result?.image = annotationView
        return result
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

