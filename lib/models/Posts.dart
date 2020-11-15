// To parse this JSON data, do
//
//     final posts = postsFromJson(jsonString);

import 'dart:convert';

Posts postsFromJson(String str) => Posts.fromJson(json.decode(str));

String postsToJson(Posts data) => json.encode(data.toJson());

class Posts {
  Posts({
    this.no,
    this.name,
    this.post,
  });

  int no;
  String name;
  List<Post> post;

  factory Posts.fromJson(Map<String, dynamic> json) => Posts(
    no: json["no"],
    name: json["nama"],
    post: List<Post>.from(json["posko"].map((x) => Post.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "no": no,
    "nama": name,
    "posko": List<dynamic>.from(post.map((x) => x.toJson())),
  };
}

class Post {
  Post({
    this.no,
    this.name,
    this.phoneNumber,
  });

  int no;
  String name;
  List<String> phoneNumber;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    no: json["no"],
    name: json["nama"],
    phoneNumber: List<String>.from(json["no_hp"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "no": no,
    "nama": name,
    "no_hp": List<dynamic>.from(phoneNumber.map((x) => x)),
  };
}
