import UIKit

class RegistrationCoordinator: NSObject {
    let navigationController: UINavigationController
    
    init(with navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }
    
    func start() {
        self.pushRegistrationController(with: .phone, animated: false)
    }
    
    func pushRegistrationController(with intent: RegistrationViewController.Intent, animated: Bool = true) {
        let vc = RegistrationViewController(with: intent)
        vc.delegate = self
        self.navigationController.pushViewController(vc, animated: animated)
    }
}

extension RegistrationCoordinator: RegistrationViewControllerDelegate {
    func didCheckPhone() {
        self.pushRegistrationController(with: .email)
    }
    
    func didAddEmail() {
        self.pushRegistrationController(with: .name)
    }
    
    func didAddName() {
        self.pushRegistrationController(with: .password)
    }
    
    func didAddPassword() {
        self.navigationController.popToRootViewController(animated: true)
    }
}
