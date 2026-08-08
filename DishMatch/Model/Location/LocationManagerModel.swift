//
//  LocationManagerModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import Foundation
import CoreLocation

@MainActor
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
        // このアプリは「今いる場所から検索する」用途にしか位置情報を使わないため、
        // 常時許可（Always）は求めずアプリ使用中のみの許可にする
        locationManager.requestWhenInUseAuthorization()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task {
            if CLLocationManager.locationServicesEnabled() {
                await MainActor.run {
                    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
                    // 継続的な追跡(startUpdatingLocation)は不要で、検索のたびに1回だけ取得できれば十分。
                    // 以前はstartUpdatingLocation + allowsBackgroundLocationUpdates = trueにしていたため、
                    // アプリを閉じた後もバックグラウンドで位置情報の取得が続いてしまっていた。
                    self.locationManager.requestLocation()
                }
            } else {
                // 位置情報が無効ならエラーをセット
                await MainActor.run {
                    self.locationError = .locationServicesDisabled
                }
            }
        }
    }


    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        Task { @MainActor in
            self.latitude = newLocation.coordinate.latitude
            self.longitude = newLocation.coordinate.longitude
            self.locationContinuation?.resume() // 位置情報取得完了を通知
            self.locationContinuation = nil
        }
    }

    /// requestLocation()は取得失敗時にdidUpdateLocationsが呼ばれないため、
    /// ここでcontinuationを解放しないとrequestLocationPermissionIfNeeded()が
    /// 権限拒否時などに永遠に待ち続けてしまう
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("DEBUG: 位置情報取得エラー \(error.localizedDescription)")
            self.locationContinuation?.resume()
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


