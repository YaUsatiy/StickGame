proc Screen.SetTextMode
     mov	ah, $0F
     int	10h
     mov	[Screen.bOldMode], al
     mov	[Screen.bOldPage], bh

     mov	ax, $0003
     int	10h
     ret
endp

proc Screen.RestoreMode
     movzx	ax, [Screen.bOldMode]
     int	10h

     mov	ah, $05
     mov	al, [Screen.bOldPage]
     int	10h
     ret
endp

proc Screen.Clear uses es di
     push	  $B800
     pop	  es
     xor	  di, di
     mov	  cx, 80 * 25
     mov	  ax, $0700 or ' '
     rep stosw
     ret
endp

proc Screen.WriteString uses es si di,\
     pstrText, iRow, alType

     mov	si, [pstrText]
     lodsb
     movzx	cx, al
     jcxz	.EndProc
     cmp	cx, 80
     ja 	.EndProc

     mov	ax, [alType]
     cmp	ax, ALIGN_LEFT
     je 	.AlignLeft
     cmp	ax, ALIGN_CENTER
     je 	.AlignCenter
     cmp	ax, ALIGN_RIGHT
     je 	.AlignRight
     jmp	.EndProc

.AlignLeft:
     xor	ax, ax
     jmp	.WriteString
.AlignCenter:
     mov	ax, 80
     sub	ax, cx
     shr	ax, 1
     jmp	.WriteString
.AlignRight:
     mov	ax, 80
     sub	ax, cx

.WriteString:
     mov	di, 80
     imul	di, [iRow]
     add	di, ax
     shl	di, 1
     push	$B800
     pop	es
     mov	ax, $0700
.WriteLoop:
     lodsb
     stosw
     loop	.WriteLoop

.EndProc:
     ret
endp