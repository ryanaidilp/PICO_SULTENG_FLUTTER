import 'package:covid_app/controllers/hospital_controller.dart';
import 'package:covid_app/controllers/posts_controller.dart';
import 'package:covid_app/models/Posts.dart';
import 'package:covid_app/models/hospital.dart';
import 'package:covid_app/widgets/custom_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _hospitalController =
      Get.put(HospitalController(), tag: 'HospitalController');
  final _postsController = Get.put(PostsController(), tag: 'PostsController');

  List<Hospital> _hospitals;
  List<Posts> _posts;

  @override
  void initState() {
    if (!_hospitalController.isLoading.value) {
      _hospitals = _hospitalController.hospitals;
    }
    if (!_postsController.isLoading.value) {
      _posts = _postsController.posts;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: CustomAppBar(),
      body: CustomScrollView(
        physics: ClampingScrollPhysics(),
        slivers: [
          _buildHeader(screenHeight),
          _buildContent(),
        ],
      ),
    );
  }

  SliverPadding _buildContent() {
    return SliverPadding(
      padding: EdgeInsets.all(20.0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Rumah Sakit Rujukan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            SizedBox(height: 10.0),
            _buildHospitalSection(),
            SizedBox(height: 20.0),
            Text(
              'Posko Gugus Tugas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            SizedBox(height: 10.0),
            _buildPostsSection()
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalSection() {
    List<Widget> _widgets = List<Widget>();

    if (_hospitals != null) {
      _widgets.addAll(_hospitals
          .map((hospital) => Container(
                width: MediaQuery.of(context).size.width,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          hospital.name,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hospital.address,
                          style:
                              TextStyle(color: Colors.black54, fontSize: 14.0),
                        ),
                        Wrap(
                          spacing: 10,
                          children: <Widget>[
                            RaisedButton.icon(
                              color: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              onPressed: () {
                                launch('tel:${hospital.telephone}');
                              },
                              textColor: Colors.white,
                              icon: Icon(
                                Icons.phone,
                                color: Colors.white,
                                size: 14.0,
                              ),
                              textTheme: ButtonTextTheme.primary,
                              label: Text(hospital.telephone),
                            ),
                            RaisedButton.icon(
                              color: Colors.green[800],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              onPressed: () {
                                launch(
                                    'geo:${hospital.latitude},${hospital.longitude}');
                              },
                              textColor: Colors.white,
                              icon: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 14.0,
                              ),
                              textTheme: ButtonTextTheme.primary,
                              label: Text('Lokasi'),
                            ),
                            RaisedButton.icon(
                              color: Colors.yellow[700],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              onPressed: () {
                                launch('mailto:${hospital.email}');
                              },
                              textColor: Colors.white,
                              icon: Icon(
                                Icons.email,
                                color: Colors.white,
                                size: 14.0,
                              ),
                              textTheme: ButtonTextTheme.primary,
                              label: Text(hospital.email),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ))
          .toList());
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: _widgets,
    );
  }

  Widget _buildPostsSection() {
    List<Widget> _widgets = List<Widget>();

    if (_posts != null) {
      _widgets.addAll(_posts
          .map((post) => Container(
                width: MediaQuery.of(context).size.width,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          post.name,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Wrap(
                            spacing: 10,
                            children: post.post
                                .map((e) => RaisedButton.icon(
                                      color: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0)),
                                      onPressed: () {
                                        launch('tel:${e.phoneNumber}');
                                      },
                                      textColor: Colors.white,
                                      icon: Icon(
                                        Icons.phone,
                                        color: Colors.white,
                                        size: 14.0,
                                      ),
                                      textTheme: ButtonTextTheme.primary,
                                      label: Text(e.name),
                                    ))
                                .toList())
                      ],
                    ),
                  ),
                ),
              ))
          .toList());
    } else {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: _widgets,
    );
  }

  SliverToBoxAdapter _buildHeader(double screenHeight) {
    return SliverToBoxAdapter(
        child: Container(
      height: screenHeight * 0.1,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40.0),
              bottomRight: Radius.circular(40.0))),
      child: Stack(children: <Widget>[
        Positioned.fill(child: Image.asset('assets/images/virus.png')),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Kontak',
                      style: TextStyle(
                          fontSize: 25.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        )
      ]),
    ));
  }
}
