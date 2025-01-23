//
//  LocationManagerModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import CoreLocation
import Foundation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation? = nil

    override init() {
        super.init()
        // CLLocationManagerの位置情報を受け取るために自分に設定
        self.locationManager.delegate = self
        // 位置情報の利用をユーザーに要求
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }

    /// 位置情報の更新があった際に呼ばれるデリゲートメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.location = location
        }
    }
}
