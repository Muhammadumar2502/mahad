// Islamic-styled icon set (assets/icons/*.svg, stroke = currentColor). Meanings map 1:1 to the
// Iconsax icons used today — see design/DESIGN_SYSTEM.md › Ikonkalar.
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MahadIcons {
  MahadIcons._();
  static const _p = 'assets/icons/';
  static const home = '${_p}home.svg'; // home_2
  static const books = '${_p}books.svg'; // book_1 (tab)
  static const heart = '${_p}heart.svg'; // heart
  static const heartFill = '${_p}heart_fill.svg'; // heart_copy
  static const profile = '${_p}profile.svg'; // profile_circle
  static const search = '${_p}search.svg'; // search_normal_1
  static const close = '${_p}close.svg'; // close_circle
  static const back = '${_p}back.svg'; // arrow_left_2
  static const chevronRight = '${_p}chevron_right.svg'; // arrow_right_3
  static const chevronDown = '${_p}chevron_down.svg'; // arrow_down_1
  static const chevronUp = '${_p}chevron_up.svg'; // arrow_up_2
  static const hourglass = '${_p}hourglass.svg'; // timer_1 / clock
  static const trophy = '${_p}trophy.svg'; // cup / cup_copy
  static const manuscript = '${_p}manuscript.svg'; // book_1 (section)
  static const lock = '${_p}lock.svg'; // lock_1
  static const clipboardTick = '${_p}clipboard_tick.svg'; // clipboard_tick
  static const clipboardText = '${_p}clipboard_text.svg'; // clipboard_text
  static const shuffle = '${_p}shuffle.svg'; // shuffle
  static const document = '${_p}document.svg'; // document_text
  static const play = '${_p}play_fill.svg'; // play
  static const refresh = '${_p}refresh.svg'; // refresh
  static const wifi = '${_p}wifi.svg'; // wifi_square
  static const calendar = '${_p}calendar.svg'; // calendar / calendar_1
  static const calendarTick = '${_p}calendar_tick.svg'; // calendar_tick
  static const question = '${_p}question.svg'; // message_question
  static const people = '${_p}people.svg'; // people
  static const mobile = '${_p}mobile.svg'; // mobile
  static const logout = '${_p}logout.svg'; // logout
  static const trash = '${_p}trash.svg'; // trash
  static const eye = '${_p}eye.svg'; // eye
  static const eyeSlash = '${_p}eye_slash.svg'; // eye_slash
  static const import_ = '${_p}import.svg'; // import / import_1
  static const arrowRight = '${_p}arrow_right.svg'; // arrow_right_1
  static const task = '${_p}task.svg'; // task
  static const filterRemove = '${_p}filter_x.svg'; // filter_remove
  static const note = '${_p}note.svg'; // note_1
  static const searchStatus = '${_p}search_status.svg'; // search_status
  static const check = '${_p}check.svg';
  static const tickCircle = '${_p}tick_circle.svg'; // tick_circle
  static const taskSquare = '${_p}task_square.svg'; // task_square
  static const timerStart = '${_p}timer_start.svg'; // timer_start
  static const timerPause = '${_p}timer_pause.svg'; // timer_pause
  static const medal = '${_p}medal.svg'; // medal_star_copy
  static const bookSmall = '${_p}book_small.svg'; // book
  static const info = '${_p}info.svg'; // info_circle
  static const danger = '${_p}danger.svg'; // danger
  static const star = '${_p}star_fill.svg'; // star_1 (filled octagram)
  static const starOutline = '${_p}star_outline.svg'; // star
  static const starMedallion = '${_p}star_medallion.svg'; // Maxsus tile icon
  static const moon = '${_p}moon.svg'; // NEW: Tungi rejim
}

class MahadIcon extends StatelessWidget {
  const MahadIcon(this.asset, {super.key, this.size = 22, this.color});

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final col = color ?? IconTheme.of(context).color;
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: col == null ? null : ColorFilter.mode(col, BlendMode.srcIn),
    );
  }
}
