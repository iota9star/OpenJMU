import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:extended_text/extended_text.dart';
import 'package:extended_image/extended_image.dart';
import 'package:like_button/like_button.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/controller/extended_typed_network_image_provider.dart';
import 'package:openjmu/widgets/image/image_viewer.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isDetail;
  final bool isRootContent;
  final String fromPage;
  final int index;
  final BuildContext parentContext;

  const PostCard(
    this.post, {
    this.isDetail = false,
    this.isRootContent,
    this.fromPage,
    this.index,
    @required this.parentContext,
    Key key,
  }) : super(key: key);

  @override
  State createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final Color actionIconColorDark = Color(0xff757575);
  final Color actionIconColorLight = Color(0xffE0E0E0);
  final Color actionTextColorDark = Color(0xff9E9E9E);
  final Color actionTextColorLight = Color(0xffBDBDBD);
  final double contentPadding = 22.0;

  TextStyle get subtitleStyle => TextStyle(color: Colors.grey, fontSize: suSetSp(18.0));
  TextStyle get rootTopicTextStyle => TextStyle(fontSize: suSetSp(18.0));
  TextStyle get rootTopicMentionStyle => TextStyle(color: Colors.blue, fontSize: suSetSp(18.0));

  @override
  void initState() {
    Instances.eventBus
      ..on<ForwardInPostUpdatedEvent>().listen((event) {
        if (event.postId == widget.post.id) widget.post.forwards = event.count;
        if (mounted) setState(() {});
      })
      ..on<CommentInPostUpdatedEvent>().listen((event) {
        if (event.postId == widget.post.id) widget.post.comments = event.count;
        if (mounted) setState(() {});
      })
      ..on<PraiseInPostUpdatedEvent>().listen((event) {
        if (event.postId == widget.post.id) {
          if (event.isLike != null) widget.post.isLike = event.isLike;
          widget.post.praises = event.count;
        }
        if (this.mounted) setState(() {});
      });
    super.initState();
  }

  Widget getPostNickname(context, post) => Row(
        children: <Widget>[
          Text(
            post.nickname ?? post.uid,
            style: TextStyle(
              color: Theme.of(context).textTheme.title.color,
              fontSize: suSetSp(22.0),
            ),
            textAlign: TextAlign.left,
          ),
          if (Constants.developerList.contains(post.uid))
            Container(
              margin: EdgeInsets.only(left: suSetWidth(14.0)),
              child: DeveloperTag(
                padding: EdgeInsets.symmetric(
                  horizontal: suSetWidth(8.0),
                  vertical: suSetHeight(4.0),
                ),
              ),
            ),
        ],
      );

  Widget getPostInfo(Post post) {
    String _postTime = post.postTime;
    DateTime now = DateTime.now();
    if (int.parse(_postTime.substring(0, 4)) == now.year) {
      _postTime = _postTime.substring(5, 16);
    } else {
      _postTime = _postTime.substring(2, 16);
    }
    if (int.parse(_postTime.substring(0, 2)) == now.month &&
        int.parse(_postTime.substring(3, 5)) == now.day) {
      _postTime = "${_postTime.substring(5, 11)}";
    }
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            alignment: ui.PlaceholderAlignment.middle,
            child: Icon(
              Icons.access_time,
              color: Colors.grey,
              size: suSetWidth(16.0),
            ),
          ),
          TextSpan(text: " $_postTime　"),
          WidgetSpan(
            alignment: ui.PlaceholderAlignment.middle,
            child: Icon(
              Icons.smartphone,
              color: Colors.grey,
              size: suSetWidth(16.0),
            ),
          ),
          TextSpan(text: " ${post.from}　"),
        ],
      ),
      style: subtitleStyle,
    );
  }

  Widget getPostContent(context, post) => Container(
        width: Screens.width,
        margin: EdgeInsets.symmetric(vertical: suSetHeight(4.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            getExtendedText(post.content),
            if (post.rootTopic != null) getRootPost(context, post.rootTopic),
          ],
        ),
      );

  Widget getRootPost(context, rootTopic) {
    var content = rootTopic['topic'];
    if (rootTopic['exists'] == 1) {
      if (content['article'] == "此微博已经被屏蔽" || content['content'] == "此微博已经被屏蔽") {
        return Container(
          margin: EdgeInsets.only(top: suSetHeight(10.0)),
          child: getPostBanned("shield"),
        );
      } else {
        final _post = Post.fromJson(content);
        String topic =
            "<M ${content['user']['uid']}>@${content['user']['nickname'] ?? content['user']['uid']}<\/M>: ";
        topic += content['article'] ?? content['content'];
        return Container(
          margin: EdgeInsets.only(top: suSetHeight(8.0)),
          child: GestureDetector(
            onTap: () {
              navigatorState.pushNamed(
                Routes.OPENJMU_POST_DETAIL,
                arguments: {
                  "post": _post,
                  "index": widget.index,
                  "fromPage": widget.fromPage,
                  "parentContext": context,
                },
              );
            },
            child: Container(
              width: Screens.width,
              margin: EdgeInsets.symmetric(horizontal: suSetWidth(16.0)),
              padding: EdgeInsets.symmetric(
                horizontal: suSetWidth(contentPadding - 6.0),
                vertical: suSetHeight(10.0),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(suSetWidth(10.0)),
                color: Theme.of(context).canvasColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  getExtendedText(topic, isRoot: true),
                  if (rootTopic['topic']['image'] != null)
                    Padding(
                      padding: EdgeInsets.only(top: suSetHeight(8.0)),
                      child: getRootPostImages(context, rootTopic['topic']),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      return Container(
        margin: EdgeInsets.only(top: suSetWidth(10.0)),
        child: getPostBanned("delete"),
      );
    }
  }

  Widget getPostImages(context, Post post) {
    return Padding(
      padding: (post.pics?.length ?? 0) > 0
          ? EdgeInsets.symmetric(
              horizontal: suSetWidth(16.0),
              vertical: suSetHeight(4.0),
            )
          : EdgeInsets.zero,
      child: getImages(context, post.pics),
    );
  }

  Widget getRootPostImages(context, rootTopic) {
    return getImages(context, rootTopic['image']);
  }

  Widget getImages(context, data) {
    if (data != null) {
      List<Widget> imagesWidget = [];
      for (int index = 0; index < data.length; index++) {
        final imageId = int.parse(data[index]['id'].toString());
        final imageUrl = data[index]['image_middle'];
        final provider = ExtendedTypedNetworkImageProvider(imageUrl);
        Widget _exImage = ExtendedImage(
          image: provider,
          fit: BoxFit.cover,
          loadStateChanged: (ExtendedImageState state) {
            Widget loader;
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                loader = Center(child: CupertinoActivityIndicator());
                break;
              case LoadState.completed:
                final info = state.extendedImageInfo;
                if (info != null) {
                  loader = ScaledImage(
                    image: info.image,
                    length: data.length,
                    num200: suSetWidth(200),
                    num400: suSetWidth(300),
                    provider: provider,
                  );
                }
                break;
              case LoadState.failed:
                break;
            }
            return loader;
          },
        );
        _exImage = GestureDetector(
          onTap: () {
            navigatorState.pushNamed(
              Routes.OPENJMU_IMAGE_VIEWER,
              arguments: {
                "index": index,
                "pics": data.map<ImageBean>((f) {
                  return ImageBean(
                    id: imageId,
                    imageUrl: f['image_original'],
                    imageThumbUrl: f['image_thumb'],
                    postId: widget.post.id,
                  );
                }).toList(),
                "post": widget.post,
                "heroPrefix": "square-post-image-hero-"
                    "${widget.isDetail ? "isDetail-" : ""}",
              },
            );
          },
          child: _exImage,
        );
        _exImage = Hero(
          tag: "square-post-image-hero-"
              "${widget.isDetail ? "isDetail-" : ""}"
              "${widget.post.id}-$imageId",
          child: _exImage,
        );
        imagesWidget.add(_exImage);
      }
      Widget _image;
      if (data.length == 1) {
        _image = Container(
          padding: EdgeInsets.only(top: suSetHeight(4.0)),
          child: Align(alignment: Alignment.topLeft, child: imagesWidget[0]),
        );
      } else if (data.length == 4) {
        _image = GridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          primary: false,
          mainAxisSpacing: suSetWidth(10.0),
          crossAxisCount: 4,
          crossAxisSpacing: suSetHeight(10.0),
          children: imagesWidget,
        );
      } else if (data.length > 1) {
        _image = GridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          primary: false,
          mainAxisSpacing: suSetWidth(10.0),
          crossAxisCount: 3,
          crossAxisSpacing: suSetHeight(10.0),
          children: imagesWidget,
        );
      }
      return _image;
    } else {
      return SizedBox.shrink();
    }
  }

  Widget postActions(context) {
    int forwards = widget.post.forwards;
    int comments = widget.post.comments;
    int praises = widget.post.praises;

    return SizedBox(
      width: Screens.width * 0.5,
      child: Row(
        children: <Widget>[
          Expanded(
            child: LikeButton(
              padding: EdgeInsets.zero,
              size: suSetWidth(26.0),
              circleColor: CircleColor(start: currentThemeColor, end: currentThemeColor),
              countBuilder: (int count, bool isLiked, String text) => SizedBox(
                width: suSetWidth(40.0),
                child: Text(
                  count == 0 ? "" : text,
                  style: TextStyle(
                    color: isLiked
                        ? currentThemeColor
                        : currentBrightness == Brightness.dark
                            ? actionTextColorDark
                            : actionTextColorLight,
                    fontSize: suSetSp(18.0),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              bubblesColor: BubblesColor(
                dotPrimaryColor: currentThemeColor,
                dotSecondaryColor: currentThemeColor,
              ),
              likeBuilder: (bool isLiked) => SvgPicture.asset(
                "assets/icons/postActions/praise-fill.svg",
                color: isLiked
                    ? currentThemeColor
                    : currentBrightness == Brightness.dark
                        ? actionIconColorDark
                        : actionIconColorLight,
                width: suSetWidth(26.0),
              ),
              likeCount: praises,
              likeCountAnimationType: LikeCountAnimationType.none,
              likeCountPadding: EdgeInsets.symmetric(
                horizontal: suSetWidth(10.0),
                vertical: suSetHeight(12.0),
              ),
              isLiked: widget.post.isLike,
              onTap: onLikeButtonTap,
            ),
          ),
          Expanded(
            child: FlatButton.icon(
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: null,
              icon: SvgPicture.asset(
                "assets/icons/postActions/comment-fill.svg",
                color: currentBrightness == Brightness.dark
                    ? actionIconColorDark
                    : actionIconColorLight,
                width: suSetWidth(26.0),
              ),
              label: SizedBox(
                width: suSetWidth(40.0),
                child: Text(
                  comments == 0 ? "" : "$comments",
                  style: TextStyle(
                    color: currentBrightness == Brightness.dark
                        ? actionTextColorDark
                        : actionTextColorLight,
                    fontSize: suSetSp(18.0),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              highlightColor: Theme.of(context).cardColor,
              splashColor: Theme.of(context).cardColor,
            ),
          ),
          Expanded(
            child: FlatButton.icon(
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () {
                navigatorState.pushNamed(
                  Routes.OPENJMU_ADD_FORWARD,
                  arguments: {"post": widget.post},
                );
              },
              icon: SvgPicture.asset(
                "assets/icons/postActions/forward-fill.svg",
                color: currentBrightness == Brightness.dark
                    ? actionIconColorDark
                    : actionIconColorLight,
                width: suSetWidth(26.0),
              ),
              label: SizedBox(
                width: suSetWidth(40.0),
                child: Text(
                  forwards == 0 ? "" : "$forwards",
                  style: TextStyle(
                    color: currentBrightness == Brightness.dark
                        ? actionTextColorDark
                        : actionTextColorLight,
                    fontSize: suSetSp(18.0),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              splashColor: Theme.of(context).cardColor,
              highlightColor: Theme.of(context).cardColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget getPostBanned(String type) {
    String content = "该条微博已被";
    switch (type) {
      case "shield":
        content += "屏蔽";
        break;
      case "delete":
        content += "删除";
        break;
    }
    return Selector<ThemesProvider, bool>(
      selector: (_, provider) => provider.dark,
      builder: (_, dark, __) {
        return Container(
          color: dark ? Colors.grey[600] : Colors.grey[400],
          padding: EdgeInsets.symmetric(vertical: suSetHeight(20.0)),
          child: Center(
            child: Text(
              content,
              style: TextStyle(
                color: Colors.grey[dark ? 350 : 50],
                fontSize: suSetSp(22.0),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget getExtendedText(content, {isRoot}) {
    return GestureDetector(
      onLongPress: widget.isDetail
          ? () {
              Clipboard.setData(ClipboardData(text: content));
              showToast("已复制到剪贴板");
            }
          : null,
      child: Padding(
        padding: (isRoot ?? false)
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(
                horizontal: suSetWidth(contentPadding),
              ),
        child: ExtendedText(
          content != null ? "$content " : null,
          style: TextStyle(fontSize: suSetSp(21.0)),
          onSpecialTextTap: specialTextTapRecognizer,
          maxLines: widget.isDetail ?? false ? null : 8,
          overFlowTextSpan: widget.isDetail ?? false
              ? null
              : OverFlowTextSpan(
                  children: <TextSpan>[
                    TextSpan(text: " ... "),
                    TextSpan(
                      text: "全文",
                      style: TextStyle(color: currentThemeColor),
                    ),
                  ],
                ),
          specialTextSpanBuilder: StackSpecialTextSpanBuilder(),
        ),
      ),
    );
  }

  Future<bool> onLikeButtonTap(bool isLiked) {
    final Completer<bool> completer = Completer<bool>();
    int id = widget.post.id;

    widget.post.isLike = !widget.post.isLike;
    !isLiked ? widget.post.praises++ : widget.post.praises--;
    completer.complete(!isLiked);

    PraiseAPI.requestPraise(id, !isLiked).catchError((e) {
      isLiked ? widget.post.praises++ : widget.post.praises--;
      completer.complete(isLiked);
      return completer.future;
    });

    return completer.future;
  }

  Widget get deleteButton => IconButton(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).dividerColor,
          size: suSetWidth(24.0),
        ),
        onPressed: () => confirmDelete(context),
      );

  Widget get postActionButton => IconButton(
        icon: Icon(
          Icons.expand_more,
          color: Theme.of(context).dividerColor,
          size: suSetWidth(30.0),
        ),
        onPressed: () => postExtraActions(context),
      );

  void confirmDelete(context) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: '删除动态',
      content: '是否确认删除这条动态?',
      showConfirm: true,
    );
    if (confirm) {
      final _loadingDialogController = LoadingDialogController();
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => LoadingDialog(
          text: '正在删除动态',
          controller: _loadingDialogController,
          isGlobal: false,
        ),
      );
      PostAPI.deletePost(widget.post.id).then((response) {
        _loadingDialogController.changeState('success', '动态删除成功');
        Instances.eventBus.fire(PostDeletedEvent(widget.post.id, widget.fromPage, widget.index));
      }).catchError((e) {
        debugPrint(e.toString());
        debugPrint(e.response?.toString());
        _loadingDialogController.changeState('failed', '动态删除失败');
      });
    }
  }

  Widget _postActionListTile({
    @required IconData icon,
    @required String text,
    @required GestureTapCallback onTap,
  }) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: suSetHeight(24.0)),
          child: Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: suSetWidth(10.0)),
                child: Icon(icon, size: suSetWidth(36.0)),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: suSetWidth(10.0)),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.body1.copyWith(fontSize: suSetSp(22.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  List<Widget> postExtraActionsBuilder({
    @required List<IconData> icons,
    @required List<String> texts,
    @required List<GestureTapCallback> onTaps,
  }) {
    assert(
      icons?.length == texts?.length &&
          icons?.length == onTaps?.length &&
          texts?.length == onTaps?.length,
      'items length must be equal.',
    );
    return List<Widget>.generate(
      texts.length * 2 - 1,
      (i) {
        if (i.isEven) {
          final index = i ~/ 2;
          return _postActionListTile(
            icon: icons.elementAt(index),
            text: texts.elementAt(index),
            onTap: onTaps.elementAt(index),
          );
        } else {
          return Container(
            margin: EdgeInsets.only(left: suSetWidth(64.0)),
            child: Divider(
              color: Theme.of(context).canvasColor,
              height: suSetHeight(1.0),
              thickness: suSetHeight(1.0),
            ),
          );
        }
      },
    );
  }

  void postExtraActions(context) {
    ConfirmationBottomSheet.show(
      context,
      children: postExtraActionsBuilder(
        icons: <IconData>[Icons.visibility_off, Icons.report],
        texts: <String>['屏蔽此人', '举报动态'],
        onTaps: <GestureTapCallback>[() => confirmBlock(context), () => confirmReport(context)],
      ),
    );
  }

  void confirmBlock(context) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: '屏蔽此人',
      content: '确定屏蔽此人吗',
      showConfirm: true,
    );
    if (confirm) {
      UserAPI.fAddToBlacklist(uid: widget.post.uid, name: widget.post.nickname);
    }
  }

  void confirmReport(context) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: '举报动态',
      content: '确定举报该条动态吗?',
      showConfirm: true,
    );
    if (confirm) {
      final provider = Provider.of<ReportRecordsProvider>(context, listen: false);
      final canReport = await provider.addRecord(widget.post.id);
      if (canReport) {
        PostAPI.reportPost(widget.post);
        showToast("举报成功");
        navigatorState.pop();
      }
    }
  }

  void pushToDetail() {
    navigatorState.pushNamed(
      Routes.OPENJMU_POST_DETAIL,
      arguments: {
        "post": widget.post,
        "index": widget.index,
        "fromPage": widget.fromPage,
        "parentContext": context,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return post.isShield && HiveFieldUtils.getEnabledHideShieldPost()
        ? SizedBox.shrink()
        : GestureDetector(
            onTap: widget.isDetail || post.isShield ? null : pushToDetail,
            onLongPress: post.isShield ? pushToDetail : null,
            child: Container(
              margin: post.isShield || widget.isDetail
                  ? EdgeInsets.zero
                  : EdgeInsets.symmetric(
                      horizontal: suSetWidth(12.0),
                      vertical: suSetHeight(6.0),
                    ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(suSetWidth(10.0)),
                color: Theme.of(context).cardColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: !post.isShield
                    ? <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: suSetWidth(contentPadding),
                            vertical: suSetHeight(10.0),
                          ),
                          child: Row(
                            children: <Widget>[
                              UserAPI.getAvatar(uid: widget.post.uid),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: suSetWidth(contentPadding),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      getPostNickname(context, post),
                                      getPostInfo(post),
                                    ],
                                  ),
                                ),
                              ),
                              post.uid == UserAPI.currentUser.uid ? deleteButton : postActionButton,
                            ],
                          ),
                        ),
                        getPostContent(context, post),
                        getPostImages(context, post),
                        Container(
                          margin: EdgeInsets.only(top: suSetHeight(6.0)),
                          height: suSetHeight(44.0),
                          padding: EdgeInsets.only(left: suSetWidth(20.0)),
                          child: OverflowBox(
                            child: Row(
                              children: <Widget>[
                                Text(
                                  "浏览${post.glances}次　",
                                  style: Theme.of(context).textTheme.caption.copyWith(
                                        fontSize: suSetSp(18.0),
                                      ),
                                ),
                                Spacer(),
                                widget.isDetail
                                    ? SizedBox(height: suSetWidth(16.0))
                                    : postActions(context),
                              ],
                            ),
                          ),
                        ),
                      ]
                    : <Widget>[getPostBanned("shield")],
              ),
            ),
          );
  }
}
