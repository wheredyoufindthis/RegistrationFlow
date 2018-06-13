import ReactiveSwift
import Result

protocol RegistrationViewModelInputs {
    func viewDidLoad()
    func viewWillAppear()
    func enter(text: String, at index: Int)
    func continueButtonPressed()
    func textFieldShouldReturn(at index: Int)
}

protocol RegistrationViewModelOutputs {
    var continueButtonEnabled: Signal<Bool, NoError> { get }
    var loading: Signal<Bool, NoError> { get }
    
    var resignFirstResponder: Signal<(), NoError> { get }
    var errorMessageByFieldIndex: [Signal<String, NoError>] { get }
    var becomeFirstResponderByFieldIndex: [Signal<(), NoError>] { get }
    
    var requestSuccessfullyEnded: Signal<(), NoError> { get }
}

protocol RegistrationViewModelType {
    var inputs: RegistrationViewModelInputs { get }
    var outputs: RegistrationViewModelOutputs { get }
}

class RegistrationViewModel: RegistrationViewModelInputs, RegistrationViewModelOutputs,
RegistrationViewModelType {
    var inputs: RegistrationViewModelInputs { return self }
    var outputs: RegistrationViewModelOutputs { return self }
    
    let continueButtonEnabled: Signal<Bool, NoError>
    let loading: Signal<Bool, NoError>
    
    let resignFirstResponder: Signal<(), NoError>
    
    let errorMessageByFieldIndex: [Signal<String, NoError>]
    let becomeFirstResponderByFieldIndex: [Signal<(), NoError>]
    
    let requestSuccessfullyEnded: Signal<(), NoError>
    
    init(intent: RegistrationViewController.Intent, with types: [FieldType]) {
        
        let viewDidLoad = self.viewDidLoadProperty.signal
        let viewWillAppear = self.viewWillAppearProperty.signal
        
        let textFieldShouldReturn = self.textFieldShouldReturnAtIndexProperty.signal.map { _ in () }
        let buttonPressed = self.continueButtonPressedProperty.signal
        
        let userInteraction = Signal.merge(
            textFieldShouldReturn,
            buttonPressed
        )
        
        let textAtIndex = Signal.merge(
            self.enterTextProperty.signal.skipNil(),
            Signal.merge(
                types.enumerated().map { index, _ in
                    viewDidLoad.map { (text: "", index: index) }
                }
            )
        )
        
        let textAndTypePairs = Signal.combineLatest(
            types.enumerated().map { it in
                textAtIndex.filter { $0.index == it.offset }.map {
                    (text: $0.text, type: types[$0.index])
                }
            }
        )
        
        let isTextValidByIndex = textAndTypePairs.map { pairs in
            pairs.map { text, type -> Bool in
                let count = text.count
                return type.minCharacterCount <= count && count <= type.maxCharacterCount
            }
        }
        
        let areTextsValid = isTextValidByIndex.map {
            $0.reduce(true, { result, isValid -> Bool in result && isValid })
        }
        
        self.errorMessageByFieldIndex = types.enumerated().map { $0.offset }.map { offset in
            buttonPressed
                .withLatest(from: isTextValidByIndex.map { $0[offset] }).map { $0.1 }
                .filter { !$0 }.map { _ in "Wrong Format" }
        }
        
        let firstWrongIndex = isTextValidByIndex.map {
            $0.enumerated().first(where: { !$0.element })?.offset
            }.skipNil()
        
        userInteraction
            .withLatest(from: firstWrongIndex)
            .map { $0.1 }.observeValues { yo in
                
        }
        
        self.becomeFirstResponderByFieldIndex = types.enumerated().map { index, type in
            Signal.merge(
                viewWillAppear.filter { index == 0 },
                userInteraction
                    .withLatest(from: firstWrongIndex)
                    .map { $0.1 }
                    .filter { $0 == index }
                    .map { _ in () }
            )
        }
        
        let texts = textAndTypePairs.map { $0.map { $0.text } }
        let areTextsNotEmpty = texts.map { $0.map { $0.count > 0 }.reduce(true, { res, isValid in res && isValid }) }
        
        let inputForRequest = userInteraction.withLatest(
            from: areTextsValid.combineLatest(with: texts)
            ).filter { $0.1.0 }.map { $0.1.1 }
        
        var requestSuccessfullyEnded: Signal<(), NoError>!
        var error: Signal<ErrorEnvelope, NoError>!
        
        switch intent {
        case .email:
            let email = inputForRequest.map { $0.first }.skipNil()
            let request = email.flatMap(.concat) {
                AppEnvironment.current.apiService
                    .add(email: $0)
                    .materialize()
                    .delay(AppEnvironment.current.apiDelayInterval,
                           on: AppEnvironment.current.scheduler)
                }
            requestSuccessfullyEnded = request.map { $0.event.value }.skipNil().map { _ in () }
            error = request.map { $0.event.error }.skipNil()
        case .name:
            let name = inputForRequest.map { $0.first }.skipNil()
            let surname = inputForRequest.map { $0.last }.skipNil()
            let request = name.combineLatest(with: surname).flatMap(.concat) {
                AppEnvironment.current.apiService
                    .add(name: $0.0, surname: $0.1)
                    .materialize()
                    .delay(AppEnvironment.current.apiDelayInterval,
                           on: AppEnvironment.current.scheduler)
                }
            requestSuccessfullyEnded = request.map { $0.event.value }.skipNil().map { _ in () }
            error = request.map { $0.event.error }.skipNil()
        case .password:
            let password = inputForRequest.map { $0.first }.skipNil()
            let request = password.flatMap(.concat) {
                AppEnvironment.current.apiService
                    .add(password: $0)
                    .materialize()
                    .delay(AppEnvironment.current.apiDelayInterval,
                           on: AppEnvironment.current.scheduler)
                }
            requestSuccessfullyEnded = request.map { $0.event.value }.skipNil().map { _ in () }
            error = request.map { $0.event.error }.skipNil()
        case .phone:
            let phone = inputForRequest.map { $0.first }.skipNil()
            let request = phone.flatMap(.concat) {
                AppEnvironment.current.apiService
                    .check(phone: $0)
                    .materialize()
                    .delay(AppEnvironment.current.apiDelayInterval,
                           on: AppEnvironment.current.scheduler)
                }
            requestSuccessfullyEnded = request.map { $0.event.value }.skipNil().map { _ in () }
            error = request.map { $0.event.error }.skipNil()
        }
        
        self.loading = Signal.merge(
            inputForRequest.map { _ in true },
            Signal.merge(
                error.map { _ in () },
                requestSuccessfullyEnded
                ).map { _ in false }
        )
        
        self.requestSuccessfullyEnded = requestSuccessfullyEnded
        
        self.resignFirstResponder = inputForRequest.map { _ in () }
        
        self.continueButtonEnabled = Signal.merge(
            areTextsNotEmpty,
            viewDidLoad.map { _ in false }
        )
    }
    
    fileprivate let viewDidLoadProperty = MutableProperty(())
    func viewDidLoad() {
        self.viewDidLoadProperty.value = ()
    }
    
    
    fileprivate let viewWillAppearProperty = MutableProperty(())
    func viewWillAppear() {
        self.viewWillAppearProperty.value = ()
    }
    
    fileprivate let enterTextProperty = MutableProperty<(text: String, index: Int)?>(nil)
    func enter(text: String, at index: Int) {
        self.enterTextProperty.value = (text, index)
    }
    
    fileprivate let continueButtonPressedProperty = MutableProperty(())
    func continueButtonPressed() {
        self.continueButtonPressedProperty.value = ()
    }
    
    fileprivate let textFieldShouldReturnAtIndexProperty = MutableProperty<Int?>(nil)
    func textFieldShouldReturn(at index: Int) {
        self.textFieldShouldReturnAtIndexProperty.value = index
    }
}
