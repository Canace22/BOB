import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import {fileURLToPath} from 'node:url';

// Narrow deterministic cropper for these generated, non-interlaced RGBA8 PNGs.
const root = path.dirname(fileURLToPath(import.meta.url));
const signature = Buffer.from([137,80,78,71,13,10,26,10]);
const crcTable = Array.from({length:256}, (_,n) => {
  for(let k=0;k<8;k++) n = n&1 ? 0xedb88320^(n>>>1) : n>>>1;
  return n>>>0;
});
function chunk(type,data) {
  const result=Buffer.alloc(data.length+12), tag=Buffer.from(type);
  result.writeUInt32BE(data.length); tag.copy(result,4); data.copy(result,8);
  let crc=0xffffffff;
  for(const byte of Buffer.concat([tag,data])) crc=crcTable[(crc^byte)&255]^(crc>>>8);
  result.writeUInt32BE((crc^0xffffffff)>>>0,result.length-4);
  return result;
}
function paeth(a,b,c) {
  const p=a+b-c, da=Math.abs(p-a), db=Math.abs(p-b), dc=Math.abs(p-c);
  return da<=db&&da<=dc?a:db<=dc?b:c;
}
function decode(file) {
  const png=fs.readFileSync(file), parts=[]; let header;
  if(!png.subarray(0,8).equals(signature)) throw Error('Not a PNG: '+file);
  for(let offset=8;offset<png.length;) {
    const length=png.readUInt32BE(offset),type=png.toString('ascii',offset+4,offset+8);
    const data=png.subarray(offset+8,offset+8+length);
    if(type==='IHDR') header=data;
    if(type==='IDAT') parts.push(data);
    offset+=length+12;
  }
  if(!header || header[8]!==8 || header[9]!==6 || header[12]!==0)
    throw Error('This trial exporter supports non-interlaced RGBA8 only: '+file);
  const width=header.readUInt32BE(0),height=header.readUInt32BE(4),stride=width*4;
  const raw=zlib.inflateSync(Buffer.concat(parts)),pixels=Buffer.alloc(width*height*4);
  if(raw.length!==(stride+1)*height) throw Error('Unexpected scanline size');
  for(let y=0;y<height;y++) for(let x=0;x<stride;x++) {
    const index=y*stride+x,a=x>=4?pixels[index-4]:0,b=y?pixels[index-stride]:0,c=y&&x>=4?pixels[index-stride-4]:0;
    const predictors=[0,a,b,Math.floor((a+b)/2),paeth(a,b,c)],filter=raw[y*(stride+1)];
    if(filter>4) throw Error('Invalid PNG filter');
    pixels[index]=(raw[y*(stride+1)+1+x]+predictors[filter])&255;
  }
  return {width,height,pixels,header};
}
function encode(pixels,size,header) {
  const scan=Buffer.alloc((size*4+1)*size),ihdr=Buffer.from(header);
  ihdr.writeUInt32BE(size,0);ihdr.writeUInt32BE(size,4);
  for(let y=0;y<size;y++) pixels.copy(scan,y*(size*4+1)+1,y*size*4,(y+1)*size*4);
  return Buffer.concat([signature,chunk('IHDR',ihdr),chunk('IDAT',zlib.deflateSync(scan)),chunk('IEND',Buffer.alloc(0))]);
}
function silhouetteDifference(a,b) {
  let different=0,union=0;
  for(let i=3;i<a.length;i+=4) {
    const x=a[i]>32,y=b[i]>32;
    if(x||y) union++;
    if(x!==y) different++;
  }
  return Number((different/Math.max(1,union)).toFixed(4));
}
function exportTrial(version,folder) {
  const dir=path.join(root,folder),source=decode(path.join(dir,'sheet.png'));
  const size=Math.ceil(Math.max(source.width,source.height)/4),pixels=[],frames=[];
  fs.mkdirSync(path.join(dir,'frames'),{recursive:true});
  for(let i=0;i<16;i++) {
    const col=i%4,row=Math.floor(i/4),x=Math.round(col*source.width/4),y=Math.round(row*source.height/4);
    const width=Math.round((col+1)*source.width/4)-x,height=Math.round((row+1)*source.height/4)-y;
    const output=Buffer.alloc(size*size*4),file='frames/'+String(i+1).padStart(2,'0')+'.png';
    for(let j=0;j<height;j++) source.pixels.copy(output,j*size*4,((y+j)*source.width+x)*4,((y+j)*source.width+x+width)*4);
    fs.writeFileSync(path.join(dir,file),encode(output,size,source.header));pixels.push(output);
    const decoded=decode(path.join(dir,file));
    if(decoded.width!==size || decoded.height!==size || !decoded.pixels.equals(output)) throw Error('Crop roundtrip failed');
    let borderPixels=0,transparentPixels=0;
    for(let py=0;py<size;py++) for(let px=0;px<size;px++) {
      const alpha=output[(py*size+px)*4+3];
      if(alpha===0) transparentPixels++;
      if((px===0||py===0||px===size-1||py===size-1)&&alpha>32) borderPixels++;
    }
    frames.push({file,rect:[x,y,width,height],offset:[0,0],durationMs:62.5,borderPixels,transparentPixels});
  }
  const differences=pixels.map((p,i)=>silhouetteDifference(p,pixels[(i+1)%16]));
  const metadata={version,status:'experiment-not-approved',method:'direct-16-frame-generation-no-video',source:'sheet.png',canvas:[size,size],direction:'right',loop:true,alignment:'raw grid crop; transparent padding only; no rescaling or anatomical registration',timing:'16 fps preview assumption; not verified against gameplay speed',frames,
    diagnostics:{definition:'alpha>32 symmetric difference divided by union, at raw grid coordinates; NOT a motion quality score',adjacentSilhouetteDifference:differences,seamDifference:differences[15],meanAdjacentDifference:Number((differences.slice(0,15).reduce((a,b)=>a+b,0)/15).toFixed(4))}};
  fs.writeFileSync(path.join(dir,'animation.json'),JSON.stringify(metadata,null,2)+'\n');
  return {version,folder,canvas:metadata.canvas,seam:metadata.diagnostics.seamDifference,mean:metadata.diagnostics.meanAdjacentDifference,edgeFrames:frames.flatMap((f,i)=>f.borderPixels?[i+1]:[])};
}
const results=[['A','.'],['B','variants/b'],['C','variants/c'],['D','variants/d']].map(([v,p])=>exportTrial(v,p));
fs.writeFileSync(path.join(root,'comparison.json'),JSON.stringify(results,null,2)+'\n');
console.log(JSON.stringify(results,null,2));
