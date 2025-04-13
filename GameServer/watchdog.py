#!/usr/bin/python

import re
import os
import socket
import time

def makebigendian(length):
    a = length / 0xFFFFFF
    b = (length % 0xFFFFFF) / 0xFFFF
    c = (length % 0xFFFF) / 0xFF
    d = length % 0xFF
    return chr(a) + chr(b) + chr(c) + chr(d)

def getbigendian(data):
    a = ord(data[0])
    b = ord(data[1])
    c = ord(data[2])
    d = ord(data[3])
    length = a * 0xFFFFFF + b * 0xFFFF + c * 0xFF + d
    return length

def main():
    with open("./ServerConfig.lua") as f:
        for line in f:
            m = re.match("(.*)=(.*);", line.strip())
            if m:
                key = m.group(1).strip()
                if key == "serverid":
                    serverid = m.group(2).strip()
                elif key == "commercial_ip":
                    commercial_ip = m.group(2).strip(' "')
                elif key == "commercial_wdport":
                    commercial_wdport = int(m.group(2).strip())
    
    while True:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((commercial_ip, commercial_wdport))
            str_send = "regist " + serverid
            s.send(makebigendian(len(str_send)) + str_send)
            print("wait for command")
            data = s.recv(1024)
            s.close()
            if data: 
                length = getbigendian(data)
                data = data[4:4+length]
                print("recv command:" + data)
                if data == "start":
                    while os.system("./run") != 0:
                        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                        s.connect((commercial_ip, commercial_wdport))
                        str_send = "crash " + serverid
                        s.send(makebigendian(len(str_send)) + str_send)
                        s.close()
                   
        except IOError, e:
            print(e)
            time.sleep(10)

main()


