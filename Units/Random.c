proc Random.Initialize
     mov	ah, $2C
     int	21h
     mov	[Random.wPrevNumber], dx
     ret
endp

proc Random.Get\
     nMinValue, nMaxValue

     xor	dx, dx
     mov	cx, [nMaxValue]
     sub	cx, [nMinValue]
     inc	cx
     ; TODO: Fix the case where nMinValue > nMaxValue

     mov	ax, [Random.wPrevNumber]
     rol	ax, 7
     add	ax, 23
     mov	[Random.wPrevNumber], ax

     div	cx
     add	dx, [nMinValue]
     mov	ax, dx

     ret
endp