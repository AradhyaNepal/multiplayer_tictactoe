//Its technical name might not be Handshake.
///It ensure that whether the another device have also received the request.
enum Handshake {
  ///Send the request to other and wait them to send back handshakeSuccess.
  ///The player who performs the action.
  sendToOther,

  ///Player receives the request performed by some another user.
  ///It performs the action on its own, then sends the another user success
  otherPersonReceived,

  ///After a user performs an action, it send another user request to perform the same action
  ///once the another user perform that action it sends back confirmation of handshakeSuccess.
  ///If the user don't get handshakeSuccess after long wait it send to the another user request again.
  ///The receiving user must make sure that same request could be send twice due to request lost on handshakeSuccess validation
  ///because the sender don't know whether request is lost before otherPersonReceived, or after otherPersonReceived but before handshakeSuccess received
  handshakeSuccess,
}

enum RestartGameRequest {
  send,
  received,
  bothConfirmed,
  rejected,
}