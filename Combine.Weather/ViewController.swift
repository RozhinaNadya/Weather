//
//  ViewController.swift
//  Combine.Weather
//
//  Created by Ivan Sapozhnik on 11/3/19.
//  Copyright © 2019 Swifty Talks. All rights reserved.
//

import UIKit
import Combine

enum WeatherError: Error {
    case invalidResponse
}

class ViewController: UIViewController {
    private let celsiusCharacters = "ºC"
    private let openWeatherBaseURL = "http://api.openweathermap.org/data/2.5/weather"
    private let openWeatherAPIKey = "13dd13f47c3bb8fe37d5c3326f2fb308"
    
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    private var cancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func searchTap(_ sender: Any) {
        view.endEditing(true)
        guard let cityName = cityTextField.text else {return}
        getTemperature(for: cityName)
    }
    
    private func getTemperature(for cityName: String) {

        guard let weatherURL = URL(string: "\(openWeatherBaseURL)?q=\(cityName)&appid=\(openWeatherAPIKey)") else {return}
        activityIndicatorView.startAnimating()
        searchButton.isEnabled = false
        cancellable = URLSession.shared.dataTaskPublisher(for: weatherURL)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw WeatherError.invalidResponse
                }
                return data
            }
        //расшифровываем джейсон
            .decode(type: Temperature.self, decoder: JSONDecoder())
        //обработка ошибок, just - один результат
            .catch {error in
                return Just(Temperature.placeholder)
            }
            .map { $0.main?.temp ?? 0.0 }
        // переведем в градусы цельсия и сделаем стринг
            .map { "\(String(format: "%.2f", ($0 - 273.15))) \(self.celsiusCharacters)"}
        //переведем на главный поток
            .subscribe(on: DispatchQueue(label: "Combine.Weather"))
        //создаем собственный поток (в данном случае не нужен, но для примера)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: {completion in
                self.activityIndicatorView.stopAnimating()
                self.searchButton.isEnabled = true
            }, receiveValue: { temp in
                self.temperatureLabel.text = temp
            })
    }
}

