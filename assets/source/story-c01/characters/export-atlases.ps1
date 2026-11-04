$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
public static class StoryAtlasExport {
 public static void Export(string path,string target,string frames,int[] rowRoots) {
  using(var source=new Bitmap(path)) using(var atlas=new Bitmap(1344,1344,PixelFormat.Format32bppArgb)) {
   for(int row=0;row<4;row++) for(int col=0;col<4;col++) {
    int x0=(int)Math.Round(col*source.Width/4.0),x1=(int)Math.Round((col+1)*source.Width/4.0);
    int y0=(int)Math.Round(row*source.Height/4.0),y1=(int)Math.Round((row+1)*source.Height/4.0);
    using(var frame=new Bitmap(336,336,PixelFormat.Format32bppArgb)) {
     int dx=12,dy=300-rowRoots[row];
     // Copy pixels, including original alpha, without any resampling or silhouette edits.
     for(int y=y0;y<y1;y++) for(int x=x0;x<x1;x++) {
      int tx=x-x0+dx,ty=y-y0+dy;
      if(tx<0||tx>=336||ty<0||ty>=336) {
       if(source.GetPixel(x,y).A>=8) throw new Exception("Visible source clipping: "+path);
       continue;
      }
      var pixel=source.GetPixel(x,y);
      frame.SetPixel(tx,ty,pixel); atlas.SetPixel(col*336+tx,row*336+ty,pixel);
     }
     frame.Save(System.IO.Path.Combine(frames,(row*4+col).ToString("00")+".png"),ImageFormat.Png);
    }
   }
   atlas.Save(target,ImageFormat.Png);
  }
 }
}
'@
$runtime = Join-Path $PSScriptRoot '../../../runtime/story-c01/characters'
$actors = @{
    forager = @{ output_id='exec-d7b07c58-3eb4-4ce8-88be-1ae78b055fc3'; roots = @(290,287,289,287); height = 143; display = 70; actions = [ordered]@{
        feed = @{frames=@(0,1,2,3);fps=4.0;loop=$true}
        walk = @{frames=@(4,5,6,7);fps=8.0;loop=$true}
        warn = @{frames=@(8,9);fps=4.0;loop=$false}
        attack = @{frames=@(8,9,10,11);fps=8.0;loop=$false}
        lunge = @{frames=@(10,11);fps=8.0;loop=$false}
        hurt = @{frames=@(12,13);fps=10.0;loop=$false}
        retreat = @{frames=@(14,15,13,14);fps=7.0;loop=$true}
    }}
    mender = @{ output_id='exec-f4f215bd-e4ff-407a-8f51-788ffebdb384'; roots = @(284,285,285,284); height = 186; display = 90; actions = [ordered]@{
        mend = @{frames=@(0,1,2,3);fps=4.0;loop=$true}
        talk = @{frames=@(4,5,6,7);fps=4.0;loop=$true}
        walk = @{frames=@(8,9,10,11);fps=6.0;loop=$true}
        idle = @{frames=@(12,13,14,15);fps=3.0;loop=$true}
    }}
}
$manifest = @{actors=@{}}
$provenance = @{method='Built-in image_gen, authored key-frame sheets; deterministic pixel-copy registration';generated_date='2026-11-04';references=@('../../xumen-reference-environment/original/reference.png','../../r1-chapter-scenes/generated/R1-02-clean.png');actors=@{}}
foreach($key in @('forager','mender')) {
    $actor = $actors[$key]
    $source = Join-Path $PSScriptRoot "$key-generated.png"
    $target = Join-Path $runtime "$key-atlas.png"
    $frames = Join-Path $PSScriptRoot "$key-frames"
    New-Item -ItemType Directory -Force $runtime,$frames | Out-Null
    [StoryAtlasExport]::Export($source,$target,$frames,[int[]]$actor.roots)
    $manifest.actors[$key] = @{texture="res://art/story-c01/characters/$key-atlas.png";reference_height=$actor.height;display_height=$actor.display;root=@(168,300);columns=4;rows=4;cell_size=@(336,336);actions=$actor.actions}
    $provenance.actors[$key] = @{source_sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash.ToLower();runtime_sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash.ToLower();source_size=@(1254,1254);grid_boundaries=@(0,314,627,940,1254);source_row_baselines=$actor.roots;destination_root=@(168,300);translate_x=12;translate_y=@($actor.roots | ForEach-Object {300-$_});scale=1;prompt="$key-prompt.txt";frames=@(Get-ChildItem -LiteralPath $frames -Filter '*.png' | Sort-Object Name | ForEach-Object {@{path="$key-frames/$($_.Name)";sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLower()}})}
    $provenance.actors[$key].generation_output_id = $actor.output_id
}
[IO.File]::WriteAllText((Join-Path $runtime 'animations.json'),($manifest | ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'provenance.json'),($provenance | ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
