import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _startVideoCall();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _startVideoCall() async {
    // Create WebRTC configuration
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': 'stun:stun.l.google.com:19302',
        },
      ],
    };

    // Create a peer connection
    final peerConnection = await createPeerConnection(configuration);

    // Get media stream from the local camera
    final mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'},
    };
    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    // Add the local stream to the peer connection
    stream.getTracks().forEach((track) {
      peerConnection.addTrack(track, stream);
    });

    // Display the local video stream
    _localRenderer.srcObject = stream;

    // Handle the remote stream once received
    peerConnection.onAddStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };

    // Create an offer to initiate the connection
    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    // Simulate a remote answer for demonstration purposes
    final answer = await peerConnection.createAnswer();
    await peerConnection.setRemoteDescription(answer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebRTC Video Call')),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(_localRenderer, mirror: true),
          ),
          Expanded(
            child: RTCVideoView(_remoteRenderer),
          ),
        ],
      ),
    );
  }
}
