import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const run = promisify(execFile);

/** Windows equivalent of owner-only 0700, using SIDs rather than localized names. */
export async function windowsPrivateDirectory(directory: string, initialize: boolean): Promise<void> {
  return verifyWindowsPath(directory, initialize, true);
}

export async function windowsPrivateFile(path: string): Promise<void> {
  return verifyWindowsPath(path, false, false);
}

async function verifyWindowsPath(directory: string, initialize: boolean, protectedAcl: boolean): Promise<void> {
  const script = `
$ErrorActionPreference = 'Stop'
$path = $env:SUPPLYBIZ_PRIVATE_DIRECTORY
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
if ((Get-Item -LiteralPath $path -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
  throw 'Reparse points are forbidden'
}
if ($env:SUPPLYBIZ_INITIALIZE_DIRECTORY -eq '1') {
  $security = New-Object System.Security.AccessControl.DirectorySecurity
  $security.SetOwner($user)
  $security.SetAccessRuleProtection($true, $false)
  $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($user, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
  $security.AddAccessRule($rule)
  Set-Acl -LiteralPath $path -AclObject $security
}
$acl = Get-Acl -LiteralPath $path
if (($env:SUPPLYBIZ_PROTECTED_ACL -eq '1' -and !$acl.AreAccessRulesProtected) -or $acl.GetOwner([System.Security.Principal.SecurityIdentifier]).Value -ne $user.Value) {
  throw 'Private directory ownership/inheritance required'
}
$allowed = @($user.Value, 'S-1-5-18', 'S-1-5-32-544')
$rules = $acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])
foreach ($rule in $rules) {
  if ($rule.AccessControlType -eq 'Allow' -and $rule.IdentityReference.Value -notin $allowed) {
    throw 'Private directory grants access to another principal'
  }
}
`;
  try {
    await run('powershell.exe', ['-NoProfile', '-NonInteractive', '-EncodedCommand',
      Buffer.from(script, 'utf16le').toString('base64')], {
      windowsHide: true, timeout: 15000, maxBuffer: 65536,
      env: { ...process.env, SUPPLYBIZ_PRIVATE_DIRECTORY: directory,
        SUPPLYBIZ_PROTECTED_ACL: protectedAcl ? '1' : '0',
        SUPPLYBIZ_INITIALIZE_DIRECTORY: initialize ? '1' : '0' },
    });
  } catch {
    // Child errors can contain filesystem/account details; fail closed without logging them.
    throw new Error('Upload paths require service ownership and private Windows ACLs');
  }
}
