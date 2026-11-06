{ Messages: the slowest message speed, and the window they are shown in. }
unit C_Msg;

interface

const
  { zone 0's highest messageSpeed, the slowest: Explore's CampSpeedMenu goes no higher, and FixMain's demo sets it }
  SLOWEST_MESSAGE_SPEED = 9;
  { the message window below the 3-D view, in text cells: Border's ScreenText makes it the text window, and EclVm's ECL
    text and menus and PostCbt's and Shop's leaving prompts use it }
  MESSAGE_LEFT = 1;
  MESSAGE_TOP = 17;
  MESSAGE_RIGHT = 38;
  MESSAGE_BOTTOM = 22;

implementation

end.
