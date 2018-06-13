import UIKit

enum FieldType: String {
    case phone
    case email
    case name
    case surname
    case password
    case confirmPassword
    
    var placeholder: String {
        return self.rawValue
    }
    
    var minCharacterCount: Int {
        switch self {
        case .phone:
            return 10
        case .email:
            return 3
        case .password, .confirmPassword:
            return 5
        case .name, .surname:
            return 1
        }
    }
    
    var maxCharacterCount: Int {
        switch self {
        case .phone:
            return 10
        default:
            return 20
        }
    }
}

class TextFieldWithErrorLabel: UIView {
    let textField = UITextField()
    let errorLabel: UILabel = {
        $0.textColor = .red
        $0.font = UIFont.systemFont(ofSize: 10.0)
        return $0
    }(UILabel())
    
    init() {
        super.init(frame: .zero)
        let stackView = UIStackView(arrangedSubviews: [self.textField, self.errorLabel])
        stackView.axis = .vertical
        
        self.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
