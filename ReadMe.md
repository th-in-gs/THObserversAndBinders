# THObserversAndBinders

© 2012 James Montgomerie  
jamie@montgomerie.net, [http://www.blog.montgomerie.net/](http://www.blog.montgomerie.net/)  
jamie@th.ingsmadeoutofotherthin.gs, [http://th.ingsmadeoutofotherthin.gs/](http://th.ingsmadeoutofotherthin.gs/)  


## What it is

- Easy, lightweight, object-based key-value observing (KVO).
- Very lightweight object-based key-value binding (KVB).
- For iOS and Mac OS X, with ARC.
- Feels comfortable.
- Here are some [examples](#examples).


## Why

To me, Cocoa KVO has three problems (well, besides the conceptual arguments about whether KVO's good idea in the first place):

- It makes your code messy. `-[(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context]` methods with huge flowing if statements in them. Need I say more?
- Lifetime management is hard to think about and therefore fragile.
- Encapsulating the above, it just doesn't 'feel comfortable'

Now, it seems like every Cocoa programmer out there has their own KVO and KVB solution, and I've tried a few of them. There are many to enumerate here. Many are quite nice. Many of them are quite nice, but I couldn't find any that passed the 'feels comfortable' test with flying colours (and, though I know it's irrational, but KVO just seems like it should be cleaner than a messily prefixed category on `NSObject`, `objc_setAssociatedObject()` or method swizzling).


## How it works

- Observers are represented by simple, lightweight `THObserver` objects that are constructed with an object to observe, a keypath to observe on the object, and a block or target-action pair to call when the observed value changes. 
- Optionally, you can also pass arbitrary Cocoa KVO options. 
- The block or action can, again optionally, be passed the old and new value, or a whole Cocoa KVO change dictionary.
- To keep code clean, there's also an option to use "value action" target-action callbacks that don't get passed the observed object and keypath like regular actions, but instead just get passed the new, or old and new, values.
- The observation's lifetime is entirely managed by the `THObserver` object. Keep it around, the observation is alive. Release it, and the observations stop. You can also optionally stop them manually by calling `-stopObserving`.
- The observed object and the target are weakly referenced, so nothing's going to blow up if you release things in the wrong order, or if your observer is being held in an autorelease pool somewhere (this isn't something I don't think should be necessary, but it's nice to have).

I like this API. It's one simple call to set up an block that fires when a property changes. Want to observe a whole bunch of things? Just set up a bunch of THObservers, store them in an array, then when it comes time to stop observing, release the array (maybe calling `-stopObserving` on the observers in the array first if there might be a reference to them lying around elsewhere, like in an autorelease pool).


## Results

- Code is no longer messy. Observer functionality is easy to set up and tear down, and the observation itself is neatly encapsulated in clean blocks or action methods.
- Observation lifetime management is really easy. The observation is just an object, and managing the lifetime of objects is intuitive.
- It feels nice and looks clean in use. No messy prefixed methods etc.
--- Okay, I'll admit there is a little bit of monkeying with analysis of selectors and casting of blocks in `THObserver`'s implementation, but it's nicely encapsulated, and the code is reasonably straightforward.

On top of that, it seemed like it would be pretty easy to write a straightforward binding mechanism with a similar API, so I did. The THBinder object represents a binding, and is easy to construct and manage (see the [binding](#binding) examples). You can optionally supply an NSValueTransformer or a block to run the value through. Lifetime is managed simiarly to THObserver - it'll stop binding when it's released, and theres also a '-stopBinding' method.


## How to use it

I've packaged this as a static library, you should be able to use it as detailed [in this block post](http://www.blog.montgomerie.net/easy-xcode-static-library-subprojects-and-submodules).


## Examples

### Block-based observation:

#### Simple observation block:

```ObjC

NSString *keyPath = @"propertyToObserve"
THObserver *observer = [THObserver observerForObject:object keyPath:@"propertyToObserve" block:^{
    NSLog(@"propertyToObserve changed, is now %@", object.propertyToObserve);
}];

```


#### Observation block with the old and new value passed in:

```ObjC

THObserver *observer = [THObserver observerForObject:observerForObject:object keyPath:@"propertyToObserve" oldAndNewBlock:^(id oldValue, id newValue) {
    NSLog(@"propertyToObserve changed, was %@, is now %@", oldValue, newValue);
}];

```


#### Observation block with custom observation options and a Cocoa change dictionary:
    
```ObjC

THObserver *observer = [THObserver observerForObject:object
                                             keyPath:@"propertyToObserve"
                                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                         changeBlock:^(NSDictionary *change) {
                                             NSLog(@"propertyToObserve is %@", change[NSKeyValueChangeNewKey]);
                                         }];

```


### Target-action Based Observation

Any of the calls below could be made with or without an 'options' argument.

#### Simple target-action:
    
```ObjC

THObserver *observer = [THObserver observerForObject:object
                                             keyPath:@"propertyToObserve"
                                              target:self
                                              action:@selector(targetActionCallback)];

```

#### Target-action, gets passed observed object
    
```ObjC

THObserver *observer = [THObserver observerForObject:object
                                             keyPath:@"propertyToObserve"
                                              target:self
                                              action:@selector(targetActionCallbackForObject:)];

```

#### Target-action, gets passed observed object and keypath
    
```ObjC

THObserver *observer = [THObserver observerForObject:object
                                             keyPath:@"propertyToObserve"
                                              target:self
                                              action:@selector(targetActionCallbackForObject:keyPath:)];

```

#### Target-action, gets passed observed object, keypath, old and new values
    
```ObjC

THObserver *observer = [THObserver observerForObject:object
                                             keyPath:@"propertyToObserve"
                                              target:self
                                              action:@selector(targetActionCallbackForObject:keyPath:oldValue:newValue:)];

```

#### Target-action with options and change dictionary:

```ObjC

THObserver *observer = [THObserver observerForObject:object
                                             keyPath:@"propertyToObserve"
                                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                              target:self
                                              action:@selector(targetActionCallbackForObject:keyPath:oldValue:change:)];

```


#### "Value action" target-action callback for new value only:

This supplies only the new value - useful in keeping code clean if you don't need the object and keypath passed in.

```ObjC

THObserver *observer = [THObserver observerForObject:object
                                             keyPath:@"propertyToObserve"
                                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                              target:self
                                         valueAction:@selector(targetActionCallbackForNewValue:)];

```

This supplies only the old and new values. Again, useful in keeping code clean (see above).

#### "Value action" target-action callback for old and new value only:

```ObjC

THObserver *observer = [THObserver observerForObject:object
                                             keyPath:@"propertyToObserve"
                                             options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                              target:self
                                         valueAction:@selector(targetActionCallbackForOldValue:newValue:)];

```


### Binding

#### Simple binding:

```ObjC

THBinder *binder = [THBinder binderFromObject:fromObject keyPath:@"fromKey"
                                     toObject:toObject keyPath:@"toKey"];

```

#### Binding with a Transformer Block:

```ObjC

THBinder *binder = [THBinder binderFromObject:fromObject keyPath:@"fromKey"
                                     toObject:toObject keyPath:@"toKey"
                          transformationBlock:^id(id value) {
                              return @([value integerValue] + 5);

                          }];
```

#### Binding with NSValueTransformer:

```ObjC

THBinder *binder = [THBinder binderFromObject:fromObject keyPath:@"fromKey"
                                     toObject:toObject keyPath:@"toKey"
                             valueTransformer:[[MyAddFiveTransformer alloc] init]];

```
