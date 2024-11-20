import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_opener/data.dart';
import 'package:file_opener/directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isPermission = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          width: double.infinity,
          height: double.infinity,
          child: FractionallySizedBox(
            widthFactor: 0.925,
            child: Column(
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(
                      RegExp("\s*(\d*[13579]\s*,\s*)*\d*[13579]"),
                    ),
                  ],
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    contentPadding: const EdgeInsets.only(
                      left: 15,
                      bottom: 11,
                      top: 11,
                      right: 15,
                    ),
                    hintStyle: const TextStyle(
                      color: Color(0xFF8D8D8D),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: dataList.length,
                    itemBuilder: (BuildContext context, int index) {
                      var data = dataList[index];
                      return TileList(
                        fileUrl: data['url']!,
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TileList extends StatefulWidget {
  const TileList({super.key, required this.fileUrl});

  final String fileUrl;

  @override
  State<TileList> createState() => _TileListState();
}

class _TileListState extends State<TileList> {
  bool downloading = false;
  bool fileExists = false;
  double progress = 0;
  String fileName = "";
  late String filePath;
  late CancelToken cancelToken;
  var getPathFile = DirectoryPath();

  startDownload() async {
    cancelToken = CancelToken();
    var storePath = await getPathFile.getPath();
    filePath = '$storePath/$fileName';
    setState(() {
      downloading = true;
      progress = 0;
    });

    try {
      await Dio().download(
        widget.fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          setState(() {
            progress = (received / total);
          });
        },
        cancelToken: cancelToken,
      );
      setState(() {
        downloading = false;
        fileExists = true;
      });
      openFile();
    } catch (e) {
      debugPrint('$e');
      setState(() {
        downloading = false;
      });
    }
  }

  cancelDownload() {
    cancelToken.cancel();
    setState(() {
      downloading = false;
    });
  }

  checkFileExit() async {
    var storePath = await getPathFile.getPath();
    filePath = '$storePath/$fileName';
    bool fileExistCheck = await File(filePath).exists();
    setState(() {
      fileExists = fileExistCheck;
    });
  }

  openFile() {
    OpenFile.open(filePath);
    debugPrint("fff $filePath");
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      fileName = basename(widget.fileUrl);
    });
    checkFileExit();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 10,
      shadowColor: Colors.grey.shade100,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: InkWell(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            fileExists && downloading == false ? openFile() : startDownload();
          },
          child: Text(fileName),
        ),
        leading: IconButton(
          onPressed: () {
            fileExists && downloading == false ? openFile() : startDownload();
          },
          icon: fileExists
              ? const Icon(
                  Icons.save,
                  color: Colors.green,
                )
              : downloading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.grey,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        Text(
                          (progress * 100).toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12),
                        )
                      ],
                    )
                  : const Icon(Icons.file_download_outlined),
        ),
        trailing: IconButton(
            onPressed: () {
              fileExists && downloading == false
                  ? openFile()
                  : cancelDownload();
            },
            icon: downloading == true
                ? const Icon(Icons.close)
                : const SizedBox()),
      ),
    );
  }
}
