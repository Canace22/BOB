# ISNet动作逐项资产复核

这是已完成图集的全帧本体/特效复核，不等于游戏操作或正式美术最终验收。帧号从0开始；来源hash锁定被检查版本。

| 动作 | 状态 | 本体 | 特效 | 处理建议 |
|---|---|---|---|---|
| walk | needs_matte_repair | 24帧逐帧深浅底检查：5/14地影明显，4/16/21脚边尾影；叉头基本完整。部分脚形与自由手运动模糊来自源片。 | manifest fx is null | BiRefNet重抠样板5/14，再决定全动作；抠像不修源变形。 |
| jump | candidate_clean | 18帧身体、叉齿、红绳完整；无显著地影、道具或裁切。 | manifest fx is null | 在游戏中按rise/apex/fall/land切段；不得把全展示段作为单次跳跃时长。 |
| double_jump | candidate_with_baked_membrane | 16帧身体完整；膜翼从2到12存在于body内，边缘清楚，不是独立FX。 | 已看16帧独立FX：只有少量淡残光，主膜翼在body；不重复生成同翼。 | 保留一次烘焙膜翼，禁止额外叠同膜翼；须实机验证触发与结束。 |
| wall_slide | needs_magenta_cleanup | 20帧仍留穿过手/身体的品红竖条及脚下细线；披风边有少量粉溢色，叉及主体未缺失。 | manifest fx is null | 对本品红背景源做限定色键与溢色清理，保护红绳；不要全局删红。 |
| wall_jump | needs_source_limb_review | 10帧叉/身体无明显透明缺块，但左后蹼状肢体与下方及右方两脚同时出现，像额外靴/手脚混淆。 | manifest fx is null | 复核左后附肢是否符合角色手形；如不符需补制，BiRefNet不能修复造型。 |
| float | needs_registration_repair | 24帧本体与烘焙膜翼干净，但13/22整体向左上跳；torso错误切换到[421,213]/[421,222]，相邻正常约[380,123]/[379,132.5]。 | null; membrane baked into body | 修注册离群，13用[379.75,123]，22用[379,132.5]或稳定跟踪；勿重生成。 |
| anchor | candidate_minor_magenta_fringe | 20帧本体完整，无原吊环/外绳/地影；少量脚尖、披风边品红溢色。 | null; runtime rope is world-space | 限定品红去溢色；采用已复核20帧真实握叉手挂点。 |
| strike2 | needs_source_pose_repair | 12帧中的1/2手与叉严重融化；3–8举叉姿态完整。 | null | 补关键姿势或明确跳过变形帧；换matte不能修造型。 |
| upper | candidate_baked_tip_flash | 12帧身体和叉完整，3/5等水平闪光部分随body。 | 已看独立加法FX12帧，为body保护区外剩余闪光，未发现额外道具。 | 确认技能事件；不要重复叠同一叉尖闪光。 |
| pogo | candidate_clean | 12帧身体、下刺叉完整，选择接壳前片段成功，无贝壳/地影残留。 | null | 真实碰撞驱动反弹，非源展示贝壳碰撞。 |
| orb | candidate_with_source_release_smear | 16帧主体完整，无独立源弹体粘连；蓄力口光烘于body，10帧推出时手/叉有源模糊拉伸，11–15恢复可辨。 | null; independently simulated projectile | 复核发射瞬间；若10帧影响阅读，换清楚推出姿势，不靠matte修原形。 |
| heavy | needs_ground_layer_repair | 16帧完整；8–11局部冲击与12/13整圈地环进入body。 | 独立FX多为body保护外残光；12/13环主要留在body。 | 源y330..410拆明亮青环，保留深靴与象牙叉；竖溅y295..330另处理。 |
| dive | needs_ground_layer_and_weapon_review | 20帧body12含整圈落地环；1–19源武器柄长成杖，区别于角色短叉。 | 独立FX13–19环可见，12仅残光；须与body互补后固定真实落地点。 | 环源y350..432限定色拆，保护靴/柄；长柄是源造型问题需记录或补制。 |
| slit | needs_magenta_cleanup | 18帧叉与手完整，但手臂/红绳间品红底留块、靴边粉边。源动作从蹲变直又蹲。 | null | 品红排除/去溢色后复核，潜隙期间展示高度须配合缩矮碰撞与头顶空间。 |
| heal | candidate_clean | 24帧身体、手叉与红绳清楚，抬手触灯动作完整，无地影/背景。 | null; waist lamp illumination remains in body | 治疗时序仍由技能驱动。 |
| scan | needs_ground_fx_boundary_repair | 16帧身体完整，轻微脚边暖光，无大块地环烘焙。 | 环下半被floor cutoff裁掉；仅剩上半环。源15外环还在视频边界被截。 | 扫描环为琥珀色，源ROI y320..432，保持body保护并取消floor cutoff，最后边界裁切需早收/淡出。 |
| interact | candidate_clean | 13帧伸手/撤回本体清楚，无测试圆把手，保留另一手握叉。 | null | 事件在往返中点触发一次，不因反向帧再触发。 |
| defeat | candidate_clean | 36帧跪下、本体与叉清楚，最后灯熄灭；中间包含静态保持。 | null | 游戏死亡状态不能被静态保持长度锁死复活。 |
| shadow_dash | needs_clean_body_reuse | 1–7长黑尾与灰白角色残像一起进入body，3–7左侧硬裁；4/5多出第二个灰角色，6/7灰像异常。 | null; source afterimages are incorrectly baked into body | 复用已清楚dash位图本体+运行时影潮着色与历史位置残影；显式记录复用来源。 |
| great_slash | candidate_baked_local_arc | 16帧：7/9/10/11/13有烘焙局部刀弧；9–11三帧脚被发力亮闪短暂遮挡，12恢复，14/15完整，不属于持续缺脚。 | 已看16帧：body与FX互补；8–15下边硬截断。 | 取消刀弧地面硬截；保留局部烘焙方式且不重复同刀光；94px实机检查。 |
| dash_slash | candidate_baked_local_arc | 12帧身体完整；4含亮刀弧，5–11姿态可读。 | 已看12帧：互补刀弧，6灰色地面残片，6–9底纹。 | 保留局部刀弧，清理地面残留且取消刀弧硬截。 |
| cyclone | needs_disconnected_leg_restore | 24帧中6/9/12/14/16整段腿脚缺失；原源片各帧双腿可见，属于分离损失。 | 腰部旋转环已拆为互补FX，但6–21残留地面投影环；body局部青光烘焙。 | 恢复躯干下方独立腿脚组件，去FX地面投影。 |
| crystal_dash | candidate_clean | 24帧身体完整，蓄力0–13、飞行14–22、退出23；无明显背景残留。 | manifest fx is null | 按蓄力/飞行循环/退出段播放，由物理推进与撞墙退出；不可整段展示时长驱动物理。 |
| up_spell | candidate_local_baked_effect | 完整身体与高举手；2为瞬时竖弧发力帧，3–12举手持续，13–15收势。 | 16帧独立上方三层弧完整；2部分局部弧在body，互补不重复。 | 按实际持续/多段窗口播放，实机验证上方攻击范围与弧对齐；不叠加重复局部效果。 |
| abyss_scream | candidate_local_baked_effect | 完整身体与高举手；3局部上弧烘焙，4–16举手持续，17–19收势。 | 20帧独立上方三层弧完整；当前additive显示浅色轮廓，暗芯在此混合方式下不作遮挡。 | 按实际持续/多段窗口播放，实机验证上方攻击范围与弧对齐；不叠加重复局部效果。 |
| shadow_orb | candidate_baked_charge | 16帧完整；5–11叉口球为蓄力状态烘焙，12–15发射后body不含离体球。 | manifest fx is null | 发射事件对齐11→12，运行弹体独立；不再叠同一叉口蓄球。 |
| dark_dive | needs_registration_and_dark_ring | 24帧身体短叉与四肢完整；10–17注册误选地环造成明显横漂瞬移；8轻微地环附脚。 | 0–18几乎为空；19–23只提取浅色尾环，暗青主环未作为FX保留。 | 10–17按已提供真披风坐标override；源地环y270..329应alpha提取而非仅additive残光，保护脚底293。 |
| swim | candidate_loop_check | 24帧身体、叉、红绳完整，无水池/背景残留；首尾手脚姿势不同。 | manifest fx is null | 实机循环检查接缝，按循环窗口选帧；物理由水域/耐蚀条件控制。 |
| tram | candidate_clean | 16帧完整，手持票证为本动作必要道具保留，无源门背景。 | manifest fx is null | 交互由通行证条件/真实门状态触发，不能当攻击。 |
| turn | candidate_direction_rule | 8帧完整，原源本身从0向右转至7向左。 | manifest fx is null | 以进入turn的旧facing固定镜像，结束后新facing；不能进入即新facing翻整段；移动不等转身锁。 |

dark_dive production decision: 原版拒用：注册选中地环瞬移且暗青主环丢失。正式升级复用dive新8姿态本体与独立dive地环，深青tint和1.2尺度；原视频仅superseded_source，非重新提取成功。
