#!/usr/bin/env python3
import os
import socket

SOCK_PATH = "/path/to/socket.sock"

def server():
    # Remove old socket file if it exists
    try:
        os.unlink(SOCKET_PATH)
    except FileNotFoundError:
        pass

    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(SOCK_PATH)
    srv.listen(1)

    print(f"Listening on {SOCKET_PAHT} ...")
    conn, _ = srv.accept()
    print("Client connected")

    with conn:
        data = conn.recv(1024)
        print("Recieved: ", data.decode("utf-8", errors="replace"))
        conn.sendall(b"OK\n")
        srv.close()

def client():
    cli = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    cli.connect(SOCK_PATH)

    with cli:
        cli.sendall(b"Hello from client!\n")
        resp = cli.recv(1024)
        print("Server replied: ", resp.decode("utf-8", error="replace"))


