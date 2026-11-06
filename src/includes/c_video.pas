{ The display hardware: the video BIOS's set-mode function, and display memory. }
unit C_Video;

interface

const
  { the video BIOS function that sets the mode in AL: Blit's SetVideoMode and GameIo's ExitGame }
  BIOS_SET_VIDEO_MODE = 0;
  { the segment of EGA and VGA display memory, EGA page 0: Blit's screen copies, TextRend's EGA pages }
  EGA_VIDEO_SEG = $A000;
  { VGA display memory as a far pointer: Border's ClearBox and TextRend's FillRect fill through it }
  VGA_BASE = $A0000000;

implementation

end.
