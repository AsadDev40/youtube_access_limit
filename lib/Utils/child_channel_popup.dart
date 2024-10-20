// ignore_for_file: must_be_immutable

import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/models/child_model.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:kidsafe_youtube/scrap_api/models/video_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class AllowChannelPopup extends StatefulHookWidget {
  // ignore: non_constant_identifier_names
  AllowChannelPopup({super.key, required this.channel});

  VideoData channel;

  @override
  State<AllowChannelPopup> createState() => _CustomPopupState();
}

class _CustomPopupState extends State<AllowChannelPopup> {
  late Future<void> childFuture;
  @override
  void initState() {
    super.initState();
    childFuture =
        Provider.of<ChildProvider>(context, listen: false).getChilds();
  }

  @override
  Widget build(BuildContext context) {
    final selectedChild = useState<ChildModel?>(null);
    final childProvider = Provider.of<ChildProvider>(context);
    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: const Center(child: Text('Choose Child')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 200,
            child: FutureBuilder(
              future: childFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (childProvider.child.isEmpty) {
                  return const Center(child: Text('No child found'));
                } else {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: childProvider.child.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox();
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final child = childProvider.child[index];
                      final selected = selectedChild.value != null &&
                          child.uid == selectedChild.value!.uid;

                      return ListTile(
                        onTap: () {
                          selectedChild.value = child;
                        },
                        trailing: Icon(selected
                            ? Icons.circle_sharp
                            : Icons.circle_outlined),
                        title: Text(child.childName),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Utils.back(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (selectedChild.value == null) {
              Utils.showToast('Please select child');
            } else {
              //selectedChild.value!.uid;
              childProvider.addChannelForChild(
                  widget.channel.video!.channelId!, selectedChild.value!.uid);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
