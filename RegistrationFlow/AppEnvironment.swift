import ReactiveSwift

struct AppEnvironment {
    static var current: AppEnvironment = AppEnvironment()
    
    let apiService: ServiceType
    
    let apiDelayInterval: TimeInterval
    
    let scheduler: DateScheduler
    
    init(
        apiService: ServiceType = MockService(),
        apiDelayInterval: TimeInterval = TimeInterval(2),
        scheduler: DateScheduler = QueueScheduler.main
        ) {
        self.apiService = apiService
        self.apiDelayInterval = apiDelayInterval
        self.scheduler = scheduler
    }
}
