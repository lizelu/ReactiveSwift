/*:
 > # IMPORTANT: To use `ReactiveSwift.playground`, please:
 
 1. Retrieve the project dependencies using one of the following terminal commands from the ReactiveSwift project root directory:
    - `git submodule update --init`
 **OR**, if you have [Carthage](https://github.com/Carthage/Carthage) installed
    - `carthage checkout`
 1. Open `ReactiveSwift.xcworkspace`
 1. Build `Result-Mac` scheme
 1. Build `ReactiveSwift-macOS` scheme
 1. Finally open the `ReactiveSwift.playground`
 1. Choose `View > Show Debug Area`
 */
import Result
import ReactiveSwift
import Foundation
/*:
 ## Property
 
 A **property**, represented by the [`PropertyProtocol`](https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/Sources/Property.swift) ,
 stores a value and notifies observers about future changes to that value.
 
 - The current value of a property can be obtained from the `value` getter.
 - The `producer` getter returns a [signal producer](SignalProductr) that will send the property’s current value, followed by all changes over time.
 - The `signal` getter returns a [signal](Signal) that will send all changes over time, but not the initial value.
 
 */
scopedExample("Creation") {
    //创建可变的属性
    let mutableProperty = MutableProperty(1)
    
    //为属性的修改绑定监听事件
    mutableProperty.producer.startWithValues {
        print("mutableProperty.producer received \($0)")
    }
    
    mutableProperty.signal.observeValues {
        print("mutableProperty.signal received \($0)")
    }
    
    print("\n取值： \(mutableProperty.value)\n")
    
    //赋值
    mutableProperty.value = 2

    print("\n再次生成另一个Property，类似于装饰器")
    let property = Property(mutableProperty)
    property.signal.observeValues {
        print("property.signal received \($0)")
    }
    mutableProperty.value = 3
    
    
    //再次添加装饰器
    let constant = Property(value: property)
    
    print("\n\n")
}
/*:
 ### Binding
 
 The `<~` operator can be used to bind properties in different ways. Note that in
 all cases, the target has to be a binding target, represented by the [`BindingTargetProtocol`](https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/Sources/UnidirectionalBinding.swift). All mutable property types, represented by the  [`MutablePropertyProtocol`](https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/Sources/Property.swift#L28), are inherently binding targets.
 
 * `property <~ signal` binds a [signal](#signals) to the property, updating the
 property’s value to the latest value sent by the signal.
 * `property <~ producer` starts the given [signal producer](#signal-producers),
 and binds the property’s value to the latest value sent on the started signal.
 * `property <~ otherProperty` binds one property to another, so that the destination
 property’s value is updated whenever the source property is updated.
 */
scopedExample("Binding from SignalProducer") {
    let producer = SignalProducer<Int, NoError> { observer, _ in
        print("New subscription, starting operation")
        observer.send(value: 1)
        observer.send(value: 2)
    }
    
    let property = MutableProperty(0)
    property.producer.startWithValues {
        print("Property received \($0)")
    }
 
    //将producerSend的值与property进行绑定
    property <~ producer
}

scopedExample("Binding from Signal") {
    let (signal, observer) = Signal<Int, NoError>.pipe()
    let property = MutableProperty(0)
    property.producer.startWithValues {
        print("Property received \($0)")
    }
    
    property <~ signal
    
    print("Sending new value on signal: 1")
    observer.send(value: 1)
    
    print("Sending new value on signal: 2")
    observer.send(value: 2)
}

scopedExample("Binding from other Property") {
    let property = MutableProperty(0)
    property.producer.startWithValues {
        print("Property received \($0)")
    }
    
    let otherProperty = MutableProperty(0)
    
    // Notice how property receives another value of 0 as soon as the binding is established
    property <~ otherProperty
    
    print("Setting new value for otherProperty: 1")
    otherProperty.value = 1

    print("Setting new value for otherProperty: 2")
    otherProperty.value = 2
}
/*:
 ### Transformations
 
 Properties provide a number of transformations like `map`, `combineLatest` or `zip` for manipulation similar to [signal](Signal) and [signal producer](SignalProducer)
 */
scopedExample("`map`") {
    let property = MutableProperty(0)
    let mapped = property.map { $0 * 2 }
    mapped.producer.startWithValues {
        print("Mapped property received \($0)")
    }
    
    print("Setting new value for property: 1")
    property.value = 1
    
    print("Setting new value for property: 2")
    property.value = 2
}

scopedExample("`skipRepeats`") {
    let property = MutableProperty(0)
    let skipRepeatsProperty = property.skipRepeats()
    
    property.producer.startWithValues {
        print("Property received \($0)")
    }
    skipRepeatsProperty.producer.startWithValues {
        print("Skip-Repeats property received \($0)")
    }
    
    print("Setting new value for property: 0")
    property.value = 0
    print("Setting new value for property: 1")
    property.value = 1
    print("Setting new value for property: 1")
    property.value = 1
    print("Setting new value for property: 0")
    property.value = 0
}

scopedExample("`uniqueValues`") {
    let property = MutableProperty(0)
    let unique = property.uniqueValues()
    property.producer.startWithValues {
        print("Property received \($0)")
    }
    unique.producer.startWithValues {
        print("Unique values property received \($0)")
    }
    
    print("Setting new value for property: 0")
    property.value = 0
    print("Setting new value for property: 1")
    property.value = 1
    print("Setting new value for property: 1")
    property.value = 1
    print("Setting new value for property: 0")
    property.value = 0

}

scopedExample("`combineLatest`") {
    let propertyA = MutableProperty(0)
    let propertyB = MutableProperty("A")
    let combined = propertyA.combineLatest(with: propertyB)
    combined.producer.startWithValues {
        print("Combined property received \($0)")
    }
    
    print("Setting new value for propertyA: 1")
    propertyA.value = 1
    
    print("Setting new value for propertyB: 'B'")
    propertyB.value = "B"
    
    print("Setting new value for propertyB: 'C'")
    propertyB.value = "C"
    
    print("Setting new value for propertyB: 'D'")
    propertyB.value = "D"
    
    print("Setting new value for propertyA: 2")
    propertyA.value = 2
}

scopedExample("`zip`") {
    let propertyA = MutableProperty(0)
    let propertyB = MutableProperty("A")
    let zipped = propertyA.zip(with: propertyB)
    zipped.producer.startWithValues {
        print("Zipped property received \($0)")
    }
    
    print("Setting new value for propertyA: 1")
    propertyA.value = 1
    
    print("Setting new value for propertyB: 'B'")
    propertyB.value = "B"
    
    // Observe that, in contrast to `combineLatest`, setting a new value for propertyB does not cause a new value for the zipped property until propertyA has a new value as well
    print("Setting new value for propertyB: 'C'")
    propertyB.value = "C"
    
    print("Setting new value for propertyB: 'D'")
    propertyB.value = "D"
    
    print("Setting new value for propertyA: 2")
    propertyA.value = 2
}

scopedExample("`flatten`") {
    let property1 = MutableProperty("one")
    let property2 = MutableProperty("two")
    let property3 = MutableProperty("three")
    
    print("改变成Property1")
    let property = MutableProperty(property1)
    // Try different merge strategies and see how the results change
    property.flatten(.latest).producer.startWithValues {
        print("Flattened property receive \($0)")
    }
    property1.value = "0-1"
    property2.value = "0-2"
    property3.value = "0-3"     //NoDisplay
    
    print("\n改变成Property2")
    property.value = property2
    property1.value = "1-1"     //NoDisplay
    property2.value = "1-2"
    property3.value = "1-3"
    
    print("\n改变成Property3")
    property.value = property3
    property1.value = "2-1"     //NoDisplay
    property2.value = "2-2"     //NoDisplay
    property3.value = "2-3"
    
    print("\n")

}


scopedExample("`Lifetime`") {
    
}

 print("\n")
 print("\n")
