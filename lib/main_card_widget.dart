import 'dart:math';

import 'package:drag_card/entity.dart';
import 'package:drag_card/orntdrag.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CardStackWidget extends StatefulWidget {
  final List<CardEntity> cardList;

  final int cardCount;
  final double offset;
  final EdgeInsetsGeometry cardPadding;

  const CardStackWidget(
      {Key key,
      this.cardList,
      this.cardCount = 2,
      this.offset = 10,
      this.cardPadding = const EdgeInsets.only(left: 20, right: 20, top: 60)})
      : assert(cardPadding != null),
        assert(cardCount != null),
        assert(offset != null),
        super(key: key);

  @override
  _CardStackWidgetState createState() => _CardStackWidgetState();
}

class _CardStackWidgetState extends State<CardStackWidget>
    with TickerProviderStateMixin {
  double _ratio = 0;
  double _totalDx;
  double _totalDy;
  Map<Type, GestureRecognizerFactory> _cardGestures;
  AnimationController _animationController;
  bool _isDragging = false;

  @override
  void initState() {
    _totalDx = _totalDy = 0;
    _cardGestures = {
      //方向手势
      DirectionGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<DirectionGestureRecognizer>(
              () => DirectionGestureRecognizer(DirectionGestureRecognizer.left |
                  DirectionGestureRecognizer.right |
                  DirectionGestureRecognizer.up), (instance) {
        instance.onDown = _onPanDown;
        instance.onUpdate = _onPanUpdate;
        instance.onEnd = _onPanEnd;
      }),
      //点击手势
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(), (instance) {
        instance.onTap = _onCardTap;
      })
    };
    super.initState();
  }

  _onCardTap() {
    if (widget.cardList != null && widget.cardList.length > 0) {
      Fluttertoast.showToast(msg: widget.cardList[0].text);
    }
  }

  _onPanDown(DragDownDetails details) {
    if (_isAnimating) {
      return;
    }
  }

  _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) {
      return;
    }
    if (!_isDragging) {
      _isDragging = true;
      return;
    }
    _totalDx += details.delta.dx;
    _totalDy += details.delta.dy;
    //计算
    _ratio =
        sqrt(_totalDx * _totalDx + _totalDy * _totalDy) / context.size.width;
    _ratio = min(max(_ratio, 0), 1.0);
    setState(() {});
  }

  _onPanEnd(DragEndDetails details) {
    if (_isAnimating) {
      return;
    }
    _isDragging = false;
    if (_totalDx.abs() >= context.size.width * 0.1 ||
        _totalDy.abs() >= context.size.height * 0.1) {
      double endX, endY;
      if (_totalDx.abs() > _totalDy.abs()) {
        endX = context.size.width * _totalDx.sign;
        endY = _totalDy.sign *
            context.size.width *
            _totalDy.abs() /
            _totalDx.abs();
      } else {
        endY = context.size.height * _totalDy.sign;
        endX = _totalDx.sign *
            context.size.height *
            _totalDx.abs() /
            _totalDy.abs();
      }
      _startAnimator(Offset(_totalDx, _totalDy), Offset(endX, endY), true);
    } else {
      _startAnimator(Offset(_totalDx, _totalDy), Offset.zero, false);
    }
  }

  bool get _isAnimating =>
      _animationController != null && _animationController.isAnimating;

  _startAnimator(Offset begin, Offset end, bool remove) {
    _animationController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    var _animation = Tween(begin: begin, end: end).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.linear));
    _animationController.addListener(() {
      setState(() {
        _totalDx = _animation.value.dx;
        _totalDy = _animation.value.dy;
        _ratio = sqrt(_totalDx * _totalDx + _totalDy * _totalDy) /
            context.size.width;
        _ratio = min(max(_ratio, 0), 1.0);
      });
    });
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (remove) {
          widget.cardList.removeAt(0);
        }
        _totalDx = 0;
        _totalDy = 0;
        _ratio = 0;
        setState(() {});
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    if (_animationController != null) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cardList == null || widget.cardList.length == 0) {
      return Container();
    }

    List<Widget> children = new List();
    int length = widget.cardList.length;
    int count = (length > widget.cardCount) ? widget.cardCount : length;
    for (int i = 0; i < count; i++) {
      double dx = i == 0 ? _totalDx : -_ratio * widget.offset;
      double dy = i == 0 ? _totalDy : _ratio * widget.offset;
      Widget cardWidget = _CardWidget(
        cardEntity: widget.cardList[i],
        position: i,
        dx: dx,
        dy: dy,
        offset: widget.offset,
      );
      if (i == 0) {
        cardWidget = RawGestureDetector(
          gestures: _cardGestures,
          //手势行为
          behavior: HitTestBehavior.deferToChild,
          child: cardWidget,
        );
      }
      children.add(Container(
        child: cardWidget,
        alignment: Alignment.topCenter,
        padding: widget.cardPadding,
      ));
    }
    return Stack(
      children: children.reversed.toList(),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final CardEntity cardEntity;
  final int position;
  final double dx;
  final double dy;
  final double offset;

  const _CardWidget(
      {Key key,
      this.cardEntity,
      this.position,
      this.dx = 0,
      this.dy = 0,
      this.offset})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //比例
    return AspectRatio(
      aspectRatio: 0.75,
      child: Transform(
          transform: Matrix4.translationValues(
              dx + (offset * position.toDouble()),
              dy + (-offset * position.toDouble()),
              0),
          child: ClipRRect(
            //圆角
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                //底部图片
                Image.network(
                  cardEntity.picUrl,
                  fit: BoxFit.cover,
                ),
                //设置颜色的
                Container(color: const Color(0x5a000000)),
                //文字
                Container(
                  margin: EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Text(
                    cardEntity.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        letterSpacing: 2,
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                    maxLines: 4,
                  ),
                )
              ],
            ),
          )),
    );
  }
}
