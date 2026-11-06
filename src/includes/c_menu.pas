{ Menu choices: the yes/no prompt's default, the choices a menu starts on, no skill line clicked, and the fields of
  CharGen's character modify menu. }
unit C_Menu;

interface

const
  { YesNoMenu's defaultChoice: Yes selected first }
  DEFAULT_YES = 1;
  { No selected first }
  DEFAULT_NO = 2;
  { set in menuChecksum, makes the next MenuHorizontal keep horizontalChoice even when its menu differs from the last
    one }
  KEEP_MENU_CHOICE = 255;
  { a horizontalChoice that starts ViewChar's UseItemMenu on the option after Join: Sell in a shop }
  SELL_CHOICE = 255;
  { clickedSkillLine when no click on the skill screen is pending: MenuCore's MenuHorizontal sets it for a click
    elsewhere, and Skills' EditSkills once it has taken the line }
  NO_SKILL_LINE = -1;
  { the fields of CharGen's ModifyCharacterMenu, 0..6 the abilities, as modifyFieldSelection holds them }
  { the name, row 1 from column 8 }
  MODIFY_NAME_FIELD = 7;
  { the hit-point maximum, row 1 from column 31 }
  MODIFY_HIT_POINTS_FIELD = 8;

implementation

end.
