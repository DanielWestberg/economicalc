import 'package:camera/camera.dart';
import 'package:economicalc_client/screens/home_screen.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  /// Default Constructor
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> cameras;
  late CameraController controller;

  @override
  void initState() {
    startCamera();
    super.initState();
  }

  void startCamera() async {
    cameras = await availableCameras();

    controller =
        CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);

    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.value.isInitialized) {
      // return Container();
      return Scaffold(
        body: Stack(
          children: [
            CameraPreview(controller),
            GestureDetector(
                onTap: (() {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HomeScreen()));
                }),
                child: button(
                    Icons.arrow_circle_left_outlined, Alignment.bottomLeft)),
            GestureDetector(
                onTap: (() {
                  controller.takePicture().then((XFile? file) {
                    if (mounted && file != null) {
                      print("Picture saved to ${file.path}");
                    }
                  });
                }),
                child:
                    button(Icons.camera_alt_outlined, Alignment.bottomCenter)),
          ],
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget button(IconData icon, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(left: 20, bottom: 20, right: 20),
        height: 50,
        width: 50,
        decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(2, 2),
                blurRadius: 10,
              )
            ]),
        child: Center(child: Icon(icon)),
      ),
    );
  }
}
