import SwiftUI

struct ContentView: View {
    @State private var viewModel = ContentViewModel()
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Volchara")
                .font(.largeTitle.weight(.bold))
            
            ModePickerView(selectedMode: $viewModel.selectedMode)
            
            SensitivityControlView(minAmplitude: $viewModel.minAmplitude)
            
            ActionButtonsView(
                isListening: viewModel.isListening,
                toggleAction: viewModel.toggleListening,
                testAction: viewModel.triggerTestSlap
            )
            
            StatusPanelView(
                statusText: viewModel.statusText,
                lastSlapText: viewModel.lastSlapText,
                copyAction: viewModel.copyStatusToClipboard
            )
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(minWidth: 560, minHeight: 420)
        .onChange(of: viewModel.selectedMode) { oldValue, newValue in
            if oldValue != newValue {
                viewModel.modeChanged(to: newValue)
            }
        }
        .onChange(of: viewModel.minAmplitude) { oldValue, newValue in
            if oldValue != newValue {
                viewModel.sensitivityChanged(to: newValue)
            }
        }
    }
}

#Preview {
    ContentView()
}
