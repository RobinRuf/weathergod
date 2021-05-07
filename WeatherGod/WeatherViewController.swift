//
//  WeatherViewController.swift
//  WeatherGod
//
//  Created by Robin Ruf on 16.12.20.
//

import UIKit
import CoreLocation // Wird benötigt, um GPS-Daten zu erhalten
import Alamofire // Externes Framework, welches wir installiert haben, wird nun importiert - URL-Abfragen
import SwiftyJSON // Externes Framework, welches wir installiert haben, wird nun importiert - Wird benötigt, um mit dem JSON-Format arbeiten zu können

class WeatherViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var weatherStatusLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var weatherStatusImageView: UIImageView!
    
    var weatherDataModel = WeatherDataModel()
    
    var timer = Timer() // Timer Objekt erstellen, um die Zeit nachher jede Sekunde anzeigen zu lassen.
    
    var locationManager = CLLocationManager() // Variable für die GPS-Daten
    
    
    // MARK: - important constants
    // Damit geben wir an, dass wir die metrischen Einheiten nutzen wollen. (Grad Celsius anstatt Fahrenheit, cm statt inch etc. (Europa-Standard)
    let UNIT = "metric"
    
    // Damit geben wir die Sprache an, in der uns openweathermap.org die Daten übergeben soll. Also statt "clear sky" steht dann automatisch "klarer Himmel" ohne, dass wir es selbst übersetzen müssen.
    let LANGUAGE = "de"
    
    // ID = API KEY von OpenWeatherMap.org --> Benutzerdefinierter Code im Account
    let ID = "f0a08c4e9804e27ccbd76f5cdbe75d04"
    
    // URLs, welche auf der Website openweathermap.org gelistet sind, damit wir wissen, über welche URLs man die Serverabfragen erreicht - jeweils eine einzigartige URL pro Abfragevariante. (über GPS (Coordinaten), über den Stadtnamen etc.
    let WEATHER_URL_BY_COORDINATES = "http://api.openweathermap.org/data/2.5/weather?"
    let WEATHER_URL_BY_CITYNAME = "http://api.openweathermap.org/data/2.5/weather?q="
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - UI Label init
        // Die abgeänderten Labels müssen über die erstellte Methode beim Laden der App aufgerufen werden, damit sich die Labels auch im UserInterface für den Endnutzer ändern - WEIL MERKE: Eine Methode definiert, was passieren soll, jedoch muss die Methode aufgerufen werden, damit es passiert!
        setLabel(label: cityLabel)
        setLabel(label: tempLabel)
        setLabel(label: weatherStatusLabel)
        setLabel(label: dateLabel)
        setLabel(label: timeLabel)
        
        setupLocationManager() // Methode wird aufgerufen, damit die Anfrage kommt, ob wir die GPS-Daten des Users nutzen dürfen. Danach werden die GPS Daten direkt geladen aus der Methode locationManager()

        setTime()
        setDate()
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(setTime), userInfo: nil, repeats: true)
        // Time Interval = in welchem Sekundenabstand soll sich die Methode wiederholen?
        // target = Wer soll die Methode ständig wiederholen? Self (WeatherViewController)
        // selector = Muss man einfach so reinschreiben und dann vor der Methode, die sich wiederholen soll ein @objc reinschrieben - einfach wegen der Syntax, weil es zur ältere objective-c Zeit gehört
        // userInfo = nil, da muss nichts passieren
        // repeats = Soll sich diese Methode ständig im gewünschten Time Interval wiederholen?
        
    }
    
    // MARK: - set Label
    // Labels werden per code visuell verändert, da dies weniger aufwendig ist, als jedes Label eigens zu im Storyboard zu verändern - vorallem bei späterer steigender Label-Anzahl
    func setLabel(label: UILabel) {
        // 1 = cityLabel 2 = timeLabel 3 = tempLabel
        
        if label.tag == 1 || label.tag == 2 {
            label.textAlignment = .center
            label.textColor = UIColor.black
            label.font = UIFont.boldSystemFont(ofSize: 18)
        } else if label.tag == 3 {
            label.textAlignment = .right
            label.font = UIFont.boldSystemFont(ofSize: 60)
            label.textColor = UIColor.cyan
        } else {
            label.textAlignment = .left
            label.font = UIFont.init(name: "Arial", size: 14)
            label.textColor = UIColor.black
        }
    }
    
    // MARK: - GPS Data
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // bedeutet, dass die Location auf 100 Meter genau ist - reicht für eine Wetter-App völlig aus.
        locationManager.requestWhenInUseAuthorization() // User anfragen, ob wir seine GPS Daten nutzen dürfen - ACHTUNG! Nicht vergessen, info.plist Datei die "Privacy" Sachen hinzufügen bzgl. der Location!!!
        locationManager.startUpdatingLocation() // Nachdem der User zugestimmt hat, gibt diese Methode uns die aktuellen GPS Daten zurück
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // latitude = Breitengrad
        // longitude = Längengrad
        // altitude = Höhengrad
        // accuracy = Genauigkeit
        
        let location = locations[locations.count - 1] // bringt immer die neusten GPS Daten (an letzter Stelle des Arrays - deshalb ANZAHL (.count) MINUS 1 (da Index im Array immer ANZAHL - 1 ist)
        
        if location.horizontalAccuracy > 0 { // Sobald die Genauigkeit inner der vorher definierten 100 Meter liegen....
            locationManager.stopUpdatingLocation() // ... dann hör auf, weiter Daten zu erstellen, um den Akku zu schonen...
            locationManager.delegate = nil // ... und ViewController, hör auf diese Methode auszugeben!
        }
        
        let latitude = Int(location.coordinate.latitude)  // Breitengrad abspeichern in einer Konstante
        let longitude = Int(location.coordinate.longitude) // Längengrad abspeichern in einer Konstante
        // Daten als INT gespeichert, da Kommawert (31.129172) nicht gebraucht wird, da für die Wetter-App bereits der Integer (31) ausreichend genau ist.
        
        
        let url = WEATHER_URL_BY_COORDINATES + "lat=\(latitude)&lon=\(longitude)" + "&appid=\(ID)" + "&units=\(UNIT)" + "&lang=\(LANGUAGE)"
        // Der Link wird um den nötigen Rest erweitert, damit der Link genau die Anfrage an den Server schickt, als würde man den Link im Browser eingeben - damit wir die richtigen Informationen erhalten. Das "&appid=\(ID)" ergänzt dann den Link mit unserem API Key, wodurch der Server von openweathermap.org weiss, dass wir berechtigt sind, diese Abfrage zu tätigen. Dann das "&units\(UNIT)" ergänzt die EINHEIT (UNIT auf Deutsch = EINHEIT), sowie "&lang=\(LANGUAGE)" die Sprache ergänzt. (en/de/fr etc.)
        
        
        getWeatherData(url: url) // Hier müssen wir die getWeatherData-Methode aufrufen, damit diese auch ausgeführt wird - als Parameter übergeben wir die Konstante "url", in dessen sich die URL + Endung zu unseren aktuellen GPS-Daten befindet + unseren API Key, damit der Server weiss, dass wir die Anfrage überhaupt tätigen dürfen.
    }
    
    // MARK: - Get Weather Data
    
    // url = Serveradresse
    // method: .get = Was wollen wir mit der URL machen? Daten erhalten (engl. GET data), deshalb .get
    // .responseJSON = Die Antwort (Response) kommt in einer JSON-Datei, deshalb .responseJSON (.antwortJSON)
    // (response) = In den () ist das RETURN, was erhalten wir zurück? Die Antwort des Servers.
    // if response.result.isSuccess = wenn der Rückgabewert erfolgreich was (also wir eine Antwort des Servers in Form einer JSON-Datei erhalten haben), dann passiert das Folgende, ansonsten (ELSE) teile dem User mit, dass die Serveranfrage nicht geklappt hat, aufgrund z.B. nicht vorhandener Internetverbindung, fehlendem GPS-Signals o.a.
    
    func getWeatherData(url: String) {
        Alamofire.request(url, method: .get).responseJSON { (response) in
            if response.result.isSuccess {
                
                let weatherJSON: JSON = JSON(response.result.value!)
// response.result ist das Resultat (Rückgabe/Return) und im Wert .value steckt das eigentliche Ergebnis. Da die Eigenschaft .value nie im voraus weiss, WAS genau in ihr steckt, ist sie vom Wert "Any?" (jeder Wert, Optional), also müssen wir es umwandeln in ein JSON-Format, und unwrappen es mit dem !-Zeichen, da wir in der If-Abfrage bereits überprüft haben, ob da ein Wert drin ist (durch das .isSuccess), müssen wir den "Optional" nicht nochmals prüfen, weil wir jetzt wissen, dass dort garantiert ein Wert drin ist. Da wir wissen, dass die Abfrage direkt eine JSON-Datei als Ergebnis zurückliefert, ist, sofern ein Wert im "response" vorhanden ist, GARANTIERT ein JSON-Format drin, also können wir es ohne Bedenken unwrappen.
                
                self.getWeatherDataFromJSON(json: weatherJSON)
            } else {
                
            }
        }
    }
    
    // MARK: - JSON Data
    func getWeatherDataFromJSON(json: JSON) {
        if json["main"]["temp"].double != nil { // json["main"]["temp"].double = Das JSON-File ist wie eine Datenstrucktur (Array) aufgebaut. Dort befinden sich Main-Data und Sub-Data. Die Main-Data stehen in der Datei mehr links, die Sub-Data haben einen leichten Einzug nach rechts verschoben. Also greift man in den ersten eckigen Klammern auf die Main-Data zu und dann mit den darauffolgenden zweiten eckigen Klammern auf eine Sub-Data IN diesen Main-Data zu. Dann die Schlusseigenschaft mit .double ist nur, weil die ["temp"] Sub-Data im ["main"] Main-Data eine Kommazahl ist!  Zum Auslesen MUSS man dann .intValue o.ä. verwenden. (.intValue / .doubleValue / .stringValue) Beispiel: print(json["main"]["temp"].intValue - warum nicht .double / .int ist einfach aus dem Grund, dass es dann als "Optional" zurückgegeben wird - bei .doubleValue sagt man, da ist auf jedenfall ein Wert drin, also gibs mir jetzt als Double aus, ohne, dass man es noch zusätzlich überprüfen und unwrappen muss.
            
            weatherDataModel.temp = json["main"]["temp"].intValue
            weatherDataModel.description = json["weather"][0]["description"].stringValue
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.country = json["sys"]["country"].stringValue
            weatherDataModel.iconName = json["weather"][0]["icon"].stringValue
            
            updateUI()
        }
    }
    
    // MARK: - Update UI
    func updateUI() {
        
        // Wetterdaten darstellen
        tempLabel.text = String(weatherDataModel.temp) + "°"
        cityLabel.text = weatherDataModel.city + ", " + weatherDataModel.country
        weatherStatusLabel.text = weatherDataModel.description
        
        // Wetter Icon laden
        let iconURL = "http://openweathermap.org/img/wn/\(weatherDataModel.iconName).png"
        
        weatherDataModel.loadImagefromURL(imageURL: iconURL, imageView: weatherStatusImageView)
    }
    
    // MARK: - Set Time and Date
    func setDate() {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "d. MMM yyyy" // Ändert das Format des Datums - M = Monat (3x M = Monat in 3 Zeichen z.B. Oct , Nov , Dec ...) , d = Tag , Komma danach, damit nach dem Tag ein Komma steht. y = Jahr, 4 x y = Jahreszahl 4-Stellig (Formatbeispielt: Oct 7, 2020)
        formatter.locale = Locale(identifier: "de_DE") // locale = Sprache vom Format wählen, damit Monat nicht in Englisch geschrieben wird. Im String dann wie die Sprachfestlegung in HTML - de_DE, de_CH, en_US etc.
        dateLabel.text = formatter.string(from: Date()) // Formatter legt nur das Format fest. Das hat eine Eigenschaft auszuwählen, wie es das Datum generieren soll - in unserem Fall als ein String, und dann muss man noch sagen, WAS der Formatter formatieren soll - also das Date() (Methode um das Datum anzuzeigen)
    }
    
    @objc func setTime() {  // sehr ähnlich zur Datumsanzeige
        let formatter = DateFormatter() // wieder ein Objekt der Klasse DateFormatter() erstellen
        formatter.dateFormat = "HH:mm:ss" // Das Format wählen (HH = Stunden, 2-stellig, mm = Minuten, 2-stellig, ss = Sekunden, 2-stellig)
        timeLabel.text = formatter.string(from: Date()) // und hier genau das gleiche, um die Zeit anzuzeigen, wie beim Datum
        
    }

}
