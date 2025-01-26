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

    private var locationManager = CLLocationManager()
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    private var locationContinuation: CheckedContinuation<Void, Never>?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.locationServicesEnabled() {
                locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
                locationManager.distanceFilter = 10
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.pausesLocationUpdatesAutomatically = false
                locationManager.startUpdatingLocation()
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


