//
//  LocationManagerModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // シングルトンインスタンス
    
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var locationError: LocationError?
    private var locationContinuation: CheckedContinuation<Void, Never>?
    private var locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.global(qos: .background).async {
            if CLLocationManager.locationServicesEnabled() {
                DispatchQueue.main.async {
                    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
                    self.locationManager.distanceFilter = 10
                    self.locationManager.allowsBackgroundLocationUpdates = true
                    self.locationManager.pausesLocationUpdatesAutomatically = false
                    self.locationManager.startUpdatingLocation()
                }
            } else {
                // 位置情報が無効ならエラーをセット
                DispatchQueue.main.async {
                    self.locationError = .locationServicesDisabled
                }
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.latitude = newLocation.coordinate.latitude
            self.longitude = newLocation.coordinate.longitude
            self.locationContinuation?.resume() // 位置情報取得完了を通知
            self.locationContinuation = nil
        }
    }
    
    func requestLocationPermissionIfNeeded() async {
        guard latitude == 0.0 && longitude == 0.0 else { return } // 既に取得済みの場合はスキップ
        await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
        }
    }
}


