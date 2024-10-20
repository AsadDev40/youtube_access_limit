// ignore_for_file: must_be_immutable, deprecated_member_use

import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/models/child_model.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:kidsafe_youtube/scrap_api/models/video_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class AllowVideoPopup extends StatefulHookWidget {
  // ignore: non_constant_identifier_names
  AllowVideoPopup({super.key, required this.videodata});

  VideoData videodata;

  @override
  State<AllowVideoPopup> createState() => _CustomPopupState();
}

class _CustomPopupState extends State<AllowVideoPopup> {
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
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Center(
        child: Text(
          'Choose Child',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onBackground,
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 200,
            child: FutureBuilder(
              future: childFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  );
                } else if (childProvider.child.isEmpty) {
                  return Center(
                    child: Text(
                      'No child found',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                  );
                } else {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: childProvider.child.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(
                        height: 2,
                      );
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final child = childProvider.child[index];
                      final selected = selectedChild.value != null &&
                          child.uid == selectedChild.value!.uid;

                      return ListTile(
                        onTap: () {
                          selectedChild.value = child;
                        },
                        trailing: Icon(
                          selected ? Icons.circle_sharp : Icons.circle_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          child.childName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
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
          child: Text(
            'Cancel',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (selectedChild.value == null) {
              Utils.showToast('Please select child');
            } else {
              childProvider.allowVideoForChild(
                  widget.videodata.video!.videoId!, selectedChild.value!.uid);
              Navigator.of(context).pop();
            }
          },
          child: Text(
            'Allow',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
