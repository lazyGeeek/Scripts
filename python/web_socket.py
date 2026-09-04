#!/usr/bin/env python3
import socket

HOST = "IP/Host"
PORT = 1337

def server():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen(1)
        print(f"Listening on {HOST}:{PORT} ...")

        conn, addr = s.accept()
        with conn:
            print("Connected by: ", addr)
            while True:
                data = conn.recv(1024)
                if not data:
                    break
                conn.sendall(b"Server response\n") # echo back

def client():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT))
        s.sendall(b"Hello from Client")
        reply = s.recv(1024)
        print("Received from Server ", reply.decode())

