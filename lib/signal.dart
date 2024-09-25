import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

import 'o.dart';

void main() => runApp(WebRTCApp());

class WebRTCApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoCallPage(),
    );
  }
}

class VideoCallPage extends StatefulWidget {
  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late WebSocketChannel channel;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  bool isMicMuted = false;
  bool isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _connectToWebSocket();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    peerConnection?.dispose();
    channel.sink.close();
    localStream?.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.220:8080'), // Replace with your WebSocket server's URL
    );

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['offer'] != null) {
        _handleOffer(data['offer']);
      } else if (data['answer'] != null) {
        _handleAnswer(data['answer']);
      } else if (data['candidate'] != null) {
        _handleCandidate(data['candidate']);
      }
    });

    _startVideoCall();
  }

  Future<void> _startVideoCall() async {
    final configuration = {
      'iceServers': [
        {
          'urls': 'stun:stun.l.google.com:19302',
        },
      ],
    };

    peerConnection = await createPeerConnection(configuration);

    final mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'},
    };

    // Get user media (audio and video)
    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = localStream;

    // Add tracks to peer connection
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Handle remote track
    peerConnection?.onTrack = (event) {
      setState(() {
        if (event.streams.isNotEmpty) {
          _remoteRenderer.srcObject = event.streams[0];
        }
      });
    };

    // Listen for ICE candidates and send them to the signaling server
    peerConnection?.onIceCandidate = (candidate) {
      if (candidate != null) {
        channel.sink.add(jsonEncode({
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }
        }));
      }
    };

    // Create offer
    final offer = await peerConnection?.createOffer();
    await peerConnection?.setLocalDescription(offer!);

    // Send offer to React via WebSocket
    channel.sink.add(jsonEncode({'offer': offer?.toMap()}));
  }

  Future<void> _handleOffer(Map<String, dynamic> offer) async {
    peerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': 'stun:stun.l.google.com:19302',
        },
      ],
    });

    // Add remote stream to remote renderer
    peerConnection?.onTrack = (event) {
      setState(() {
        if (event.streams.isNotEmpty) {
          _remoteRenderer.srcObject = event.streams[0];
        }
      });
    };

    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    // Create and send answer
    final answer = await peerConnection?.createAnswer();
    await peerConnection?.setLocalDescription(answer!);

    // Send answer to the React app
    channel.sink.add(jsonEncode({'answer': answer?.toMap()}));
  }

  Future<void> _handleAnswer(Map<String, dynamic> answer) async {
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
  }

  Future<void> _handleCandidate(Map<String, dynamic> candidate) async {
    final iceCandidate = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    await peerConnection?.addCandidate(iceCandidate);
  }

  void _toggleMute() {
    if (localStream != null) {
      setState(() {
        isMicMuted = !isMicMuted;
        localStream!.getAudioTracks()[0].enabled = !isMicMuted;
      });
    }
  }

  void _switchCamera() async {
    if (localStream != null) {
      final videoTrack = localStream!.getVideoTracks()[0];
      await videoTrack.switchCamera();
      setState(() {
        isFrontCamera = !isFrontCamera;
      });
    }
  }

  void _endCall() {
    peerConnection?.close();
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    channel.sink.close();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Video Call'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fiber_manual_record, color: Colors.red),
            onPressed: () {}, // Placeholder for recording indicator
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
              Expanded(
                child: RTCVideoView(_remoteRenderer),
              ),
            ],
          ),
          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: isMicMuted ? Icons.mic_off : Icons.mic,
                  onPressed: _toggleMute,
                ),
                const SizedBox(width: 30),
                _buildControlButton(
                  icon: Icons.switch_camera,
                  onPressed: _switchCamera,
                ),
                const SizedBox(width: 30),
                _buildControlButton(
                  icon: Icons.call_end,
                  onPressed: _endCall,
                  color: Colors.red,
                ),
              ],
            ),
          ),
          // Subtitle Bar
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'BRAVE MEN REJOICE IN  ADVERSITY, JUST AS BRAVE SOLDIERS TRIUMPH IN WAR.',
                style: TextStyle(color: Colors.green, fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white38,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white24,
        child: Icon(icon, color: color),
      ),
    );
  }
}