import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class TextDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('test'),
      ),
//      body: MyRenderParagraph(),
      body: MongolText(
          'There is an overhead for the switch from native to dart. For cpu light operations, I suspect it is more efficient to just simply provide all the data at once than to perform multiple dart to native to dart operations. A method returning only the line number would in practice be almost the same overhead as returning all information about the line, and making two separate calls would almost certainly be much slower in terms of performance. \nThough this is not yet benchmarked, this generally seems to be the case. In any case, the idea is to somehow provide access to a vector of LineMetrics (or whatever the final name is), and a direct "get all the metrics" call seems to be the most straightforward way.\nAnother thing to consider is that the line number is actually used to perform layout, as I adapted LineMetrics from an existing internal class, so regardless, the line number is already there.\nI hope this is helpful and may give some insight into how this should end up working.美国从上世纪80年代就开始立法鼓励商业航天不同，\n中国民营企业长期以来一直难以涉足航天技术。直到2015年前后，国家政策才明确鼓励民营企业发展商业航天。在军民融合的政策放开背景下，民营航天公司在2015年后开始遍地开花。数十年来一直用国家力量推动的航天行业迎来了一股新鲜血液。\n过去几年，星际荣耀、蓝箭航天、零壹空间、翎客航天、深蓝航天、星途探索、星河动力、灵动飞天、九州云箭等一众民营火箭公司先后成立。中国民营火箭行业的发展呈现出了“火箭速度”，从公司数量和业务能力上都处于百花齐放的状态。',
          style: TextStyle(color: Colors.green, fontSize: 16)
      ),
    );
  }
}