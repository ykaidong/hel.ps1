# ---------------------------------------------------------------------------
# @file     hel.ps1
# @author   大杨 <ykaidong@devlabs.cn>
# @version  0.21
# @date     2021-10-09
# @bref     此脚本运行于Windows平台上的PowerShell,  在运行脚本前需要在PowerShell中
#           执行 "Set-ExecutionPolicy RemoteSigned" 以更改脚本执行策略
#           此脚本用于将当前文件中所有符合条件的视频文件(后缀名位于 $suffixs 中)
#           使用FFMpeg重新编码并且保持原来的文件夹结构
# ----------------------------------------------------------------------------
# Change Logs:
# Date          Version     Author          Notes
# 2021-09-12    0.1         ykaidong        初始版本
# 2021-10-09    0.2         ykaidong        将转换小分辨率率与转换代理的功能合并
# 2021-10-09    0.21        ykaidong        为不同分辨率视频增加顶级文件夹
# ----------------------------------------------------------------------------
# @attention
#
# ----------------------------------------------------------------------------

# 以下数组中, [0]对应ProRes, [1]对应H264
$destdir = "ProRes", "H264"     
$codecs = "prores_ks -profile:v standard -pix_fmt yuv422p10le", "libx264" 
$resolutions = @(
    @{"name" = "HD";      "content" = "1280x720"},
    @{"name" = "FHD";     "content" = "1920x1080"}
)

$suffixs = "*.mov", "*.mp4", "*.mxf", "*.avi"

# 需要忽略的文件夹, 所有目标文件夹会被自动忽略掉
$exclude = "04_视觉效果", "07_导出"

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
 Descript: 此脚本用于将当前目录中符合条件的视频文件进行转码(PreRes or H264)
           存放ProRes文件的目标目录为./$($destdir[0]), 存放H.264
           的目标文件夹为./$($destdir[1]), 且在目标文件夹中保持源目录结构.
-------------------------------------------------------------------------------

1. 使用ProRes编码
2. 使用H.264编码

"@


Write-Host $name
Write-Host $title

# 功能选择
while ((1, 2) -notcontains $inputfun) {
    $inputfun = Read-Host "请选择目标编码(1-2)"
}
# 匹配数组(数组从0开始)
$inputfun = $inputfun - 1

# 分辨率数组长度
$n = $resolutions.Length

# 分辨率选择
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
    $inputres = Read-Host "请选择目标分辨率(1-$n)"
}
$inputres = $inputres - 1

# ----------------------------------------------------------------------------

# 脚本运行的目录
$location = (Get-Location).Path

# 目标根目录
$destroot = (-join(
        "$($destdir[$inputfun])", 
        "_", 
        "$($resolutions[$inputres].name)"
))

# 排除所有目标目录
$excludedest = @()
foreach ($d in $destdir) {
    foreach ($r in $resolutions) {
        $excludedest += (-join($d, "_", $r.name))
    }
}
$exclude += $excludedest

# 获取 $item 在 目标目录中对应的路径
function getproxy($item) 
{
    return ($item.FullName.Replace($location, (-join($location, "\", $destroot))))
}


function encode($file) 
{
    if ($suffixs -contains $file.Extension.ToLower().Replace(".", "*.")) {  # 如果后缀名符合条件
        $dest = getproxy($file)                                             # 获取目标文件夹中对应的位置
        $dest = $dest -replace "\.[^\.]+$", ".mov"                          # 替换文件后缀(用mov封装prores)
        if (-not (Test-Path $dest)) {                                       # 如果文件不存在于目标位置
            $src = (-join('"', $file.FullName, '"'))                        # 则使用FFMpeg进行转换
            $dest = (-join('"', $dest, '"'))
            Invoke-Expression (("ffmpeg", "-i", $src, 
                                          "-c:v", $codecs[$inputfun], 
                                          "-s", $resolutions[$inputres].content, 
                                          $dest) -join " ")
        }
    }

    return
}


function traverse($set)                                                     # 递归处理
{
    foreach ($item in $set) {                                               # 对传入参数的每个元素处理
        if (-not ($item.Attributes -eq "Directory")) {                      # 如果该元素不是目录 
            encode($item)                                                   # 尝试编码
        } elseif ($item.Attributes -eq "Directory") {                       # 如果是目录
            $path = (-join($item.FullName, "\*"))
            if ((Get-ChildItem -Path $path -Include $suffixs)) {            # 且内部有符合条件的文件
                $destpath = getproxy($item)                                 # 获取代理文件夹中对应的路径
                if (-not (Test-Path $destpath)) {                           # 如果此路径不存在
                    New-Item -ItemType Directory $destpath                  # 创建之
                }
            } 
            traverse((Get-ChildItem $item.FullName))                        # 递归之
        }
    }

    return
}


# 用于处理项目根目录下有文件的情况
if (-not (Test-Path $destroot)) {                                   # 如果目标根路径不存在
    New-Item -ItemType Directory $destroot                          # 创建之
}

# 获取当前目录下除了代理文件夹和排除文件夹之外的所有条目
$root = Get-ChildItem -Exclude $exclude

# 开始处理
traverse($root) 
    


