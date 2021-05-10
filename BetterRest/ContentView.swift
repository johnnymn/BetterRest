import CoreML
import SwiftUI

struct ContentView: View {
  // How much sleep the user wants.
  @State private var sleepAmount: Double = 8
  // How much coffee they drink.
  @State private var coffeeAmount = 1
  // When the user wants to wake up.
  @State private var wakeup = defaultWakeTime

  static var defaultWakeTime: Date {
    var components = DateComponents()
    components.hour = 7
    components.minute = 0

    return Calendar.current.date(from: components) ?? Date()
  }

  // CoreML Tabular Regressor model.
  let model: SleepCalculator = {
    do {
      return try SleepCalculator(configuration: MLModelConfiguration())
    } catch {
      print(error)
      fatalError("Couldn't create SleepCalculator")
    }
  }()

  // Estimates the time that the user should go to bed
  // to get the desired amount of sleep considering the
  // amount of coffee consumed, and displays it on a
  // text box.
  // The prediction is done by the CoreML model.
  private var bedTime: String {
    // Break down the wakeup date into hour/minutes.
    let components = Calendar.current.dateComponents(
            [.hour, .minute], from: wakeup)
    let hour = (components.hour ?? 0) * 60 * 60
    let minutes = (components.minute ?? 0) * 60
    var bedTime = ""

    // The CoreML prediction can fail.
    do {
      let prediction = try model.prediction(
              wake: Double(hour + minutes),
              estimatedSleep: sleepAmount,
              coffee: Double(coffeeAmount))

      let sleepTime = wakeup - prediction.actualSleep
      let formatter = DateFormatter()
      formatter.timeStyle = .short
      bedTime = formatter.string(from: sleepTime)
    } catch {
      // Something went wrong, show an alert
      alertTitle = "Error"
      alertMessage = "Sorry, there was a problem calculating your bedtime"
      showingAlert = true
    }

    return bedTime
  }

  // Prediction output alert.
  @State private var alertTitle = ""
  @State private var alertMessage = ""
  @State private var showingAlert = false

  var body: some View {
    NavigationView {
      Form {
        // Put each pair of text view and control in a
        // VStack so each is displayed as a single row
        // in the form
        Section(header: Text("When do you want to wake up?")) {
          DatePicker("Please enter a time",
                  selection: $wakeup,
                  displayedComponents: .hourAndMinute)
                  .labelsHidden()
                  .datePickerStyle(WheelDatePickerStyle())
        }

        Section(header: Text("Desired amount of sleep")) {
          Stepper(value: $sleepAmount, in: 4...12, step: 0.25) {
            Text("\(sleepAmount, specifier: "%g")")
          }
        }

        Section(header: Text("Daily coffee intake")) {
          Stepper(value: $coffeeAmount, in: 1...20) {
            Text(coffeeAmount == 1 ? "1 cup" : "\(coffeeAmount) cups")
          }
        }

        Section(header: Text("Recommended bed time")) {
          Text("\(bedTime)")
        }
      }.navigationBarTitle("Better Rest").alert(isPresented: $showingAlert) {
        Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("Ok")))
      }
    }
  }
}

class ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }

  #if DEBUG
  @objc class func injected() {
    UIApplication.shared.windows.first?.rootViewController =
            UIHostingController(rootView: ContentView())
  }
  #endif
}
