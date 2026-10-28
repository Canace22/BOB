from pathlib import Path
import json,shutil,hashlib
from PIL import Image

ROOT=Path('G:/鲸落万物生')
P=ROOT/'godot/first-level-artmatch'
SRC=ROOT/'outputs/须门遗港_R1_全景与分层拆解/references'
for d in ['scripts','scenes/r1','assets/reference/r1','assets/masks','assets/runtime','docs','evidence','.production']:(P/d).mkdir(parents=True,exist_ok=True)
for f in ['project.godot','export_presets.cfg']:shutil.copy2(ROOT/'godot/first-level'/f,P/f)
s=(P/'project.godot').read_text('utf8').replace('须门遗港"','须门遗港 · 原图场景还原 v0.5"').replace('WhalefallFirstLevel','WhalefallArtmatchV05')
(P/'project.godot').write_text(s,encoding='utf8')
shutil.copytree(ROOT/'godot/first-level/assets/runtime/hero',P/'assets/runtime/hero',dirs_exist_ok=True)
shutil.copy2(ROOT/'godot/first-level/assets/runtime/v04/oral-depth.png',P/'assets/runtime/clean-depth.png')

def pts(s):return [[float(v) for v in x.split(',')] for x in s.split()]
def poly(s):return pts(s) if isinstance(s,str) else s
def actor(name,shape,offset):return dict(name=name,shape=pts(shape),offset=offset)

# Native source pixel coordinates. These contours, not the superseded U-grid,
# are the authoritative visual and physical geometry for this edition.
data=[
dict(name='外伤坡',spawn=[239,611],
 surfaces=[pts('0,611 100,609 200,612 320,620 390,618 460,586 540,577 650,577 710,563 770,536 840,525 925,530 1020,548 1070,577 1110,613 1220,626 1330,655 1420,662 1510,657 1600,646 1671,650')],
 canopy=pts('0,0 1671,0 1671,597 1590,560 1570,350 1520,272 1440,200 1360,190 1290,190 1240,50 1180,0 1120,15 1090,132 1060,180 1000,223 960,202 940,160 900,178 870,150 850,70 820,178 770,282 700,310 650,336 610,321 570,345 540,315 510,348 490,270 450,340 430,375 410,331 375,310 310,230 210,213 130,273 0,425'),
 foreground=pts('0,620 50,632 75,689 130,696 140,741 230,714 283,754 330,715 382,770 450,790 500,760 580,784 635,827 690,812 730,848 790,804 830,850 900,854 950,879 1030,851 1140,842 1260,900 1325,873 1430,910 1510,895 1600,927 1671,866 1671,941 0,941'),
 holes=[pts('150,748 260,760 330,742 385,722 400,754 470,765 500,782 380,805 200,786'),pts('590,704 665,687 715,655 750,612 786,607 800,652 836,680 850,661 895,687 980,665 1035,692 1050,749 1115,803 1122,841 990,848 870,845 730,804 620,783')],
 actors=[actor('PlayerArt','201,610 210,599 211,585 199,580 190,570 207,550 224,539 220,525 226,516 241,515 252,521 257,532 248,543 249,555 264,551 270,535 279,528 280,539 273,550 281,547 288,531 293,532 289,547 282,554 276,561 272,583 261,594 252,596 251,585 244,577 240,589 236,601 247,610 231,613 221,607 214,612',[-110,-15])],
 enemies=[],rings=[],reward=[93,550]),
dict(name='须筛',spawn=[194,715],
 surfaces=[pts('0,718 130,717 260,719 370,711 440,681 510,661 590,661 650,661 697,684 760,695 810,687 849,650 925,640 1015,640 1080,657 1100,686 1150,711 1280,719 1420,716 1530,715 1672,713'),pts('160,498 230,495 300,498 358,502'),pts('162,343 232,339 300,340 358,347'),pts('126,184 210,186 295,193 357,203'),pts('1360,280 1460,272 1560,275 1672,277')],
 canopy=pts('0,0 1672,0 1672,225 1600,230 1530,260 1430,273 1380,269 1330,310 1310,349 1250,390 1220,395 1180,350 1110,344 1050,320 1000,306 960,260 920,275 850,267 800,260 740,227 710,250 665,200 630,180 620,140 590,90 560,12 520,10 480,51 420,82 350,90 260,150 170,220 110,340 140,490 100,580 0,600'),
 foreground=pts('0,742 80,740 130,712 170,760 215,810 280,810 350,850 420,784 490,734 530,733 560,787 620,811 680,755 732,752 760,717 790,750 829,777 865,851 950,858 1030,884 1100,892 1170,868 1240,850 1320,837 1400,804 1500,792 1590,755 1672,687 1672,941 0,941'),
 holes=[],actors=[actor('PlayerArt','157,713 169,696 165,683 155,681 161,666 176,654 182,633 195,630 212,640 217,648 207,660 216,670 228,660 229,646 235,641 239,647 235,657 245,648 250,650 245,663 235,670 233,691 219,706 211,694 204,684 198,703 208,714 194,718 185,710 174,715',[-110,-20]),actor('EnemyArt0','538,657 543,640 556,627 547,620 534,620 523,612 526,602 535,608 542,606 536,598 524,597 532,590 544,587 560,592 565,605 561,617 577,625 578,612 592,608 610,614 621,627 634,635 647,647 652,660 642,658 638,648 626,643 630,658 620,658 612,641 601,636 591,651 590,660 580,656 582,644 564,637 551,645 547,659',[-140,-85])],
 enemies=[dict(pos=[590,661],boss=False)],rings=[[1124,531],[1245,422],[1357,304]],reward=[]),
dict(name='舌台',spawn=[258,581],
 surfaces=[pts('0,565 100,578 200,580 300,589 350,590 420,568 490,553 550,550 610,558 665,578 710,605 770,618 850,622 910,616 980,589 1030,568 1110,559 1190,566 1240,584 1300,607 1400,612 1510,614 1600,612 1672,600'),pts('1047,447 1105,442 1160,442 1228,445'),pts('0,698 180,727 320,755 460,768 620,787 780,800 950,796 1100,788 1280,766 1450,736 1672,682')],
 canopy=pts('0,0 1672,0 1672,460 1600,453 1545,453 1485,413 1430,405 1380,382 1330,352 1270,310 1230,264 1200,199 1165,180 1130,206 1080,209 1035,164 1000,80 975,0 943,20 925,166 900,211 866,260 819,259 800,237 773,241 737,202 716,203 690,186 674,136 647,42 620,114 595,170 557,210 520,214 500,247 464,243 440,255 403,248 380,237 350,184 320,155 250,213 150,260 95,292 0,432'),
 foreground=pts('0,588 60,648 96,704 140,722 170,768 213,738 250,795 310,796 365,752 400,785 450,819 470,781 500,823 555,857 600,855 658,880 725,868 800,905 900,918 1010,900 1090,870 1180,835 1220,780 1270,805 1310,760 1380,771 1450,696 1500,710 1535,670 1590,701 1640,651 1672,648 1672,941 0,941'),
 holes=[pts('150,647 220,640 300,623 380,608 405,637 400,688 360,735 260,728 190,704'),pts('622,666 690,672 744,679 770,713 794,689 819,710 842,687 893,702 933,680 961,676 998,682 1033,730 1055,759 951,785 870,787 760,779 659,755'),pts('1264,671 1370,654 1480,652 1520,651 1537,691 1460,722 1350,745')],
 actors=[actor('PlayerArt','219,579 230,567 223,551 213,548 228,532 248,525 247,511 255,503 267,503 277,510 278,522 268,530 278,540 290,534 291,518 299,513 304,520 299,529 308,518 309,526 301,537 294,544 290,562 279,572 270,562 265,550 258,570 270,580 253,584 244,576 236,581',[-100,-70]),actor('EnemyArt0','480,551 490,532 500,518 512,516 529,509 548,508 562,515 575,505 575,490 585,479 596,475 613,479 605,485 597,484 595,491 606,490 601,502 588,508 578,517 578,528 591,533 597,553 586,551 582,538 570,534 567,553 557,549 554,535 542,535 533,551 523,551 528,535 514,531 501,542 496,555',[-100,-80]),actor('EnemyArt1','1035,559 1037,539 1050,527 1041,512 1031,510 1025,498 1026,486 1039,481 1056,486 1067,501 1060,513 1078,518 1092,512 1110,514 1127,523 1135,537 1147,548 1151,563 1140,560 1133,548 1121,542 1121,559 1110,559 1104,545 1094,541 1084,556 1074,560 1075,544 1061,537 1047,546 1045,560',[-140,-60])],
 enemies=[dict(pos=[541,552],boss=False),dict(pos=[1092,560],boss=False)],rings=[],reward=[1135,420]),
dict(name='负壳蟹',spawn=[381,709],
 surfaces=[pts('0,644 75,646 145,652 200,696 285,710 400,711 600,712 800,711 1000,715 1200,714 1400,710 1591,705'),pts('502,641 570,635 650,638 733,647'),pts('1128,646 1190,637 1270,637 1345,641')],
 canopy=pts('0,0 1591,0 1591,555 1510,530 1500,329 1410,353 1330,357 1260,355 1220,296 1190,245 1170,173 1120,254 1090,261 1060,260 1040,241 1010,273 960,280 915,267 880,243 850,190 829,167 800,213 740,291 690,303 640,321 610,327 580,347 550,326 523,352 490,336 465,352 441,330 400,357 370,389 343,380 309,406 283,371 250,320 220,350 240,500 270,704 209,710 184,559 165,470 113,385 0,435'),
 foreground=pts('0,673 70,711 116,745 156,796 209,810 270,772 310,796 367,767 410,797 445,823 480,807 520,836 560,819 620,841 668,808 696,833 740,817 800,868 900,897 930,871 960,890 1050,899 1120,873 1200,899 1280,873 1340,819 1410,850 1440,789 1500,760 1591,749 1591,989 0,989'),
 holes=[],actors=[actor('PlayerArt','342,706 353,695 345,681 334,677 345,657 366,649 365,637 375,627 387,626 394,636 396,645 387,655 398,665 406,654 407,642 414,636 419,641 415,654 423,642 425,649 418,659 412,668 410,684 398,699 389,685 383,677 379,696 389,708 376,710 367,702 356,709',[-90,-20]),actor('EnemyArt0','777,706 780,670 796,637 812,617 837,601 856,605 863,593 847,575 831,567 819,548 818,528 797,523 776,506 761,486 749,452 760,465 783,475 792,461 770,439 745,432 733,430 739,420 760,416 791,421 814,432 835,453 851,481 853,506 847,529 860,549 864,573 882,586 889,565 874,551 896,533 918,532 935,515 956,499 984,484 1006,478 1008,489 994,512 1037,505 1046,509 1034,531 1064,548 1080,561 1107,588 1109,595 1072,600 1098,625 1092,641 1074,645 1091,664 1109,686 1114,707 1105,705 1097,686 1080,671 1076,690 1067,707 1054,710 1050,694 1035,702 1015,704 1015,693 997,704 977,713 965,704 954,699 951,683 960,672 983,664 978,652 967,645 951,651 940,664 920,666 899,650 880,628 875,650 873,676 886,706 872,711 859,685 850,657 853,626 834,621 818,636 803,657 793,681 789,707',[-365,-100])],
 enemies=[dict(pos=[935,712],boss=True)],rings=[],reward=[]),
dict(name='流膜育窝',spawn=[565,573],
 surfaces=[pts('0,551 90,552 180,559 275,570 375,578'),pts('506,588 600,577 700,577 787,585'),pts('810,564 900,555 1000,564 1118,571'),pts('1230,582 1330,570 1450,563 1612,558')],
 canopy=pts('0,0 1612,0 1612,550 1530,525 1510,393 1470,334 1370,313 1260,280 1160,267 1050,248 990,244 900,274 835,278 751,262 661,233 605,213 525,227 452,219 380,190 300,144 234,126 180,138 144,238 113,337 0,447'),
 foreground=pts('0,630 90,689 145,746 211,808 279,853 360,844 450,866 550,799 645,816 740,847 850,895 950,843 1030,804 1130,816 1250,856 1360,799 1450,736 1530,667 1612,638 1612,976 0,976'),
 holes=[pts('375,590 500,588 540,634 541,696 480,705 411,691 350,670'),pts('791,598 809,590 846,627 852,690 769,694'),pts('1114,591 1230,596 1264,641 1284,695 1158,705 1067,689')],
 actors=[actor('PlayerArt','390,527 418,509 437,493 469,488 500,488 540,492 555,482 562,476 575,474 586,477 591,486 586,498 574,509 590,513 607,503 608,492 616,486 622,489 619,500 610,509 603,519 594,535 575,547 562,541 546,552 526,570 511,569 516,551 530,532 513,529 480,539 444,541 411,554 421,544 451,527 421,531',[-100,-150])],enemies=[],rings=[],reward=[110,503]),
dict(name='喷气孔上层',spawn=[425,643],
 surfaces=[pts('0,791 100,796 210,792 330,788 475,798'),pts('410,650 490,643 590,643 679,650'),pts('613,490 700,482 840,482 955,485 1040,489'),pts('912,343 1050,335 1210,332 1350,335 1476,340')],
 canopy=pts('0,0 1476,0 1476,331 1380,322 1300,322 1243,251 1160,235 1100,205 1055,297 1021,279 990,227 967,207 890,181 800,157 720,157 660,167 570,144 480,116 440,80 372,86 330,107 290,95 240,60 198,57 162,96 118,132 68,163 38,205 30,285 49,323 0,400'),
 foreground=pts('0,792 50,800 90,852 156,829 210,898 290,914 390,929 470,939 540,1000 620,1010 680,1050 760,1065 840,1020 900,971 957,970 1000,911 1070,895 1110,842 1180,842 1240,787 1285,736 1350,744 1400,683 1450,676 1476,705 1476,1065 0,1065'),
 holes=[],actors=[actor('PlayerArt','320,616 350,588 375,569 398,562 417,551 429,548 441,555 445,566 436,577 444,583 455,576 460,559 468,556 472,562 469,573 462,581 456,589 447,606 431,614 418,607 414,627 398,644 388,640 395,617 383,612 360,623 340,622',[-100,-100])],enemies=[],rings=[],reward=[1173,304]),
dict(name='鲸须记忆袋',spawn=[452,546],
 surfaces=[pts('0,565 100,566 220,572 325,575 403,579'),pts('562,579 650,572 750,572 875,580'),pts('1026,581 1150,570 1300,569 1450,572 1572,575')],
 canopy=pts('0,0 1572,0 1572,343 1510,356 1480,414 1410,427 1360,378 1310,364 1240,324 1200,280 1170,246 1150,199 1110,191 1070,115 1030,51 1005,132 973,188 945,230 890,257 847,283 803,276 762,297 733,325 707,333 684,370 648,366 620,342 580,341 554,327 523,296 496,317 462,342 433,365 403,360 370,359 343,342 313,310 292,285 260,272 240,204 200,205 160,249 120,257 65,300 0,369'),
 foreground=pts('0,576 60,660 95,688 130,732 210,814 265,842 340,874 425,906 460,863 495,909 530,891 575,914 650,932 705,894 750,913 784,962 864,978 920,963 990,941 1080,901 1130,883 1210,842 1310,829 1370,767 1430,745 1500,666 1572,620 1572,1001 0,1001'),
 holes=[],actors=[actor('PlayerArt','418,512 422,495 435,478 447,470 445,453 455,444 467,443 476,453 476,465 467,475 478,474 483,458 486,439 491,438 490,461 489,480 480,494 473,505 466,519 461,541 451,550 445,540 444,527 434,541 430,533 438,512 428,511',[-100,-40])],enemies=[],rings=[[490,380],[640,381],[896,382],[1018,382]],reward=[1300,524])
]
data[0]['reward']=[]
data[4]['reward']=[]
data[4]['play_spawn']=[200,559]
data[5]['play_spawn']=[190,790]
data[6]['play_spawn']=[350,574]
data[0]['camp']=[93,550]
data[3]['camp']=[80,610]
data[4]['camp']=[110,503]
data[4]['soft_beds']=[{'from':375,'to':506,'y':700},{'from':787,'to':810,'y':720},{'from':1118,'to':1230,'y':710}]
data[5]['surfaces'].append(pts('0,590 80,581 150,575 205,584'))
data[5]['surfaces'].append(pts('180,868 280,896 400,916 510,945 620,970 720,986 850,967 960,941 1050,920 1150,870 1250,820 1350,765 1476,730'))
data[2]['actors'].append(actor('RewardArt','1107,431 1105,413 1114,399 1129,391 1144,393 1158,406 1165,424 1157,435 1130,439',[-55,-60]))
data[5]['actors'].append(actor('RewardArt','1144,323 1141,308 1147,288 1164,276 1183,276 1201,291 1210,309 1207,326 1178,331',[-85,-30]))
data[6]['actors'].append(actor('RewardArt','1245,546 1245,522 1254,504 1272,500 1279,488 1295,480 1317,482 1332,500 1330,514 1341,523 1340,545 1325,558 1275,560',[-125,-25]))
data[3]['actors'].append(actor('DoorArt','1468,695 1465,661 1472,621 1485,589 1502,565 1521,552 1534,565 1549,592 1556,628 1555,672 1545,700 1500,706',[-180,-50]))
claw=pts('733,430 739,420 760,416 791,421 814,432 835,453 851,481 853,506 847,529 860,549 864,573 853,580 831,567 819,548 818,528 797,523 776,506 761,486 749,452 760,465 783,475 792,461 770,439 745,432')

def svg(w,h,content):return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{content}</svg>'
def polygon(v,color):return '<polygon points="'+' '.join(f'{x},{y}'for x,y in v)+f'" fill="{color}"/>'
def packed(v):return 'PackedVector2Array('+', '.join(str(x) for p in v for x in p)+')'
def write(path,content):(P/path).write_text(content,encoding='utf8')
write('scripts/extract.gdshader','''shader_type canvas_item;
uniform sampler2D silhouette : filter_linear;
uniform sampler2D clean_plate : filter_linear;
uniform vec2 source_size;
uniform vec4 bounds;
uniform bool recover_edges=false;
uniform sampler2D exclude_mask : filter_linear;
uniform bool has_exclusion=false;
void fragment(){vec4 c=texture(TEXTURE,UV);float a=texture(silhouette,UV).r;
 if(recover_edges){vec2 p=UV*source_size;float inside=step(bounds.x,p.x)*step(bounds.y,p.y)*step(p.x,bounds.z)*step(p.y,bounds.w);float d=length(c.rgb-texture(clean_plate,UV).rgb);a=max(a,inside*smoothstep(0.18,0.40,d));}
 if(has_exclusion)a*=1.0-texture(exclude_mask,UV).r;
 c.a*=a; COLOR=c;}
''')
write('scripts/layer.gdshader','''shader_type canvas_item;
uniform sampler2D classes : filter_nearest;
uniform sampler2D actor_holes : filter_nearest;
uniform sampler2D clean_plate : filter_linear;
uniform sampler2D far_plate : filter_linear;
uniform int layer_id = 0;
uniform vec2 source_size;
uniform vec2 patch0;
uniform vec2 patch1;
uniform vec2 patch2;
uniform vec2 patch3;
uniform vec4 remove0;
uniform vec4 remove1;
uniform vec4 remove2;
uniform vec4 remove3;
uniform int fallback_reward = -1;
uniform float clock = 0.0;
uniform float motion = 0.0;
uniform float membrane_drop = 0.0;
float rect_weight(vec2 p,vec4 r){return smoothstep(0.0,10.0,min(min(p.x-r.x,r.z-p.x),min(p.y-r.y,r.w-p.y)));}
void fragment(){
 vec2 uv=UV;
 if(layer_id==1){uv.x+=sin(clock*0.8+UV.x*16.0)*motion*1.4/source_size.x*smoothstep(0.05,0.40,UV.y)*(1.0-smoothstep(0.45,0.7,UV.y));}
 if(layer_id==2 && membrane_drop>0.0){float w=sin(clamp((UV.x*source_size.x-680.0)/320.0,0.0,1.0)*3.14159265);float vy=UV.y*source_size.y;uv.y-=membrane_drop*w*smoothstep(530.0,590.0,vy)*(1.0-smoothstep(690.0,740.0,vy))/source_size.y;}
 vec3 m=texture(classes,uv).rgb;
 int k=0; if(m.b>0.5)k=1; if(m.g>0.5)k=2; if(m.r>0.5)k=3;
 vec4 src=texture(TEXTURE,uv);vec4 far_color=texture(far_plate,uv);
 if(k==0 && src.r>src.b*0.85 && length(src.rgb-far_color.rgb)>0.12){k=uv.y>0.43?2:1;}
 vec4 c=texture(TEXTURE,uv);
 vec2 p=uv*source_size;
 float a0=rect_weight(p,remove0);float a1=rect_weight(p,remove1);float a2=rect_weight(p,remove2);float a3=rect_weight(p,remove3);
 vec4 cl=texture(clean_plate,uv);
 c=mix(c,fallback_reward==0?texture(TEXTURE,uv+patch0/source_size):cl,a0);
 c=mix(c,fallback_reward==1?texture(TEXTURE,uv+patch1/source_size):cl,a1);
 c=mix(c,fallback_reward==2?texture(TEXTURE,uv+patch2/source_size):cl,a2);
 c=mix(c,fallback_reward==3?texture(TEXTURE,uv+patch3/source_size):cl,a3);
 COLOR=vec4(c.rgb,c.a*float(k==layer_id));
}
''')

manifest=[]
for i,r in enumerate(data):
 rid=f'R1-{i+1:02d}';r['id']=rid
 f=SRC/(rid+'.png');w,h=Image.open(f).size;r['size']=[w,h]
 shutil.copy2(f,P/'assets/reference/r1'/f.name)
 r['reference']=f'res://assets/reference/r1/{rid}.png'
 # World domain follows foreground objects; small decorative flora are retained
 # on the terrain layer. Far apertures are restored after terrain classification.
 content=f'<rect width="{w}" height="{h}" fill="black"/>'+polygon(r['canopy'],'blue')
 for j,surf in enumerate(r['surfaces']):
  if i in [0,1,2,3] and j==0:
   contour=[[x,y-70] for x,y in surf]+[[w,h],[0,h]]
  else:
   depth=150 if i in [1,3] else 230
   contour=[[x-12 if q==0 else x+12 if q==len(surf)-1 else x,y-65] for q,(x,y) in enumerate(surf)]+[[surf[-1][0],min(h,surf[-1][1]+depth)],[surf[0][0],min(h,surf[0][1]+depth)]]
  content+=polygon(contour,'lime')
 for hole in r['holes']:content+=polygon(hole,'black')
 # Exact original ring silhouettes lie on the fixed interactive layer.
 for x,y in r['rings']:content+=f'<ellipse cx="{x}" cy="{y}" rx="47" ry="90" fill="lime"/>'
 # End gates and camps must never parallax away from their triggers.
 for x in [0,w-170]:content+=f'<rect x="{x}" y="{h*.43}" width="170" height="{h*.4}" fill="lime"/>'
 content+=polygon(r['foreground'],'red')
 write(f'assets/masks/{rid}-classes.svg',svg(w,h,content))
 holebody=f'<rect width="{w}" height="{h}" fill="black"/>'
 for j,a in enumerate(r['actors']):
  holebody+=polygon(a['shape'],['red','lime','blue','yellow'][j])
  actor_mask=f'<rect width="{w}" height="{h}" fill="black"/>'+polygon(a['shape'],'white')
  if i==3 and a['name']=='EnemyArt0':actor_mask+=polygon(claw,'black')
  write(f'assets/masks/{rid}-{a["name"]}.svg',svg(w,h,actor_mask))
 write(f'assets/masks/{rid}-actors.svg',svg(w,h,holebody))
 lines=['[gd_scene load_steps=20 format=3]',f'[ext_resource type="Texture2D" path="{r["reference"]}" id="1"]',f'[ext_resource type="Texture2D" path="res://assets/masks/{rid}-classes.svg" id="2"]',f'[ext_resource type="Texture2D" path="res://assets/masks/{rid}-actors.svg" id="3"]','[ext_resource type="Shader" path="res://scripts/layer.gdshader" id="4"]','[ext_resource type="Shader" path="res://scripts/extract.gdshader" id="5"]']
 for j,a in enumerate(r['actors']):lines.append(f'[ext_resource type="Texture2D" path="res://assets/masks/{rid}-{a["name"]}.svg" id="{6+j}"]')
 lines.append(f'[ext_resource type="Texture2D" path="res://assets/clean/{rid}-far.png" id="10"]')
 lines.append(f'[ext_resource type="Texture2D" path="res://assets/clean/{rid}.png" id="11"]')
 if i==3:
  write(f'assets/masks/{rid}-claw.svg',svg(w,h,f'<rect width="{w}" height="{h}" fill="black"/>'+polygon(claw,'white')))
  lines.append(f'[ext_resource type="Texture2D" path="res://assets/masks/{rid}-claw.svg" id="12"]')
 for k in range(4):
  lines += [f'[sub_resource type="ShaderMaterial" id="Layer{k}"]','shader = ExtResource("4")','shader_parameter/classes = ExtResource("2")','shader_parameter/actor_holes = ExtResource("3")',f'shader_parameter/layer_id = {k}',f'shader_parameter/source_size = Vector2({w}, {h})']
  for j in range(4):
   off=r['actors'][j]['offset'] if j<len(r['actors']) else [0,0]
   lines.append(f'shader_parameter/patch{j} = Vector2({off[0]}, {off[1]})')
   shape=r['actors'][j]['shape']if j<len(r['actors'])else [[-100,-100]]
   xs=[p[0]for p in shape];ys=[p[1]for p in shape]
   lines.append(f'shader_parameter/remove{j} = Vector4({min(xs)-14}, {min(ys)-14}, {max(xs)+14}, {max(ys)+14})')
  lines.append('shader_parameter/clean_plate = ExtResource("11")')
  lines.append('shader_parameter/far_plate = ExtResource("10")')
  lines.append(f'shader_parameter/fallback_reward = {3 if i==2 else -1}')
 for j,a in enumerate(r['actors']):
  lines +=[f'[sub_resource type="ShaderMaterial" id="Actor{j}"]','shader = ExtResource("5")',f'shader_parameter/silhouette = ExtResource("{6+j}")','shader_parameter/clean_plate = ExtResource("11")',f'shader_parameter/source_size = Vector2({w},{h})']
  xs=[v[0]for v in a['shape']];ys=[v[1]for v in a['shape']]
  lines.append(f'shader_parameter/bounds = Vector4({min(xs)-5},{min(ys)-5},{max(xs)+5},{max(ys)+5})')
  lines.append('shader_parameter/recover_edges = '+('true' if a['name']=='PlayerArt' or a['name'].startswith('EnemyArt') else 'false'))
  if i==3 and a['name']=='EnemyArt0':lines+=['shader_parameter/has_exclusion = true','shader_parameter/exclude_mask = ExtResource("12")']
 if i==3:lines +=['[sub_resource type="ShaderMaterial" id="Claw"]','shader = ExtResource("5")','shader_parameter/silhouette = ExtResource("12")']
 lines.append(f'[node name="{rid}" type="Node2D"]')
 for k,name in enumerate(['Far','Middle','World','Foreground']):
  lines +=[f'[node name="{name}" type="Node2D" parent="."]',f'z_index = {[-30,-15,0,10][k]}']
  if k==0:lines +=['[node name="OcclusionUnderpaint" type="Sprite2D" parent="Far"]','texture = ExtResource("10")','centered = false']
  lines +=[f'[node name="{name}OriginalPixels" type="Sprite2D" parent="{name}"]',f'material = SubResource("Layer{k}")','texture = ExtResource("1")','centered = false']
 lines +=['[node name="Terrain" type="Node2D" parent="World"]']
 for j,surf in enumerate(r['surfaces']):
  # Thin solid slabs allow the secondary route below the tongue surface.
  underside=list(reversed([[x,y+35]for x,y in surf]))
  lines +=[f'[node name="Surface{j}" type="StaticBody2D" parent="World/Terrain"]',f'[node name="Contour" type="CollisionPolygon2D" parent="World/Terrain/Surface{j}"]','polygon = '+packed(surf+underside)]
  if i==2 and j==0:lines.append('one_way_collision = true')
 for j,a in enumerate(r['actors']):
  lines +=[f'[node name="{a["name"]}" type="Node2D" parent="World"]','z_index = 4']
  parent=f'World/{a["name"]}'
  if a['name'].startswith('EnemyArt'):
   ep=r['enemies'][int(a['name'][-1])]['pos']
   lines +=[f'[node name="Pivot" type="Node2D" parent="{parent}"]',f'position = Vector2({ep[0]}, {ep[1]})']
   parent+='/Pivot'
  lines +=[f'[node name="OriginalSilhouette" type="Sprite2D" parent="{parent}"]',f'material = SubResource("Actor{j}")','texture = ExtResource("1")','centered = false']
  if a['name'].startswith('EnemyArt'):lines.append(f'position = Vector2({-ep[0]}, {-ep[1]})')
 if i==3:lines +=['[node name="BossClaw" type="Node2D" parent="World/EnemyArt0"]','position = Vector2(864,576)','[node name="Art" type="Sprite2D" parent="World/EnemyArt0/BossClaw"]','position = Vector2(-864,-576)','texture = ExtResource("1")','centered = false','material = SubResource("Claw")']
 write(f'scenes/r1/{rid}.tscn','\n\n'.join(lines)+'\n')
 manifest.append(dict(id=rid,source=str(f),sha256=hashlib.sha256(f.read_bytes()).hexdigest(),size=[w,h],layers=['Far','Middle','World','Foreground'],scene=f'scenes/r1/{rid}.tscn',masks=f'assets/masks/{rid}-classes.svg',actor_count=len(r['actors']),collision_contours=len(r['surfaces'])))

def door(pos,to,spawn,ability=''):return dict(pos=pos,to=to,spawn=spawn,ability=ability)
data[0]['doors']=[door([1600,650],1,[180,715])]
data[1]['doors']=[door([75,715],0,[1530,653]),door([1600,713],2,[255,580]),door([170,190],5,[190,790],'float'),door([1610,275],6,[250,571],'anchor')]
data[2]['doors']=[door([75,578],1,[1510,715]),door([1605,612],3,[381,709])]
data[3]['doors']=[door([80,645],2,[1500,612]),door([1505,710],4,[200,559],'boss')]
data[4]['doors']=[door([100,552],3,[1400,710]),door([1515,560],-1,[0,0])]
data[5]['doors']=[door([100,795],1,[195,185],'float'),door([1380,335],-2,[0,0])]
data[5]['doors'][1]['message']='R2-05远侧闩只能从另一侧开启；请原路返回须筛。'
data[6]['doors']=[door([95,568],1,[1510,275],'anchor')]
write('assets/rooms.json',json.dumps(data,ensure_ascii=False,indent=2))
write('docs/source-manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2))
write('docs/instruction-v05.md','''# 原图场景还原执行包 v0.5
输入：七房原图及用户上传的01—04图；首关全景与拆解册。
优先级：原图地形轮廓高于旧矩形坐标表；保留七房功能拓扑。
工具：Godot 4.7.2 Compatibility，Godot ShaderMaterial/Sprite2D、原生碰撞多边形；可编辑 SVG 分类遮罩由代码生成。PNG 原件不修改。
流程：01样板→七房遮罩与原生场景→交互与输入→实际图形运行→逐房截图与分层截图→便携构建复验。
费用：无外部生成或付费服务。
验收：原图对齐构图；地表碰撞沿曲面；原图角色独立，移动后不留同一烘焙角色；四层可独立显示；七房转换与支路回访；日志无脚本错误。
失败入口：掩膜及碰撞修 work/r1_v05_build.py；操作/状态修 scripts/main.gd 与 player.gd。保存失败日志再复测。
已知技术限制：原图为单张合成图，没有隐藏面的原始分层信息。角色背后采用 Godot 纹理邻域填补；较大位移处仍需独立背景精修，不能宣称恢复了原作者的完整图层。
''')
write('.production/state.json',json.dumps(dict(version='0.5',stage='scene_integration',status='in_progress',scope='原图七房场景还原',engine='4.7.2.stable.official.ed1daf0bf',next='运行图形场景并逐房对照'),ensure_ascii=False,indent=2))
print('built',len(data),'rooms;',sum(len(r['surfaces'])for r in data),'collision contours')
