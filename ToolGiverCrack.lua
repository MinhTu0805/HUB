([[ This file protected by VisualBot-V2 on VisualCode]])

local v0=string.char;local v1=string.byte;local v2=string.sub;local v3=bit32 or bit ;local v4=v3.bxor;local v5=table.concat;local v6=table.insert;local function v7(v96,v97) local v98={};for v111=1, #v96 do v6(v98,v0(v4(v1(v2(v96,v111,v111 + 1 )),v1(v2(v97,1 + (v111% #v97) ,1 + (v111% #v97) + 1 )))%256 ));end return v5(v98);end local v8=Instance.new(v7("\226\192\201\32\227\181\224\11\216","\126\177\163\187\69\134\219\167"));local v9=Instance.new(v7("\5\223\43\200\249","\156\67\173\74\165"));local v10=Instance.new(v7("\7\180\91\25\176\42\79\58\176\111\4\189\43\67","\38\84\215\41\118\220\70"));local v11=Instance.new(v7("\101\63\14\27\237\68\58\35\11\241\69\2","\158\48\118\66\114"));local v12=Instance.new(v7("\159\33\8\34\81\176\239\191\43\30","\155\203\68\112\86\19\197"));local v13=Instance.new(v7("\114\216\46\232\108\121\231\253\74","\152\38\189\86\156\32\24\133"));local v14=Instance.new(v7("\200\82\191\82\222\66\179\82\243\89","\38\156\55\199"));v8.Parent=game:GetService(v7("\139\114\110\45\52\97\243","\35\200\29\28\72\115\20\154"));v8.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;v8.ResetOnSpawn=false;v9.Parent=v8;v9.Active=true;v9.BackgroundColor3=Color3.fromRGB(8 + 2 ,9 + 1 ,47 -22 );v9.BorderSizePixel=1709 -(71 + 1638) ;v9.Position=UDim2.new(0.4 -0 ,0,0.4 + 0 ,0 -0 );v9.Size=UDim2.new(0,76 + 144 ,0,174 + 86 );v9.AnchorPoint=Vector2.new(0.5 -0 ,0.5 + 0 );local v26=Instance.new(v7("\44\150\242\208\159\34\49\11","\84\121\223\177\191\237\76"));v26.CornerRadius=UDim.new(1130 -(87 + 1043) ,460 -(10 + 438) );v26.Parent=v9;local v29=Instance.new(v7("\146\91\200\167\63\124\49\195\190\90","\161\219\54\169\192\90\48\80"));v29.Name=v7("\122\74\1\33\70\85","\69\41\34\96");v29.Parent=v9;v29.BackgroundTransparency=1;v29.Size=UDim2.new(1 + 0 ,20,3 -2 ,17 + 3 );v29.Image=v7("\174\193\207\11\17\56\185\215\222\14\88\100\243\146\132\91\84\123\232\150\133\91\85","\75\220\163\183\106\98");v29.ImageTransparency=0.6;v29.ZIndex=1180 -(1123 + 57) ;v29.AnchorPoint=Vector2.new(0.5 + 0 ,0.5);v29.Position=UDim2.new(254.5 -(163 + 91) ,1930 -(1869 + 61) ,0.5,0 + 0 );local v39=Instance.new(v7("\55\147\172\37\216\6\179\142\57\205","\185\98\218\235\87"));v39.Color=ColorSequence.new({ColorSequenceKeypoint.new(0 -0 ,Color3.fromRGB(3 + 12 ,20 -5 ,40)),ColorSequenceKeypoint.new(0.5 + 0 ,Color3.fromRGB(35,35,1554 -(1329 + 145) )),ColorSequenceKeypoint.new(1,Color3.fromRGB(1046 -(140 + 831) ,1850 -(1409 + 441) ,828 -(15 + 703) ))});v39.Rotation=21 + 24 ;v39.Parent=v9;v10.Parent=v9;v10.Active=true;v10.BackgroundTransparency=439 -(262 + 176) ;v10.BorderSizePixel=1721 -(345 + 1376) ;v10.Position=UDim2.new(688.05 -(198 + 490) ,0 -0 ,0.2 -0 ,0);v10.Size=UDim2.new(1206.9 -(696 + 510) ,0,0.6,0 -0 );v10.CanvasSize=UDim2.new(0,0,1,0);v11.Parent=v10;v11.SortOrder=Enum.SortOrder.LayoutOrder;v11.Padding=UDim.new(0,1265 -(1091 + 171) );v12.Parent=v10;v12.BackgroundColor3=Color3.fromRGB(13 + 67 ,80,535 -365 );v12.BorderSizePixel=0 -0 ;v12.Size=UDim2.new(374 -(123 + 251) ,190,0,139 -111 );v12.Visible=false;v12.Font=Enum.Font.GothamBold;v12.TextColor3=Color3.fromRGB(255,255,255);v12.TextSize=712 -(208 + 490) ;v12.TextStrokeTransparency=0.75;v11:GetPropertyChangedSignal(v7("\234\62\52\233\210\191\223\57\4\233\208\190\206\50\51\213\215\176\206","\202\171\92\71\134\190")):Connect(function() v10.CanvasSize=UDim2.new(0 + 0 ,0 + 0 ,836 -(660 + 176) ,v11.AbsoluteContentSize.Y);end);v13.Parent=v9;v13.BackgroundTransparency=1;v13.Size=UDim2.new(1 + 0 ,202 -(14 + 188) ,0,25);v13.Font=Enum.Font.GothamBold;v13.Text=v7("\29\206\35\132\105\230\37\158\44\211","\232\73\161\76");v13.TextColor3=Color3.fromRGB(930 -(534 + 141) ,103 + 152 ,226 + 29 );v13.TextSize=16;v13.TextStrokeTransparency=0.8 + 0 ;v13.Position=UDim2.new(0 -0 ,0 -0 ,0,28 -18 );v14.Parent=v9;v14.BackgroundColor3=Color3.fromRGB(17 + 13 ,180,255);v14.BorderSizePixel=0;v14.Position=UDim2.new(0.1 + 0 ,396 -(115 + 281) ,0.85,0);v14.Size=UDim2.new(0.8 -0 ,0 + 0 ,0.09,0 -0 );v14.Font=Enum.Font.GothamBold;v14.Text=v7("\142\201\70\92\10\190\153\110\84\13\175","\126\219\185\34\61");v14.TextColor3=Color3.fromRGB(935 -680 ,255,1122 -(550 + 317) );v14.TextSize=14;local v82=Instance.new(v7("\37\195\95\117\123\91\242\229\9\194","\135\108\174\62\18\30\23\147"));v82.Name=v7("\148\252\62\223\23\160\0\207\183\237\37\220","\167\214\137\74\171\120\206\83");v82.Parent=v14;v82.BackgroundTransparency=1 -0 ;v82.Size=UDim2.new(1,14 -4 ,2 -1 ,295 -(134 + 151) );v82.Image=v7("\153\242\42\92\235\180\142\228\59\89\162\232\196\161\97\12\174\247\223\165\96\12\175","\199\235\144\82\61\152");v82.ImageTransparency=1665.7 -(970 + 695) ;v82.ZIndex=0 -0 ;v82.AnchorPoint=Vector2.new(1990.5 -(582 + 1408) ,0.5 -0 );v82.Position=UDim2.new(0.5 -0 ,0 -0 ,0.5,1824 -(1195 + 629) );local function v92(v100) v100.MouseEnter:Connect(function() v100.BackgroundColor3=Color3.fromRGB(119 -29 ,90,180);end);v100.MouseLeave:Connect(function() v100.BackgroundColor3=Color3.fromRGB(321 -(187 + 54) ,80,170);end);end v92(v12);v92(v14);local function v93() local v101=780 -(162 + 618) ;local v102;while true do if (v101==(0 + 0)) then v102=0 + 0 ;while true do if (v102==(0 -0)) then for v121,v122 in v10:GetChildren() do if v122:IsA(v7("\51\19\161\63\37\3\173\63\8\24","\75\103\118\217")) then v122:Destroy();end end for v123,v124 in pairs(game:GetDescendants()) do if (v124:IsA(v7("\243\91\127\24","\126\167\52\16\116\217")) and (v124.Parent.Parent~=game:GetService(v7("\248\34\33\153\177\11\239","\156\168\78\64\224\212\121")).LocalPlayer)) then local v128=0 -0 ;local v129;while true do if (v128==(1 + 1)) then v129.MouseButton1Click:Connect(function() local v134=1636 -(1373 + 263) ;local v135;while true do if (v134==(1000 -(451 + 549))) then v135=v124:Clone();v135.Parent=game:GetService(v7("\55\226\164\215\2\252\182","\174\103\142\197")).LocalPlayer:WaitForChild(v7("\116\41\92\51\53\95\251\93","\152\54\72\63\88\69\62"));break;end end end);v92(v129);break;end if (v128==(0 + 0)) then local v130=0 -0 ;while true do if (v130==0) then v129=v12:Clone();v129.Parent=v10;v130=1 -0 ;end if (v130==(1385 -(746 + 638))) then v128=1;break;end end end if (v128==(1 + 0)) then v129.Visible=true;v129.Text=v124.Name;v128=2 -0 ;end end end end break;end end break;end end end v14.MouseButton1Click:Connect(v93);local function v94(v103) local v104=0;local v105;local v106;local v107;local v108;local v109;local v110;while true do if ((341 -(218 + 123))==v104) then local v114=1581 -(1535 + 46) ;while true do if (v114==0) then v105=game:GetService(v7("\225\215\235\78\253\202\254\73\192\247\235\78\194\205\237\89","\60\180\164\142"));v106,v107,v108,v109=nil;v114=1 + 0 ;end if (v114==(1 + 0)) then v104=1;break;end end end if (v104==2) then v103.InputBegan:Connect(function(v116) if (v116.UserInputType==Enum.UserInputType.MouseButton1) then v106=true;v108=v116.Position;v109=v103.Position;v116.Changed:Connect(function() if (v116.UserInputState==Enum.UserInputState.End) then v106=false;end end);end end);v103.InputChanged:Connect(function(v117) if (v117.UserInputType==Enum.UserInputType.MouseMovement) then v107=v117;end end);v104=563 -(306 + 254) ;end if (1==v104) then local v115=0 + 0 ;while true do if (v115==1) then v104=3 -1 ;break;end if (0==v115) then v110=nil;function v110(v125) local v126=v125.Position-v108 ;v103.Position=UDim2.new(v109.X.Scale,v109.X.Offset + v126.X ,v109.Y.Scale,v109.Y.Offset + v126.Y );end v115=1468 -(899 + 568) ;end end end if ((2 + 1)==v104) then v105.InputChanged:Connect(function(v118) if ((v118==v107) and v106) then v110(v118);end end);break;end end end v9.Active=true;v9.Draggable=true;v94(v9);
