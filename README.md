# HMEventSourceManager-iOS

Rx-enabled event source manager for iOS clients, based on https://github.com/inaka/EventSource.

Simple open a stream with a HMSSERequest object, and subscribe to it to receive events. The stream automatically handles network connectivity, interval-based retries and last event ID retrieval.

```
sseManager.rx.openConnection(request)
    .map(HMSSEvents.eventData)
    .observeOn(MainScheduler.instance)
    .subscribe()
    .disposed(by: disposeBag)
```

Since the SSE manager is stateless (aside from the event IDs in local storage), it can be safely passed around.
