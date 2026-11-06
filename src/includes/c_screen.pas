{ The text screen: its status row, its width in columns, and the end of a frame script. }
unit C_Screen;

interface

const
  { the text screen's bottom row, the status line: TextRend shows its prompts and messages there, and Money's
    InputNumberMax reads a number there }
  STATUS_ROW = 24;
  { text columns across the screen: TextRend and Money blank the status line that wide }
  TEXT_COLUMNS = 40;
  { the byte that ends one of Border's frame scripts, the runs of border tiles that lay out a screen, in place of a
    run's x1 }
  FRAME_SCRIPT_END = 254;

implementation

end.
