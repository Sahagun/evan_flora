import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evan_flora_223/calendar_events_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'camera_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget{
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  void navigateToProfile(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  void navigateToCamera(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraPage()),
    );
  }

  void navigateToCalenderEventsPage(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CalendarEventPage()),
    );
  }

  void navigateToSearch(){

  }

  String dateFormat(DateTime dt){
    String result = '';
    if(dt.month == DateTime.january){ result = 'January'; }
    else if(dt.month == DateTime.february){ result = 'February'; }
    else if(dt.month == DateTime.march){ result = 'March'; }
    else if(dt.month == DateTime.april){ result = 'April'; }
    else if(dt.month == DateTime.may){ result = 'May'; }
    else if(dt.month == DateTime.june){ result = 'June'; }
    else if(dt.month == DateTime.july){ result = 'July'; }
    else if(dt.month == DateTime.august){ result = 'August'; }
    else if(dt.month == DateTime.september){ result = 'September'; }
    else if(dt.month == DateTime.october){ result = 'October'; }
    else if(dt.month == DateTime.november){ result = 'November'; }
    else if(dt.month == DateTime.december){ result = 'December'; }

    result += ' ${dt.day}, ${dt.year}';
    return result;
  }

  FutureBuilder getImage(firebase_storage.Reference imageRef){
    return FutureBuilder(
        future:  imageRef.getDownloadURL(),
        builder: (context, snapshot) {
          if(snapshot.hasError){
            return const Center(child: Text('Something went wrong'));
          }
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }
          return Image.network(snapshot.data);
        }
    );
  }

  Future< Map<String, dynamic> > getPostsData() async{
    CollectionReference collectionRef = FirebaseFirestore.instance.collection('user_content');
    QuerySnapshot snapshot = await collectionRef.get();

    Map<String, dynamic> posts = {};

    for(QueryDocumentSnapshot doc in snapshot.docs){
      // print(doc.id);
      // print(doc.data());
      posts[doc.id] = doc.data();
    }

    return posts;
  }

  FutureBuilder postsSection() {
    return FutureBuilder(
      future: getPostsData(),
      builder: (context, snapshot) {
        if(snapshot.hasError){
          return const Center(child: Text('Something went wrong'));
        }
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, dynamic> posts = snapshot.data;
        List<String> postIDs = posts.keys.toList();

        return ListView.builder(
          itemCount: postIDs.length,
          itemBuilder: (buildContext, index){
            String key = postIDs[index];
            Map<String, dynamic> postInfo = posts[key];

            firebase_storage.Reference imageRef = firebase_storage.FirebaseStorage.instance.ref().child(posts[key]['image_path']);

            Timestamp ts = postInfo['created'];
            DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch);
            String timeString = dateFormat(dt);

            String username = 'n/a';
            if(postInfo.containsKey('username')){
              username = postInfo['username'];
            }

            return Card(
              child: ListTile(
                title: Center(
                  child: Column(
                    children: [
                      Text(postInfo['species']),
                      getImage(imageRef),
                      Row(
                          children:[
                            Text('Time Taken'),
                            Spacer(),
                            Text(timeString),
                          ]
                      ),
                      Row(
                          children:[
                            Text('By'),
                            Spacer(),
                            Text(username),
                          ]
                      ),
                    ],
                  ),
                ),
                onTap: (){},
              )
            );
          }
        );
      },
    );
  }



  Widget buttonsSection(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: navigateToCamera, child: const Text("Upload")),
        ElevatedButton(onPressed: navigateToCalenderEventsPage, child: const Text("Events")),
      ],
    );
  }


  Widget stateBody(){
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: postsSection()),
          // const Spacer(),
          buttonsSection(),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(FirebaseAuth.instance.currentUser!.displayName!),
        actions: [
          IconButton(onPressed: navigateToProfile, icon: const Icon(Icons.account_circle))
        ],
      ),
      body: stateBody(),
    );
  }
}