//
//  LocationManagerModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    
    override init() {
        super.init()
        locationManager.delegate = self
        
        // 権限が変更されるのを待ってから位置情報の更新を開始
        locationManager.requestAlwaysAuthorization()
    }
}
