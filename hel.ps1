# ---------------------------------------------------------------------------
# @file     hel.ps1
# @author   ���� <ykaidong@devlabs.cn>
# @version  0.2
# @date     2021-10-09
# @bref     �˽ű�������Windowsƽ̨�ϵ�PowerShell,  �����нű�ǰ��Ҫ��PowerShell��
#           ִ�� "Set-ExecutionPolicy RemoteSigned" �Ը��Ľű�ִ�в���
#           �˽ű����ڽ���ǰ�ļ������з�����������Ƶ�ļ�(��׺��λ�� $suffixs ��)
#           ת��ΪApple prores����ĵͷֱ����ļ��Ա��ڼ���
#           ���з����������ļ����ᱻת�뵽 ./$destdir �ļ�����
#           ���ұ���ԭ�����ļ��нṹ
# ----------------------------------------------------------------------------
# Change Logs:
# Date          Author          Notes
# 2021-09-12    ykaidong        ��ʼ�汾
# 2021-10-09    ykaidong        ��ת��С�ֱ�������ת������Ĺ��ܺϲ�
# ----------------------------------------------------------------------------
# @attention
#
# ----------------------------------------------------------------------------

# [0]��Ӧproxy, [1]��Ӧresize
$destdir = "proxy", "resize"     
$resolutions = "1280x720", "1920x1080"
$codecs = "prores_ks -profile:v standard -pix_fmt yuv422p10le", "libx264" 

$suffixs = "*.mov", "*.mp4", "*.mxf", "*.avi"

# ���Ե��ļ���, �������$destdir, �����ظ�ת��
$exclude = $destdir + ("04_�Ӿ�Ч��", "07_����")

# ----------------------------------------------------------------------------

$name1 = @"
 _          _           
| |        | |          
| |__   ___| |_ __  ___ 
| '_ \ / _ \ | '_ \/ __|
| | | |  __/ | |_) \__ \
|_| |_|\___|_| .__/|___/
             | |        
             |_|        
"@

$name2 = @"
      ___           ___           ___       ___           ___     
     /\__\         /\  \         /\__\     /\  \         /\  \    
    /:/  /        /::\  \       /:/  /    /::\  \       /::\  \   
   /:/__/        /:/\:\  \     /:/  /    /:/\:\  \     /:/\ \  \  
  /::\  \ ___   /::\~\:\  \   /:/  /    /::\~\:\  \   _\:\~\ \  \ 
 /:/\:\  /\__\ /:/\:\ \:\__\ /:/__/    /:/\:\ \:\__\ /\ \:\ \ \__\
 \/__\:\/:/  / \:\~\:\ \/__/ \:\  \    \/__\:\/:/  / \:\ \:\ \/__/
      \::/  /   \:\ \:\__\    \:\  \        \::/  /   \:\ \:\__\  
      /:/  /     \:\ \/__/     \:\  \        \/__/     \:\/:/  /  
     /:/  /       \:\__\        \:\__\                  \::/  /   
     \/__/         \/__/         \/__/                   \/__/    
"@


$title = @"

File name: hel.ps1
  Version: V0.2
     Date: 2021-10-09
 Descript: �˽ű����ڽ���ǰĿ¼�з�����������Ƶ�ļ�ת��Ϊ�����ļ�(Apple PreRes)
           ��С�ֱ��ʸ�ʽ(H.264), ��Ŵ����ļ���Ŀ��Ŀ¼Ϊ./$($destdir[0]), ���С�ֱ���
           ��Ŀ���ļ���Ϊ./$($destdir[1]), ����Ŀ���ļ����б���ԴĿ¼�ṹ.
-------------------------------------------------------------------------------

1. ת��Ϊ�����ļ�
2. ת��ΪС�ֱ����ļ�

"@


Write-Host $name2
Write-Host $title

# ����ѡ��
while ((1, 2) -notcontains $inputfun) {
    $inputfun = Read-Host "��ѡ��Ҫִ�еĲ���(1-2)"
}
# ƥ������(�����0��ʼ)
$inputfun = $inputfun - 1

# �ֱ������鳤��
$n = $resolutions.Length

# �ֱ���ѡ��
Write-Host ""
for ($i = 0; $i -le $n-1; $i++) {
    Write-Host (-join(($i + 1), ". ", $resolutions[$i]))
}

Write-Host ""
while ((1..$n) -notcontains $inputres) {
    $inputres = Read-Host "��ѡ��ֱ���(1-$n)"
}
$inputres = $inputres - 1

# ----------------------------------------------------------------------------

# �ű����е�Ŀ¼
$location = (Get-Location).Path

# ��ȡ $item �� Ŀ��Ŀ¼�ж�Ӧ��·��
function getproxy($item) 
{
    return ($item.FullName.Replace($location, (-join($location, "\", $destdir[$inputfun]))))
}


function encode($file) 
{
    if ($suffixs -contains $file.Extension.ToLower().Replace(".", "*.")) {  # �����׺����������
        $dest = getproxy($file)                                             # ��ȡ�����ļ����ж�Ӧ��λ��
        $dest = $dest -replace "\.+.*$", ".mov"                             # �滻��׺(��mov��װprores)
        if (-not (Test-Path $dest)) {                                       # ����ļ���������Ŀ��λ��
            $src = (-join('"', $file.FullName, '"'))                        # ��ʹ��FFMpeg����ת��
            $dest = (-join('"', $dest, '"'))
            Invoke-Expression (("ffmpeg", "-i", $src, "-c:v", $codecs[$inputfun], "-s", $resolutions[$inputres], $dest) -join " ")
            # Write-Host (("ffmpeg", "-i", $src, "-c:v", $codecs[$inputfun], "-s", $resolutions[$inputres], $dest) -join " ")
        }
    }

    return
}


function traverse($set)                                                     # �ݹ鴦��
{
    foreach ($item in $set) {                                               # �Դ��������ÿ��Ԫ�ش���
        if (-not ($item.Attributes -eq "Directory")) {                      # �����Ԫ�ز���Ŀ¼ 
            encode($item)                                                   # ���Ա���
        } elseif ($item.Attributes -eq "Directory") {                       # �����Ŀ¼
            $path = (-join($item.FullName, "\*"))
            if ((Get-ChildItem -Path $path -Include $suffixs)) {            # ���ڲ��з����������ļ�
                $destpath = getproxy($item)                                 # ��ȡ�����ļ����ж�Ӧ��·��
                if (-not (Test-Path $destpath)) {                           # �����·��������
                    New-Item -ItemType Directory $destpath                  # ����֮
                }
            } 
            traverse((Get-ChildItem $item.FullName))                        # �ݹ�֮
        }
    }

    return
}


if (-not (Test-Path $destdir[$inputfun])) {                                   # ���Ŀ��·��������
    New-Item -ItemType Directory $destdir[$inputfun]                          # ����֮
}

# ��ȡ��ǰĿ¼�³��˴����ļ��к��ų��ļ���֮���������Ŀ
$root = Get-ChildItem -Exclude $exclude

# ��ʼ����
traverse($root) 
    


