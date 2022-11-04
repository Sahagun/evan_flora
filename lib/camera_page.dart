import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert' as convert;

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


class CameraPage extends StatefulWidget{
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {

  String? documentID;

  final imagePicker = ImagePicker();
  File? _imageFile;

  String? description;
  String? species;
  bool? isNative;

  bool tfLoading = false;
  bool tfProcessing = false;

  String toggleState = 'off';

  List<String> nativePlants = [];


  Future getImage() async{
    final pickedImage = await imagePicker.pickImage(source: ImageSource.camera);
    // final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage == null){
      // if no image was selected
      return;
    }

    setState(() {
      _imageFile = File(pickedImage.path);
    });

    await classifyPlant();

    // recognizeImageBinary();

    // final rawImage = await pickedImage.readAsBytes();
    // final bytes = await resizeImage(Uint8List.view(rawImage.buffer), height: 224, width: 224);
    // if (bytes != null){
    //   Uint8List imageForTflite = Uint8List.view(bytes.buffer);
    //   await getPlantFromImage(imageForTflite);
    // }

  }


  Uint8List imageToByteListUint8(img.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel);
        buffer[pixelIndex++] = img.getGreen(pixel);
        buffer[pixelIndex++] = img.getBlue(pixel);
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }


  Future<void> classifyPlant() async {
    File image = _imageFile!;
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    print("starttime: $startTime");

    tfProcessing = true;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://172.118.224.173:1234/plant')
    );

    Map<String, String> headers = {"Content-type": "multipart/form-data"};

    request.files.add(
      http.MultipartFile(
        'image',
        image.readAsBytes().asStream(),
        image.lengthSync(),
        filename: "image",
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    request.headers.addAll(headers);
    print("request sent");
    StreamedResponse responseStream = await request.send();
    var data = await responseStream.stream.bytesToString();

    Map<String, dynamic> json = convert.jsonDecode(data) as Map<String, dynamic>;
    print(json);

    species = json['plant'];
    isNative = nativePlants.contains(species);

    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Classifying took ${endTime - startTime}ms");

    tfProcessing = false;
    setState(() {

    });
  }


  Future recognizeImageBinary() async {
    File image = _imageFile!;
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    print("starttime: $startTime");
    // print("imageByte");
    // print(image.path);
    // var imageBytes = (await rootBundle.load(image.path)).buffer;
    // var imageBytes = await _imageFile.readAsBytes();
    print("oriImage");
    img.Image? oriImage = img.decodeJpg(await _imageFile!.readAsBytes());
    print("resizedImage");
    img.Image resizedImage = img.copyResize(oriImage!, height: 224, width: 224);
    print(resizedImage);

    // print("imageToByteListFloat32");
    // var imageF32 = imageToByteListFloat32(resizedImage, 224, 127.5, 127.5);

    print("imageToByteListUint8");
    Uint8List imageUint8 = imageToByteListUint8(resizedImage, 224);
    print(imageUint8);

    //
    // print("Tflite Start");
    // var recognitions = await Tflite.runModelOnBinary(
    //   binary: imageUint8,
    //   numResults: 1,
    //   threshold: 0.05,
    // );
    //
    // print(recognitions);


    // setState(() {
    //   _recognitions = recognitions;
    // });
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");


  }






  // Future getPlantFromImage(Uint8List? image) async{
  //   if(image == null){
  //     return;
  //   }
  //
  //   setState(() { tfProcessing = true; });
  //
  //   int startTime = new DateTime.now().millisecondsSinceEpoch;
  //
  //   print(image);
  //
  //   print('Tflite Starts');
  //   var recognitions = await Tflite.runModelOnBinary(
  //       binary: image
  //   );
  //
  //   print(recognitions);
  //
  //   // var recognitions = await Tflite.runModelOnImage(
  //   //     path: image.path,
  //   // );
  //
  //   int endTime = new DateTime.now().millisecondsSinceEpoch;
  //   print( 'Processing Time: ${endTime - startTime}ms' );
  //
  //   description = "Taco";
  //   species = "Taco Plant";
  //   isInvasive = false;
  //
  //   String path = await uploadImageToStorage();
  //   documentID = await uploadInfoToFireStore(path, species!, isInvasive!);
  //
  //   description = path;
  //
  //   // print(recognitions);
  //   setState(() { tfProcessing = false; });
  // }


  Future<void> uploadToFirebase() async {
    setState(() { tfProcessing = true; });

    String uid = FirebaseAuth.instance.currentUser!.uid;
    String timestamp = DateTime.now().toIso8601String();
    String fileName = '${timestamp}_$uid.jpg';
    print(fileName);


    // Upload Image
    firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child('user_uploads/$fileName');
    final metadata = firebase_storage.SettableMetadata(contentType: 'image/jpeg');

    firebase_storage.UploadTask uploadTask = ref.putFile(File(_imageFile!.path), metadata);
    firebase_storage.UploadTask task = await Future.value(uploadTask);

    Future.value(uploadTask).then(
            (value)=>{print("Upload Path: ${value.ref.fullPath}")}
    ).onError(
            (error, stackTrace) => {print("Upload Error: ${error.toString()} ")}
    );
    String imagePath = ref.fullPath;

    // upload data
    CollectionReference userContent =  FirebaseFirestore.instance.collection('user_content');
    DocumentReference docRef = await userContent.add({
      'image_path': imagePath,
      'created': DateTime.now(),
      'species': species,
      'native': isNative,
      'userid': FirebaseAuth.instance.currentUser!.uid,
    });


    try{
      DocumentReference userRef =  FirebaseFirestore.instance.doc('users/${FirebaseAuth.instance.currentUser!.uid}');
      DocumentSnapshot userSnapshot = await userRef.get();
      if(!userSnapshot.exists){
        await userRef.set( {"posts": ['${docRef.id}'] } );
      }
      else{
        List<dynamic> posts = userSnapshot['posts'];
        posts.add(docRef.id);
        await userRef.update( {'posts': posts} );
      }
    }
    catch(e){
      print(e);
    }

    setState(() { tfProcessing = false; });
  }


   Future<String> uploadInfoToFireStore(String imagePath, String species, bool invasive) async{
    CollectionReference userContent =  FirebaseFirestore.instance.collection('user_content');
    DocumentReference docRef = await userContent.add({
      'image_path': imagePath,
      'created': DateTime.now(),
      'species': species,
      'invasive': invasive,
      'userid': FirebaseAuth.instance.currentUser!.uid,
      'corrected': false,
      'gps': null,
      'corrected_species': null,
      'corrected_invasive': null,
    });


    try{
      DocumentReference userRef =  FirebaseFirestore.instance.doc('users/${FirebaseAuth.instance.currentUser!.uid}');
      DocumentSnapshot userSnapshot = await userRef.get();
      if(!userSnapshot.exists){
        await userRef.set( {"posts": ['${docRef.id}'] } );
      }
      else{
        List<dynamic> posts = userSnapshot['posts'];
        posts.add(docRef.id);
        await userRef.update( {'posts': posts} );
      }
    }
    catch(e){
      print(e);
    }

    return docRef.id;
  }


  void uploadCorrections() async{
    setState(() { tfProcessing = true; });
    try {
      DocumentReference docRef = FirebaseFirestore.instance.doc(
          'user_content/$documentID');
      DocumentSnapshot docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        var data = {
          'corrected': true,
          'corrected_invasive': isNative,
          'corrected_species': species
        };
        await docRef.update(data);
      }
    }
    catch(e){
      print(e);
    }

    setState(() { tfProcessing = false; });
  }


  // Returns the full path of the file
  Future<String> uploadImageToStorage() async{
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String timestamp = DateTime.now().toIso8601String();

    String fileName = '${timestamp}_$uid.jpg';

    print(fileName);

    firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child('user_uploads/$fileName');

    final metadata = firebase_storage.SettableMetadata(
      contentType: 'image/jpeg',
    );

    firebase_storage.UploadTask uploadTask = ref.putFile(File(_imageFile!.path), metadata);
    firebase_storage.UploadTask task = await Future.value(uploadTask);

    Future.value(uploadTask).then(
            (value)=>{print("Upload Path: ${value.ref.fullPath}")}
    ).onError(
            (error, stackTrace) => {print("Upload Error: ${error.toString()} ")}
    );

    return ref.fullPath;
  }


  Future loadModel() async{
    // Tflite.close();
    // try{
    //   String? res = await Tflite.loadModel(
    //     model: 'assets/lite-model_aiy_vision_classifier_plants_V1_3.tflite',
    //     labels: 'assets/aiy_plants_V1_labelmap.csv'
    //   );
    //   print(res);
    // }
    // on PlatformException{
    //   print('Failed to load the model');
    // }
  }

  void toggleTF(){
    if(tfLoading){
      toggleState = "processing";
      tfLoading = false;
      tfProcessing = true;
    }
    else if (tfProcessing){
      toggleState = "off";
      tfLoading = false;
      tfProcessing = false;
    }
    else{
      toggleState = "loading";
      tfLoading = true;
      tfProcessing = false;
    }
    setState(() {

    });
  }


  void updateData(){
    description = 'asdfsa';
    species = 'asdf';
    isNative = true;
    setState(() {});
  }

  Widget buttonsSection(){
    List<Widget> widgetsToAdd = [];

    // Camera Button
    ElevatedButton cameraBtn = _imageFile == null ?
      ElevatedButton(onPressed: getImage, child: const Icon(Icons.camera_alt)):
      ElevatedButton(onPressed: getImage, child: const Text("reCapture"));

    widgetsToAdd.add(cameraBtn);

    if(_imageFile!=null){
      widgetsToAdd.add(
          ElevatedButton(onPressed: showEditDialogBox, child: const Text("Correction"))      );
      widgetsToAdd.add(
          ElevatedButton(onPressed: uploadToFirebase, child: const Text("Upload"))      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widgetsToAdd,
    );
  }

  Widget imageSection(){
    return Expanded(
      child: Center(
        child: _imageFile != null ?
          Image.file(_imageFile!):
          const Text("No Preview"),
      ),
    );
  }

  Widget showData(){
    return Column(
      children: [
        // species info
        Row(
          children: [
            const Text("Species:"),
            const Spacer(),
            (species==null || species!.isEmpty) ? const Text('-') : Text(species!)
          ],
        ),

        // description info
        // Row(
        //   children: [
        //     const Text("Description:"),
        //     const Spacer(),
        //     (description==null || description!.isEmpty) ? const Text('-') : Text(description!)
        //   ],
        // ),

        // invasive info
        Row(
          children: [
            const Text("Is Native:"),
            const Spacer(),
            (isNative==null) ? const Text('-') : Text('$isNative')
          ],
        ),
      ],
    );
  }

  Widget loadingWidget(){
    if (tfLoading || tfProcessing){
      return Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
            child: Opacity(
              opacity: .5,
              child: Container(
                // the size where the blurring starts
                height: MediaQuery.of(context).size.height ,
                color: Colors.grey,
                // color: Colors.transparent,
              ),
            ),
          ),

          const Center(
            child: CircularProgressIndicator(
              strokeWidth: 4,
            ),
          ),
        ]
      );
    }
    return  Container();
  }


  Widget stateBody(){
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child:
            Column(
              children: [
                imageSection(),
                showData(),
                buttonsSection(),
              ],
            ),
        ),
        loadingWidget(),
        // ElevatedButton(onPressed: toggleTF, child: Text(toggleState)),
      ],
    );
  }


  @override
  void initState(){
    super.initState();
    tfLoading = true;
    loadNativePlants().then(
      (val){
        setState(() {
          tfLoading = false;
        });
      }
    );
    // tfLoading = true;
    // loadModel().then(
    //     (val){
    //       setState(() {
    //         tfLoading = false;
    //       });
    //     }
    // );
  }

  Future<void> loadNativePlants() async {
    String allstringdata = await rootBundle.loadString('assets/native.txt');
    nativePlants = allstringdata.split('\n');
    print(nativePlants[3]);
  }

  void showEditDialogBox(){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return EditPlantDialog( "cactus", false);
      }
    ).then((value) {
      if(value!= null){
        setState(() {
          species = value[0];
          isNative = value[1];
        });
        // uploadCorrections();
        print(value);
      }
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Camera Page"),
      ),
      body: stateBody(),
    );
  }

} // End of _CameraPageState class



class EditPlantDialog extends StatefulWidget{
  final String species;
  final bool isInvasive ;

  EditPlantDialog(this.species, this.isInvasive);

  @override
  _EditPlantDialogState createState() => _EditPlantDialogState();
}

class _EditPlantDialogState extends State<EditPlantDialog>{

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final speciesTextFieldController = TextEditingController();

  bool submitLock = false;

  bool correctedIsInvasive = false;

  @override
  void initState(){
    super.initState();
    correctedIsInvasive = widget.isInvasive;
  }

  @override
  void dispose(){
    speciesTextFieldController.dispose();
    super.dispose();
  }

  String? validateSpecies(String? value){
    int stringLengthLimit = 30;
    if(value == null || value.isEmpty){
      return 'Please enter a species.';
    }
    else if(value.length >= stringLengthLimit){
      return 'Please enter no more than ${stringLengthLimit} characters.';
    }
    return null;
  }

  void onUpdateButtonPressed(){
    if(_formKey.currentState!.validate()){
      Navigator.pop(context, [speciesTextFieldController.text, correctedIsInvasive]);
    }
  }

  void onIsInvasiveCheckBoxChanged(bool? value){
    setState(() {
      correctedIsInvasive = value!;
    });
  }

  Widget dialogContent(){
    return Form(
      key: _formKey,
      child: Column(
        children: [

          // Species Text Field
          TextFormField(
            controller: speciesTextFieldController,
            validator: validateSpecies,
            decoration: const InputDecoration(
              hintText: 'ex: "Acacia Pycnantha" or "Golden Wattle"',
              labelText: "Species Name",
            ),
          ),

          // Is Native checkbox
          Row(
            children: [
              const Text("Is this plant native?"),
              Spacer(),
              const Text("Yes"),
              Checkbox(value: correctedIsInvasive, onChanged: onIsInvasiveCheckBoxChanged )
            ],
          ),

        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Submit a Correction'),
      actions: [
        // Cancel button
        ElevatedButton(
          child: Text("Cancel"),
          onPressed: (){ Navigator.pop(context); },
        ),

        // Submit button
        ElevatedButton(
          child: Text("Update"),
          onPressed: onUpdateButtonPressed,
        )
      ],
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: dialogContent(),
      )
    );
  }
}