// A SLOW LINK in front of a local server, the way a phone on a cellular network meets it: every
// connection pays a handshake round trip before it may send, each direction is delayed half the
// round trip, and the downlink and the uplink are each ONE pipe at a fixed rate that every
// connection queues on. It counts the octets it carries down, so what a page costs on the wire is
// read off the link itself, whatever engine asked.
//
//   const link = await slowLink({ target: 8787, rtt: 120, downMbit: 4, upMbit: 4 });
//   link.port; link.carried(); link.reset(); link.close();
//
// Run as a script it stands until killed: node slow_link.mjs <listen-port> <target-port> [rtt] [down] [up]
import net from "node:net";
import { pathToFileURL } from "node:url";

export function slowLink({ listen = 0, target, rtt = 120, downMbit = 4, upMbit = 4 }) {
  const half = rtt / 2;
  const pipe = (mbit) => ({ freeAt: 0, bps: (mbit * 1e6) / 8 });
  const down = pipe(downMbit), up = pipe(upMbit);
  let carried = 0;
  const open = new Set();
  // A piece entering `link` now leaves once the queue ahead of it is serialized, and arrives half
  // a round trip later; a socket's pieces arrive in the order sent.
  const carry = (link, from, to, counted) => {
    let lastAt = 0;
    from.on("data", (piece) => {
      const now = performance.now();
      link.freeAt = Math.max(now, link.freeAt) + (piece.length / link.bps) * 1000;
      const at = Math.max(link.freeAt + half, lastAt);
      lastAt = at;
      if (counted) carried += piece.length;
      setTimeout(() => to.write(piece), at - now);
    });
    from.on("end", () => setTimeout(() => to.end(), Math.max(0, lastAt - performance.now()) + 1));
  };
  const server = net.createServer((client) => {
    client.pause();
    const far = net.connect(target, "127.0.0.1");
    open.add(client).add(far);
    for (const s of [client, far]) s.on("close", () => open.delete(s));
    far.on("error", () => client.destroy());
    client.on("error", () => far.destroy());
    setTimeout(() => {
      carry(up, client, far, false);
      carry(down, far, client, true);
      client.resume();
    }, rtt);
  });
  return new Promise((ready) => server.listen(listen, "127.0.0.1", () => ready({
    port: server.address().port,
    carried: () => carried,
    reset: () => { carried = 0; },
    close: () => { for (const s of open) s.destroy(); server.close(); },
  })));
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  const [listen, target, rtt, down, up] = process.argv.slice(2).map(Number);
  const link = await slowLink({ listen, target, rtt: rtt || 120, downMbit: down || 4, upMbit: up || 4 });
  console.log(`slow link :${link.port} -> :${target}`);
}
