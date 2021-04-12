import SwiftUI

struct ContentView: View {
  // How much sleep the user usually likes.
  @State private var sleepAmount: Double = 0
  // When the user wants to wake up.
  @State private var wakeup = Date()
  // How much coffee they drink.
  @State private var coffeeAmount = 1

  // CoreML Tabular Regressor model.
  private let model = SleepCalculator()

  // Prediction output alert.
  @State private var alertTitle = ""
  @State private var alertMessage = ""
  @State private var showingAlert = false

  var body: some View {
    NavigationView {
      VStack {
        Text("When do you want to wake up?").font(.headline)
        // This date picker will get rendered as a spinning
        // wheel because it's inside of a VStack.
        DatePicker("Please enter a time",
                selection: $wakeup,
                displayedComponents: .hourAndMinute).labelsHidden()

        Text("Desired amount of sleep").font(.headline)
        Stepper(value: $sleepAmount, in: 4...12, step: 0.25) {
          Text("\(sleepAmount, specifier: "%g")")
        }

        Text("Daily coffee intake").font(.headline)
        Stepper(value: $coffeeAmount, in: 1...20) {
          Text(coffeeAmount == 1 ? "1 cup" : "\(coffeeAmount) cups")
        }
      }.navigationBarTitle("Better Rest")
              .navigationBarItems(trailing: Button(action: calculateBedtime) {
                Text("Calculate")
              })
              .alert(isPresented: $showingAlert) {
                Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("Ok")))
              }
    }
  }

  /// Shows an alert with the time that the user should go
  /// to bed to get the desired amount of sleep considering
  /// the amount of coffee consumed.
  /// This is predicted by a CoreML model.
  func calculateBedtime() {
    // Break down the wakeup date into hour/minutes.
    let components = Calendar.current.dateComponents(
            [.hour, .minute], from: wakeup)
    let hour = (components.hour ?? 0) * 60 * 60
    let minutes = (components.minute ?? 0) * 60

    // The CoreML prediction can fail.
    do {
      let prediction = try model.prediction(
              wake: Double(hour + minutes),
              estimatedSleep: sleepAmount,
              coffee: Double(coffeeAmount))

      let sleepTime = wakeup - prediction.actualSleep
      let formatter = DateFormatter()
      formatter.timeStyle = .short
      alertMessage = formatter.string(from: sleepTime)
      alertTitle = "Your ideal bedtime is..."
    } catch {
      // Something went wrong.
      alertTitle = "Error"
      alertMessage = "Sorry, there was a problem calculating your bedtime"
    }

    // Show the alert no mather what, because
    // we use it for both results and errors.
    showingAlert = true
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
