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
    
    // MARK: - check if network works
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

    /*
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
    }*/
    
    // MARK: - Get current location coordinate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //get current location
        guard let currentLocation = locations.last else{
            return
        }
        let coordinate = currentLocation.coordinate
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            print(currentLocation)
        }
        NSLog("Lat:\(coordinate.latitude),Lon:\(coordinate.longitude)")
        
        //download your-city-location-data
        DispatchQueue.once(token: "locateYourCity"){
           
            getAddressFromCoordinate(pdblLatitude: String(coordinate.latitude), withLongitude: String(coordinate.longitude)) { (address) in
            self.address = address
             loadData(url:getURL(city: address), completion: { (shopList) in
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
    
    // MARK: - convert coordinate to address
    func getAddressFromCoordinate(pdblLatitude: String, withLongitude pdblLongitude: String, completion: @escaping (String) -> Void){
        var center = CLLocationCoordinate2D()
        let lat = Double("\(pdblLatitude)")!
        let lon = Double("\(pdblLongitude)")!
        let ceo = CLGeocoder()
        center.latitude = lat
        center.longitude = lon
        
        //change device language to show chinese name of city
        let defaults = UserDefaults.standard
        
        let lans = defaults.object(forKey: "AppleLanguages")
        //繁體中文
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
                    //print city
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
    
    // MARK: - add shop to annotation
    func addShopAnnotation(list:Array<Shop>){
        for shop in list{
            let annotation = MKPointAnnotation()
            if shop.coordinate != nil {
                var shopCoordinate = shop.coordinate!
                if let latNum = shopCoordinate["lat"] as? Double, let lngNum = shopCoordinate["lng"] as? Double {
                    let coordinate = CLLocationCoordinate2D(latitude: latNum, longitude: lngNum)
                    annotation.coordinate = coordinate
                    annotation.title = shop.title
                    annotation.subtitle = shop.address
                }
                 print(annotation.coordinate)
                 self.mapView.addAnnotation(annotation)
                
            }
            else{
                print("Do nothing")
            }
        }
        
    }
    
    
    // MARK: - put annotation on map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let identifier = "store"
        var result = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if result == nil{
            result = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        else{
            result?.annotation = annotation
        }
        result?.canShowCallout = true
        let image = UIImage(named: "pointRed")
        result?.image = image
        
        //Prepare LeftCalloutAccessoryView
        let imageView = UIImageView(image: image)
        result?.leftCalloutAccessoryView = imageView
        
        return result
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

