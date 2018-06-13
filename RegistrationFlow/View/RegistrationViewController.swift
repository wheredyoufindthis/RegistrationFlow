import UIKit

import SnapKit
import PKHUD

protocol RegistrationViewControllerDelegate: NSObjectProtocol {
    func didCheckPhone()
    func didAddEmail()
    func didAddName()
    func didAddPassword()
}

class RegistrationViewController: UIViewController {
    
    enum Intent {
        case phone
        case email
        case name
        case password
    }
    
    static func fieldTypes(by intent: Intent) -> [[FieldType]] {
        switch intent {
        case .phone:
            return [[.phone]]
        case .email:
            return [[.email]]
        case .name:
            return [[.name, .surname]]
        case .password:
            return [[.password], [.confirmPassword]]
        }
    }
    
    let intent: Intent
    let contentStackView: UIStackView = {
        $0.axis = .vertical
        return $0
    }(UIStackView())
    
    let fieldsWithLabel: [TextFieldWithErrorLabel]
    let fieldTypes: [FieldType]
    let textFieldStackView: UIStackView
    
    let viewModel: RegistrationViewModelType
    
    let textFieldsWrapperView = UIView()
    let continueButton: UIButton = {
        $0.setTitle("Submit", for: .normal)
        $0.setTitleColor(.black, for: .normal)
        return $0
    }(UIButton())
    
    private var keyboardHeight: CGFloat = 0
    
    weak var delegate: RegistrationViewControllerDelegate?
    
    init(with intent: Intent) {
        self.intent = intent
        
        let fieldTypesByRow = RegistrationViewController.fieldTypes(by: intent)
        let rowAndTextFieldsPairs = fieldTypesByRow.map(
            RegistrationViewController.buildHorizontalRow
        )
        
        let rows = rowAndTextFieldsPairs.map { $0.0 }
        self.fieldsWithLabel = rowAndTextFieldsPairs
            .map { $0.1 }
            .reduce([TextFieldWithErrorLabel]()) { (result, fields) -> [TextFieldWithErrorLabel] in
                result + fields
        }
        
        let textFieldStackView = UIStackView(arrangedSubviews: rows)
        textFieldStackView.axis = .vertical
        textFieldStackView.spacing = 20.0
        self.textFieldStackView = textFieldStackView
        
        let fieldTypes = fieldTypesByRow.reduce([FieldType]()) { (result, types) -> [FieldType] in
            result + types
        }
        self.fieldTypes = fieldTypes
        
        self.viewModel = RegistrationViewModel(intent: intent, with: fieldTypes)
        
        super.init(nibName: nil, bundle: nil)
        
        fieldsWithLabel.forEach { [weak self] in
            $0.textField.delegate = self
            $0.textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        }
        
        self.continueButton.addTarget(self, action: #selector(continueButtonPressed), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.inputs.viewWillAppear()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default
            .addObserver(forName: .UIKeyboardWillShow, object: nil, queue: nil) { [weak self] in
                self?.updateLayout(notification: $0)
        }
        
        NotificationCenter.default
            .addObserver(forName: .UIKeyboardWillHide, object: nil, queue: nil) { [weak self] _ in
                self?.updateLayout(keyboardHeight: 0)
        }
        
        let textFields = self.fieldsWithLabel.map { $0.textField }
        let labels = self.fieldsWithLabel.map { $0.errorLabel }
        
        zip(textFields, self.viewModel.outputs.becomeFirstResponderByFieldIndex).forEach { field, signal in
            signal.observeValues {
                field.becomeFirstResponder()
            }
        }
        
        zip(labels, self.viewModel.outputs.errorMessageByFieldIndex).forEach { label, signal in
            signal.observeValues {
                label.text = $0
            }
        }
        
        self.viewModel.outputs.continueButtonEnabled.observeValues { [weak self] in
            self?.continueButton.isEnabled = $0
            self?.continueButton.alpha = $0 ? 1.0 : 0.5
        }
        
        self.viewModel.outputs.loading.observeValues {
            $0
                ? HUD.show(.progress)
                : HUD.hide(animated: false)
        }
        
        self.viewModel.outputs.resignFirstResponder.observeValues { [weak self] in
            self?.view.endEditing(true)
        }
        
        self.viewModel.outputs.requestSuccessfullyEnded.observeValues { [weak self] in
            if let intent = self?.intent {
                switch intent {
                case .email:
                    self?.delegate?.didAddEmail()
                case .name:
                    self?.delegate?.didAddName()
                case .password:
                    self?.delegate?.didAddPassword()
                case .phone:
                    self?.delegate?.didCheckPhone()
                }
            }
        }
        
        self.viewModel.inputs.viewDidLoad()
    }
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.contentStackView)
        self.contentStackView.snp.makeConstraints {
            $0.edges.equalTo(self.view.snp.margins)
        }
        
        self.contentStackView.addArrangedSubview(self.textFieldsWrapperView)
        self.contentStackView.addArrangedSubview(self.continueButton)
        
        self.textFieldsWrapperView.addSubview(self.textFieldStackView)
        self.textFieldStackView.snp.makeConstraints {
            $0.leading.trailing.centerY.equalToSuperview()
        }
    }
    
    static func buildHorizontalRow(with types: [FieldType]) -> (UIView, [TextFieldWithErrorLabel]) {
        let textViews = types.map { (type) -> TextFieldWithErrorLabel in
            let fieldWithLabel = TextFieldWithErrorLabel()
            fieldWithLabel.textField.placeholder = type.placeholder
            return fieldWithLabel
        }
        let stackView = UIStackView(arrangedSubviews: textViews)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10.0
        return (stackView, textViews)
    }
    
    override func updateViewConstraints() {
        self.contentStackView.snp.updateConstraints { make in
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(self.keyboardHeight)
        }
        
        super.updateViewConstraints()
    }
    
    func updateLayout(keyboardHeight: CGFloat) {
        self.keyboardHeight = keyboardHeight
        self.updateViewConstraints()
        self.view.layoutIfNeeded()
    }
    
    func updateLayout(notification: Notification) {
        let rectValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        if let height = rectValue?.cgRectValue.height {
            self.updateLayout(keyboardHeight: height)
        }
    }
    
    func getIndex(by textField: UITextField) -> Int? {
        return self.fieldsWithLabel.enumerated()
            .first(where: { $0.element.textField === textField })?
            .offset
    }
    
    @objc func textChanged(_ textField: UITextField) {
        if let index = self.getIndex(by: textField),
            let text = textField.text {
            self.viewModel.inputs.enter(text: text, at: index)
        }
    }
    
    @objc func continueButtonPressed(_ sender: UIButton) {
        self.viewModel.inputs.continueButtonPressed()
    }
}

extension RegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let index = self.getIndex(by: textField) {
            self.viewModel.inputs.textFieldShouldReturn(at: index)
        }
        return false
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let index = self.getIndex(by: textField), let text = textField.text else { return true }
        self.fieldsWithLabel[index].errorLabel.text = ""
        let newLength = (text as NSString).replacingCharacters(in: range, with: string).count
        return newLength <= self.fieldTypes[index].maxCharacterCount
    }
}

