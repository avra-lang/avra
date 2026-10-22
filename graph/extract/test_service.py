"""Witnesses for the service's treatment of departed clients."""
import socket
import threading
import unittest

import cascade


class Departure(unittest.TestCase):
    def test_a_connected_client_is_not_gone(self):
        a, b = socket.socketpair()
        self.assertFalse(cascade.gone(a))
        b.sendall(b"more")
        self.assertFalse(cascade.gone(a))

    def test_a_closed_client_is_gone(self):
        a, b = socket.socketpair()
        b.close()
        self.assertTrue(cascade.gone(a))

    def test_a_streamed_answer_stops_once_cancelled(self):
        cancelled, computed = threading.Event(), []

        def lines():
            for i in range(5):
                computed.append(i)
                yield i

        seen = []
        for line in cascade.until_cancelled(lines(), cancelled):
            seen.append(line)
            if line == 1:
                cancelled.set()
        self.assertEqual(seen, [0, 1])
        self.assertEqual(computed, [0, 1])


if __name__ == "__main__":
    unittest.main()
