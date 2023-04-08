import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/appid.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int uid = 0; // uid of the local user
  Timer? _timer;
  int? _remoteUid; // uid of the remote user
  bool _isJoined = false; // Indicates if the local user has joined the channel
  late RtcEngine agoraEngine; // Agora engine instance
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Global key to access the scaffold

  bool _enableVideo = true;
  bool _enableMic = true;
  bool _enableSpeaker = true;

  showMessage(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  void initState() {
    super.initState();
    setupVideoSDKEngine();
  }

  Future<void> setupVideoSDKEngine() async {
    // retrieve or request camera and microphone permissions
    await [Permission.microphone, Permission.camera].request();

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(const RtcEngineContext(appId: appId));

    await agoraEngine.enableVideo();

    // Register the event handler
    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          showMessage(
              "Local user uid:${connection.localUid} joined the channel");
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          showMessage("Remote user uid:$remoteUid joined the channel");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          showMessage("Remote user uid:$remoteUid left the channel");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );
    _timer = Timer(const Duration(seconds: 2), join);
  }

  @override
  void dispose() {
    agoraEngine.leaveChannel();
    agoraEngine.release();
    _timer!.cancel();
    super.dispose();
  }

  void join() async {
    await agoraEngine.startPreview();

    // Set channel options including the client role and channel profile
    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    );

    await agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );
  }

  void leave() async {
    setState(() {
      _isJoined = false;
      _remoteUid = null;
    });
    if (_isJoined) agoraEngine.leaveChannel();
    _timer!.cancel();
    Navigator.pop(context);
  }

  void enableCam() {
    _enableVideo = !_enableVideo;
    _enableVideo ? agoraEngine.disableVideo() : agoraEngine.enableVideo();
  }

  void enableMic() {
    _enableMic = !_enableMic;
    _enableMic ? agoraEngine.disableAudio() : agoraEngine.enableAudio();
  }

  void enableSpeaker() {
    _enableSpeaker = !_enableSpeaker;
    _enableSpeaker
        ? agoraEngine.setEnableSpeakerphone(true)
        : agoraEngine.setEnableSpeakerphone(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _remoteVideo(),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          color:
                              const Color.fromARGB(0, 0, 0, 0).withOpacity(0.6),
                        )
                      ],
                    ),
                    child: const Text(
                      "User",
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                          boxShadow: const [
                            BoxShadow(
                                blurRadius: 0.5,
                                color: Colors.white,
                                spreadRadius: 0.5)
                          ],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2)),
                      width: 150,
                      height: 150,
                      child: _localPreview(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 20,
                    child: Image.asset(
                      "assets/icons/switch-camera.png",
                      width: 35,
                      height: 35,
                      color: Colors.grey[100],
                    ),
                  ),
                  toolbar()
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Positioned toolbar() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIcon(Icons.volume_up, Icons.volume_off_sharp,
              function: enableSpeaker),
          _buildIcon(Icons.videocam, Icons.videocam_off, function: enableCam),
          _buildIcon(Icons.call_end, Icons.call_end,
              function: leave, bgColor: Colors.red),
          _buildIcon(Icons.mic, Icons.mic_off, function: enableMic),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, IconData iconToggle,
      {required Function function, Color? bgColor}) {
    return IconToggle(
      icon: icon,
      iconToggle: iconToggle,
      bgColor: bgColor,
      function: function,
    );
  }

// Display local video preview
  Widget _localPreview() {
    if (_isJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: agoraEngine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Text(
        'Join a channel',
        textAlign: TextAlign.center,
      );
    }
  }

// Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: agoraEngine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channelName),
        ),
      );
    } else {
      String msg = '';
      if (_isJoined) msg = 'Waiting for a remote user to join';
      return Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

// ignore: must_be_immutable
class IconToggle extends StatefulWidget {
  const IconToggle(
      {super.key,
      required this.icon,
      required this.iconToggle,
      this.bgColor,
      required this.function});

  final IconData icon;
  final IconData iconToggle;
  final Color? bgColor;
  final Function function;

  @override
  State<IconToggle> createState() => _IconToggleState();
}

class _IconToggleState extends State<IconToggle> {
  bool enable = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.function();
        setState(() {
          enable = !enable;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: widget.bgColor ?? (enable ? Colors.black54 : Colors.grey[100]),
        ),
        child: Center(
          child: Icon(
            enable ? widget.icon : widget.iconToggle,
            size: 26,
            color: widget.bgColor != null
                ? Colors.white
                : (!enable ? Colors.black87 : Colors.white),
          ),
        ),
      ),
    );
  }
}
