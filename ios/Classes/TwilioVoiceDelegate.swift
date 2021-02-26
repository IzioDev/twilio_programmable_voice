import Foundation
import TwilioVoice
import Flutter
import CallKit

class TwilioVoiceDelegate: NSObject, NotificationDelegate, CallDelegate {
	var callInvite:CallInvite?
	var call:Call?
	var callOutgoing: Bool = false
	var userInitiatedDisconnect: Bool = false
	// TODO find a better name
	var callCompletionCallback: ((Bool)->Swift.Void?)? = nil
	private var callStatusEventChannelWrapper: CallStatusEventChannelWrapper;

	init(eventChannel: FlutterEventChannel) {
		self.callStatusEventChannelWrapper = CallStatusEventChannelWrapper(eventChannel: eventChannel);
	}

	public func callInviteReceived(callInvite: CallInvite) {
		print("callInviteReceived called")
		var from: String = self.callInvite?.from ?? "Unknow Caller"
		from = from.replacingOccurrences(of: "client:", with: "")
			
		SwiftTwilioProgrammableVoicePlugin.instance!.callKitDelegate.reportIncomingCall(from: from, uuid: callInvite.uuid)
		self.callInvite = callInvite
		
		self.callStatusEventChannelWrapper.sendCallInvite(callInvite: getCallInvitePayload(callInvite: callInvite));
	}
	
	public func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
		print("cancelledCallInviteReceived called")
			if (self.callInvite == nil) {
					return
			}
			
			if let ci = self.callInvite {
				SwiftTwilioProgrammableVoicePlugin.instance!.callKitDelegate.performEndCallAction(uuid: ci.uuid)
			}
		
		self.callStatusEventChannelWrapper.sendCancelledCallInvite(cancelledCallInvite: getCancelledCallInvitePayload(cancelledCallInvite: cancelledCallInvite));
	}
	
	public func callDidStartRinging(call: Call) {
		print("callDidStartRinging called")
		callStatusEventChannelWrapper.sendCallRinging(call: getCallPayload(call: call, type: TwilioProgrammableVoice.CALL_RINGING));
	}
	
	public func callDidConnect(call: Call) {
		print("callDidConnect called")

		if let callKitCompletionCallback = self.callCompletionCallback {
					callKitCompletionCallback(true)
			}
			
		SwiftTwilioProgrammableVoicePlugin.instance!.toggleAudioRoute(toSpeaker: false)
		callStatusEventChannelWrapper.sendCallConnect(call: getCallPayload(call: call, type: TwilioProgrammableVoice.CALL_CONNECTED));
	}
	
	public func call(call: Call, isReconnectingWithError error: Error) {
		print("isReconnectingWithError called");
		
		callStatusEventChannelWrapper.sendCallReconnecting(call: getCallPayload(call: call, type: TwilioProgrammableVoice.CALL_RECONNECTING));
	}
	
	public func callDidReconnect(call: Call) {
		print("isReconnectingWithError callDidReconnect");

		callStatusEventChannelWrapper.sendCallReconnect(call: getCallPayload(call: call, type: TwilioProgrammableVoice.CALL_RECONNECTED));
	}
	
	public func callDidFailToConnect(call: Call, error: Error) {
		print("isReconnectingWithError callDidFailToConnect");
			if(error.localizedDescription.contains("Access Token expired")){
				// TODO
				print("accessToken expired")
			}
		if let completion = self.callCompletionCallback {
					completion(false)
			}
			
			
		SwiftTwilioProgrammableVoicePlugin.instance!.callKitDelegate.callKitProvider.reportCall(with: call.uuid!, endedAt: Date(), reason: CXCallEndedReason.failed)
		self.callDisconnected()
		// No callStatusEventWrapper method bind to this cb
	}
	
	public func callDidDisconnect(call: Call, error: Error?) {
		print("isReconnectingWithError callDidDisconnect");

		if self.userInitiatedDisconnect {
					var reason = CXCallEndedReason.remoteEnded
					if error != nil {
							reason = .failed
					}
					
			SwiftTwilioProgrammableVoicePlugin.instance!.callKitDelegate.callKitProvider.reportCall(with: call.uuid!, endedAt: Date(), reason: reason)
			}
			
		self.callDisconnected()

		callStatusEventChannelWrapper.sendCallDisconnect(call: getCallPayload(call: call, type: TwilioProgrammableVoice.CALL_DISCONNECTED));
	}
	
	private func callDisconnected() {
		print("isReconnectingWithError callDisconnected");

			if (self.call != nil) {
				self.call = nil
			}
		if (self.callInvite != nil) {
			self.callInvite = nil
		}
			
			self.callOutgoing = false
			self.userInitiatedDisconnect = false
	}
	
	private func getCallInvitePayload(callInvite: CallInvite) -> Dictionary<String, String> {
		return [
			"type": TwilioProgrammableVoice.CALL_INVITE,
			"from": callInvite.from ?? TwilioProgrammableVoice.UNKNOW_FROM,
			"to": callInvite.to,
			"callSid": callInvite.callSid
		]
	}

	private func getCancelledCallInvitePayload(cancelledCallInvite: CancelledCallInvite) -> Dictionary<String, String> {
		return [
			"type": TwilioProgrammableVoice.CANCELLED_CALL_INVITE,
			"from": cancelledCallInvite.from ?? TwilioProgrammableVoice.UNKNOW_FROM,
			"to": cancelledCallInvite.to,
			"callSid": cancelledCallInvite.callSid
		]
	}
	
	private func getCallPayload(call: Call , type: String) -> Dictionary<String, Any> {
		return [
			"type": type,
			"from": call.from ?? TwilioProgrammableVoice.UNKNOW_FROM,
			"to": call.to ?? TwilioProgrammableVoice.UNKNOW_TO,
			"sid": call.sid,
			"state": call.state.rawValue,
			"isMuted": call.isMuted,
			"isOnHold": call.isOnHold
		]
	}
}
