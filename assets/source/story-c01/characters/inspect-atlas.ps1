param([string]$Source = 'forager-generated.png')
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
public static class StoryAtlasInspection {
 public static void Inspect(string path) {
  using(var image=new Bitmap(path)) {
   Console.WriteLine("Size: "+image.Width+"x"+image.Height);
   for(int row=0;row<4;row++) for(int col=0;col<4;col++) {
    int x0=(int)Math.Round(col*image.Width/4.0),x1=(int)Math.Round((col+1)*image.Width/4.0);
    int y0=(int)Math.Round(row*image.Height/4.0),y1=(int)Math.Round((row+1)*image.Height/4.0);
    int minX=99999,minY=99999,maxX=-1,maxY=-1,count=0;
    for(int y=y0;y<y1;y++) for(int x=x0;x<x1;x++) {
     if(image.GetPixel(x,y).A<32) continue;
     minX=Math.Min(minX,x-x0); minY=Math.Min(minY,y-y0);
     maxX=Math.Max(maxX,x-x0); maxY=Math.Max(maxY,y-y0); count++;
    }
    Console.WriteLine((row*4+col)+": "+minX+","+minY+".."+maxX+","+maxY+" pixels="+count);
   }
   using(var preview=new Bitmap(image.Width*2,image.Height)) using(var g=Graphics.FromImage(preview)) {
    g.Clear(Color.FromArgb(232,228,218));
    using(var brush=new SolidBrush(Color.FromArgb(8,25,35)))g.FillRectangle(brush,image.Width,0,image.Width,image.Height);
    g.DrawImageUnscaled(image,0,0); g.DrawImageUnscaled(image,image.Width,0);
    preview.Save(path+".backgrounds.png",ImageFormat.Png);
   }
  }
 }
}
'@
[StoryAtlasInspection]::Inspect((Join-Path $PSScriptRoot $Source))
