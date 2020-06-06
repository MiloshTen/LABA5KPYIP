.model small

.stack 100h 

.data
    fileName db 30 dup(0) 
    outFileName db '\',13 dup(0),0 
    fileOpened db 'file opened', '$'
    fileDontOpened db 'can not open file', '$'
    fileid dw 0
    outFileid dw 0 
    n db 0
    numOfCurrentLine db 1
    symbol db 0 
    argsSize db ?
    args db 120 dup('$') 
    emptyArgs db 'bad cmd args', '$'
    error db 'error', '$'
    endedStr db 'programm ended', '$'
.code

outStr macro str
    mov ah, 09h
    mov dx, offset str
    int 21h
    
    mov dl, 0Ah             
	mov ah, 02h           
	int 21h 
	
	mov dl, 0Dh             
	mov ah, 02h             
	int 21h     
endm

stepBack macro
    mov ah, 42h
    mov al, 1
    mov cx, 0
    mov dx, 0
    mov bx, fileid
    int 21h
    jc basicError
    mov cx, dx
    mov dx, ax
    dec dx
    mov ah, 42h
    mov al, 0
    mov bx, fileid
    int 21h
    jc basicError
endm
 
readSymbol proc 
    pusha
startReading:
    mov dx, offset symbol
    mov bx, fileid
    mov cx, 1
    mov ah, 3Fh
    int 21h
    cmp ax, 0
    je clearCall
    jmp endReading
clearCall: 
    call clear
endReading:  
    popa  
    ret
readSymbol endp      

findlLineBeg proc
findLineBegStart:   
    call readSymbol
    cmp symbol, 0Dh
    je ifCR
    cmp symbol, 0Ah
    je lineEnded
    cmp symbol, 0h
    je lineEnded
    jmp writeToFile  
ifCR:
    call writeInFile
    inc numOfCurrentLine
    call readSymbol
    cmp symbol, 0Ah
    jne goBack
    jmp writeToFile
lineEnded:
    inc numOfCurrentLine
writeToFile:
    call writeInFile
    jmp endFinding
goBack:
    stepBack
endFinding:
    ret         
findlLineBeg endp 
    
skipLineProc proc
skipLineProcBegin:
    call readSymbol
    cmp symbol, 0Dh
    je ifCR_2
    cmp symbol, 0Ah
    je skipLineProcEnded
    cmp symbol, 0h
    je skipLineProcEnded
    jmp skipLineProcBegin
ifCR_2: 
    call readSymbol
    cmp symbol, 0Ah
    je skipLineProcEnded
    stepBack
skipLineProcEnded:      
    ret
skipLineProc endp

writeInFile proc
    pusha
    mov ah, 40h
    mov cx, 1
    mov bx, outFileid
    mov dx, offset symbol
    int 21h 
    popa 
    ret
writeInFile endp

processingArgs proc
    xor ax, ax
    xor bx, bx
    mov bl, 10
    xor cx, cx 
    mov si, offset args
processingArgsNum: 
    lodsb 
    cmp al, ' '
    je processingArgsNumEnd
    cmp al, '0'
    jb processingArgsError
    cmp al, '9'
    ja processingArgsNum
    sub al, '0'
    xchg ax, cx
    mul bl
    jo emptyArgsM  
    add ax, cx
    js emptyArgsM
    xchg ax, cx
    jmp processingArgsNum
processingArgsNumEnd:
    mov n, cl
    mov di, offset filename
processingArgsFilename:    
    cmp [si], 0Dh
    je processingEnded
    movsb
    jmp processingArgsFilename    
processingArgsError:
    outStr emptyArgs
    ret
processingEnded:
    ret               
processingArgs endp    

clear proc
clearM:    
    mov ah, 3Eh
    mov bx, fileid
    int 21h
    mov ah, 3Eh
    mov bx, outFileid
    int 21h
    mov ah, 41h
    mov dx, offset fileName
    int 21h
    mov ah, 56h
    mov dx, offset outFileName
    mov di, offset filename
    int 21h  
    jmp ended
clear endp    

start:
    mov ax, @data
    mov es, ax    
    xor cx, cx
	mov cl, ds:[80h]			
	mov argsSize, cl 		
	mov si, 82h
	mov di, offset args 
	rep movsb
	mov ds, ax
	call processingArgs    
    mov ax, 3D00h
    mov dx, offset fileName
    int 21h
    jc fileError 
    mov fileid, ax
    jnc opened 
    jmp ended
continue:      
    mov ah, 5Ah
    xor cx, cx
    mov cx, 7
    mov dx, offset outFileName
    int 21h
    mov outFileid, ax
    cmp n, 1
    je clearM
mainLoop:       
    call findlLineBeg
    mov bl, n
    cmp bl, numOfCurrentLine
    je skipLine
    jmp mainLoop    
skipLine:
    call skipLineProc
    mov numOfCurrentLine, 1
    jmp mainLoop
opened:
    outStr fileOpened
    jmp continue
emptyArgsM:
    outStr emptyArgs
    jmp ended
fileError:
    outStr fileDontOpened
    jmp ended
basicError:
    outStr error                              
ended:
    outStr endedStr
    mov ah, 4Ch
    int 21h
end start