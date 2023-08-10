import 'package:flutter/material.dart';
enum ScoredBy {
  cross,
  zero,
}


class LocalPlayerScreen extends StatefulWidget {
  const LocalPlayerScreen({super.key});

  @override
  State<LocalPlayerScreen> createState() => _LocalPlayerScreenState();
}

class _LocalPlayerScreenState extends State<LocalPlayerScreen> {
  final _scoredList = List<ScoredBy?>.filled(9, null);
  List<ScoredBy?> get scoredList => List.unmodifiable(_scoredList);
  var _whoseTurn = ScoredBy.cross;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mainCrossExtend = size.width * 0.75;
    return WillPopScope(
      onWillPop: () {
        return Future.value(true);
      },
      child: NotificationListener<SelectedNotification>(
        onNotification: (value){
          if(_scoredList[value.index]!=null)return true;
          _scoredList[value.index]=_whoseTurn;
          _whoseTurn=_whoseTurn==ScoredBy.cross?ScoredBy.zero:ScoredBy.cross;
          return true;
        },
        child: Scaffold(
          body: Center(
              child: SizedBox(
            height: mainCrossExtend,
            width: mainCrossExtend,
            child: Column(
              children: [
                for (int column = 0; column < 3; column++)
                  Expanded(
                    child: Row(
                      children: [
                        for (int row = 0; row < 3; row++)
                          Expanded(
                            child: _SingleItem(
                              scoredList: _scoredList,
                              index: column * 3 + row,
                            ),
                          )
                      ],
                    ),
                  )
              ],
            ),
          )),
        ),
      ),
    );
  }
}

class _SingleItem extends StatefulWidget {
  final int index;
  final List<ScoredBy?> scoredList;

  const _SingleItem({
    super.key,
    required this.index,
    required this.scoredList,
  });

  @override
  State<_SingleItem> createState() => _SingleItemState();
}

class _SingleItemState extends State<_SingleItem> {
  @override
  Widget build(BuildContext context) {
    final scoredBy=widget.scoredList[widget.index];
    return GestureDetector(
      onTap: () {
        SelectedNotification(widget.index).dispatch(context);
        Future.delayed(Duration.zero,(){
          setState(() {

          });
        });
      },
      child: Container(
          color: widget.index % 2 == 0 ? Colors.red : Colors.yellow,
          height: double.infinity,
          width: double.infinity,
          child: switch (scoredBy) {
            ScoredBy.cross => const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ScoredBy.zero => const Icon(
                Icons.done,
                color: Colors.white,
              ),
            _ => const SizedBox(),
          }),
    );
  }
}

class SelectedNotification extends Notification{
  int index;
  SelectedNotification(this.index);
}