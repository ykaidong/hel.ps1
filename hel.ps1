# ---------------------------------------------------------------------------
# @file     hel.ps1
# @author   ���� <ykaidong@devlabs.cn>
# @version  0.21
# @date     2021-10-09
# @bref     �˽ű�������Windowsƽ̨�ϵ�PowerShell,  �����нű�ǰ��Ҫ��PowerShell��
#           ִ�� "Set-ExecutionPolicy RemoteSigned" �Ը��Ľű�ִ�в���
#           �˽ű����ڽ���ǰ�ļ������з�����������Ƶ�ļ�(��׺��λ�� $suffixs ��)
#           ʹ��FFMpeg���±��벢�ұ���ԭ�����ļ��нṹ
# ----------------------------------------------------------------------------
# Change Logs:
# Date          Version     Author          Notes
# 2021-09-12    0.1         ykaidong        ��ʼ�汾
# 2021-10-09    0.2         ykaidong        ��ת��С�ֱ�������ת������Ĺ��ܺϲ�
# 2021-10-09    0.21        ykaidong        Ϊ��ͬ�ֱ�����Ƶ���Ӷ����ļ���
# ----------------------------------------------------------------------------
# @attention
#
# ----------------------------------------------------------------------------

# ����������, [0]��ӦProRes, [1]��ӦH264
$destdir = "ProRes", "H264"     
$codecs = "prores_ks -profile:v standard -pix_fmt yuv422p10le", "libx264" 
$resolutions = @(
    @{"name" = "HD";      "content" = "1280x720"},
    @{"name" = "FHD";     "content" = "1920x1080"}
)

$suffixs = "*.mov", "*.mp4", "*.mxf", "*.avi"

# ��Ҫ���Ե��ļ���, ����Ŀ���ļ��лᱻ�Զ����Ե�
$exclude = "04_�Ӿ�Ч��", "07_����"

# ----------------------------------------------------------------------------

$name = @"
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
  Version: V0.21
     Date: 2021-10-09
 Descript: �˽ű����ڽ���ǰĿ¼�з�����������Ƶ�ļ�����ת��(PreRes or H264)
           ���ProRes�ļ���Ŀ��Ŀ¼Ϊ./$($destdir[0]), ���H.264
           ��Ŀ���ļ���Ϊ./$($destdir[1]), ����Ŀ���ļ����б���ԴĿ¼�ṹ.
-------------------------------------------------------------------------------

1. ʹ��ProRes����
2. ʹ��H.264����

"@


Write-Host $name
Write-Host $title

# ����ѡ��
while ((1, 2) -notcontains $inputfun) {
    $inputfun = Read-Host "��ѡ��Ŀ�����(1-2)"
}
# ƥ������(�����0��ʼ)
$inputfun = $inputfun - 1

# �ֱ������鳤��
$n = $resolutions.Length

# �ֱ���ѡ��
Write-Host ""
for ($i = 0; $i -le $n-1; $i++) {
    Write-Host (-join(
            ($i + 1), 
            ". $($resolutions[$i].content)",
            "($($resolutions[$i].name))"
    ))
}

Write-Host ""
while ((1..$n) -notcontains $inputres) {
    $inputres = Read-Host "��ѡ��Ŀ��ֱ���(1-$n)"
}
$inputres = $inputres - 1

# ----------------------------------------------------------------------------

# �ű����е�Ŀ¼
$location = (Get-Location).Path

# Ŀ���Ŀ¼
$destroot = (-join(
        "$($destdir[$inputfun])", 
        "_", 
        "$($resolutions[$inputres].name)"
))

# �ų�����Ŀ��Ŀ¼
$excludedest = @()
foreach ($d in $destdir) {
    foreach ($r in $resolutions) {
        $excludedest += (-join($d, "_", $r.name))
    }
}
$exclude += $excludedest

# ��ȡ $item �� Ŀ��Ŀ¼�ж�Ӧ��·��
function getproxy($item) 
{
    return ($item.FullName.Replace($location, (-join($location, "\", $destroot))))
}


function encode($file) 
{
    if ($suffixs -contains $file.Extension.ToLower().Replace(".", "*.")) {  # �����׺����������
        $dest = getproxy($file)                                             # ��ȡĿ���ļ����ж�Ӧ��λ��
        $dest = $dest -replace "\.[^\.]+$", ".mov"                          # �滻�ļ���׺(��mov��װprores)
        if (-not (Test-Path $dest)) {                                       # ����ļ���������Ŀ��λ��
            $src = (-join('"', $file.FullName, '"'))                        # ��ʹ��FFMpeg����ת��
            $dest = (-join('"', $dest, '"'))
            Invoke-Expression (("ffmpeg", "-i", $src, 
                                          "-c:v", $codecs[$inputfun], 
                                          "-s", $resolutions[$inputres].content, 
                                          $dest) -join " ")
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


# ���ڴ�����Ŀ��Ŀ¼�����ļ������
if (-not (Test-Path $destroot)) {                                   # ���Ŀ���·��������
    New-Item -ItemType Directory $destroot                          # ����֮
}

# ��ȡ��ǰĿ¼�³��˴����ļ��к��ų��ļ���֮���������Ŀ
$root = Get-ChildItem -Exclude $exclude

# ��ʼ����
traverse($root) 
    


