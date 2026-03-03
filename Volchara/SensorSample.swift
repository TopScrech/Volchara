import Foundation

struct SensorSample {
    let x: Double
    let y: Double
    let z: Double
    
    var magnitude: Double {
        (x * x + y * y + z * z).squareRoot()
    }
}
