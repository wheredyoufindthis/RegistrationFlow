import ReactiveSwift

struct CheckPhoneEnvelope {
    
}

struct AddNameEnvelope {
    
}

struct AddEmailEnvelope {
    
}

struct AddPasswordEnvelope {
    
}

struct ErrorEnvelope: Error {
    
}

protocol ServiceType {
    func check(phone: String) -> SignalProducer<CheckPhoneEnvelope, ErrorEnvelope>
    func add(name: String, surname: String) -> SignalProducer<AddNameEnvelope, ErrorEnvelope>
    func add(email: String) -> SignalProducer<AddEmailEnvelope, ErrorEnvelope>
    func add(password: String) -> SignalProducer<AddPasswordEnvelope, ErrorEnvelope>
}

extension ServiceType {
    func check(phone: String) -> SignalProducer<CheckPhoneEnvelope, ErrorEnvelope> {
        return .init(value: CheckPhoneEnvelope())
    }
    
    func add(name: String, surname: String) -> SignalProducer<AddNameEnvelope, ErrorEnvelope> {
        return .init(value: AddNameEnvelope())
    }
    
    func add(email: String) -> SignalProducer<AddEmailEnvelope, ErrorEnvelope> {
        return .init(value: AddEmailEnvelope())
    }
    
    func add(password: String) -> SignalProducer<AddPasswordEnvelope, ErrorEnvelope> {
        return .init(value: AddPasswordEnvelope())
    }
}
