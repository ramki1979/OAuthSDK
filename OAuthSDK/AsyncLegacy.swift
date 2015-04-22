//
// AsyncLegacy.swift
//
// Created by Tobias DM on 15/07/14.
// Modifed by Joseph Lord
// Copyright (c) 2014 Human Friendly Ltd.
//
// OS X 10.9+ and iOS 7.0+
// Only use with ARC
//
// The MIT License (MIT)
// Copyright (c) 2014 Tobias Due Munk
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
import Foundation
// HACK: For Beta 5, 6
prefix func +(v: qos_class_t) -> Int {
    return Int(v.value)
}
private class GCD {
    /* dispatch_get_queue() */
    class final func mainQueue() -> dispatch_queue_t {
        return dispatch_get_main_queue()
        // Could use return dispatch_get_global_queue(+qos_class_main(), 0)
    }
    class final func userInteractiveQueue() -> dispatch_queue_t {
        //return dispatch_get_global_queue(+QOS_CLASS_USER_INTERACTIVE, 0)
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
    }
    class final func userInitiatedQueue() -> dispatch_queue_t {
        //return dispatch_get_global_queue(+QOS_CLASS_USER_INITIATED, 0)
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
    }
    class final func defaultQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    }
    class final func utilityQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    }
    class final func backgroundQueue() -> dispatch_queue_t {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
    }
}
public class Async {
    //The block to be executed does not need to be retained in present code
    //only the dispatch_group is needed in order to cancel it.
    //private let block: dispatch_block_t
    private let dgroup: dispatch_group_t = dispatch_group_create()
    private var isCancelled = false
    private init() {}
}
extension Async { // Static methods
    /* dispatch_async() */
    private class final func async(block: dispatch_block_t, inQueue queue: dispatch_queue_t) -> Async {
        // Wrap block in a struct since dispatch_block_t can't be extended and to give it a group
        let asyncBlock = Async()
        // Add block to queue
        dispatch_group_async(asyncBlock.dgroup, queue, asyncBlock.cancellable(block))
        return asyncBlock
    }
    public class final func main(block: dispatch_block_t) -> Async {
        return Async.async(block, inQueue: GCD.mainQueue())
    }
    public class final func userInteractive(block: dispatch_block_t) -> Async {
        return Async.async(block, inQueue: GCD.userInteractiveQueue())
    }
    public class final func userInitiated(block: dispatch_block_t) -> Async {
        return Async.async(block, inQueue: GCD.userInitiatedQueue())
    }
    public class final func default_(block: dispatch_block_t) -> Async {
        return Async.async(block, inQueue: GCD.defaultQueue())
    }
    public class final func utility(block: dispatch_block_t) -> Async {
        return Async.async(block, inQueue: GCD.utilityQueue())
    }
    public class final func background(block: dispatch_block_t) -> Async {
        return Async.async(block, inQueue: GCD.backgroundQueue())
    }
    public class final func customQueue(queue: dispatch_queue_t, block: dispatch_block_t) -> Async {
        return Async.async(block, inQueue: queue)
    }
    /* dispatch_after() */
    private class final func after(seconds: Double, block: dispatch_block_t, inQueue queue: dispatch_queue_t) -> Async {
        let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
        let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
        return at(time, block: block, inQueue: queue)
    }
    private class final func at(time: dispatch_time_t, block: dispatch_block_t, inQueue queue: dispatch_queue_t) -> Async {
        // See Async.async() for comments
        let asyncBlock = Async()
        dispatch_group_enter(asyncBlock.dgroup)
        dispatch_after(time, queue){
            let cancellableBlock = asyncBlock.cancellable(block)
            cancellableBlock() // Compiler crashed in Beta6 when I just did asyncBlock.cancellable(block)() directly.
            dispatch_group_leave(asyncBlock.dgroup)
        }
        return asyncBlock
    }
    public class final func main(#after: Double, block: dispatch_block_t) -> Async {
        return Async.after(after, block: block, inQueue: GCD.mainQueue())
    }
    public class final func userInteractive(#after: Double, block: dispatch_block_t) -> Async {
        return Async.after(after, block: block, inQueue: GCD.userInteractiveQueue())
    }
    public class final func userInitiated(#after: Double, block: dispatch_block_t) -> Async {
        return Async.after(after, block: block, inQueue: GCD.userInitiatedQueue())
    }
    public class final func default_(#after: Double, block: dispatch_block_t) -> Async {
        return Async.after(after, block: block, inQueue: GCD.defaultQueue())
    }
    public class final func utility(#after: Double, block: dispatch_block_t) -> Async {
        return Async.after(after, block: block, inQueue: GCD.utilityQueue())
    }
    public class final func background(#after: Double, block: dispatch_block_t) -> Async {
        return Async.after(after, block: block, inQueue: GCD.backgroundQueue())
    }
    public class final func customQueue(#after: Double, queue: dispatch_queue_t, block: dispatch_block_t) -> Async {
        return Async.after(after, block: block, inQueue: queue)
    }
}
extension Async { // Regualar methods matching static once
    private final func chain(block chainingBlock: dispatch_block_t, runInQueue queue: dispatch_queue_t) -> Async {
        // See Async.async() for comments
        let asyncBlock = Async()
        dispatch_group_enter(asyncBlock.dgroup)
        dispatch_group_notify(self.dgroup, queue) {
            let cancellableChainingBlock = asyncBlock.cancellable(chainingBlock)
            cancellableChainingBlock()
            dispatch_group_leave(asyncBlock.dgroup)
        }
        return asyncBlock
    }
    private final func cancellable(blockToWrap: dispatch_block_t) -> dispatch_block_t {
        // Retains self in case it is cancelled and then released.
        return {
            if !self.isCancelled {
                blockToWrap()
            }
        }
    }
    public final func main(chainingBlock: dispatch_block_t) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.mainQueue())
    }
    public final func userInteractive(chainingBlock: dispatch_block_t) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.userInteractiveQueue())
    }
    public final func userInitiated(chainingBlock: dispatch_block_t) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.userInitiatedQueue())
    }
    public final func default_(chainingBlock: dispatch_block_t) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.defaultQueue())
    }
    public final func utility(chainingBlock: dispatch_block_t) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.utilityQueue())
    }
    public final func background(chainingBlock: dispatch_block_t) -> Async {
        return chain(block: chainingBlock, runInQueue: GCD.backgroundQueue())
    }
    public final func customQueue(queue: dispatch_queue_t, chainingBlock: dispatch_block_t) -> Async {
        return chain(block: chainingBlock, runInQueue: queue)
    }
    /* dispatch_after() */
    private final func after(seconds: Double, block chainingBlock: dispatch_block_t, runInQueue queue: dispatch_queue_t) -> Async {
        var asyncBlock = Async()
        dispatch_group_notify(self.dgroup, queue)
            {
                dispatch_group_enter(asyncBlock.dgroup)
                let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
                let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
                dispatch_after(time, queue) {
                    let cancellableChainingBlock = self.cancellable(chainingBlock)
                    cancellableChainingBlock()
                    dispatch_group_leave(asyncBlock.dgroup)
                }
        }
        // Wrap block in a struct since dispatch_block_t can't be extended
        return asyncBlock
    }
    public final func main(#after: Double, block: dispatch_block_t) -> Async {
        return self.after(after, block: block, runInQueue: GCD.mainQueue())
    }
    public final func userInteractive(#after: Double, block: dispatch_block_t) -> Async {
        return self.after(after, block: block, runInQueue: GCD.userInteractiveQueue())
    }
    public final func userInitiated(#after: Double, block: dispatch_block_t) -> Async {
        return self.after(after, block: block, runInQueue: GCD.userInitiatedQueue())
    }
    public final func default_(#after: Double, block: dispatch_block_t) -> Async {
        return self.after(after, block: block, runInQueue: GCD.defaultQueue())
    }
    public final func utility(#after: Double, block: dispatch_block_t) -> Async {
        return self.after(after, block: block, runInQueue: GCD.utilityQueue())
    }
    public final func background(#after: Double, block: dispatch_block_t) -> Async {
        return self.after(after, block: block, runInQueue: GCD.backgroundQueue())
    }
    public final func customQueue(#after: Double, queue: dispatch_queue_t, block: dispatch_block_t) -> Async {
        return self.after(after, block: block, runInQueue: queue)
    }
    /* cancel */
    public final func cancel() {
        // I don't think that syncronisation is necessary. Any combination of multiple access
        // should result in some boolean value and the cancel will only cancel
        // if the execution has not yet started.
        isCancelled = true
    }
    /* wait */
    /// If optional parameter forSeconds is not provided, use DISPATCH_TIME_FOREVER
    public final func wait(seconds: Double = 0.0) {
        if seconds != 0.0 {
            let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
            let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
            dispatch_group_wait(dgroup, time)
        } else {
            dispatch_group_wait(dgroup, DISPATCH_TIME_FOREVER)
        }
    }
}
// Convenience
// extension qos_class_t {
//
// // Calculated property
// var description: String {
// get {
// switch +self {
// case +qos_class_main(): return "Main"
// case +QOS_CLASS_USER_INTERACTIVE: return "User Interactive"
// case +QOS_CLASS_USER_INITIATED: return "User Initiated"
// case +QOS_CLASS_DEFAULT: return "Default"
// case +QOS_CLASS_UTILITY: return "Utility"
// case +QOS_CLASS_BACKGROUND: return "Background"
// case +QOS_CLASS_UNSPECIFIED: return "Unspecified"
// default: return "Unknown"
// }
// }
// }
//}

// Async syntactic sugar
/*
Async.background {
    println("A: This is run on the background")
    }.main {
        println("B: This is run on the , after the previous block")
}
*/
// Regular GCD
/*
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
println("REGULAR GCD: This is run on the background queue")
dispatch_async(dispatch_get_main_queue(), 0), {
println("REGULAR GCD: This is run on the main queue")
})
})
*/
/*
// Chaining with Async
var id = 0
Async.main {
println("This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)) count: \(++id) (expected 1) ")
// Prints: "This is run on the Main (expected Main) count: 1 (expected 1)"
}.userInteractive {
println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_USER_INTERACTIVE.description)) count: \(++id) (expected 2) ")
// Prints: "This is run on the Main (expected Main) count: 2 (expected 2)"
}.userInitiated {
println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_USER_INITIATED.description)) count: \(++id) (expected 3) ")
// Prints: "This is run on the User Initiated (expected User Initiated) count: 3 (expected 3)"
}.utility {
println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_UTILITY.description)) count: \(++id) (expected 4) ")
// Prints: "This is run on the Utility (expected Utility) count: 4 (expected 4)"
}.background {
println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description)) count: \(++id) (expected 5) ")
// Prints: "This is run on the User Interactive (expected User Interactive) count: 5 (expected 5)"
}
*/
/*
// Keep reference for block for later chaining
let backgroundBlock = Async.background {
println("This is run on the \(qos_class_self().description) (expected \(QOS_CLASS_BACKGROUND.description))")
}
// Run other code here...
backgroundBlock.main {
println("This is run on the \(qos_class_self().description) (expected \(qos_class_main().description)), after the previous block")
}
*/
/*
// Custom queues
let customQueue = dispatch_queue_create("CustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
let otherCustomQueue = dispatch_queue_create("OtherCustomQueueLabel", DISPATCH_QUEUE_CONCURRENT)
Async.customQueue(customQueue) {
println("Custom queue")
}.customQueue(otherCustomQueue) {
println("Other custom queue")
}
*/
/*
// After
let seconds = 0.5
Async.main(after: seconds) {
println("Is called after 0.5 seconds")
}.background(after: 0.4) {
println("At least 0.4 seconds after previous block, and 0.9 after Async code is called")
}
*/
/*
// Cancel blocks not yet dispatched
let block1 = Async.background {
// Heavy work
for i in 0...1000 {
println("A \(i)")
}
}
let block2 = block1.background {
println("B – shouldn't be reached, since cancelled")
}
Async.main {
block1.cancel() // First block is _not_ cancelled
block2.cancel() // Second block _is_ cancelled
}
*/
