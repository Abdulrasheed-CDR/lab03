//
//  ViewController.swift
//  lab03
//
//  Created by Abdulrasheed  on 05/11/2024.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var weatherConditionImg: UIImageView!
    
    @IBOutlet weak var tempLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    
    private let locationManager = CLLocationManager()
    private var isCelsius = true // Track the temperature unit
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        displaySampleImage()
        searchTextField.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        loadWeather(search: textField.text)
        return true
    }
    
    private func displaySampleImage() {
        let config = UIImage.SymbolConfiguration(paletteColors: [
            .systemBlue, .systemOrange, .systemGray
        ])
        weatherConditionImg.preferredSymbolConfiguration = config
        weatherConditionImg.image = UIImage(systemName: "cloud.sun.rain")
    }
    
    @IBAction func onToggleSwitchChanged(_ sender: UISwitch) {
        isCelsius = sender.isOn
        loadWeather(search: searchTextField.text) // Refresh the data to apply the unit change
    }
    
    @IBAction func onlocationClicked(_ sender: UIButton) {
        locationManager.requestLocation()
    }
    
    @IBAction func onSearchClicked(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
    }
    
    private func loadWeather(search: String?) {
        guard let search = search, !search.isEmpty else {
            print("Please enter a location.")
            return
        }
        
        guard let url = getURL(query: search) else {
            print("Invalid location. Please try again.")
            return
        }
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: url) { data, response, error in
            print("Network call finished ")
            
            guard error == nil else {
                print("Error recieved")
                return
            }
            
            guard let data = data, let weatherResponse = self.parseJson(data: data) else {
                print("Could not retrieve weather data.")
                return
            }
            
            DispatchQueue.main.async {
                self.updateUI(with: weatherResponse)
            }
        }
        
        dataTask.resume()
    }
    
    
    private func getURL(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndPoint = "current.json"
        let apiKey = "6265a2a5ee8a43f7ba1211209240611"
        let urlString = "\(baseUrl)\(currentEndPoint)?key=\(apiKey)&q=\(query)"
        
        return URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
    }
    
    private func parseJson(data: Data) -> WeatherResponse? {
        let decoder = JSONDecoder()
        
        do{
            return try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("Decoding error")
            return nil
        }
    }
    
    private func updateUI(with weatherResponse: WeatherResponse) {
            locationLabel.text = weatherResponse.location.name
            let temp = isCelsius ? weatherResponse.current.temp_c : (weatherResponse.current.temp_c * 9/5) + 32
            tempLabel.text = String(format: "%.1f%@", temp, isCelsius ? "°C" : "°F")
            updateWeatherSymbol(for: weatherResponse.current.condition.code)
        }
    
    private func updateWeatherSymbol(for code: Int) {
            let symbolName: String
            switch code {
            case 1000: symbolName = "sun.max"
            case 1003: symbolName = "cloud.sun"
            case 1006: symbolName = "cloud"
            case 1009: symbolName = "smoke"
            default: symbolName = "cloud.sun.rain"
            }
            weatherConditionImg.image = UIImage(systemName: symbolName)
        }
    
    private func showError(message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
}

extension ViewController {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            loadWeather(search: "\(latitude),\(longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error)")
        showError(message: "Could not get your location.")
    }
}

struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name: String
}

struct Weather: Decodable {
    let temp_c: Float
    let condition: weatherCondition
}

struct weatherCondition: Decodable {
    let text: String
    let code: Int
}
