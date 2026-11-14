"""Artificial local IPC source for integration tests; no camera/dependencies."""
import socket,json,time,argparse
p=argparse.ArgumentParser();p.add_argument('--port',type=int,required=True);p.add_argument('--token',required=True);p.add_argument('--camera',default=0);args=p.parse_args()
sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);sock.bind(('127.0.0.1',0));sock.setblocking(False)
for sequence in range(1,301):
 try:
  raw,_=sock.recvfrom(2048)
  if json.loads(raw).get('quit'):break
 except BlockingIOError:pass
 packet=dict(v=1,token=args.token,seq=sequence,sent_ms=int(time.time()*1000),tracked=True,camera_ready=True,kind='palm',palm=[.5,.5],cursor=[.5,.5],status='Synthetic test source')
 sock.sendto(json.dumps(packet).encode(),('127.0.0.1',args.port));time.sleep(1/30)
sock.close()
