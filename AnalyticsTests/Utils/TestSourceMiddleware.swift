//
//  TestSourceMiddleware.swift
//  AnalyticsTests
//
//  Created by Brandon Sneed on 1/27/20.
//  Copyright © 2020 Segment. All rights reserved.
//

import Foundation
import Analytics

class PassthroughSourceMiddleware: NSObject, SourceMiddleware {
    var lastContext: Context?
  
    func event(_ payload: Payload, context: Context) -> Payload? {
        lastContext = context
        return payload
    }
}

class TestSourceMiddleware: NSObject, SourceMiddleware {
    var lastContext: Context?
    var swallowEvent = false

    func event(_ payload: Payload, context: Context) -> Payload? {
        lastContext = context
        if swallowEvent {
           return nil
        }
        return payload
    }
}

class CustomizeTrackSourceMiddleware: NSObject, SourceMiddleware {
    var lastContext: Context?
    var swallowEvent = false

    func event(_ payload: Payload, context: Context) -> Payload? {
        if swallowEvent {
            return nil
        }
        
        if context.eventType == .track {
            guard let track = context.payload as? TrackPayload else {
                return payload
            }
            
            var newProps = track.properties ?? [:]
            let newEvent = "[New] \(track.event)"
            newProps["customAttribute"] = "Hello"
            newProps["nullTest"] = NSNull()
            let newPayload = TrackPayload(
              event: newEvent,
              properties: newProps,
              context: track.context,
              integrations: track.integrations
            )
            return newPayload
        }
        
        return payload
    }
}

class TypedSourceMiddleware: NSObject, SourceMiddleware {
    func trackEvent(_ payload: TrackPayload, context: Context) -> Payload? {
        var newProps = payload.properties ?? [:]
        newProps["trackCalled"] = true
        let newPayload = TrackPayload(event: payload.event,
                                      properties: newProps,
                                      context: payload.context,
                                      integrations: payload.integrations)
        return newPayload
    }
  
    func identifyEvent(_ payload: IdentifyPayload, context: Context) -> Payload? {
        var newTraits = payload.traits ?? [:]
        newTraits["identifyCalled"] = true
        let newPayload = IdentifyPayload(userId: payload.userId ?? "dude",
                                         anonymousId: payload.anonymousId,
                                         traits: newTraits,
                                         context: payload.context,
                                         integrations: payload.integrations)
        return newPayload
    }

    func aliasEvent(_ payload: AliasPayload, context: Context) -> Payload? {
        let newPayload = AliasPayload(newId: "transformedId",
                                      context: payload.context,
                                      integrations: payload.integrations)
        return newPayload
    }

    func groupEvent(_ payload: GroupPayload, context: Context) -> Payload? {
        var newTraits = payload.traits ?? [:]
        newTraits["groupCalled"] = true
        let newPayload = GroupPayload(groupId: payload.groupId,
                                      traits: newTraits,
                                      context: payload.context,
                                      integrations: payload.integrations)
        return newPayload
    }

    func screenEvent(_ payload: ScreenPayload, context: Context) -> Payload? {
        var newProps = payload.properties ?? [:]
        newProps["screenCalled"] = true
        let newPayload = ScreenPayload(name: payload.name,
                                       properties: newProps,
                                       context: payload.context,
                                       integrations: payload.integrations)
        return newPayload
    }

    func applicationLifecycleEvent(_ payload: ApplicationLifecyclePayload, context: Context) -> Payload? {
        var newContext = payload.context
        newContext["appLifeCalled"] = true
        let newPayload = ApplicationLifecyclePayload(context: newContext, integrations: payload.integrations)
        return newPayload
    }

    func openURLEvent(_ payload: OpenURLPayload, context: Context) -> Payload? {
        var newContext = payload.context
        newContext["openUrlCalled"] = true
        let newPayload = OpenURLPayload(context: newContext, integrations: payload.integrations)
        return newPayload
    }

    func remoteNotificationEvent(_ payload: RemoteNotificationPayload, context: Context) -> Payload? {
        var newContext = payload.context
        newContext["remoteCalled"] = true
        let newPayload = RemoteNotificationPayload(context: payload.context, integrations: payload.integrations)
        return newPayload
    }

}

