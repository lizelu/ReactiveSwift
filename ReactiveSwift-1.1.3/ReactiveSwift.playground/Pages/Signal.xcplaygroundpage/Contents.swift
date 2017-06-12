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
## Signal

A **signal**, represented by the [`Signal`](https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/ReactiveSwift/Signal.swift) type, is any series of [`Event`](https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/ReactiveSwift/Event.swift) values
over time that can be observed.

Signals are generally used to represent event streams that are already “in progress”,
like notifications, user input, etc. As work is performed or data is received,
events are _sent_ on the signal, which pushes them out to any observers.
All observers see the events at the same time.

Users must observe a signal in order to access its events.
Observing a signal does not trigger any side effects. In other words,
signals are entirely producer-driven and push-based, and consumers (observers)
cannot have any effect on their lifetime. While observing a signal, the user
can only evaluate the events in the same order as they are sent on the signal. There
is no random access to values of a signal.

Signals can be manipulated by applying [primitives](https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/Documentation/BasicOperators.md) to them.
Typical primitives to manipulate a single signal like `filter`, `map` and
`reduce` are available, as well as primitives to manipulate multiple signals
at once (`zip`). Primitives operate only on the `value` events of a signal.

The lifetime of a signal consists of any number of `value` events, followed by
one terminating event, which may be any one of `failed`, `completed`, or
`interrupted` (but not a combination).
Terminating events are not included in the signal’s values—they must be
handled specially.
*/

/*:
### `Subscription`
A Signal represents and event stream that is already "in progress", sometimes also called "hot". This means, that a subscriber may miss events that have been sent before the subscription.
Furthermore, the subscription to a signal does not trigger any side effects
*/
scopedExample("Subscription") {

	let (signal, sendMessage) = Signal<Int, NoError>.pipe()

	let subscriber1 = Observer<Int, NoError>(value: { print("Subscriber 1 received \($0)") } )
	let subscriber2 = Observer<Int, NoError>(value: { print("Subscriber 2 received \($0)") } )

	let actionDisposable1 = signal.observe(subscriber1)
	sendMessage.send(value: 10)

    print("\n")
	signal.observe(subscriber2)
	sendMessage.send(value: 20)
    
    print("\n")
    print(actionDisposable1?.isDisposed)
    actionDisposable1?.dispose()        //取消subscriber1对Signal信号量的观察
    
    print(actionDisposable1?.isDisposed)
    sendMessage.send(value: 30)
    
    
}

/*:
### `empty`
A Signal that completes immediately without emitting any value.
*/
scopedExample("`empty`") {
    
	let emptySignal = Signal<Int, NoError>.empty

	let observer = Observer<Int, NoError>(
		value: { _ in print("value not called") },
		failed: { _ in print("error not called") },
		completed: { print("completed not called") },
		
		//每次关联Observer时都会执行该闭包
		interrupted: { print("interrupted called") }
	)

	emptySignal.observe(observer)
    emptySignal.observe(observer)
    
}

/*:
### `never`
A Signal that never sends any events to its observers.
*/
scopedExample("`never`") {
	let neverSignal = Signal<Int, NoError>.never

	let observer = Observer<Int, NoError>(
		value: { _ in print("value not called") },
		failed: { _ in print("error not called") },
		completed: { print("completed not called") },
		interrupted: { print("interrupted not called") }
	)

	neverSignal.observe(observer)
}

/*:
## `Operators`
### `uniqueValues`
Forwards only those values from `self` that are unique across the set of
all values that have been seen.

Note: This causes the values to be retained to check for uniqueness. Providing
a function that returns a unique value for each sent value can help you reduce
the memory footprint.
*/
scopedExample("`uniqueValues`") {
	let (signal, sender) = Signal<Int, NoError>.pipe()
    let uniqueSignal = signal.uniqueValues()
    
	let subscriber = Observer<Int, NoError>(value: { print("Subscriber received \($0)") } )
	uniqueSignal.observe(subscriber)
    
	sender.send(value: 1)
	sender.send(value: 2)
	sender.send(value: 3)
    sender.send(value: 2)   //not print
    sender.send(value: 2)   //not print
	sender.send(value: 4)
	sender.send(value: 3)   //not print
	sender.send(value: 3)   //not print
	sender.send(value: 5)
}

/*:
### `map`
Maps each value in the signal to a new value.
*/
scopedExample("`map`") {
    
	let (signal, observer) = Signal<Int, NoError>.pipe()
    
    let mappedSignal: Signal<String, NoError> = signal.map({ (value) -> String in
        return "映射规则:\(value * 3)"
    })
    
    let subscriber = Observer<String, NoError>(value: { print("Subscriber received \($0)") } )
	mappedSignal.observe(subscriber)
    
	observer.send(value: 10)
    
}

/*:
### `mapError`
Maps errors in the signal to a new error.
*/
scopedExample("`mapError`") {
	let (signal, sender) = Signal<Int, NSError>.pipe()
    
	let subscriber = Observer<Int, NSError>(failed: { print("Subscriber received error: \($0)") } )
	let mappedErrorSignal = signal.mapError { (error:NSError) -> NSError in
		let userInfo = [NSLocalizedDescriptionKey: "🔥"]
		let code = error.code + 10000
		let mappedError = NSError(domain: "com.reactivecocoa.errordomain", code: code, userInfo: userInfo)
		return mappedError
	}

	mappedErrorSignal.observe(subscriber)
	
	sender.send(error: NSError(domain: "com.reactivecocoa.errordomain", code: 4815, userInfo: nil))
}

/*:
### `filter`
Preserves only the values of the signal that pass the given predicate.
*/
scopedExample("`filter`") {
    
	let (signal, observer) = Signal<Int, NoError>.pipe()
    
    let filteredSignal: Signal<Int, NoError> = signal.filter { $0 > 12 ? true : false }
    
    let subscriber = Observer<Int, NoError>(value: { print("Subscriber received \($0)") } )
	filteredSignal.observe(subscriber)
    
	observer.send(value: 10)
	observer.send(value: 11)
	observer.send(value: 12)
	observer.send(value: 13)
	observer.send(value: 14)
    
}

/*:
### `skipNil`
Unwraps non-`nil` values and forwards them on the returned signal, `nil`
values are dropped.
*/
scopedExample("`skipNil`") {
	let (signal, observer) = Signal<Int?, NoError>.pipe()
	// note that the signal is of type `Int?` and observer is of type `Int`, given we're unwrapping
	// non-`nil` values
	let subscriber = Observer<Int, NoError>(value: { print("Subscriber received \($0)") } )
	let skipNilSignal = signal.skipNil()

	skipNilSignal.observe(subscriber)
	observer.send(value: 1)
	observer.send(value: nil)
	observer.send(value: 3)
}

/*:
### `take(first:)`
Returns a signal that will yield the first `count` values from `self`
*/
scopedExample("`take(first:)`") {
    
	let (signal, observer) = Signal<Int, NoError>.pipe()
    
    let takeSignal = signal.take(first: 3)
    
	let subscriber = Observer<Int, NoError>(value: { print("Subscriber received \($0)") } )
	takeSignal.observe(subscriber)
    
    
	observer.send(value: 1)
	observer.send(value: 2)
	observer.send(value: 3)
	observer.send(value: 4)
    
}

/*:
### `collect`
Returns a signal that will yield an array of values when `self` completes.
- Note: When `self` completes without collecting any value, it will send
an empty array of values.
*/
scopedExample("`collect`") {
    
	let (signal, observer) = Signal<Int, NoError>.pipe()
    
	let collectSignal = signal.collect()
    
    let subscriber = Observer<[Int], NoError>(value: { print("Subscriber received \($0)") } )
	collectSignal.observe(subscriber)
    
	observer.send(value: 1)
	observer.send(value: 2)
	observer.send(value: 3)
	observer.send(value: 4)
    
	observer.sendCompleted()
    
}

/*:
 ### `collect`
 Returns a signal that will yield an array of values when `self` completes.
 - Note: When `self` completes without collecting any value, it will send
 an empty array of values.
 */
scopedExample("`collect_count`") {
    
    let (signal, observer) = Signal<Int, NoError>.pipe()
    
    let collectSignal = signal.collect(count: 3)
    
    let subscriber = Observer<[Int], NoError>(value: { print("Subscriber received \($0)") } )
    collectSignal.observe(subscriber)
    
    observer.send(value: 1)
    observer.send(value: 2)
    observer.send(value: 3)
    observer.send(value: 4)
    observer.send(value: 5)
    
    observer.sendCompleted()
    
}

scopedExample("`collect_predicate1`") {
    
    let (signal, observer) = Signal<Int, NoError>.pipe()
    
    let collectSignal = signal.collect { values in values.reduce(0, +) == 8 }
    
    collectSignal.observeValues { print($0) }
    
    observer.send(value: 1)
    observer.send(value: 3)
    observer.send(value: 5)
    observer.send(value: 7)
    observer.send(value: 1)
    observer.send(value: 5)
    observer.send(value: 6)
    
    observer.sendCompleted()

}

scopedExample("`collect_predicate2`") {
    
    let (signal, observer) = Signal<Int, NoError>.pipe()

    let collectSignal: Signal<[Int], NoError> = signal.collect { values, value in value == 7 }
    
    collectSignal.observeValues { print($0) }

    observer.send(value: 1)
    observer.send(value: 1)
    observer.send(value: 7)
    observer.send(value: 7)
    observer.send(value: 5)
    observer.send(value: 6)
    
    observer.sendCompleted()
    
}



scopedExample("`observer_action`") {

    let (signal, observer) = Signal<Int, NSError>.pipe()
    
    //observe(action)
    signal.observe({ (event) in
        if case let Event.value(value) = event {
            print("value: \(value)")
        }
        
        if case let Event.failed(error) = event {
            print("error: \(error)")
        }
        
        if case Event.completed = event {
            print("completed")
        }
        
        if case Event.interrupted = event {
            print("interrupted")
        }
    })
    
    //observeResult(result)
    signal.observeResult({ (result) in
        if case let Result.success(value) = result {
            print("success: \(value)")
        }
        
        if case let Result.failure(error) = result {
            print("error: \(error)")
        }
    })
    
    //observeCompleted(completed)
    signal.observeCompleted {
        print("completed事件")
    }
    
    //observeFailed(error)
    signal.observeFailed({ (error) in
        print("Failed事件\(error)")
    })
    
    //observeInterrupted(interrupted)
    signal.observeInterrupted {
        print("interrupted事件")
    }
    
    observer.send(value: 1000)
    observer.send(error: NSError(domain: "error.test", code: 0000, userInfo: nil))
    observer.sendCompleted()
    observer.sendInterrupted()
    
    
    print("\n\n\n")

}

