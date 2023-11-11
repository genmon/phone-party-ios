import type * as Party from "partykit/server";

// server.ts
// https://phone-party.genmon.partykit.dev
export default class PhonePartyServer implements Party.Server {
  constructor(public party: Party.Party) {}

  onMessage(
    message: string,
    websocket: Party.Connection
  ): void | Promise<void> {
    if (message === "ping") {
      websocket.send("pong");
      return;
    }

    this.party.broadcast(message, [websocket.id]);
  }
}

PhonePartyServer satisfies Party.Worker;
