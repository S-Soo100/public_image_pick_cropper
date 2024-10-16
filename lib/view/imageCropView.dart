import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:public_image_pick_cropper/service/imageCropService.dart';

class ImageCropView extends StatefulWidget {
  const ImageCropView({Key? key}) : super(key: key);

  @override
  State<ImageCropView> createState() => _ImageCropViewState();
}

class _ImageCropViewState extends State<ImageCropView> {
  final String demoImage = "assets/demo.png"; // 사진 업로드 전 기본 예시 이미지
  late ImageCropService _imageCropService;
  FToast fToast = FToast();
  bool isLoading = false;
  bool _isPictureUploaded = false;
  XFile? _originalImage;
  XFile? _cropedImage;

  @override
  void initState() {
    super.initState();
    fToast.init(context); // toast메세지 초기화
    _imageCropService = ImageCropService(); // 서비스 인스턴스
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    // await _imageCropService.requestPermission();
    bool permissionGranted = await _imageCropService.requestPermission();
    // Future.delayed(Duration(seconds: 1));
    // print(permissionGranted ? "true" : "false");
    if (permissionGranted == false) {
      fToast.showToast(child: Text('권한이 필요합니다.'));
    }
  }

  Future<void> _takePhoto() async {
    _originalImage = await _imageCropService.takePhoto();
    if (_originalImage != null) {
      await _cropAndCompressImage(_originalImage!.path);
    } else {
      fToast.showToast(child: Text('오류! 다시 촬영해주세요!'));
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    _originalImage = await _imageCropService.pickImageFromGallery();
    if (_originalImage != null) {
      await _cropAndCompressImage(_originalImage!.path);
    } else {
      fToast.showToast(child: Text('사진 선택이 취소되었습니다.'));
    }
  }

  Future<void> _cropAndCompressImage(String imagePath) async {
    final croppedFile = await _imageCropService.cropImage(imagePath);
    if (croppedFile != null) {
      _cropedImage = await _imageCropService.compressImage(croppedFile.path);
      setState(() {
        _isPictureUploaded = true;
      });
    }
  }

  ImageProvider _centerImage() {
    if (!_isPictureUploaded) {
      return AssetImage(demoImage);
    }
    return FileImage(File(_cropedImage!.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '📸 Photo Picker',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.33),
                    blurRadius: 10,
                    spreadRadius: 5,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  if (_isPictureUploaded) {
                    _cropAndCompressImage(_originalImage!.path);
                  }
                  _showUploadPictureModal(context);
                },
                child: Stack(
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                            image: _centerImage(),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(width: 1)),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: _isPictureUploaded
                          ? null
                          : Container(
                              height: 40,
                              width: 160,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  Text(
                                    '사진 추가',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            _isPictureUploaded
                ? Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            _cropAndCompressImage(_originalImage!.path);
                          },
                          radius: 20,
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                            child: Icon(Icons.edit, color: Colors.white),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isPictureUploaded = false;
                              _originalImage = null;
                              _cropedImage = null;
                            });
                          },
                          radius: 20,
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox()
          ],
        ),
      ),
    );
  }

  Future<dynamic> _showUploadPictureModal(BuildContext context) {
    return showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return Material(
            color: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.25,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24))),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      _takePhoto();
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                          ),
                          child: Icon(Icons.camera_alt, size: 24),
                        ),
                        SizedBox(width: 6),
                        Text("사진 촬영하기", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      await _pickImageFromGallery(context);
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                          ),
                          child: Icon(Icons.image, size: 24),
                        ),
                        SizedBox(width: 6),
                        Text("내 사진첩에서 선택하기", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
