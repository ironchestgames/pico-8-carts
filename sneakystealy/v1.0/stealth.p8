pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- sneaky stealy 1.0
-- by ironchest games

--[[

notes:
 - any _i is the position, where the part before *32 is the y-axis, and the the one after *32+ is the x-axis
 - local _x,_y=_i&31,_i\32

cartdata layout:
 0 - highscore
 1 - cash
 2 - day
 3 - wantedness

--]]

--[[

todo

- fix camcontrol power off bug

- increase chance of locked doors to room with safe?

- msg.y's should not be in same interval

- clearer texts of why the alarm goes of (maybe do different values for when lighted by camera or guard, then have text "camera: statuette gone!")

- filing drawers
 - search (up/down?)

- bug if suspect seen and caught same tick (came out of hiding for ex)

- guard behaviour
 - go towards player if lighted
 - standing guard

- cabinet
 - search (how? just open?)

- table???
 - hide under

- busting out of jail???

- names: johnny, jimmy, tommy, timmy, benny, lenny, ray, jay, donny, sonny, fred, ted, zed, tony, vince, roy

--]]

cartdata'ironchestgames_sneakystealy_v1'



-- s2t usage:
-- t=s2t'1;2;3;4;5;6;7;hej pa dig din gamle gries;'
-- t=s2t'.x;1;.y;2;'
function s2t(s)
 local _t,_i,_s,_d={},1,''
 repeat
  _d,s=sub(s,1,1),sub(s,2)
  if _d != ';' then
   _s=_s.._d
  else
   if sub(_s,1,1) != '.' then
    _s=tonum(_s) or _s
   end
   _t[_i]=_s
   if (_s == '') _t[_i]=nil
   _i+=1
   _s=''
  end
 until #s == 0
 for _i=2,#_t,2 do
  local _tib=_t[_i-1]
  if sub(tostr(_tib),1,1) == '.' then
   _s=sub(_tib,2)
   _s=tonum(_s) or _s
   _t[_s],_t[_i-1],_t[_i]=_t[_i]
  end
 end
 return _t
end

local tick
local msgs
local floor
local objs
local cameras
local alertlvl

local players
local escapedplayers
local playerinventory

local guards

local seli
local ispoweron
local mapthings

local initpolice
local initstatus
local initsplash

local fogdirs,
 camcontrolscreenpos,
 floorlightcols,
 adjdeltas,
 cameradirs,
 windowpeekdys,
 doortypopened,
 doortypclosed,
 computerstatetoyoffset,
 guardsholdingdeltas,
 guarddxdeltas,
 guarddydeltas,
 light,
 alertlvls,
 msgcols,
 fog,
 arslen,
 policet,
 wantedness,
 seenaddend={
  s2t'.x;1;.y;0;.dx;1;.dy;1;', -- fogdirs
  s2t'.x;1;.y;0;.dx;1;.dy;-1;',
  s2t'.x;-1;.y;0;.dx;-1;.dy;1;',
  s2t'.x;-1;.y;0;.dx;-1;.dy;-1;',
  s2t'.x;0;.y;1;.dx;1;.dy;1;',
  s2t'.x;0;.y;1;.dx;-1;.dy;1;',
  s2t'.x;0;.y;-1;.dx;1;.dy;-1;',
  s2t'.x;0;.y;-1;.dx;-1;.dy;-1;',
 },
 { -- camcontrolscreenpos
  s2t'.x;-2;.y;-4;',
  s2t'.x;3;.y;-4;',
  s2t'.x;-2;.y;-1;',
  s2t'.x;3;.y;-1;',
 },
 s2t'.0;0;.1;1;.2;2;.3;0;.11;13;.12;2;', -- floorlightcols
 s2t'.0;-1;.1;1;.2;-32;.3;32;', -- adjdeltas
 s2t'8;12;', -- cameradirs
 s2t'-64;-32;0;32;', -- windowpeekdys
 s2t'.14;15;.18;20;.19;20;', -- doortypopened
 s2t'.15;14;.20;19;', -- doortypclosed
 s2t'.booting;-3;.success;9;.fail;12;', -- computerstatetoyoffset
 s2t'-65;-64;-63;-34;-33;-32;-31;-30;-2;-1;0;1;2;30;31;32;33;34;63;64;65;', -- guardsholdingdeltas
 s2t'.0;1;.1;-1;.2;0;.3;0;', -- guarddxdeltas
 s2t'.0;0;.1;0;.2;1;.3;-1;', -- guarddydeltas
 s2t'.0;0;.1;0;.2;0;.3;0;.4;0;.5;0;.6;0;.7;0;.8;0;.9;0;.10;0;.11;0;.12;0;.13;0;.14;0;.15;0;.16;0;.17;0;.18;0;.19;0;.20;0;.21;0;.22;0;.23;0;.24;0;.25;0;.26;0;.27;0;.28;0;.29;0;.30;0;.31;0;.32;0;.33;0;.34;0;.35;0;.36;0;.37;0;.38;0;.39;0;.40;0;.41;0;.42;0;.43;0;.44;0;.45;0;.46;0;.47;0;.48;0;.49;0;.50;0;.51;0;.52;0;.53;0;.54;0;.55;0;.56;0;.57;0;.58;0;.59;0;.60;0;.61;0;.62;0;.63;0;.64;0;.65;0;.66;0;.67;0;.68;0;.69;0;.70;0;.71;0;.72;0;.73;0;.74;0;.75;0;.76;0;.77;0;.78;0;.79;0;.80;0;.81;0;.82;0;.83;0;.84;0;.85;0;.86;0;.87;0;.88;0;.89;0;.90;0;.91;0;.92;0;.93;0;.94;0;.95;0;.96;0;.97;0;.98;0;.99;0;.100;0;.101;0;.102;0;.103;0;.104;0;.105;0;.106;0;.107;0;.108;0;.109;0;.110;0;.111;0;.112;0;.113;0;.114;0;.115;0;.116;0;.117;0;.118;0;.119;0;.120;0;.121;0;.122;0;.123;0;.124;0;.125;0;.126;0;.127;0;.128;0;.129;0;.130;0;.131;0;.132;0;.133;0;.134;0;.135;0;.136;0;.137;0;.138;0;.139;0;.140;0;.141;0;.142;0;.143;0;.144;0;.145;0;.146;0;.147;0;.148;0;.149;0;.150;0;.151;0;.152;0;.153;0;.154;0;.155;0;.156;0;.157;0;.158;0;.159;0;.160;0;.161;0;.162;0;.163;0;.164;0;.165;0;.166;0;.167;0;.168;0;.169;0;.170;0;.171;0;.172;0;.173;0;.174;0;.175;0;.176;0;.177;0;.178;0;.179;0;.180;0;.181;0;.182;0;.183;0;.184;0;.185;0;.186;0;.187;0;.188;0;.189;0;.190;0;.191;0;.192;0;.193;0;.194;0;.195;0;.196;0;.197;0;.198;0;.199;0;.200;0;.201;0;.202;0;.203;0;.204;0;.205;0;.206;0;.207;0;.208;0;.209;0;.210;0;.211;0;.212;0;.213;0;.214;0;.215;0;.216;0;.217;0;.218;0;.219;0;.220;0;.221;0;.222;0;.223;0;.224;0;.225;0;.226;0;.227;0;.228;0;.229;0;.230;0;.231;0;.232;0;.233;0;.234;0;.235;0;.236;0;.237;0;.238;0;.239;0;.240;0;.241;0;.242;0;.243;0;.244;0;.245;0;.246;0;.247;0;.248;0;.249;0;.250;0;.251;0;.252;0;.253;0;.254;0;.255;0;.256;0;.257;0;.258;0;.259;0;.260;0;.261;0;.262;0;.263;0;.264;0;.265;0;.266;0;.267;0;.268;0;.269;0;.270;0;.271;0;.272;0;.273;0;.274;0;.275;0;.276;0;.277;0;.278;0;.279;0;.280;0;.281;0;.282;0;.283;0;.284;0;.285;0;.286;0;.287;0;.288;0;.289;0;.290;0;.291;0;.292;0;.293;0;.294;0;.295;0;.296;0;.297;0;.298;0;.299;0;.300;0;.301;0;.302;0;.303;0;.304;0;.305;0;.306;0;.307;0;.308;0;.309;0;.310;0;.311;0;.312;0;.313;0;.314;0;.315;0;.316;0;.317;0;.318;0;.319;0;.320;0;.321;0;.322;0;.323;0;.324;0;.325;0;.326;0;.327;0;.328;0;.329;0;.330;0;.331;0;.332;0;.333;0;.334;0;.335;0;.336;0;.337;0;.338;0;.339;0;.340;0;.341;0;.342;0;.343;0;.344;0;.345;0;.346;0;.347;0;.348;0;.349;0;.350;0;.351;0;.352;0;.353;0;.354;0;.355;0;.356;0;.357;0;.358;0;.359;0;.360;0;.361;0;.362;0;.363;0;.364;0;.365;0;.366;0;.367;0;.368;0;.369;0;.370;0;.371;0;.372;0;.373;0;.374;0;.375;0;.376;0;.377;0;.378;0;.379;0;.380;0;.381;0;.382;0;.383;0;.384;0;.385;0;.386;0;.387;0;.388;0;.389;0;.390;0;.391;0;.392;0;.393;0;.394;0;.395;0;.396;0;.397;0;.398;0;.399;0;.400;0;.401;0;.402;0;.403;0;.404;0;.405;0;.406;0;.407;0;.408;0;.409;0;.410;0;.411;0;.412;0;.413;0;.414;0;.415;0;.416;0;.417;0;.418;0;.419;0;.420;0;.421;0;.422;0;.423;0;.424;0;.425;0;.426;0;.427;0;.428;0;.429;0;.430;0;.431;0;.432;0;.433;0;.434;0;.435;0;.436;0;.437;0;.438;0;.439;0;.440;0;.441;0;.442;0;.443;0;.444;0;.445;0;.446;0;.447;0;.448;0;.449;0;.450;0;.451;0;.452;0;.453;0;.454;0;.455;0;.456;0;.457;0;.458;0;.459;0;.460;0;.461;0;.462;0;.463;0;.464;0;.465;0;.466;0;.467;0;.468;0;.469;0;.470;0;.471;0;.472;0;.473;0;.474;0;.475;0;.476;0;.477;0;.478;0;.479;0;.480;0;.481;0;.482;0;.483;0;.484;0;.485;0;.486;0;.487;0;.488;0;.489;0;.490;0;.491;0;.492;0;.493;0;.494;0;.495;0;.496;0;.497;0;.498;0;.499;0;.500;0;.501;0;.502;0;.503;0;.504;0;.505;0;.506;0;.507;0;.508;0;.509;0;.510;0;.511;0;.512;0;.513;0;.514;0;.515;0;.516;0;.517;0;.518;0;.519;0;.520;0;.521;0;.522;0;.523;0;.524;0;.525;0;.526;0;.527;0;.528;0;.529;0;.530;0;.531;0;.532;0;.533;0;.534;0;.535;0;.536;0;.537;0;.538;0;.539;0;.540;0;.541;0;.542;0;.543;0;.544;0;.545;0;.546;0;.547;0;.548;0;.549;0;.550;0;.551;0;.552;0;.553;0;.554;0;.555;0;.556;0;.557;0;.558;0;.559;0;.560;0;.561;0;.562;0;.563;0;.564;0;.565;0;.566;0;.567;0;.568;0;.569;0;.570;0;.571;0;.572;0;.573;0;.574;0;.575;0;.576;0;.577;0;.578;0;.579;0;.580;0;.581;0;.582;0;.583;0;.584;0;.585;0;.586;0;.587;0;.588;0;.589;0;.590;0;.591;0;.592;0;.593;0;.594;0;.595;0;.596;0;.597;0;.598;0;.599;0;.600;0;.601;0;.602;0;.603;0;.604;0;.605;0;.606;0;.607;0;.608;0;.609;0;.610;0;.611;0;.612;0;.613;0;.614;0;.615;0;.616;0;.617;0;.618;0;.619;0;.620;0;.621;0;.622;0;.623;0;.624;0;.625;0;.626;0;.627;0;.628;0;.629;0;.630;0;.631;0;.632;0;.633;0;.634;0;.635;0;.636;0;.637;0;.638;0;.639;0;.640;0;.641;0;.642;0;.643;0;.644;0;.645;0;.646;0;.647;0;.648;0;.649;0;.650;0;.651;0;.652;0;.653;0;.654;0;.655;0;.656;0;.657;0;.658;0;.659;0;.660;0;.661;0;.662;0;.663;0;.664;0;.665;0;.666;0;.667;0;.668;0;.669;0;.670;0;.671;0;.672;0;.673;0;.674;0;.675;0;.676;0;.677;0;.678;0;.679;0;.680;0;.681;0;.682;0;.683;0;.684;0;.685;0;.686;0;.687;0;.688;0;.689;0;.690;0;.691;0;.692;0;.693;0;.694;0;.695;0;.696;0;.697;0;.698;0;.699;0;.700;0;.701;0;.702;0;.703;0;.704;0;.705;0;.706;0;.707;0;.708;0;.709;0;.710;0;.711;0;.712;0;.713;0;.714;0;.715;0;.716;0;.717;0;.718;0;.719;0;.720;0;.721;0;.722;0;.723;0;.724;0;.725;0;.726;0;.727;0;.728;0;.729;0;.730;0;.731;0;.732;0;.733;0;.734;0;.735;0;.736;0;.737;0;.738;0;.739;0;.740;0;.741;0;.742;0;.743;0;.744;0;.745;0;.746;0;.747;0;.748;0;.749;0;.750;0;.751;0;.752;0;.753;0;.754;0;.755;0;.756;0;.757;0;.758;0;.759;0;.760;0;.761;0;.762;0;.763;0;.764;0;.765;0;.766;0;.767;0;.768;0;.769;0;.770;0;.771;0;.772;0;.773;0;.774;0;.775;0;.776;0;.777;0;.778;0;.779;0;.780;0;.781;0;.782;0;.783;0;.784;0;.785;0;.786;0;.787;0;.788;0;.789;0;.790;0;.791;0;.792;0;.793;0;.794;0;.795;0;.796;0;.797;0;.798;0;.799;0;.800;0;.801;0;.802;0;.803;0;.804;0;.805;0;.806;0;.807;0;.808;0;.809;0;.810;0;.811;0;.812;0;.813;0;.814;0;.815;0;.816;0;.817;0;.818;0;.819;0;.820;0;.821;0;.822;0;.823;0;.824;0;.825;0;.826;0;.827;0;.828;0;.829;0;.830;0;.831;0;.832;0;.833;0;.834;0;.835;0;.836;0;.837;0;.838;0;.839;0;.840;0;.841;0;.842;0;.843;0;.844;0;.845;0;.846;0;.847;0;.848;0;.849;0;.850;0;.851;0;.852;0;.853;0;.854;0;.855;0;.856;0;.857;0;.858;0;.859;0;.860;0;.861;0;.862;0;.863;0;.864;0;.865;0;.866;0;.867;0;.868;0;.869;0;.870;0;.871;0;.872;0;.873;0;.874;0;.875;0;.876;0;.877;0;.878;0;.879;0;.880;0;.881;0;.882;0;.883;0;.884;0;.885;0;.886;0;.887;0;.888;0;.889;0;.890;0;.891;0;.892;0;.893;0;.894;0;.895;0;.896;0;.897;0;.898;0;.899;0;.900;0;.901;0;.902;0;.903;0;.904;0;.905;0;.906;0;.907;0;.908;0;.909;0;.910;0;.911;0;.912;0;.913;0;.914;0;.915;0;.916;0;.917;0;.918;0;.919;0;.920;0;.921;0;.922;0;.923;0;.924;0;.925;0;.926;0;.927;0;.928;0;.929;0;.930;0;.931;0;.932;0;.933;0;.934;0;.935;0;.936;0;.937;0;.938;0;.939;0;.940;0;.941;0;.942;0;.943;0;.944;0;.945;0;.946;0;.947;0;.948;0;.949;0;.950;0;.951;0;.952;0;.953;0;.954;0;.955;0;.956;0;.957;0;.958;0;.959;0;.960;0;.961;0;.962;0;.963;0;.964;0;.965;0;.966;0;.967;0;.968;0;.969;0;.970;0;.971;0;.972;0;.973;0;.974;0;.975;0;.976;0;.977;0;.978;0;.979;0;.980;0;.981;0;.982;0;.983;0;.984;0;.985;0;.986;0;.987;0;.988;0;.989;0;.990;0;.991;0;.992;0;.993;0;.994;0;.995;0;.996;0;.997;0;.998;0;.999;0;.1000;0;.1001;0;.1002;0;.1003;0;.1004;0;.1005;0;.1006;0;.1007;0;.1008;0;.1009;0;.1010;0;.1011;0;.1012;0;.1013;0;.1014;0;.1015;0;.1016;0;.1017;0;.1018;0;.1019;0;.1020;0;.1021;0;.1022;0;.1023;0;', -- light
 s2t'24;8;', -- alertlvls, note: only tick time
 {s2t'6;13;',s2t'9;10;'}, -- msgcols
 {}, -- fog
 1023, -- arslen, note: 32*32-1
 0, -- policet
 0, -- wantedness
 0 -- seenaddend


-- helper funcs

local function curry3(_f,_a,_b,_c)
 return function()
  _f(_a,_b,_c)
 end
end

local function shuffle(_l)
 for _i=#_l,2,-1 do
  local _j=flr(rnd(_i))+1
  _l[_i],_l[_j]=_l[_j],_l[_i]
 end
 return _l
end


local function adjacency(_x1,_y1,_x2,_y2)
 if _x1 == _x2-1 and _y1 == _y2 then
  return 0
 elseif _x1 == _x2+1 and _y1 == _y2 then
  return 1
 elseif _x1 == _x2 and _y1 == _y2-1 then
  return 2
 elseif _x1 == _x2 and _y1 == _y2+1 then
  return 3
 end
 -- return nil
end

local function walladjacency(_a)
 local _i=_a.y*32+_a.x
 for _j=0,3 do
  local _tile=floor[_i+adjdeltas[_j]]
  if _tile and _tile >= 2 then
   return _j
  end
 end
 -- return nil
end



local function playerloots(_p,_o)
 local _m='(nothing of value)'
 if _o.loot then
  _m=_o.loot[1]
  if _o.loot[2] then -- has value, then it's a thing, take it
   add(_p.loot,_o.loot)
  else
   add(playerinventory,_o.loot) -- no value, it's information
  end
 end
 add(msgs,{_p.x,_p.y-1,_m,1,20})
 _o.loot=nil
end


local function setalertlvl2(_m,_x,_y)
 if alertlvl == 1 then
  sfx(21)
  alertlvl,tick,policet=2,60,60
  for _g in all(guards) do
   _g.state,_g.state_c='patrolling',0
  end
  add(msgs,{_x,_y,_m,2})
 end
end


local function makesound(_p,_sfx,_loudness)
 sfx(_sfx)
 for _g in all(guards) do
  local _dx,_dy=_g.x-_p.x,_g.y-_p.y
  local _h=sqrt(_dx*_dx+_dy*_dy)
  _loudness=_loudness or 6
  if _h < _loudness then
   local _newdir,_m=flr(rnd(4)),'!'
   _g.dx,_g.dy=guarddxdeltas[_newdir],guarddydeltas[_newdir]
   if alertlvl == 1 then
    _g.state,_m='listening','?'
    _g.state_c+=flr(rnd(3))+5
   end
   add(msgs,{_g.x,_g.y,_m,2,30})
  end
 end
end


local function computer(_p,_o,_tmp)
 _p.workingstate='hacking'
 if ispoweron then
  if not _tmp.action_c then
   _tmp.seq,_tmp.action_c,_tmp.state={},0,'booting'
   makesound(_p,11)
   local _l=6+flr(rnd(8))
   for _i=1,_l do
    local _n=0
    repeat
     _n=flr(rnd(3))
    until _n != _tmp.seq[_i-1]
    _tmp.seq[_i]=_n
   end
   _o.draw=function()
    local _yoffset=0
    if computerstatetoyoffset[_tmp.state] then
     _yoffset=computerstatetoyoffset[_tmp.state]
    else
     _yoffset=_tmp.seq[1]*3
    end
    sspr(0,105+_yoffset,4,3,_tmp.ox*4,_tmp.oy*4-3)
   end
  end

  _tmp.action_c+=1

  if _tmp.action_c == 30 then
   _tmp.state='ready'
   makesound(_p,12)
  end

  if _tmp.state == 'ready' then
   local _input
   for _i=0,2 do
    if btnp(_i,_p.i) then
     _input=_i
    end
   end

   if _input then
    if _input == _tmp.seq[1] then
     del(_tmp.seq,_input)
     if #_tmp.seq == 0 then
      _tmp.state='success'
      makesound(_p,10)
      playerloots(_p,_o)
     end
    else
     _tmp.state='fail'
     makesound(_p,9)
    end
   end
  end

 else
  _tmp.action_c,_o.draw=nil
 end

 if btnp(3,_p.i) then
  -- reset player and obj
  _p.state,_p.action,_o.draw='standing'
 end
end


-- states:
-- 0 - off
-- 1 - on
-- 2 - selected/on (camcontrol)
-- 3 - system alarm (camcontrol) (not used)
local function camcontrol(_p,_o,_tmp)
 _p.workingstate='hacking'
 if ispoweron then
  if not _tmp.sel then
   _tmp.sel,_tmp.pos=0,camcontrolscreenpos

   -- start all cameras
   for _i=1,4 do
    local _c=cameras[_i]
    _tmp.pos[_i].state=1
    if _c then
     _c.state=1
    end
   end

   _tmp.pos[1].state=2

   _o.draw=function()
    for _i=1,#_tmp.pos do
     local _p=_tmp.pos[_i]
     sspr(0,120+_p.state*2,3,2,_tmp.ox*4+_p.x,_tmp.oy*4+_p.y)
    end
   end

   makesound(_p,11)
  end

  _tmp.pos[_tmp.sel+1].state=1

  if btnp(0,_p.i) then
   _tmp.sel-=1
  elseif btnp(1,_p.i) then
   _tmp.sel+=1
  end

  _tmp.sel=_tmp.sel%4
  _tmp.pos[_tmp.sel+1].state=2

  if btnp(2,_p.i) then
   for _i=1,4 do
    _tmp.pos[_i].state=1
   end
   _tmp.pos[_tmp.sel+1].state=0
   _tmp.sel=(_tmp.sel+1)%4
   _tmp.pos[_tmp.sel+1].state=2
  end

  for _c in all(cameras) do
   _c.state=_tmp.pos[_c.i].state
  end

  local _count=0
  for _p in all(_tmp.pos) do
   if _p.state == 0 then
    _count+=1
   end
  end

 else
  _tmp.sel,_o.draw=nil
 end

 if btnp(3,_p.i) then
  -- reset player and obj
  _p.state,_p.action,_o.draw='standing'

  -- reset all cameras
  if _tmp.pos then
   for _i=1,4 do
    _tmp.pos[_i].state=1
    local _c=cameras[_i]
    if _c then
     _c.state=1
    end
   end
  end
 end
end


local function safe(_p,_o,_tmp)
 _p.workingstate='cracking'
 if not _o.isopen then

  -- reset for this try
  if not _tmp.code then
   _tmp.code,_tmp.codei,_tmp.codetick,_tmp.codedir=_o.code,1,0,_o.codedir

   _o.draw=function()
    local _x,_y=_tmp.ox*4+5,_tmp.oy*4-3
    if not _o.isopen then
     if _tmp.iserror then
      pset(_x,_y,8)
     elseif _tmp.unlocked then
      pset(_x,_y,11)
     end
    end
   end
  end

  for _i=0,1 do
   if btnp(_i,_p.i) then
    if not _tmp.codedir then
     _tmp.codedir,_o.codedir=_i,_i
    end
    local _snd
    if _tmp.codedir == _i then
     _tmp.codetick+=1
     if _tmp.codetick == _tmp.code[_tmp.codei] and not _tmp.iserror then
      _tmp.unlocked=_tmp.codei == #_tmp.code
      _tmp.codei+=1
      _tmp.codedir,_tmp.codetick,_snd=abs(_i-1),0,true
      sfx(14) -- high click
     end
    else
     _tmp.iserror=true
     _tmp.unlocked=false
    end
    if not _snd then -- todo: token hunt, maybe order sfx so you can do sfx(14+_sfxi)
     sfx(15) -- click
    end
   end
  end

  if _tmp.unlocked and btnp(2,_p.i) then
   _o.isopen=true
   objs[_tmp.oi].typ+=2
   objs[_tmp.oi+1].typ+=2
   makesound(_p,10) -- creek open
   playerloots(_p,_o)
  end
 end
 
 if btnp(3,_p.i) then
  -- reset player and obj
  _p.state,_p.action,_o.draw='standing'
 end

end

--[[

14 - regular door
15 - regular door open
16 - regular door frame

17 - door with lock (locked)
18 - door with lock (unlocked)
19 - door with lock (shutdown)
20 - door with lock open
21 - door with lock frame

--]]
local function resetdoor(_p,_o)
 -- reset player
 _p.state,_p.action='standing'

 -- reset obj
 _o.typ=doortypclosed[_o.typ]
 if _o.typ == 19 and ispoweron then
  _o.typ=17
 end
end

local function door(_p,_o,_tmp,_doorobj,_dy,_forstop)
 if not _tmp.opened then
  _doorobj.typ=doortypopened[_doorobj.typ]
  _tmp.opened=true
  makesound(_p,23)
 end

 if light[(_tmp.oy+2*_dy)*32+_tmp.ox] == 1 then
  setalertlvl2('door opened!',_tmp.ox,_tmp.oy)
 end

 fog[(_tmp.oy+1)*32+_tmp.ox]=0
 for _y=_tmp.oy+2*_dy,_forstop,_dy do
  local _i=_y*32+_tmp.ox
  fog[_i]=0
  if floor[_i] == 2 then
   break
  end
 end

 if btnp(2,_p.i) then
  if _dy < 0 then
   _p.y-=3
  end
  resetdoor(_p,_doorobj)
 end

 if btnp(3,_p.i) then
  if _dy > 0 then
   _p.y+=3
  end
  resetdoor(_p,_doorobj)
 end
end

local function doorfromunder(_p,_o,_tmp)
 door(_p,_o,_tmp,_o,-1,0)
end

local function doorfromabove(_p,_o,_tmp)
 door(_p,_o,_tmp,objs[_tmp.oi+32],1,31)
end

local function doorpeekfromunder(_p,_o,_tmp)
 fog[(_tmp.oy-2)*32+_tmp.ox]=0
end

local function doorpeekfromabove(_p,_o,_tmp)
 local _i=_tmp.oy*32+_tmp.ox
 fog[_i+32]=0
 fog[_i+64]=0
end


local function lockeddoor(_p,_o,_tmp,_doorobj,_dy,_forstop)
 if _doorobj.typ == 17 then
  for _l in all(playerinventory) do
   if _l[1] ==  'door pin' then
    _doorobj.typ=18
    _p.state,_p.action='standing'
    makesound(_p,24)
    return
   end
  end
  makesound(_p,25)
  _p.state,_p.action='standing'
  return
 end

 if not _tmp.opened then
  _doorobj.typ=doortypopened[_doorobj.typ]
  _tmp.opened=true
  makesound(_p,23)
 end

 if light[(_tmp.oy+2*_dy)*32+_tmp.ox] == 1 then
  setalertlvl2('door opened!',_tmp.ox,_tmp.oy)
 end

 fog[(_tmp.oy+1)*32+_tmp.ox]=0
 for _y=_tmp.oy+2*_dy,_forstop,_dy do
  local _i=_y*32+_tmp.ox
  fog[_i]=0
  if floor[_i] >= 2 then
   break
  end
 end

 if btnp(2,_p.i) then
  if _dy < 0 then
   _p.y-=3
  end
  resetdoor(_p,_doorobj)
 end

 if btnp(3,_p.i) then
  if _dy > 0 then
   _p.y+=3
  end
  resetdoor(_p,_doorobj)
 end
end

local function lockeddoorfrombelow(_p,_o,_tmp)
 lockeddoor(_p,_o,_tmp,_o,-1,0)
end

local function lockeddoorfromabove(_p,_o,_tmp)
 lockeddoor(_p,_o,_tmp,objs[_tmp.oi+32],1,31)
end


local function fusebox(_p,_o,_tmp)
 _o.typ,_p.workingstate,ispoweron=25,'cracking'
 if not _tmp.tick then
  _tmp.tick=0

  _o.draw=function()
   if _tmp.tick%12 > 6 then
    pset(_tmp.ox*4+3,_tmp.oy*4,9)
   end
  end
 end

 _tmp.tick+=1

 for _i=0,arslen do
  local _o=objs[_i]
  if _o and (_o.typ == 17 or _o.typ == 18) then
   _o.typ=19
  end
 end

 if btn(3,_p.i) then
  -- reset player and obj and ispoweron
  ispoweron,_p.state,_o.typ,_p.action,_o.draw=true,'standing',24
  for _i=0,arslen do
   local _o=objs[_i]
   if _o and _o.typ == 19 then
    _o.typ=17
   end
  end
 end
end

local function locker(_p,_o,_tmp)
 if not _tmp.opened then
  makesound(_p,23)
  _tmp.opened=true
  _o.typ=6
  _p.workingstate='hacking'
 end

 if btnp(2,_p.i) then
  makesound(_p,0)
  playerloots(_p,_o)
 end

 if btnp(3,_p.i) then
  -- reset player and obj
  _p.state,_o.typ,_p.action='standing',5
 end
end


local function getwindowpeekfunc(_startoff,_end,_di)
 return function(_p,_o)
  for _dy in all(windowpeekdys) do
   local _y=_p.y*32+_dy
   for _x=_p.x+_startoff,_end,_di do
    fog[_y+_x]=0
    if floor[_y+_x] >= 2 then
     break
    end
   end
  end
 end
end

local function getbreakwindowfunc(_xmod)
 return function(_p,_o)
  if _o.typ == 22 then
   _o.typ+=1
   makesound(_p,22,12)
  elseif _o.typ == 23 then
   _p.x+=2*_xmod
  end

  -- reset player
  _p.state,_p.action='standing'
 end
end

local function soundaction(_p)
 makesound(_p,0,8)
 _p.state,_p.action='standing'
end



local function newwindow()
 return {
  typ=22,
  action={[0]=getbreakwindowfunc(-1),getbreakwindowfunc(1)},
  adjaction={[0]=getwindowpeekfunc(-2,0,-1),getwindowpeekfunc(2,32,1)},
 }
end

local statuettestolentyps=s2t'.29;1;.30;1;'
local function searchsteal(_p,_o,_tmp)
 makesound(_p,0)
 playerloots(_p,_o)
 if statuettestolentyps[_o.typ] then
  _o.typ=31
 end
 _o.action,
 _p.state,
 _p.action=
  {[0]=soundaction,soundaction,soundaction,soundaction},
  'standing'
end



local function iswallclose(_x,_y,_dx,_dy)
 local _c=0
 while _y >= 2 and _y <= 30 and _x >= 2 and _x <= 30 and floor[_y*32+_x] < 2 do
  _x+=_dx
  _y+=_dy
  _c+=1
 end
 return _c <= 3
end












function mapgen()
 floor,objs,guards,cameras,mapthings,ispoweron={},{},{},{},{},true
 local computercount=0

 local _r=rnd()
 local _x,_y=30,30
 if _r < 0.25 then
  _x,_y=0,2
 elseif _r < 0.5 then
  _y=2
 elseif _r < 0.75 then
  _x=0
 end
 for _p in all(players) do
  _p.x,_p.y=_x+_p.i,_y+_p.i
 end

 for _i=0,arslen do
  floor[_i]=0
 end

 local function floorcount(_x,_y)
  local _c,_i=0,_y*32+_x
  for _j=0,3 do
   if floor[_i+adjdeltas[_j]] == 1 then
    _c+=1
   end
  end
  return _c
 end

 -- add rooms
 local _xmin,_ymin,_ystart=2,3,3

 repeat
  local _w,_h=flr(rnd(19))+10, flr(rnd(5))+6
  local _xstart=2+flr(rnd(28-_w))

  for _y=0,_h-1 do
   for _x=0,_w-1 do
    local _i=(_ystart+_y)*32+_xstart+_x
    if _y == 0 or _y == _h-1 or _x == 0 or _x == _w-1 then
     floor[_i],floor[(_ystart+_y-1)*32+_xstart+_x]=2,2
    else
     floor[_i]=1
    end
   end
  end

  -- add window
  local _xoff=0
  if rnd() > 0.5 then
   _xoff=_w-1
  end
  objs[(_ystart+2+flr(rnd(_h-5)))*32+_xstart+_xoff]=newwindow()

  -- add top door
  objs[_ystart*32+_xstart+2+flr(rnd(_w-5))]={
   typ=14,
   action={[2]=doorfromunder},
   adjaction={[2]=doorpeekfromunder}
  }

  -- add camera
  local _c={x=_xstart+1,y=_ystart+1,state=1}
  if rnd() < 0.5 then
   _c.x=_xstart+_w-2
  end

  if rnd() > 0.5 then
   add(cameras,_c)
  end

  -- add guard
  local _gx,_gy=flr(_xstart+_w/2),flr(_ystart+_h/2)
  if _h > 6 and #guards < 3 and rnd() > 0.5 then
   local _g=s2t'.dx;-1;.dy;0;.state;patrolling;.state_c;0;'
   _g.x,_g.y,_g.isarmed=_gx,_gy,flr(rnd()+0.2)
   add(guards,_g)
  end

  -- bottom wall
  _ystart+=_h-1

  -- add bottom door
  if _ystart < 31 then
   objs[_ystart*32+_xstart+2+flr(rnd(_w-5))]={
    typ=14,
    action={[2]=doorfromunder},
    adjaction={[2]=doorpeekfromunder}
   }
  end

 until _ystart+_h-1 > 27

 -- add corridor
 local _w,_h=flr(rnd(5))+6, flr(rnd(18))+10
 local _xstart,_ystart=2+flr(rnd(28-_w)),3

 for _y=0,_h-1 do
  for _x=0,_w-1 do
   local _i=(_ystart+_y)*32+_xstart+_x
   local _fc=floorcount(_xstart+_x,_ystart+_y)
   if _y == 0 or _y == _h-1 then
    floor[(_ystart+_y)*32+_xstart+_x],floor[(_ystart+_y-1)*32+_xstart+_x]=2,2
   end
   if _y == 0 or _y == _h-1 or _x == 0 or _x == _w-1 then
    local _current=floor[_i]
    if _current == 2 then
     floor[_i]=2
    elseif _current == 1 and _fc > 1 then
     floor[_i]=1
    else
     floor[_i]=2
    end
   else
    floor[_i]=1
   end
  end
 end

 -- add pillar
 local _pillarx,_pillary=flr(rnd(32)),flr(rnd(31))
 floor[_pillary*32+_pillarx]=2
 floor[(_pillary+1)*32+_pillarx]=2

 -- add trees
 for _i=0,6 do
  local _i=(1+flr(rnd(30)))*(1+flr(rnd(30)))
  if floor[_i] == 0 then
   floor[_i]=3
   objs[_i]={typ=110,shadow={}}
  end
 end

 -- add outside fusebox
 local _fbi=(_ystart+_h-1)*32+_xstart+2
 if floor[_fbi+32] != 2 then
  objs[_fbi]={typ=24,shadow={},action={[2]=fusebox}}
 end

 -- fix cameras
 for _j=#cameras,1,-1 do
  local _c=cameras[_j]
  local _i=_c.y*32+_c.x
  if objs[_i] or
     objs[_i-31] or
     objs[_i-1] or
     objs[_i+1] or
     objs[_i-32] or
     objs[_i+32] or
     floor[_i] == 2 or
     floor[_i-32] != 2 or
     not (floor[_i+1] == 2 or floor[_i-1] == 2) then
   del(cameras,_c)
  end
 end

 shuffle(cameras)

 while #cameras > 4 do
  deli(cameras,1)
 end

 -- add i for cameras
 for _i=1,#cameras do
  cameras[_i].i=_i
 end

 -- create objs positions
 local _pos={}
 for _y=2,29 do
  local _x=flr(rnd(4))+2
  while _x < 29 do
   local _i,_remove=_y*32+_x
   for _c in all(cameras) do
    if _c.x == _x and _c.y == _y or adjacency(_c.x,_c.y,_x,_y) then
     _remove=true
     break
    end
   end
   local _imin1,_iplus1,_iplus2=_i-1,_i+1,_i+2
   if (not _remove) and
      not (objs[_imin1-32] or
       objs[_i-32] or
       objs[_iplus1-32] or
       objs[_iplus2-32] or
       objs[_imin1] or
       objs[_i] or
       objs[_iplus1] or
       objs[_iplus2]) and
      floor[_i-32] == 2 and
      floor[_iplus1-32] == 2 and
      floor[_iplus2-32] == 2 and
      floor[_i] == 1 and
      floor[_iplus1] == 1 and
      floor[_iplus2] == 1 and
      floor[_i+32] == 1 and
      floor[_iplus1+32] == 1 and
      floor[_iplus2+32] == 1 and
      floor[_i+64] == 1 and
      floor[_iplus1+64] == 1 and
      floor[_iplus2+64] == 1 then
    add(_pos,_i)
    _x+=5
   elseif _remove == true then
    _x+=2
   else
    _x+=flr(rnd(6))+1
   end
  end
 end

 shuffle(_pos)

-- add objects

 -- 0 - plant
 -- 1 - watercooler
 -- 2 - boxes
 -- 3 - chair (right)
 -- 4 - chair (left)
 -- 5 - locker (closed)
 -- 7 - camcontrol
 -- 10 - safe
 -- 26 - computer
 -- 29 - golden statuette
 -- 30 - statuette
 -- 31 - stolen statuette

 local _types,_hasgoldenstatuette,_safe=s2t'0;0;26;10;30;'

 if #cameras > 0 then
  add(_types,7)
 end

 for _i in all(_pos) do
  local _typ,_iplus1=_types[flr(rnd(#_types))+1],_i+1
  if _typ == 10 or _typ == 7 then
   del(_types,_typ)
  end

  if _typ == 0 then
   _typ=flr(rnd(6))
  end

  local _o,_doorpin={typ=_typ,shadow=s2t'.0;1;.1;1;'},{'door pin'}
  objs[_i]=_o

  if _typ == 26 then
   local _deskactions,_wallets={[0]=soundaction,soundaction,searchsteal},shuffle{nil,{'wallet',rnd(60)}}

   _o.shadow,
   _o.action,
   _o.loot=
    s2t'.0;1;',
    _deskactions,
    shuffle{nil,nil,_doorpin,_wallets[1]}[1]

   objs[_iplus1],
   objs[_i+2]=
    {
     typ=27,
     action={nil,computer},
     loot=shuffle{
      {'cute cat pictures',1},
      {'blackmail material',rnd(400)},
      {'company secrets',rnd(800)},
      {'classified files',rnd(1200)},
      }[1],
     shadow={},
    },
    {
     typ=28,
     shadow={1},
     action=_deskactions,
     loot=shuffle{nil,nil,_doorpin,_wallets[2]}[1]
    }

   computercount+=1
   if computercount == 2 then
    add(mapthings,'hackable computers')
   end

  elseif _typ == 5 then
   _o.action,
   _o.loot=
    {[0]=soundaction,soundaction,locker},
    shuffle{nil,nil,_doorpin,{'a really nice tie',10},{'wallet',rnd(60)}}[1]

  elseif _typ == 7 then
   _o.shadow,
   objs[_iplus1],
   objs[_i+2]=
    s2t'.0;1;',
    {typ=8,action={[0]=soundaction,nil,camcontrol},shadow={}},
    {typ=9,shadow={1}}

  elseif _typ == 10 then
   _safe,
   _o.shadow,
   _o.action,
   _o.code=
    _o,
    s2t'.0;1;',
    {soundaction,safe},
    {}

   -- generate new code
   for _i=1,5 do
    add(_o.code,flr(rnd(5))+1)
   end

   objs[_iplus1]={typ=11,shadow={1}}

  elseif _typ == 30 then
   _o.action,
   _o.loot=
    {[0]=searchsteal,searchsteal,searchsteal,searchsteal},
    {'statuette',50+rnd(49)}

   if rnd() > 0.8 and not _hasgoldenstatuette then
    _hasgoldenstatuette,
    _o.typ,
    _o.loot=
     true,
     29,
     {'golden statuette',100+rnd(99)}

    add(mapthings,'some art')
   end
  end
 end

 -- add plants and watercoolers and boxes vertically
 for _x=2,29 do
  for _j=1,3 do
   local _y=flr(rnd(29))+2
   local _i=_y*32+_x
   local _imin1,_iplus1=_i-1,_i+1
   if not (objs[_i] or
       objs[_i-32] or
       objs[_imin1] or
       objs[_iplus1] or
       objs[_i+32]) and
      floor[_i] == 1 and
      floor[_i-32] == 1 and
      floor[_i+32] == 1 and
      (floor[_iplus1] == 1 or floor[_imin1] == 1) and
      (floor[_iplus1] == 2 or floor[_imin1] == 2) then
    local _typ=flr(rnd(3))
    local _o={typ=_typ,shadow=s2t'.2;1;.3;1;'} -- todo: fix flashlight bug
    objs[_i]=_o
   end
  end
 end


 -- fix objs
 for _i=0,arslen do
  local _o,_iplus1=objs[_i],_i+1
  if _o then
   _o.light,_o.action={},_o.action or {[0]=soundaction,soundaction,soundaction,soundaction}

   -- remove windows
   if _o.typ == 22 then
    if not (floor[_i] == 2 and floor[_i-1] != 2 and floor[_iplus1] != 2) then
     objs[_i]=nil
    end

   -- fix doors
   elseif _o.typ == 14 then
    if objs[_iplus1] or 
       not (floor[_i] == 2 and
        floor[_i-1] == 2 and
        floor[_iplus1] == 2 and
        floor[_i+32] != 2 and
        floor[_i-64] != 2) then
     objs[_i]=nil
    else
     objs[_i-32],
     objs[_iplus1]=
       {action={nil,nil,doorfromabove},adjaction={nil,nil,doorpeekfromabove}},
       {typ=16}

     -- switch to locked
     if rnd() > 0.7 then
      objs[_i].typ,
      objs[_i].action[2],
      objs[_i-32].action[3],
      objs[_iplus1].typ=
        17,
        lockeddoorfrombelow,
        lockeddoorfromabove,
        21
     end
    end
   end
  end
 end

 -- fix guards
 for _g in all(guards) do
  if floor[_g.y*32+_g.x] == 2 then -- todo: more checks would be nice
   del(guards,_g)
  end
 end

 if #cameras > 1 then
  add(mapthings,'many cameras')
 end

 if #guards > 1 then
  add(mapthings,'many guards')
 end

 for _g in all(guards) do
  if _g.isarmed == 1 then
   add(mapthings,'guards might be armed')
   break
  end
 end

 -- set safe loot
 if _safe then
  if #guards > 1 or #cameras > 2 then
   local _goldbars={'gold bars',500+rnd(500)}
   _safe.loot=shuffle{
    _goldbars,
    _goldbars,
    {'diamonds',1000+rnd(500)},
   }[1]
   add(mapthings,'loaded safe')
   if _safe.loot[1] == 'diamonds' then
    add(mapthings,'rumors of diamonds')
   end
  else
   local _goodcash={'good cash',300+rnd(200)}
   _safe.loot=shuffle{
    _goodcash,
    _goodcash,
    _goodcash,
    {'important documents',100+rnd(300)}
   }[1]
   add(mapthings,'crackable safe')
  end
 end

end











local function initgame()
 poke(0x5f5c,5) -- note: set auto-repeat delay for btnp
 msgs,tick,alertlvl,seenaddend,seent={},0,1,-1
 local _playwalksfx
 _update=function()
  tick-=1

  -- reset fog
  fog={}

  -- update players
  for _p in all(players) do

   -- switch player control
   if btnp(4) then
    _p.i=_p.i^^1
    if _p.i == 0 then
     add(msgs,{_p.x,_p.y,'.',1,15})
    end
   end

   -- input
   if _p.state == 'working' then
    local waspoweron=ispoweron
    _p.workingstate='hacking'
    _p.action()

    -- update from ispoweron
    if ispoweron and not waspoweron then
     for _c in all(cameras) do
      _c.state=1
     end
    elseif waspoweron and not ispoweron then
     for _c in all(cameras) do
      _c.state=0
     end

     for _i=0,arslen do
      local _o=objs[_i]
      if _o and _o.typ == 20 then
       _o.typ=18
      end
     end
    end

   else
    _p.dx,_p.dy=0,0
    if btnp(0,_p.i) then
     _p.dx,_p.dir=-1,0
    elseif btnp(1,_p.i) then
     _p.dx,_p.dir=1,1
    elseif btnp(2,_p.i) then
     _p.dy=-1
    elseif btnp(3,_p.i) then
     _p.dy=1
    end
    local _nextx,_nexty,_otherp=_p.x+_p.dx,_p.y+_p.dy,players[1]
    if _otherp == _p then
     _otherp=players[2]
    end
    if _otherp and _nextx == _otherp.x and _nexty == _otherp.y then
     makesound(_p,20)
    else
     if _nextx > 31 or _nextx < 0 or _nexty > 31 or _nexty < 0 then
      add(escapedplayers,del(players,_p))
      add(msgs,{_p.x,_p.y,'escaped',1,30})

      if #players <= 0 then
       initstatus()
       return
      end
     else

      local _ni=_nexty*32+_nextx
      local _nexto=objs[_ni]
      if _nexto != nil then
       local _a=adjacency(_nextx,_nexty,_p.x,_p.y)
       _nextx,_nexty=_p.x,_p.y
       if _nexto.action and _nexto.action[_a] then
        _p.state,
        _p.action=
         'working',
         curry3(_nexto.action[_a],_p,_nexto,{ox=_ni&31,oy=_ni\32,oi=_ni})
       end
      end

      if _p.state != 'working' then
       local _i=_p.y*32+_p.x
       for _a=0,3 do
        local _oi=_i+adjdeltas[_a]
        local _adjo=objs[_oi]
        if _adjo and _adjo.adjaction and _adjo.adjaction[_a] then
         _adjo.adjaction[_a](_p,_adjo,{ox=_oi&31,oy=_oi\32,oi=_oi})
        end
       end
      end


      if _p.state != 'caught' and floor[_nexty*32+_nextx] < 2 then
       _p.x,_p.y=_nextx,_nexty

       -- hide behind object
       if _p.state != 'working' then
        local _i,_pwa,_hiding=_p.y*32+_p.x, walladjacency(_p)
        for _a=0,3 do
         local _oi=_i+adjdeltas[_a]
         local _o=objs[_oi]
         if _o then
          local _ox,_oy=_oi&31,_oi\32
          local _a,_owa=adjacency(_p.x,_p.y,_ox,_oy), walladjacency{x=_ox,y=_oy}
          if _o.shadow and _o.shadow[_a] and _owa and _pwa and _a and light[_i] == 0 then
           _p.state,
           _p.adjacency,
           _hiding=
            'hiding',
            _a,
            true
          end
         end
        end
        if not _hiding then
         _p.state='standing'
        end
       end

      end
     end
    end
   end

   -- if one square from guard, get caught
   for _g in all(guards) do
    local _dx,_dy=_p.x-_g.x,_p.y-_g.y
    if (_p.state != 'hiding' or light[_p.y*32+_p.x] == 1) and _p.state != 'caught' and abs(_dx) <= 1 and abs(_dy) <= 1 then
     setalertlvl2('suspect caught!',_g.x,_g.y)
     _p.state,_g.state='caught','holding'
    end
   end
  end

  if tick <= 0 then

   -- update guards
   for _g in all(guards) do

    -- handle state
    if _g.state == 'patrolling' then

     -- turn when close to wall
     if iswallclose(_g.x,_g.y,_g.dx,_g.dy) then
      local _obj=objs[(_g.y+_g.dy*3)*32+_g.x+_g.dx*3]
      if _obj and _obj.typ == 23 and not _obj.isguarded then
       _obj.isguarded,_g.state=true,'guarding'
      else
       local _turns=shuffle{
        {dx=_g.dy,dy=_g.dx},
        {dx=-_g.dy,dy=-_g.dx},
       }
       add(_turns,{dx=-_g.dx,dy=-_g.dy})
       for _i=1,3 do -- note: #_turns is always 3
        local _t=_turns[_i]
        if not iswallclose(_g.x,_g.y,_t.dx,_t.dy) then
         _g.dx,_g.dy=_t.dx,_t.dy
         break
        end
       end
      end
     end

     -- move
     local _gwa=walladjacency{x=_g.x+_g.dx,y=_g.y+_g.dy} -- todo: do this better
     _g.x+=guarddxdeltas[_gwa] or _g.dx
     _g.y+=guarddydeltas[_gwa] or _g.dy

    elseif _g.state == 'listening' then
     _g.state_c-=1

     if _g.state_c <= 0 or _g.state_c % 10 == 1 then
      _g.dx,_g.dy,_g.state=_g.dx*-1,_g.dy*-1,'patrolling'
     elseif _g.state_c > 30 then
      setalertlvl2('heard someone!',_g.x,_g.y)
     end

    -- elseif _g.state == 'guarding' then -- do nothing
    -- elseif _g.state == 'holding' then -- do nothing
    -- elseif _g.state == 'gunpointing' then -- do nothing
    end
   end

   -- set new tick
   _playwalksfx=not _playwalksfx
   if _playwalksfx then
    sfx(18+alertlvl-1)
   end
   if alertlvl == 2 and policet > 0 then
    policet-=1
    if policet == 44 then
     sfx(16)
    end
    if policet <= 0 then
     local _f
     if #players == 1 then
      _f=function()
       add(escapedplayers[1].loot,{'bail',-2000})
       initstatus()
      end
     end
     initpolice(_f)
     return
    end
   end
   tick=alertlvls[alertlvl]
  end

  -- update messages
  -- 1 - x
  -- 2 - y
  -- 3 - string
  -- 4 - colorset (1 or 2)
  -- 5 - time
  for _m in all(msgs) do
   _m[5]=_m[5] or 90
   _m[5]-=1
   if _m[5] <= 0 then
    del(msgs,_m)
   end
  end

  -- clear light
  for _i=0,arslen do
   local _o=objs[_i]
   if _o then
    _o.light={}
   end
   light[_i]=0
  end

  -- add cameras light
  -- todo: token hunt???
  for _c in all(cameras) do
   if _c.state != 0 then
    local _dx=1
    if floor[_c.y*32+_c.x+1] == 2 then
     _dx=-1
    end
    local _x,_y,_ldown,_lside=_c.x,_c.y,32,32
    repeat
     local _bx,_by=_x,_y
     local _bydown,_bldown=_by,1
     while floor[_bydown*32+_bx] != 2 and _bldown <= _ldown do
      local _o=objs[_bydown*32+_bx]
      if _o then
       add(_o.light,{x=0,y=-1})
      end

      light[_bydown*32+_bx]=1

      -- remove fog if selected in camcontrol
      if _c.state == 2 then
       fog[_bydown*32+_bx]=0

       local _i=(_bydown+1)*32+_bx
       if floor[_i] == 2 then
        fog[_i]=0
       end

       _i=_bydown*32+_bx+1
       if floor[_i] == 2 then
        fog[_i]=0
       end

       _i=_i-2
       if floor[_i] == 2 then
        fog[_i]=0
       end
      end

      _bydown+=1
      _bldown+=1
     end

     local _bxside,_blside=_bx,1
     while floor[_by*32+_bxside] != 2 and _blside <= _lside do
      local _o=objs[_by*32+_bxside]
      if _o then
       add(_o.light,{x=-_dx,y=0})
      end

      light[_by*32+_bxside]=1

      -- remove fog if selected in camcontrol
      if _c.state == 2 then
       if _by == _y then
        fog[(_by-1)*32+_bxside]=0
       end

       fog[_by*32+_bxside]=0

       local _i=(_by+1)*32+_bxside
       if floor[_i] == 2 then
        fog[_i]=0
       end

       _i=_by*32+_bxside+_dx
       if floor[_i] == 2 then
        fog[_i]=0
       end
      end

      _bxside+=_dx
      _blside+=1
     end
     _lside,_ldown=_blside-2,_bldown-2
     _y+=1
     _x+=_dx
    until floor[_y*32+_x] == 2 or
          floor[(_y-1)*32+_x] == 2 or
          floor[_y*32+_x-_dx] == 2
   end
  end

  -- shine guards flashlights
  for _g in all(guards) do
   if _g.state == 'holding' then
    local _i=_g.y*32+_g.x
    for _ghd in all(guardsholdingdeltas) do
     light[_i+_ghd]=1
    end

   elseif _g.dx != 0 then
    for _i=1,-1,-2 do
     local _x,_y,_l=_g.x+_g.dx,_g.y+_g.dy,32
     while floor[_y*32+_x] != 2 do
      local _c,_bx,_by=0,_x,_y
      while floor[_by*32+_bx] != 2 and _c <= _l do
       local _o=objs[_by*32+_bx]
       if _o then
        add(_o.light,{x=0,y=-(_i)})
        add(_o.light,{x=-_g.dx,y=0})
       end
       light[_by*32+_bx]=1
       _bx+=_g.dx
       _by+=_i
       _c+=1
      end
      _l=_c-1
      _x+=_g.dx
     end
    end

   elseif _g.dy != 0 then

    for _i=1,-1,-2 do
     local _x,_y,_l=_g.x+_g.dx,_g.y+_g.dy,32
     while floor[_y*32+_x] != 2 do
      local _c,_bx,_by=0,_x,_y
      while floor[_by*32+_bx] != 2 and _c <= _l do
       local _o=objs[_by*32+_bx]
       if _o then
        add(_o.light,{x=0,y=-_g.dy})
        add(_o.light,{x=-(_i),y=0})
       end
       light[_by*32+_bx]=1
       _bx+=_i
       _by+=_g.dy
       _c+=1
      end
      _l=_c-1
      _y+=_g.dy
     end
    end
   end
  end

  -- add shadow around objects
  for _i=0,arslen do
   local _o=objs[_i]
   if _o and _o.shadow then
    for _j=0,3 do
     if _o.shadow[_j] then
      light[_i+adjdeltas[_j]]=0
     end
    end

    local _ox,_oy=_i&31,_i\32
    for _l in all(_o.light) do
     light[(_oy+_l.y)*32+_ox+_l.x]=1
    end
   end
  end


  for _i=0,arslen do

   -- light up walls
   if light[_i+32] == 1 and
      floor[_i] == 2 and
      floor[_i+32] != 2 then
    light[_i]=1
   end

   -- light up windows
   local _o=objs[_i]
   if _o and (_o.typ == 22 or _o.typ == 23) and
      (light[_i-1] == 1 or light[_i+1] == 1) then
    light[_i]=1
   end
  end

  -- intruder alert
  for _p in all(players) do
   if light[_p.y*32+_p.x] == 1 then
    if not seent then
     seenaddend,seenx,seeny,seent=1,_p.x*4-2,_p.y*4-8,60
     if wantedness >= 3 then
      add(msgs,{_p.x,_p.y-1,'we\'ve seen your face now!',2})
     end
    end
    setalertlvl2('intruder alert!',_p.x,_p.y)
   end
  end
  if alertlvl == 1 then
   for _i=0,arslen do
    local _o=objs[_i]
    if _o and light[_i] == 1 then
     local _x,_y=_i&31,_i\32
     if _o.typ == 12 then
      setalertlvl2('safe opened!',_x,_y)
     elseif _o.typ == 31 then
      setalertlvl2('statuette gone!',_x,_y)
     elseif _o.typ == 23 then
      setalertlvl2('broken window!',_x,_y)
     end
    end
   end
  end


  -- armed guards catch
  for _g in all(guards) do
   if _g.isarmed == 1 then
    for _p in all(players) do
     if _p.y == _g.y then
      for _x=_g.x,_g.x+_g.dx*10,_g.dx do
       if floor[_g.y*32+_x] == 2 then
        break
       elseif _p.x == _x then
        if _p.state != 'caught' then
         add(msgs,{_g.x,_g.y,'hands up!',2})
        end
        _p.state,_p.workingstate,_g.state='caught','handsup','gunpointing'
       end
      end
     end
    end
   end
  end


  -- remove fog
  for _p in all(players) do
   if _p.state != 'caught' or _p.workingstate == 'handsup' then
    for _d in all(fogdirs) do
     local _x,_y,_l=_p.x,_p.y,32
     while floor[_y*32+_x] != 2 and floor[_y*32+_x] do
      local _c,_bx,_by=0,_x,_y
      while _by < 32 and
            _by >= 0 and
            _bx < 32 and
            _bx >= 0 and
            floor[_by*32+_bx] != 2 and
            floor[_by*32+_bx] and
            _c <= _l do
       fog[_by*32+_bx]=0
       _bx+=_d.dx
       _by+=_d.dy
       _c+=1
      end
      if _by < 32 and _by >= 0 and _bx < 32 and _bx >= 0 then
       fog[_by*32+_bx]=0
      end
      _bx+=_d.dx
      _by+=_d.dy
      _l=_c
      _x+=_d.x
      _y+=_d.y
      if _y < 32 and _y >= 0 and _x < 32 and _x >= 0 then
       fog[_y*32+_x]=0
      else
       break
      end
     end
    end
   end
  end

  -- remove fog from holding guards
  for _g in all(guards) do
   if _g.state == 'holding' then
    for _ghd in all(guardsholdingdeltas) do
     fog[_g.y*32+_g.x+_ghd]=0
    end
   end
  end

  -- remove fog from walls
  for _i=0,arslen do
   if fog[_i+32] == 0 and floor[_i] == 2 and floor[_i+32] == 2 then
    fog[_i]=0
   end
  end

 end


 _draw=function()
  cls()
  if alertlvl == 2 and policet <= 44 then
   pal(0,12)
   if policet%8 >= 4 then
    pal(0,8)
   end
  end

  for _i=arslen,0,-1 do

   -- draw floor
   local _tile,_l,_x,_y=floor[_i],light[_i],_i&31,_i\32
   local _sx,_sy,_col,_l10=_x*4,_y*4,_tile,_l*10

   _col=floorlightcols[_tile+_l10]
   rectfill(_sx,_sy,_sx+3,_sy+3,_col)
   
   -- draw walls
   if _tile == 2 then
    local _tilebelow=floor[_i+32]
    if _tilebelow == 0 then
     sspr(12,104,4,5,_sx,_sy)
    elseif _tilebelow == 1 then
     rectfill(_sx,_sy,_sx+3,_sy+4,13-7*_l)
    end
   end
  end

  -- add border of premises
  rect(0,0,127,127,5)

  pal()
  palt(0,false)
  palt(15,true)

  -- draw objs
  for _i=0,arslen do
   local _o=objs[_i]
   if _o and _o.typ then
    local _sx,_sy=(_i&31)*4,(_i\32)*4
    if _o.typ > 100 then -- draw trees
     sspr(_o.typ,112,6,16,_sx-1,_sy-12)
    else
     sspr(
      _o.typ*4,
      light[_i]*13,
      4,
      13,
      _sx,
      _sy-5)
    end
   end
   _o=objs[_i-1]
   if _o and _o.draw then
    _o.draw()
   end
  end

  -- draw cameras
  for _c in all(cameras) do
   sspr(cameradirs[floor[_c.y*32+_c.x+1]],116+_c.state*3,4,3,_c.x*4,_c.y*4-4)
  end

  -- draw players
  for _p in all(players) do
   local _i=_p.y*32+_p.x
   local _l,_floor23,_px,_py=light[_i],floor[_i]*23,_p.x*4,_p.y*4-5
   local _sylight=72+_l*9
   if _p.state == 'hiding' then
    sspr(46+_p.adjacency*4,72,4,9,_px,_py)
   elseif _p.state == 'working' then
    if _p.workingstate == 'hacking' then
     sspr(12+_floor23,_sylight,5,9,_px,_py)
    elseif _p.workingstate == 'cracking' then
     sspr(17+_floor23,_sylight,5,9,_px,_py)
    end
    if #_p.loot > 0 then
     sspr(5,91+_l*4,8,4,_px,_py+5)
    end
   elseif _p.state == 'caught' then
    if _p.workingstate == 'handsup' then
     sspr(13,90,3,10,_px,_py-1)
    else
     sspr(0,90,6,9,_px,_py)
    end
    if #_p.loot > 0 then
     sspr(5,95,8,4,_px,_py+5)
    end
   else
    local _flipx,_px2,_sx=_p.dir == 1,_px-_p.dir*2,0
    if #_p.loot > 0 then
     _sx=6
    end
    sspr(_sx+_floor23,_sylight,6,9,_px2,_py,6,9,_flipx)
   end

   local _o=objs[_i+32]
   if _o and _o.typ then
    local _l=light[_i+32]
    sspr(_o.typ*4,_l*13,4,13,_px,_py+4)
   end

   for _j=1,4 do
    local _o=objs[_i+32*_j]
    if _o and _o.typ and _o.typ > 100 then -- draw trees
     sspr(_o.typ,112,6,16,_px-1,_py-3+4*(_j-1))
    end
   end
  end

  -- draw guards
  for _g in all(guards) do
   local _dir,_gx,_gy,_sy=0,_g.x*4-2,_g.y*4-7,31+11*_g.isarmed
   for _j=1,3 do
    if adjdeltas[_j] == _g.dy*32+_g.dx then
     _dir=_j
    end
   end
   if _g.state == 'patrolling' then
    local _frame=2
    if tick < alertlvls[alertlvl]/2 then
     _frame=1
    end
    sspr(_dir*27+_frame*9,_sy,9,11,_gx,_gy)

   elseif _g.state == 'holding' then
    sspr(109,_sy,7,11,_gx,_gy)

   elseif _g.state == 'gunpointing' then
    sspr(11+11*_g.dx,53,7,11,_gx,_gy)

   elseif _g.state == 'listening' or _g.state == 'guarding' then
    sspr(_dir*27,_sy,9,11,_gx,_gy)
   end
  end


  -- draw fog
  for _i=0,arslen do
   if not fog[_i] then
    local _x,_y=(_i&31)*4,(_i\32)*4
    rectfill(_x,_y,_x+3,_y+3,0)
   end
  end

  -- draw seen icons
  if seent and seent > 0 then
   seent-=1
   if seent%8 > 4 then
    spr(246,seenx,seeny)
   end
  end

  -- draw messages
  local _coli=1
  if tick%8 >= 4 then
   _coli=2
  end
  for _m in all(msgs) do
   local _hw=#_m[3]*2
   print(
    _m[3],
    max(min(_m[1]*4-_hw,127-_hw*2),0),
    max(_m[2]*4-13,0),
    msgcols[_m[4]][_coli])
  end
 end
end






local function drawstatusbar(_transparent)
 local _hscol=7
 if not _transparent then
  rectfill(0,0,27,6,3)
  rectfill(29,0,59,6,5)
  rectfill(61,0,127,6,5)
  _hscol=6
 end
 print('$'..dget(1),2,1,7)
 print('day '..dget(2),31,1,7)
 print('highscore $'..dget(0),63,1,_hscol)
end






initpolice=function(_onpress)
 sfx(16,-2)
 sfx(17)
 palt(0)
 palt(15,false)
 palt(11,true)
 wantedness,seenaddend=3,0

 -- sort players on x
 if #players == 2 and players[1].x > players[2].x then
  players[1],players[2]=players[2],players[1]
 end

 _update=function()
  if btnp(4) then
   if _onpress then
    _onpress()
   else
    dset(2,0) -- day
    initsplash()
   end
  end
 end

 _draw=function()
  cls(s2t'.0;12;.1;8;'[flr(t())%2])

  -- draw players
  for _i=1,#players do
   local _p=players[_i]
   local _off=_i*4
   local _x,_y=mid(20+_off,_p.x*4,107-_off),mid(12+_off,_p.y*4,89-_off)
   sspr(89,86,3,10,_x,_y)
   if #_p.loot > 0 then
    sspr(81,86,8,10,_x,_y)
   end

   -- draw officers
   local _dx,_flipx=-1,_i%2 == 0
   if _flipx then
    _dx=1
   end
   local _tmp=_x+16*_dx
   sspr(92,63,8,11,_tmp,_y+15,8,11,_flipx)
   sspr(92,74,8,11,_x+18*_dx,_y-1,8,11,_flipx)
   sspr(92,85,8,11,_tmp,_y-15,8,11,_flipx)
  end

  -- draw police car
  sspr(100,61,28,17,80,104)

  local _s='caught!  \x8e to pay bail'

  -- draw armored truck for game over
  if not _onpress then
   sspr(100,78,28,18,15,102)
   _s='caught!  \x8e to start over'
   drawstatusbar(true)
  end
  print(_s,16,122,10)

 end
end










local function initmapselect()
 palt() -- 0,false
 -- srand(1000) -- set if test level
 mapgen()
 local _cash,_reconcost=0
 _update=function()
  if btnp(1) then
   initgame()
  elseif btnp(0) then
   initstatus()
  end
 end

 _draw=function()
  cls()

  rectfill(14,15,116,97,5)
  print('next target',43,26,15)

  for _i=1,#mapthings do
   print(mapthings[_i],23,36+_i*7,7)
  end
  if #mapthings == 0 then
   print('(nothing much)',23,41,7)
  end

  print('\x8b skip',7,119,10)
  print('hit! \x91',97,119,10)

  drawstatusbar()
 end
end








initstatus=function()
 poke(0x5f5c,-1)
 sfx(16,-2)
 sfx(17,-2)
 local _rows={{'ingoing balance',dget(1)}} -- cash
 for _p in all(escapedplayers) do
  for _l in all(_p.loot) do
   _l[2]=flr(_l[2])
   add(_rows,_l)
  end
 end
 dset(2,dget(2)+1) -- day
 add(_rows,{'daily expenses',-48-dget(2)*2}) -- day
 local _cash=0
 for _r in all(_rows) do
  _cash+=_r[2]
 end
 if _cash < -20000 then
  _cash=32767
 end
 dset(1,_cash) -- cash
 dset(0,max(_cash,dget(0))) -- highscore

 for _p in all(escapedplayers) do
  _p.i,_p.loot,players[_p.origi+1]=_p.origi,{},_p
 end

 -- init msg
 local _msg='scout next target \x91'
 if dget(1) < 0 then
  _msg='no cash! start over \x91'
 end

 wantedness=mid(0,wantedness+seenaddend,4)
 seenaddend=-1
 dset(3,wantedness)
 local _recognised=wantedness == 4
 if _recognised then
  _msg='dare to scout next target... \x91'
 end

 -- init players
 players={{},{}}
 for _i=0,1 do
  players[_i+1]={
   i=_i,
   x=10+6*_i,
   y=8,
   origi=_i,
   dir=1,
   state='standing',
   workingstate='hacking',
   loot={},
  }
 end

 escapedplayers,playerinventory={},{}

 _update=function()
  if btnp(1) then
   if _recognised then
    initpolice()
   elseif _cash < 0 then
    dset(2,0)
    initsplash()
   else
    initmapselect()
   end
  end
 end

 _draw=function()
  cls()

  if _recognised and flr(t()*2)%2 == 1 then
   print('wanted',46,16,8)
  end

  for _i=0,3 do
   spr(244+mid(0,wantedness-_i,1),9+_i*8,15)
  end

  local _offy=30
  for _r in all(_rows) do
   print(_r[1],10,_offy,6)
   local _r2,_col,_offx='$'.._r[2],11,0
   if _r[2] < 0 then
    _r2,_col,_offx='-$'..abs(_r[2]),14,4
   end
   print(_r2,88-_offx,_offy,_col)
   _offy+=7
  end

  print('total',10,110,5)

  local _col=11
  if _cash < 0 then
   _col=14
  end
  local _s='$'.._cash
  print(_s,98-#_s*2,110,_col)

  print(_msg,64-#_msg*2,119,10)

  drawstatusbar()
 end
end








function initsplash()
 sfx(16,-2)
 sfx(17,-2)
 sfx(62)
 local _msg='continue saved "career" \x91'
 if dget(2) == 0 then -- day

  dset(1,200) -- cash
  dset(3,0) -- wantedness
  wantedness=0
  _msg='start new "career" \x91'
 end

 _update=function()
  if btnp(1) then
   menuitem(1, 'rat on eachother', function()
    for _p in all(escapedplayers) do
     add(players,del(escapedplayers,_p))
    end
    initpolice()
   end)
   initstatus()
  end
 end
 _draw=function()
  cls()
  print('sneaky stealy',37,44,1)
  print('sneaky stealy',38,45,13)
  print(_msg,64-#_msg*2,119,10)
 end
end


_init=initsplash

__gfx__
f5ffffffffffffffffff555555555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff99ff6ffffff
f5f5ccccf555ffffffff522521152511155111525111111551111125ffffffffffffffffffffffffffffffff5dd55dd5fffffffffff555555ffff9ffff6fffff
ff5fcc3cf2225ffffff552252115251115511152511d1115515552252222222222ff222222222222222222ff5dd55d15ffffffff5ff511115ffff99ff66fffff
f5ffcc3c555f5ffffff55225211525555555555251111115555552d52555211152ff2ddd2ddd2ddd2111d2ff5dd55115fffffffff5f511115ffff55ff55ff55f
f5ffc3cc555f5ffffff55225211525111551115251dd1115511112252555211552ff2ddd2ddd2ddd211dd2ff5dd55115ffffffff252511115222555555555555
2222fccf222f5222222552d5211555111551115551d11115511112d52555211552ff2ddd2ddd2ddd211dd2ff5dd55dd5444445552d2555555222544554455445
dddd55555d55555555555225211555555555555551111115515552252555211552ff28dd2bdd24dd211dd2ffffffffff222225552225d5d55222555555555555
dddd522555555ff55ff5522521152255d15d552255555555555552552d55211552ff25dd25dd25dd211dd2ffffffffff2225255522255d5d5252555555555555
22225ff522225ff55ff55225211522255555522255ffff5555ffff552555211d52ff2ddd2ddd2ddd2115d2ffffffffff22222555222555555222555555555555
ffffffffffffffffffff55555555552222222255ffffffffffffffff2555211552ff2ddd2ddd2ddd211dd2fffffffffff5fff5ff5ffffffffff5ffffffffffff
ffffffffffffffffffffffffffffff52222225fffffffffffffffffffffffff5fffffffffffffffffffdffffffffffffffffffff5ffffffffff5ffffffffffff
fffffffffffffffffffffffffffffff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5ffffffffff5ffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f3ffffffffffffffffff555555555555555555555555555555555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaff7ffffff
f3f3ccccf444ffffffff5dd5d115d5111551115d5222222551111125ffffffffffffffffffffffffffffffff46744674fffffffffff555555ffffaffff7fffff
ff3fcc7cf2225ffffff55dd5d115d5111551115d52262225514442252222222222ff222222222222222222ff47644714ffffffff3ff511115ffffaaff77fffff
f3ffcc7c444f5ffffff55dd5d115d5555555555d52222225555552652444211142ff266626662666211162ff46644114fffffffff3f511115ffff55ff55ff55f
f3ffc7cc444f5ffffff55dd5d115d5111551115d52662225511112252444211442ff266626662666211662ff46744114ffffffff434511115444555555555555
4444fccf222f588888855d65d11555111551115552622225511112652444211442ff266626662666211662ff47644764ddddd555464555555444599559955995
666655554944555555555dd5d11555555555555552222225514442252444211442ff28662b662466211662ffffffffff4444455544456d6d5444555555555555
6666544544445ff55ff55dd5d11522556d56552255555555555552552944211442ff2d662d662d66211662ffffffffff444d45554445d6d65454555555555555
44445ff522225ff55ff55dd5d11522255555522255ffff5555ffff552444211942ff266626662666211d62ffffffffff44444555444555555444555555555555
ffffffffffffffffffff55555555552222222255ffffffffffffffff2444211442ff266626662666211662fffffffffff5fff5ff2ffffffffff2ffffffffffff
ffffffffffffffffffffffffffffff52222225fffffffffffffffffffffffff4fffffffffffffffffff6ffffffffffffffffffff2ffffffffff2ffffffffffff
fffffffffffffffffffffffffffffff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2ffffffffff2ffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff4ffffffff4fffffffffffffff4ffffffff4ffffffffffffffffff4ffffffff4fffffffffffffffff4ffffffff4fffffffffffffffff4fffffffffffffff
ffff44fffffff44ffffffff4ffffff44fffffff44fffffff4ffffffff44fffffff44ffffffff4ffffffff44fffffff44fffffff4ffffffff44ffffffffffffff
fffff9ffffffff9fffffff44ffffff9ffffffff9ffffffff44ffffffff9ffffffff9fffffff44ffffffff9ffffffff9ffffffff44fffffff9fffffffffffffff
fffff9ffffffff9ffffffff9ffffff9ffffffff9ffffffff9fffffffff9ffffffff9ffffffff9ffffffff9ffffffff9ffffffff9ffffffff9fffffffffffffff
ffff444ffffff444fffffff9fffff444ffffff444fffffff9ffffffff444ffffff444fffffff9fffffff444ffffff444fffffff9fffffff444ffffffffffffff
fff44444ffff44444fffff444fff44444ffff44444fffff444ffffff44444ffff44444fffff444fffff44444ffff44444fffff444fffff44444fffffffffffff
759f5554f759f555f4fff44444ff4555f9574f555f957f44444fffff45554ffff4555f9fff44444ffff95554ffff9555f9fff44444fff4f555f9ffffffffffff
ffff4449fffff444f9759f5594ff9444ffff9f444fffff4955f957fff4449fffff444fffff45554ffff54449ffff5444fffff95559fff9f444ffffffffffffff
ffff4f4ffffff4f4ffffff444ffff4f4ffffff4f4ffffff444fffffff4f4ffffff4f4ffffff444fffff74f4fffff74f4fffff5444ffffff4f4ffffffffffffff
ffff4f4ffffff444ffffff4f44fff4f4ffffff444fffff44f4fffffff4f4ffffff4ffffffff4f4ffffff4f4ffffffff4fffff74f4ffffff4f4ffffffffffffff
ffff4f4ffffffff4ffffff4ffffff4f4ffffff4ffffffffff4fffffff4f4ffffff4ffffffffff4ffffff4f4ffffffff4ffffff4ffffffff4f4ffffffffffffff
fffff5ffffffff5fffffffffffffff5ffffffff5ffffffffffffffffff5ffffffff5fffffffffffffffff5ffffffff5fffffffffffffffff5fffffffffffffff
ffff55fffffff55ffffffff5ffffff55fffffff55fffffff5ffffffff55fffffff55ffffffff5ffffffff55fffffff55fffffff5ffffffff55ffffffffffffff
fffff9ffffffff9fffffff55ffffff9ffffffff9ffffffff55ffffffff9ffffffff9fffffff55ffffffff9ffffffff9ffffffff55fffffff9fffffffffffffff
fffff9ffffffff9ffffffff9ffffff9ffffffff9ffffffff9fffffffff9ffffffff9ffffffff9ffffffff9ffffffff9ffffffff9ffffffff9fffffffffffffff
ffff555ffffff555fffffff9fffff555ffffff555fffffff9ffffffff555ffffff555fffffff9fffffff555ffffff555fffffff9fffffff555ffffffffffffff
fff55555ffff55555fffff555fff55555ffff55555fffff555ffffff55555ffff55555fffff555fffff55555ffff55555fffff555fffff55555fffffffffffff
759f4445f759f444f5fff55555ff5444f9575f444f957f55555fffff54445ffff5444f9fff55555ffff94445ffff9444f9fff55555fff5f444f9ffffffffffff
ffff5549fffff554f9759f4495ff9455ffff9f455fffff5944f957fff4559fffff455fffff54445ffff55549ffff5554fffff94449fff9f554ffffffffffffff
ffff5f5ffffff5f5ffffff554ffff5f5ffffff5f5ffffff455fffffff5f5ffffff5f5ffffff455fffff75f5fffff75f5fffff5554ffffff5f5ffffffffffffff
ffff5f5ffffff555ffffff5f55fff5f5ffffff555fffff55f5fffffff5f5ffffff5ffffffff5f5ffffff5f5ffffffff5fffff75f5ffffff5f5ffffffffffffff
ffff5f5ffffffff5ffffff5ffffff5f5ffffff5ffffffffff5fffffff5f5ffffff5ffffffffff5ffffff5f5ffffffff5ffffff5ffffffff5f5ffffffffffffff
fffff5fffffffffffffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffff55fffffffffffffffff55fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff9fffffffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff9fffffffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f00f555fffffffffffffff555f00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff95555fffffffffffffff55559fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f759544fffffffffffffff445957ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffff554fffffffffffffff455fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffff5f5fffffffffffffff5f5fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbb88bbbbbbbbbbbbb
ffff5f5fffffffffffffff5f5fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbb7777788777bbbbbbbbbb
ffff5f5fffffffffffffff5f5fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbb777777667777bbbbbbbbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb1bbbbbbbbbbb7f77777cc777f7bbbbbbbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb11bb5bbbddddf777777cc7777f7bbbbbbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb9bb5bbbddddd7f77777dd777f7fdddddbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb9bb9bbbddddd7f6666666666f77ddddddb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb11111bbbdddddf649446449446f7dddddd7
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb1111bbb5ddddd64449464449446fdddddd7
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbdddbbbb5d111164444964444944ddddddd5
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb1111bbb511110dd6666d6666666600011d7
ff1fffff1ffff1fffff1fffff0fffff0ffff0fffff0fffffffffffffffffffffffffffffffffffffffffffffffffb1bb1bbb51110166d666d6666666d1110117
ff1fffff1ffff1fffff1f1fff0fffff0ffff0fffff0f0ffffffffffffff0ffffffffffffffffffffffffffffffff11bb1bbb588110006666d666666d60001115
f111fff1111f111fff111fff000fff0000f000fff000fffff00fffffff000fffffffffffffffffffffffffffffffbb1bbbbb511100000666d666666600000115
11111f1111111111ff11fff00000f0000000000ff00ffffff00fffffff000fffffffffffffffffffffffffffffffbb11bbbbb51100100666666666660010015b
1111f1111111111fff11fff0000f0000000000fff00fffff0000ffff0f000fffffffffffffffffffffffffffffffbb9bbbbbbbbb00001bbbbbbbbbbb00001bbb
f111fff11111111fff111fff000fff00000000fff000ffff0000ffff0f000fffffffffffffffffffffffffffffffbb9bbb55bbbbb111bbbbbbbbbbbbb111bbbb
f1f1fff1f1ff1f1ff11f1fff0f0fff0f0ff0f0ff00f0fff000000ff0000f0fffffffffffffffffffffffffffffffb111119bbbbddddddddddddddddddbbbbbbb
f1f1fff1f1ff1f1fffffffff0f0fff0f0ff0f0fffffffff000000ff000ffffffffffffffffffffffffffffffffff1111bbbbbbdddddddddddddd88ddddbbbbbb
f1f1fff1f1ff1f1fffffffff0f0fff0f0ff0f0ffffffff00f00f00f000ffffffffffffffffffffffffffffffffff19ddbbbbbbdddddddddddddd11ddd6dbbbbb
fffffffffffff1fffff1ffffffffffffffff1fffff1fffffffffffffffffffffffffffffffffffffffffffffffffb111bbbbbbddddddddddddddddddd76dbbbb
ff1fffff1ffffefffffefefff1fffff1ffffefffffefeffffffffffffff1ffffffffffffffffffffffffffffffffb1b1bbbbbb1dddddddddddddddddd676ddbb
f1e1fff1e22f111fff111fff1e1fff1e22f111fff111fffff11fffffff1e1fffffffffffffffffffffffffffffffb1b1bbbbbb1111111111111111111677dddb
11111f111e22111eff11fff11111f111e22111eff11ffffffeefffffff111fffffffffffffffffffffffffffffffb1b1bbbbbb110101011010111d555167dddb
1e11fe1e1122111fff11fff1e11fe1e1122111fff11fffff1111ffff1fe1efffffffffffffffffffffffffffffffbbbbbbbbbb1101010110101115d55516dddb
f111fff11122111fff111fff111fff11122111fff111ffff1111ffffef111ffffffffffffffffffffbbbbbbbbebebb1bbbbbbb11010101101011155d5551ddd7
f1f1fff1f1ff1f1ff11f1fff1f1fff1f1ff1f1ff11f1fff111111ff1111f1ffffffffffffffffffffbbbbbbbb1b1bb11bbbbb5110101011010111111111111d7
f1f1fff1f1ff1f1fffffffff1f1fff1f1ff1f1fffffffff111111ff111ffffffffffffffbb88e8bbbbbbbbbbb111bb9bbbbbb511111111111111111111111115
f1f1fff1f1ff1f1fffffffff1f1fff1f1ff1f1ffffffff11feef11f111ffffffffffffffb8288e8bbbbbbbbbb1e1bb9bbbbbb511110001111111111110001117
fffffffffffffefeffffffffffffffffffffffffffffffffffffffffffffffffffffffffb28ee7ebbbbbbbbbb111b111bbbbb581101110111111111101110117
ff1ffffffffff1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffb8288eebbbbbbbbbb111b1111b5bb581110001111111111110001115
f1e1fffffffff111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffb8288eebbbbbbbbbb111bdd119b5b511100000111111111100000115
11111ffffff001e1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffbd888e6bbbbbbbbbb1b1b111bbbbbb5550010055555555550010055b
15151fffff000111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb6667bbbbbbbbb221b1b1bb1bbbbbbbb00001bbbbbbbbbb00001bbb
f151fffffffff111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbb2221b111bb1bbbbbbbbb111bbbbbbbbbbbb111bbbb
f1f1fffffffff111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1fffffff221f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1ffffff2221f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
1111fffffffff1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
1111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
1111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffdddd22200000111122220202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffdddd00000000111122222020ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
b333ffffdddd02220000111122220202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffdddd00000000111122222020ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffdddd22021111dddd0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
333bffff666644451111dddd0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffff666655551111dddd0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3bb3ffff666654441111dddd0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffff6666555500000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5fffff5ffffff2ff
3333ffff6666445400000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5fffff2ffffff2ff
bbbbffffffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55ffff55fffff22f
bbbbffffffffffff00000000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55fffff2ffffff2ff
bbbbffffff4ff4ff000a0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff55fff55fffff22ff
8888fffff551155f00aaa000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5fffff2ffffff22f
8888ffff5ffffff50aaaaa00fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5555fff255ffff2ff
8888ffffff8ff8ffaaaaaaa0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5555ff5555fffff2ff
111ffffff551155fa0000000000a0000002222000088e800ff88e8ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff555ff5255fff22ff
111fffff5ffffff5aa00000000aa0000021222d008288e80f8288e8ffffffffffffffffffffffffffffffffffffffffffffffffffffffff55555f52555f2f22f
777fffffffbffbffaaa000000aaa0000012dde20028ee7e0f28ee7efffffffffffffffffffffffffffffffffffffffffffffffffffffff5555ff5555fffff2f2
777ffffff551155faaaa0000aaaa000002122d2008288ee0f8288eefffffffffffffffffffffffffffffffffffffffffffffffffffffffff55ffff55fffff2ff
bbbfffff5ffffff5aaa000000aaa000002122d2008288ee0f8288eeffffffffffffffffffffffffffffffffffffffffffffffffffffffff5555ff5555fff222f
bbbfffffffffffffaa00000000aa00000d222d600d888e60fd888e6fffffffffffffffffffffffffffffffffffffffffffffffffffffff555555555555f2f2f2
888fffffffffffffa0000000000a000000ddd60000666700ff6667ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22ffff22fffff2ff
888fffffffffffff00000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22ffff22fffff2ff
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000100000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000
00000000000011111000000000000000000000000000001110000000000000000000000111110000000000000000000000000000111000000000000000000000
000000000001111d1110000000000000000000000000000111000000000000000000001111d11100000000000000000000000000011100000000000000000000
0000000000011ddddd00000000000000000000000000000ddd0000000000000000000011ddddd0000100000000000000000000000ddd00000000000000000000
000000000001dddddddd0000000000000000000000000001ddd00000000000000000001dddddddd001100000000000000000000001ddd0000000000000000000
000000000001ddd0ddd00000000000000000000000000001ddd00000000000000000001ddd0ddd0011d00000000000000000000001ddd0000000000000000000
000000000001ddd000000110100000000000000000000001ddd11110110001100000001ddd00000111dd1100000000000000000001ddd0110001100000000000
000000000001ddd100001111111000011111001111110001ddd11101111011100000001ddd1000111ddd1000111110001111110001ddd1111011100000000000
000000000001ddd1100001dd1d1100111111100111111001ddd1dddd1dd011dd0000001ddd110000ddddddd1111111000111111001ddd01dd011dd0000000000
000000000000ddd1d1000ddddddd0011ddddd00dddddd001ddddddd0dddd1ddd0000000ddd1d100ddddddd011ddddd000dddddd001ddd0dddd1ddd0000000000
000000000000dddddd1001ddddddd01ddddddd00dddddd01dddddd001ddd1ddd0000000dddddd1001ddd0001ddddddd000dddddd01ddd01ddd1ddd0000000000
0000000000000dddddd001ddd1ddd01ddd1ddd1111dddd01ddddddd01ddd1ddd00000000dddddd001ddd0001ddd1ddd01111dddd01ddd01ddd1ddd0000000000
0000000000000000dddd01ddd1ddd01ddd1ddd111ddddd01ddd1ddd01ddd1ddd00000000000dddd01ddd0001ddd1ddd0111ddddd01ddd01ddd1ddd0000000000
00000000000000001ddd01ddd1ddd01ddd1ddd1ddddddd01ddd1ddd01ddd1ddd000000000001ddd01ddd0001ddd1ddd01ddddddd01ddd01ddd1ddd0000000000
00000000000000001ddd01ddd1ddd01ddd1ddd1ddd1ddd01ddd1ddd01ddd1ddd000000000001ddd01ddd0001ddd1ddd01ddd1ddd01ddd01ddd1ddd0000000000
00000000000010001ddd01ddd1ddd01ddddddd1ddd1ddd01ddd1ddd01ddd1ddd000000010001ddd01ddd0001ddddddd01ddd1ddd01ddd01ddd1ddd0000000000
00000000000111101ddd01ddd1ddd01dddddd01ddd1ddd01ddd1ddd01ddd1ddd000000111101ddd01ddd0001dddddd001ddd1ddd01ddd01ddd1ddd0000000000
0000000000111d111ddd01ddd1ddd01dddd0001ddd1ddd01ddd1ddd01ddd1ddd00000111d111ddd01ddd0001dddd00001ddd1ddd01ddd01ddd1ddd0000000000
000000000000dddd1ddd11ddd0ddd00ddd11000ddd1ddd11ddd0ddd00ddd1ddd0000000dddd1ddd00ddd1100ddd110000ddd1ddd11ddd00ddd1ddd0000000000
00000000000ddddddddd00ddd0ddd00ddddd000ddddddd00ddd0ddd00ddddddd000000ddddddddd00dddd000ddddd0000ddddddd00ddd00ddddddd0000000000
00000000000000ddddd00dddd00ddd00ddddd000ddddd00dddd00ddd00dddddd000000000ddddd0000ddddd00ddddd0000ddddd00ddddd00dddddd0000000000
000000000000000000000000000000000000000000000000000000000000dddd00000000000000000000000000000000000000000000000000dddd0000000000
0000000000000000000000000000000000000000000000000000000001001ddd000000000000000000000000000000000000000000000001001ddd0000000000
0000000000000000000000000000000000000000000000000000000001111ddd000000000000000000000000000000000000000000000001111ddd0000000000
0000000000000000000000000000000000000000000000000000000000d11ddd000000000000000000000000000000000000000000000000d11ddd0000000000
0000000000000000000000000000000000000000000000000000000000dddddd000000000000000000000000000000000000000000000000dddddd0000000000
00000000000000000000000000000000000000000000000000000000000dddd00000000000000000000000000000000000000000000000000dddd00000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000100ddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddd00100000001000000010000000100000001000000000000000000000000000
00000000000010dddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1dddddd0100000001000000010000000100000000000000010000000000000000000
00000101011111111111111111111111111111111111111111111111111111111111111111111111111111111111111101111101010100000000000000000000
0000000010000ddd10dddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddd0010000000100000001000000010000000100000000000000000000000
000000001000dddd10d2dddd1dddd0dd1ddddddd1ddddddd1ddddddd1ddddddd1dddddd010000000100000001111111111110101000000000000000000000000
000000001000dddd10d2222d1d1d00dd1ddddd221ddddddd1ddddddd1d1166691ddddddd10000000100000001100000000000000000000000000000000000000
00000101111111111112212211111111111112221111111111111111111666669111111111111111111111111101111111111100000000000000000000000000
00001000000d10ddddd2221211d020dddddd1212dddd1ddddddd1ddd1166666669dd1ddddd001000000010000101111111111000000011100000000000000000
0000100000d0100ddd0d2222120220dddddd2122000010dddddd1dd116666666669d1dddddd01000000010000101111101110000000011111000000000000000
00001000000d1000d00d1d1111222dddddd122200000100ddddd1ddddddd11dddddd1dddddd01000000010000101dd1000000000001011111110000000000000
00010111111111111111111111221111111111111111111111111111111149111111111111111111111111111101dd1100000000011011001111100000000000
0000000d10dddd0010d0dd2221111d0d11d21100100000001ddddddd1dd1449d1ddddddd1ddd0000100000001155550000000000111010110011111000000000
0000000d10dddd001000ddd22212100d11111122100000001ddddddd1dd1119d1ddddddd1dddd000100000001100110000000001111010111100111000000000
0000000d10ddddd0100000dd2211022d1211121210000ddd1ddddddd1d1144491ddddddd1dddd00010000000110044110000000011d010111111011000000000
0001111111111111111111111011212112211122111111111111111111222222291111111111111111111111110044110000000011d010111111101000000000
000010000ddd10dddd0010dd0111122dd211122d00001000dddd1ddd1122222229dd1ddddddd1d00000010000100441100000000111010111d11101000000000
000000000ddd10dd00001dd01101120d11212d0000000001000011111111144444449ddddddd1dd0000010000100041000000000010010111111101000000000
000010000ddd10d00d0010d00000100dd1d1112200000010000000000000011111111ddddddd1dd0000010000105541550101010101010111111101000000000
000101111111111111111111100211211121122211000100000000111111444444491111111111111111111111ddd511d0d1d1d1d1d010111111101000000000
0000000d10dddddd1d000dd0002111dd221121200000010000d00011000011111149dddd1ddddddd100000001dddd5d4dd01d1d1d1d010111111101000000000
0000000d10dddddd10000d00121221d2212122000000010d00000010111144444919dddd1ddddddd50000000dd0dddd10dd0d1d1d1d010111111101000000000
0000000d10dddddd100000d01222d1d2221200000000001000000010111494444919dddd1ddddddd555450dd100dd5d100d00000000010111111101000000000
0011011111111111111d11110111111111111111111100100000001011144444491911111111111151140dd1010dd511011d0111111011011111101000000000
0000100000dd10dddddd10000000112dd112100000001000100000110000111111491ddddddd1ddd00001000010ddd11010d0110011011100111101000000000
0000100000dd10dddddd10000022111dd212200000000000010000111111444444491ddddddd1ddd000010000101dd100111d011111011111000101000000000
0000000000dd10dddd001000002112111112120000000000010000110000111111491ddddddd1dd000001000010000000111d01100101101111d011000000000
00001011111111111111111000222121211122111100000000000010111444444919111111111111111111111100000001004441111010100111d11000000000
0000000d100ddddd1d00000000002221111100001000000610000010111494444919dddd1ddddd00100000001000000001114114111010111000111000000000
0000000d1000dddd1ddd0dd010000dd11d1110000000006110000010111444444919dddd1dddd000100000001000010001111111011010111111011000000000
0000000d1000dddd1dddd0001000d111666600000100066c10000011000011111149dddd1ddd0000100000001000011001111111111010111111101000000000
0000010111111111111111111100100011111100100006c6c0000011111144444449111111111111111111111000011001111001111010111111101000000000
00000000000d10dddddd1d00000011116666100010000000000000110000111111491dddddd01000000010000000011001111111111010111111101000000000
00000000000d10dddddd1d00000011116666100001000000000000101114444449191ddddd001000000010000100011001111111111010111111101000000000
00000000000d10dddddd1d00000011116666100000100000000000101114944449191dddd0001000000010000100011001111110111010111111101000000000
00000001011111111111111111000111666611010001000000000010111144444919111111111111111111111100011001111111111010111111101000000000
000000001000000d10dddd0010000100016000000010000000000011000011111149ddd010000000100000001100011001111111111011011111101000000000
000000001000000d10ddddd010000011111000000100000000000011111144444449dd0010000000100000001100011000111111111011100111101000000000
00000000000000000000000000000000000000000000000000000010000000000009000000000000000000000000000000000000000001111001101000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011110011000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddd0ddd00dd0dd000dd0d0d0ddd00dd0ddd000000dd0ddd0ddd0ddd00dd0000000000000000000000000000000000000000000000000d0d0dd000000ddd000
000d00d0d0d0d0d0d0d000d0d0d000d0000d000000d000d0d0ddd0d000d000000000000000000000000000000000000000000000000000d0d00d000000d0d000
000d00dd00d0d0d0d0d000ddd0dd00ddd00d000000d000ddd0d0d0dd00ddd0000000000000000000000000000000000000000000000000d0d00d000000d0d000
000d00d0d0d0d0d0d0d000d0d0d00000d00d000000d0d0d0d0d0d0d00000d0000000000000000000000000000000000000000000000000ddd00d000000d0d000
00ddd0d0d0dd00d0d00dd0d0d0ddd0dd000d000000ddd0d0d0d0d0ddd0dd000000000000000000000000000000000000000000000000000d00ddd00d00ddd000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000100001d050110400c0400204010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000018050190400c0400204010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002900001405013050110000f000070001b0001800016000160001300016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0000050500a0500f050180501f0502e0501f00030050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d00000f0501b0501300000000000000f0000f0000f0000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002f00000c3300c3000c320003000c330003000c320003000c330003000c320003000c3300c3000c3000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000600001d0601c0001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001b05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008001051d711257111d711257111d711007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00800000257711d771257711d77100700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000000
003000000502503005000250000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000000c122031020b1220010200102001020010200102001020010200102001020010200102001020010200102001020010200102001020010200102001020010200102001020010200102001020010200102
001000000524007200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
000900001045110451004011145111451004011245112451004011345113451004011445114451004011545115451394013a4013a4013a4013a40139401004013c40100401004010040100401004010040100401
002700002262303603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603
0001000017131171211813118131191311b1311d1311f121261312f13138131001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
000b0000211552a155361550010537105301052910500105001050010523105211052710522105211052110500105001050010500105001050010500105001050010500105001050010500105001050010500105
0015000002160021000d1000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011500000405300003000030000300003000030000300003040530000300003000030000300003000030000304053000030000300003000030000300003000030405300003000030000300003000030000300003
012a0020041100611507115041100b114041150a11204115041100611507115041100a11204115091140411504110061150711504110091140411507114041150411506110071150611504110011100211503110
011100000b1300a135081300512405120051200513005130051420514205142051520515500100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
011100000142002425004000342004425000000d6230d1330c40006420074250c4000d623084200000004424094200c4000d1330a4220c400044440b4220c4000c4000c4000c4000c4000c400004000040000000
__music__
00 3c3d4344

