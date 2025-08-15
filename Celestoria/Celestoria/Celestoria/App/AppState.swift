
     @Published var shouldNavigateToMemoryDetail: Bool = false {
             didSet {
                 Logger.info("Should Navigate To Memory Detail: \(shouldNavigateToMemoryDetail)")
             }
         }
    
    // Explore Navigation Trigger
    @Published var shouldNavigateToExplore: Bool = false {
        didSet {
            Logger.info("Should Navigate To Explore: \(shouldNavigateToExplore)")
        }
    }
    
    // Main navigation control
