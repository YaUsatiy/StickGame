        include 'macro\proc16.inc'

struc String Params&
{
  local ..Length
  . db ..Length, Params
  ..Length = $ - . - 1
}

Game.MinSticks  = 15
Game.MaxSticks  = 40
Game.MinMove    = 1
Game.MaxMove    = 3

        org 100h

        include 'Units\Random.h'
        include 'Units\Screen.h'
        include 'Units\Keyboard.h'

FALSE           = 0
TRUE            = 1

PLAYER_COMPUTER = 0
PLAYER_USER     = 1

EntryPoint:
        stdcall Random.Initialize
        stdcall Screen.SetTextMode

        stdcall GameModel.NewGame

.GameLoop:
        stdcall Keyboard.ReadKey
        stdcall GameController.ProcessKey, ax
        test    ax, ax
        jnz     .GameLoop

        stdcall Screen.RestoreMode
        ret

proc GameController.ProcessKey\
     wKey

     cmp        [wKey], VK_ESCAPE
     je         .ReturnFALSE

     stdcall    GameModel.IsGameOver
     test       ax, ax
     jnz        .ReturnFALSE

     stdcall    GameModel.WhoMoves
     cmp        ax, PLAYER_USER
     je         .UserMove
.ComputerMove:
     stdcall    GameModel.MakeComputerMove
     jmp        .Done
.UserMove:
     mov        ax, [wKey]
     sub        ax, '0'
     cmp        ax, 1
     jb         .Done
     cmp        ax, 3
     ja         .Done
     stdcall    GameModel.MakeUserMove, ax
.Done:
     mov        ax, TRUE
     jmp        .EndProc

.ReturnFALSE:
     xor        ax, ax
.EndProc:
     ret
endp

proc GameView.Update
     stdcall    Screen.Clear

     push       $B800
     pop        es
     stdcall    GameModel.GetSticksInitial
     mov        di, 80
     sub        di, ax
     shr        di, 1
     add        di, 80 * 12
     shl        di, 1
     stdcall    GameModel.GetSticksLeft
     mov        cx, ax
     mov        ax, $0700 or '|'
     rep stosw

     stdcall    GameModel.IsGameOver
     test       ax, ax
     jnz        .GameOver
     stdcall    GameModel.WhoMoves
     cmp        ax, PLAYER_COMPUTER
     je         .ComputerMove
.UserMove:
     mov        ax, strUserMove
     jmp        .WriteString
.ComputerMove:
     stdcall    GameModel.GetComputerMove
     add        al, '0'
     mov        [bComputerMove], al
     mov        ax, strComputerMove
     jmp        .WriteString

.GameOver:
     stdcall    GameModel.WhoWon
     cmp        ax, PLAYER_COMPUTER
     je         .ComputerWon
.UserWon:
     mov        ax, strUserWon
     jmp        .WriteString
.ComputerWon:
     mov        ax, strComputerWon

.WriteString:
     stdcall    Screen.WriteString, ax, 15, ALIGN_CENTER
     ret
endp

proc GameModel.NewGame
     stdcall    Random.Get, Game.MinSticks, Game.MaxSticks
     mov        [GameModel.nSticksLeft], ax
     mov        [GameModel.nSticksInitial], ax
     mov        [GameModel.plNext], PLAYER_USER
     stdcall    GameView.Update
     ret
endp

proc GameModel.ComputerChooseSticks
     ; Костыль!!! Исправить Random.Get при nMinValue > nMaxValue
     stdcall    GameModel.IsGameOver
     test       ax, ax
     jnz        .EndProc

     mov        ax, [GameModel.nSticksLeft]
     dec        ax
     and        ax, 0000'0000_0000'0011b
     jnz        .Done

     mov        ax, [GameModel.nSticksLeft]
     cmp        ax, Game.MaxMove
     jbe        @F
     mov        ax, Game.MaxMove
@@:
     stdcall    Random.Get, Game.MinMove, ax

.Done:
     mov        [GameModel.nNextMove], ax
.EndProc:
     ret
endp

proc GameModel.MakeMove\
     nCount

     mov        ax, [nCount]
     cmp        ax, Game.MinMove
     jb         .EndProc
     cmp        ax, Game.MaxMove
     ja         .EndProc
     cmp        ax, [GameModel.nSticksLeft]
     ja         .EndProc

     sub        [GameModel.nSticksLeft], ax
     xor        [GameModel.plNext], 1

.EndProc:
     ret
endp

proc GameModel.MakeComputerMove
     stdcall    GameModel.MakeMove, [GameModel.nNextMove]
     stdcall    GameView.Update
     ret
endp

proc GameModel.MakeUserMove\
     nCount

     stdcall    GameModel.MakeMove, [nCount]
     stdcall    GameModel.ComputerChooseSticks
     stdcall    GameView.Update
     ret
endp

proc GameModel.IsGameOver
     xor        ax, ax
     cmp        [GameModel.nSticksLeft], ax
     sete       al
     ret
endp

proc GameModel.WhoMoves
     mov        ax, [GameModel.plNext]
     ret
endp

GameModel.WhoWon = GameModel.WhoMoves

proc GameModel.GetSticksLeft
     mov        ax, [GameModel.nSticksLeft]
     ret
endp

proc GameModel.GetSticksInitial
     mov        ax, [GameModel.nSticksInitial]
     ret
endp

proc GameModel.GetComputerMove
     mov        ax, [GameModel.nNextMove]
     ret
endp

        include 'Units\Random.c'
        include 'Units\Screen.c'
        include 'Units\Keyboard.c'

strUserMove             String  'Your turn. Press 1, 2 or 3.'
strUserWon              String  'You''ve won, cheater!..'
strComputerWon          String  'Ha-ha! I''ve won, loser!'

strComputerMove         db      strComputerMove.Length, 'I take '
bComputerMove           db      ?
                        db      '.'
strComputerMove.Length = $ - strComputerMove - 1

        include 'Units\Random.di'
        include 'Units\Screen.di'
        include 'Units\Keyboard.di'

GameModel.nSticksLeft           dw      ?
GameModel.nSticksInitial        dw      ?
GameModel.plNext                dw      ?
GameModel.nNextMove             dw      ?

        include 'Units\Random.du'
        include 'Units\Screen.du'
        include 'Units\Keyboard.du'