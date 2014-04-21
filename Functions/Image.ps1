<#
.Synopsis
   批量缩放图片
.DESCRIPTION
   根据百分比或者像素大小缩放图片
.EXAMPLE
   'C:\1.png' | Resize-Image -Percent -Percentage 0.8
   将图片1.png缩放至80%
.EXAMPLE
   'C:\1.png' | Resize-Image -Pixels -Width 600 -Height 400
   将图片1.png缩放至600X400像素
.EXAMPLE
   dir $home\Pictures\*png | Resize-Image -Percent -Percentage 0.5
   将'我的图片'下的所有png图片缩放至50%
.NOTES
   作者: Mosser Lee
   原文链接: http://www.pstips.net/resize-image.html
#>
Function Resize-Image
{
    param
    (
    [Switch]$Percent,
    [float]$Percentage,
    [Switch]$Pixels,
    [int]$Width,
    [int]$Height
    )
 
    begin
    {
        if( $Percent -and $Pixels)
        {
            Write-Error "按照百分比(Percent)或者分辨率(Pixels)缩放，只能任选其一奥！"
            break
        }
        elseif($Percent)
        {
            if($Percentage -le 0)
            {
              Write-Error "参数Percentage的值必须大于0！"
              break
            }
        }
        elseif($Pixels)
        {
            if( ($Width -lt 1) -or ($Height -lt 1))
            {
              Write-Error "参数Width和Height的值必须大于等于1！"
              break
            }
        }
        else
        {
            Write-Error "请选择按照百分比(-Percent)或者分辨率(-Pixels)缩放！"
            break
        }
        Add-Type -AssemblyName 'System.Windows.Forms'
        $count=0
 
    }
    process
    {
 
        $img=[System.Drawing.Image]::FromFile($_)
 
        # 按百分比重新计算图片大小
        if( ($Percentage -gt 0) -and ($Percentage -ne 1.0) )
        {
            $Width = $img.Width * $Percentage
            $Height = $img.Height * $Percentage
        }
 
        # 缩放图片
        $size = New-Object System.Drawing.Size($Width,$Height)
        $bitmap =  New-Object System.Drawing.Bitmap($img,$size)
 
        # 保存图片
        $img.Dispose()
        $bitmap.Save($_)
        $bitmap.Dispose()
 
        $count++
    }
    end
    {
        "完毕，共处理 $count 了个文件"
    }
}