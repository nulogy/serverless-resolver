import socket

def lambda_handler(event, context):
    addr = socket.gethostbyname(event['host'])
    return { 'addr': addr }
