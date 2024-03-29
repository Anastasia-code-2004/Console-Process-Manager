format PE64 Console 4.0
entry Start

include 'win64wx.inc'

   section '.code' executable
Start:
        invoke CreateToolhelp32Snapshot, 2, 0
        mov [handle_snap], eax
        mov [pe32.size], sizeof.PROCESSENTRY32
        invoke Process32First, [handle_snap], pe32
         
       
FindNext:
 cmp eax, 0
 je Exit

invoke printf, pe32.FileName
invoke printf, newline
invoke printf, newline

invoke printf, ID, [pe32.processID]
invoke printf, newline
 
invoke OpenProcess, PROCESS_QUERY_INFORMATION, FALSE, [pe32.processID]
mov [processHandle], eax

        
invoke GetProcessMemoryInfo, [processHandle], memCounter, 40
xor eax, eax
mov eax, [memCounter.WorkingSetSize]
shr eax, 10
invoke printf, usage, eax
invoke printf, newline
        
        
invoke GetProcessTimes, [processHandle], creationTime, exitTime, kernelTime, userTime
invoke FileTimeToSystemTime, creationTime, systemCreationTime
        
xor eax, eax
xor ebx, ebx
xor ecx, ecx

movzx eax, word [systemCreationTime]      ; Year
movzx ebx, word [systemCreationTime + 2]  ; Month 
movzx ecx, word [systemCreationTime + 6]  ; Day 
        
invoke printf, date, ecx, ebx, eax
invoke printf, newline
 
xor eax, eax
xor ebx, ebx
xor ecx, ecx 
 
movzx eax, word [systemCreationTime + 8]       ; Hour
cmp eax, 0
jne Sub_nine
Here:
  movzx ebx, word [systemCreationTime + 10]   ; Minute
  movzx ecx, word [systemCreationTime + 12]   ; Second

  invoke printf, timeFormat, eax, ebx, ecx
  invoke printf, newline
  
  invoke OpenProcess, PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, [pe32.processID]
  mov [processHandle], eax
  invoke GetModuleFileNameExA, [processHandle], 0, filename_buffer, 260
  
    cmp dword [filename_buffer], 0
    je NoFilePath
    jne YesFilePath
NoFilePath:
    invoke printf, fileNo
    jmp The_NEXT 
YesFilePath:
    invoke printf, filePath, filename_buffer, 0
    
The_NEXT:
    invoke GetExitCodeProcess, [processHandle], exitCode
    cmp eax, 0
    je Failure_get_exitCODE 
    cmp dword [exitCode], STILL_ACTIVE
    je ProcessIsRunning
    jne ProcessIsNotRunning
    
Failure_get_exitCODE:
    invoke printf, newline
    invoke printf, failure
    jmp Continue
 
ProcessIsRunning:
    invoke printf, newline
    invoke printf, processStatus_run, [exitCode]
    jmp Continue

ProcessIsNotRunning:
    invoke printf, newline
    invoke printf, processStatus_no_run, [exitCode]
    
Continue:
invoke printf, newline
invoke printf, newline
invoke Process32Next, [handle_snap], pe32
inc dword [counter]
jmp FindNext

Exit:
    invoke getch
    invoke ExitProcess, 0
 
Sub_nine:
    sub eax, 8
    jmp Here
    
section '.data' readable writable

        
        newline db 10, 0
        usage db '---Usage of memory: %u KB', 0
        ID db 'ID: %d', 0  
        handle_snap dd NULL     ; descriptor
        date db 'Creation Date: %02u/%02u/%02u', 0
        
        filePath db 'File path: %s', 0
        fileNo db 'No path!', 0
        filename_buffer rb 260
        
        processHandle dd ?
        
        timeFormat db 'Time: %02u:%02u:%02u', 0
        
        processStatus_run db 'Process status: still active, exit code:  %u', 0
        processStatus_no_run db 'Process status: no run, exit code:  %u', 0
        exitCode dd 0
        failure db 'Failure to get exit code', 0 
        systemCreationTime SYSTEMTIME <>
        
        creationTime FILETIME <>
        exitTime FILETIME <>
        kernelTime FILETIME <>
        userTime FILETIME <> 
 
struct PROCESSENTRY32
   size                 dd ?
   usage                dd ?
   processID            dd ?
   defaultHeapID        dd ?
   moduleID             dd ?
   threads              dd ?
   parentProcessID      dd ?
   priClassBase         dd ?
   flags                dd ?
   FileName             rb 260d
ends

struct PROCESS_MEMORY_COUNTERS 
   cb                             dd ?
   PageFaultCount                 dd ?
   PeakWorkingSetSize             dd ?
   WorkingSetSize                 dd ?
   QuotaPeakPagedPoolUsage        dd ?
   QuotaPagedPoolUsage            dd ?
   QuotaPeakNonPagedPoolUsage     dd ?
   QuotaNonPagedPoolUsage         dd ?
   PagefileUsage                  dd ?
   PeakPagefileUsage              dd ?
ends

struct Information_Processes
   ProcessID                  dd ?
   MemoryUsage                dd ?
   AbilityExit                db ?
   FileName                   rb 260d
ends

        pe32 PROCESSENTRY32 ?
        memCounter PROCESS_MEMORY_COUNTERS <>
        InfoArray Information_Processes 1000
        counter dd 0 

section '.idata' import readable

        library advapi32,'ADVAPI32.DLL',kernel32,'KERNEL32.DLL',shlwapi,'shlwapi.dll',shell32,'SHELL32.DLL',user32,'USER32.DLL', msvcrt, 'msvcrt.dll', psapi, 'PSAPI.DLL'
        
        import msvcrt,\
  				printf, 'printf',\
          getch, '_getch'
        import psapi,\
  				GetProcessMemoryInfo, 'GetProcessMemoryInfo',\
          QueryFullProcessImageNameA, 'QueryFullProcessImageNameA',\
          GetModuleFileNameExA, 'GetModuleFileNameExA'
        include '%fasm%\api\advapi32.inc'
        include '%fasm%\api\kernel32.inc'
        include '%fasm%\api\shell32.inc'
        include '%fasm%\api\user32.inc'