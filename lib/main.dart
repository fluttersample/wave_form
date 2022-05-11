import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Audio Waveforms',
      debugShowCheckedModeBanner: false,
      home: TestWave(),
    );
  }
}

class TestWave extends StatefulWidget {
  const TestWave({Key? key}) : super(key: key);

  @override
  State<TestWave> createState() => _TestWaveState();
}

class _TestWaveState extends State<TestWave> with SingleTickerProviderStateMixin{

  /// Animation
  late AnimationController controller;
  late Animation<double> valueAnim;

  /// Wave Form
  late final RecorderController recorderController;
  final PlayerController playerController1 = PlayerController();

  /// Var
  String? path;
  File? fileRec;


  @override
  void initState() {
    super.initState();
    _getDir();
    _initialControllers();
  }
  void _initialControllers()
  {
    /// Animation
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    valueAnim = Tween<double>(begin: 1,end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.ease));

    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;


  }
  void resetAllControllers ()
  {
    fileRec?.delete();
    fileRec=null;
    controller.reset();
    playerController1.stopPlayer();
    recorderController.reset();
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wave Form'),
        actions: [
          IconButton(
              onPressed: (){
                resetAllControllers();
              },
              icon:Icon(
                  Icons.delete_forever
              ))
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            AudioWaveforms(
              enableGesture: true,
              size: Size(MediaQuery.of(context).size.width , 50),
              recorderController: recorderController,
              waveStyle:  const WaveStyle(
                waveColor: Colors.white,
                extendWaveform: true,
                showMiddleLine: false,
                waveThickness: 3.5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color:  Colors.orange,
              ),
              padding: const EdgeInsets.only(left: 15,top: 3,bottom: 3,
              right: 15),
              margin: const EdgeInsets.symmetric(horizontal: 15),
            ),
            SizedBox(
              height: 20,
            ),
            fileRec !=null && !recorderController.isRecording?
            IconButton(
                iconSize: 45,
                onPressed: () {
                  _initPlayer();
                },
                icon: AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: controller,
                  color: Colors.blue,
                )): AnimatedBuilder(
              animation: controller,
              builder: (cn , widget){
                return Transform.scale(
                  scale: valueAnim.value,
                  child: widget,
                );
              },
              child: GestureDetector(
                onLongPressDown: (details) {
                  _stopOrStartRec();

                },
                onLongPressEnd: (z){
                  _stopOrStartRec();
                },
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,

                  ),
                  child: const Icon(
                    Icons.keyboard_voice,
                    color: Colors.white,
                  ),
                ),
              ) ,)

          ],
        ),
      ),
    );
  }
  void _stopOrStartRec()async
  {
    if(recorderController.isRecording)
    {
       await recorderController.stop(false);
      controller.reverse();
    }else {
      await recorderController.record(path);
      if(path!=null) fileRec = File(path!);
      controller.repeat(reverse: true);


    }
    setState(() {});
  }
  void _getDir() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory.path}/music.aac";
  }
  void _initPlayer()async
  {

    if(playerController1.playerState == PlayerState.stopped)
    {
      await  playerController1.preparePlayer(fileRec!.path);
      playerController1.startPlayer();
      controller.forward();
    }
    else if(playerController1.playerState == PlayerState.playing)
    {
      playerController1.pausePlayer();
      controller.reverse();

    }else {
      playerController1.startPlayer();
      controller.forward();

    }


  }
}