@testable import SwiftUICaseStudies
import ComposableArchitecture
import XCTest

class StateBindingTests: XCTestCase {
  func testStateBindingWithStorage() {
    struct Feature {
      var external: String = ""
      var `internal`: Int = 0
    }
    struct State {
      var content: String = ""
      var _feature: Feature = .init()
      
      static var _feature = StateBinding(\Self._feature)
        .rw(\.content, \.external)

      var feature: Feature {
        get { Self._feature.get(self) }
        set { Self._feature.set(&self, newValue) }
      }
    }
        
    var state = State()
    state.feature.internal = 1
    state.feature.external = "Hello!"
        
    XCTAssertEqual(state.feature.internal, 1)
    XCTAssertEqual(state.feature.external, "Hello!")
    XCTAssertEqual(state.content, "Hello!")

    state.content = "World!"
    XCTAssertEqual(state.feature.internal, 1)
    XCTAssertEqual(state.feature.external, "World!")
  }
    
  func testOptionalStateBindingWithStorage() {
    struct Feature {
      var external: String = ""
      var `internal`: Int = 0
    }
    struct State {
      var content: String = ""
      var _feature: Feature? = nil
      static var _feature = StateBinding(\Self._feature)
        .map(
          .rw(\.content, \.external)
        )

      var feature: Feature? {
        get { Self._feature.get(self) }
        set { Self._feature.set(&self, newValue) }
      }
    }
        
    var state = State()
    state.feature = .init()
        
    state.feature?.internal = 1
    state.feature?.external = "Hello!"
        
    XCTAssertEqual(state.feature?.internal, 1)
    XCTAssertEqual(state.feature?.external, "Hello!")
    XCTAssertEqual(state.content, "Hello!")

    state.content = "World!"
    XCTAssertEqual(state.feature?.internal, 1)
    XCTAssertEqual(state.feature?.external, "World!")
        
    state._feature = nil
    state.feature?.external = "Test"
    // `content` should be unchanged as `feature` is nil.
    XCTAssertEqual(state.content, "World!")
  }
  
  func testCanonicalOptionalStateBindingWithStorage() {
    struct Feature {
      var external: String = ""
      var `internal`: Int = 0
    }
    struct State {
      var content: String = ""
      var _feature: Feature? = nil
      static var _feature = StateBinding(\Self._feature)
        .rw(\.content, \.external)

      var feature: Feature? {
        get { Self._feature.get(self) }
        set { Self._feature.set(&self, newValue) }
      }
    }
        
    var state = State()
    state.feature = .init()
        
    state.feature?.internal = 1
    state.feature?.external = "Hello!"
        
    XCTAssertEqual(state.feature?.internal, 1)
    XCTAssertEqual(state.feature?.external, "Hello!")
    XCTAssertEqual(state.content, "Hello!")

    state.content = "World!"
    XCTAssertEqual(state.feature?.internal, 1)
    XCTAssertEqual(state.feature?.external, "World!")
        
    state._feature = nil
    state.feature?.external = "Test"
    // `content` should be unchanged as `feature` is nil.
    XCTAssertEqual(state.content, "World!")
  }
    
  func testComputedStateBinding() {
    struct Feature {
      var external: String = ""
      var `internal`: Int = 0
    }
    struct State {
      var content: String = ""
      var count = 0
            
      static var _feature = StateBinding<State, Feature>(with: Feature.init)
        .rw(\.content, \.external)
        .rw(\.count, \.internal)

      var feature: Feature {
        get { Self._feature.get(self) }
        set { Self._feature.set(&self, newValue) }
      }
    }
        
    var state = State()
    state.feature.internal = 1
    state.feature.external = "Hello!"
        
    XCTAssertEqual(state.feature.internal, 1)
    XCTAssertEqual(state.feature.external, "Hello!")
        
    state.content = "World!"
    state.count = 2
        
    XCTAssertEqual(state.feature.internal, 2)
    XCTAssertEqual(state.feature.external, "World!")
  }
    
  func testOptionalComputedStateBinding() {
    struct Feature {
      var external: String = ""
      var `internal`: Int = 0
    }
    struct State {
      var content: String = ""
      var count = 0
      var hasFeature = false
      static var _feature = StateBinding<State, Feature?>(with: { $0.hasFeature ? .init() : nil })
        .rw(\.content, \.external)
        .rw(\.count, \.internal)

      var feature: Feature? {
        get { Self._feature.get(self) }
        set { Self._feature.set(&self, newValue) }
      }
    }
        
    var state = State()
    XCTAssertNil(state.feature)
        
    state.content = "World!"
    state.count = 2
        
    state.hasFeature = true

    XCTAssertEqual(state.feature?.internal, 2)
    XCTAssertEqual(state.feature?.external, "World!")
        
    state.feature?.internal = 1
    state.feature?.external = "Hello!"
        
    XCTAssertEqual(state.count, 1)
    XCTAssertEqual(state.content, "Hello!")
        
    state.hasFeature = false

    state.feature?.internal = 3
    state.feature?.external = "Test"
        
    // Should be unchanged as `feature` is nil.
    XCTAssertEqual(state.count, 1)
    XCTAssertEqual(state.content, "Hello!")
  }
  
  func testStateBindingDeDuplication() {
    struct Feature: Equatable {
      var external: String = ""
      var `internal`: Int = 0
    }
    struct State {
      var content: String = "" {
        didSet { XCTFail("`content` value was set") }
      }

      var _feature: Feature = .init() {
        didSet { XCTFail("`_feature` value was set") }
      }

      static var _feature = StateBinding(\Self._feature, removeDuplicateStorage: ==)
        .rw(\.content, \.external, removeDuplicates: ==)

      var feature: Feature {
        get { Self._feature.get(self) }
        set { Self._feature.set(&self, newValue) }
      }
    }
        
    var state = State(content: "Hello!", _feature: .init(external: "Hello!", internal: 1))
    // This would hit didSet and fail if not deduplicated.
    state.feature.internal = 1
    state.feature.external = "Hello!"
  }
  
  func testArrayStateBindingWithStorage() {
    struct Feature {
      var external: String = ""
      var `internal`: Int = 0
    }
    struct State {
      var content: String = ""
      var _features: [Feature] = []
      static var _features = StateBinding(\Self._features)
        .map(
          .rw(\.content, \.external)
        )

      var features: [Feature] {
        get { Self._features.get(self) }
        set { Self._features.set(&self, newValue) }
      }
    }
        
    var state = State()
    state.features = [.init(), .init()]
      
    state.content = "World!"
    XCTAssertEqual(state.features[0].external, "World!")
    XCTAssertEqual(state.features[1].external, "World!")

    state.features[0].external = "Hello!"
    
    // `content` should be unchanged.
    XCTAssertEqual(state.content, "World!")
    XCTAssertEqual(state.features[0].external, "World!")
  }
  
  func testDictionaryStateBindingWithStorage() {
    struct Feature {
      var external: String = ""
      var `internal`: Int = 0
    }
    struct State {
      var content: String = ""
      var _features: [Int: Feature] = [:]
      static var _features = StateBinding(\Self._features)
        .map(
          .rw(\.content, \.external)
        )

      var features: [Int:Feature] {
        get { Self._features.get(self) }
        set { Self._features.set(&self, newValue) }
      }
    }
        
    var state = State()
    state.features = [1:.init(), 2:.init()]
      
    state.content = "World!"
    XCTAssertEqual(state.features[1]?.external, "World!")
    XCTAssertEqual(state.features[2]?.external, "World!")

    state.features[1]?.external = "Hello!"
    
    // `content` should be unchanged.
    XCTAssertEqual(state.content, "World!")
    XCTAssertEqual(state.features[1]?.external, "World!")
  }
  
  func testIdentifiedArrayStateBindingWithStorage() {
    struct Feature: Identifiable {
      var id: Int
      var external: String = ""
      var `internal`: Int = 0
    }
    struct State {
      var content: String = ""
      var _features: IdentifiedArray<Int, Feature> = IdentifiedArray<Int, Feature>(id: \.id)
      static var _features = StateBinding(\Self._features)
        .map(
          .rw(\.content, \.external)
        )

      var features: IdentifiedArray<Int, Feature> {
        get { Self._features.get(self) }
        set { Self._features.set(&self, newValue) }
      }
    }
        
    var state = State()
    state.features.append(.init(id: 1))
    state.features.append(.init(id: 2))

    state.content = "World!"
    XCTAssertEqual(state.features[0].external, "World!")
    XCTAssertEqual(state.features[1].external, "World!")

    state.features[0].external = "Hello!"
    
    // `content` should be unchanged.
    XCTAssertEqual(state.content, "World!")
    XCTAssertEqual(state.features[0].external, "World!")
  }
  
  func testStatesSynchronization() {
    let store = TestStore(
      initialState: SharedStateWithBinding(),
      reducer: sharedStateWithBindingReducer,
      environment: ()
    )

    store.assert(
      .send(.feature1(.binding(BindingAction<SharedStateWithBinding.FeatureState>.set(\.text, "Hello!")))) {
        $0.content = "Hello!"
        $0._feature2.count = 0
        $0._feature2.text = ""
        $0._feature2.name = ""
      },
      .send(.feature2(.binding(BindingAction<SharedStateWithBinding.FeatureState>.set(\.count, 4)))) {
        $0._feature2.count = 4
        $0._feature2.text = "Hello!"
        $0._feature2.name = $0.feature2Name
        $0._feature3 = nil
      },
      .send(.toggleFeature3) {
        $0._feature3 = SharedStateWithBinding.FeatureState()
      },
      .send(.feature3(.binding(BindingAction<SharedStateWithBinding.FeatureState>.set(\.count, 10)))) {
        $0._feature3?.count = 10
        $0._feature3?.text = "Hello!"
        $0._feature3!.name = $0.feature3Name
      },
      .send(.feature3(.binding(BindingAction<SharedStateWithBinding.FeatureState>.set(\.text, "World")))) {
        $0._feature3?.count = 10
        $0._feature3?.text = "World"
        $0.content = "World"
      }
    )
  }
  
}
