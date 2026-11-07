"""Execute the real Profiles module against explicit minimal Roblox service mocks.
This validates mode selection/lifecycle, not DataStore or Studio integration.
"""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
source=(root/'src/server/Profiles.luau').read_text()
fixture=root/'build/ProfileModeTests.luau'
fixture.parent.mkdir(exist_ok=True)
fixture.write_text('local function module(game)\nlocal warn=function(...) end\n'+source+'\nend\n'+'''
local function host(studio,gameId,fail)
 local calls=0
 local service={GetDataStore=function() calls+=1; if fail then error("API unavailable") end; return {} end}
 local fake={GameId=gameId,JobId="test"}
 function fake:GetService(name)
  if name=="RunService" then return {IsStudio=function() return studio end} end
  if name=="DataStoreService" then return service end
  if name=="HttpService" then return {GenerateGUID=function() return "guid" end} end
  error(name)
 end
 return fake,function() return calls end
end
local sim={profile=function() return {coins=100} end}
local fake,calls=host(true,0,true)
local profiles=module(fake).new(sim)
assert(profiles.temporary and calls()==0)
local player={UserId=1}
local p=profiles:load(player); assert(p.coins==100)
p.coins=20; assert(profiles:save(player,false) and profiles.loaded[player].coins==20)
assert(profiles:save(player,true) and not profiles.loaded[player])
assert(profiles:load(player).coins==100)
print("PASS unpublished Studio uses isolated temporary state and resets on rejoin")
for _,case in {{true,123},{false,123},{false,0}} do
 local live,n=host(case[1],case[2],false)
 local profile=module(live).new(sim)
 assert(not profile.temporary and n()==1)
end
print("PASS published Studio and all live servers select DataStore")
local published,n=host(true,123,true)
assert(not pcall(function() module(published).new(sim) end))
assert(n()==1)
print("PASS published API failure never falls back to a temporary profile")
''')
subprocess.run([str(root/'.tools/bin/luau'),str(fixture)],cwd=root,check=True)
