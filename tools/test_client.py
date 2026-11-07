"""Exercise real client startup and language button callbacks with UI/service mocks.
Checks text updates and request wiring, not Roblox rendering or input routing.
"""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
source=(root/'src/client/Bootstrap.client.luau').read_text()
pre=r'''
local nativeRequire=require
local Catalog=nativeRequire("../src/shared/Catalog")
local Languages=nativeRequire("../src/shared/Localization")
local Genetics=nativeRequire("../src/shared/Genetics")
local sim=nativeRequire("../src/shared/Simulation").new(Catalog,Genetics,function() return .5 end,function() return "id" end)
local profile=sim.profile()
local function signal() return {Connect=function(self,fn) self.callback=fn; return {} end} end
local methods={}
local mt={__index=function(t,k) return methods[k] or t.props[k] end,__newindex=function(t,k,v) t.props[k]=v; if k=="Parent" and v then table.insert(v.children,t) end end}
Instance={new=function(class)
 return setmetatable({ClassName=class,children={},attrs={},props={Activated=signal(),DescendantAdded=signal()}},mt)
end}
function methods:IsA(class) return self.ClassName==class end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants() local result={}; for _,c in self.children do if not c.destroyed then table.insert(result,c); for _,v in c:GetDescendants() do table.insert(result,v) end end end; return result end
function methods:Destroy() self.destroyed=true end
function methods:FindFirstChild(name) for _,c in self.children do if c.Name==name then return c end end; return self.props[name] end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),name) end
function methods:GetAttribute(key) return self.attrs[key] end
function methods:SetAttribute(key,value) self.attrs[key]=value end
function methods:GetAttributeChangedSignal() return signal() end
UDim2={new=function(...) return {} end,fromOffset=function(...) return {} end,fromScale=function(...) return {} end}
UDim={new=function(...) return {} end}; Vector2={new=function(...) return {} end}
Color3={fromRGB=function(...) return {} end}; TweenInfo={new=function(...) return {} end}
Enum=setmetatable({},{__index=function(t,k) local v=setmetatable({},{__index=function(_,k2) return k2 end}); rawset(t,k,v); return v end})
task={spawn=function() end,delay=function() end,defer=function(fn,...) fn(...) end}
local playerGui=Instance.new("PlayerGui")
local player={LocaleId="en-us",UserId=1,WaitForChild=function() return playerGui end}
local shared={Catalog=Catalog,Localization=Languages}
local remote={InvokeServer=function(self,action,args)
 local ok,msg=true,"ready"
 if action~="Sync" then ok,msg=sim.act(profile,action,args,100,"Sunny") end
 return {ok=ok,message=msg,profile=profile,weather="Sunny",temporary=true}
end}
local rs={Shared=shared,WaitForChild=function(self,key) return if key=="Shared" then shared else remote end}
local service={Players={LocalPlayer=player},ReplicatedStorage=rs,TweenService={Create=function() return {Play=function() end} end},UserInputService={InputBegan=signal(),TouchTapInWorld=signal()},ProximityPromptService={PromptTriggered=signal()}}
local game={GetService=function(_,key) return assert(service[key],key) end}
workspace=Instance.new("Workspace")
local world=Instance.new("Folder"); world.Name="MutationGarden"; world.Parent=workspace
local sign=Instance.new("TextLabel"); sign:SetAttribute("LocaleKey","station_shop"); sign.Parent=world
local prompt=Instance.new("ProximityPrompt"); prompt:SetAttribute("GardenScreen","research"); prompt.Parent=world
local function require(value) return value end
local function runClient()
'''
post=r'''
end
runClient()
local function find(text)
 for _,obj in playerGui:GetDescendants() do if obj.Text==text then return obj end end
 return nil
end
assert(find("Settings")); find("Settings").Activated.callback()
assert(find(Languages.en.language)); find(Languages.en.language).Activated.callback()
assert(profile.settings.language=="ru" and profile.settings.languageChosen)
assert(sign.Text==Languages.ru.station_shop)
assert(prompt.ObjectText==Languages.ru.station_research and prompt.ActionText==Languages.ru.open)
for _,key in {"garden","shop","inventory","research","collection","quests","settings","menu","home","plant","water","harvest"} do
 assert(find(Languages.ru[key]),"Client failed to update: "..key)
end
assert(find(Languages.ru.language))
find(Languages.ru.shop).Activated.callback()
assert(find(Languages.text("ru","shop_item",Languages.ru.p01,Languages.ru.Common,8,25,1)))
assert(not find("Settings") and not find("My garden"))
assert(find("EN")); find("EN").Activated.callback(); assert(profile.settings.language=="en" and find("Settings"))
print("PASS real client language callbacks refresh tabs, HUD, shop, world labels, prompts and saved preference using UI mocks")
'''
f=root/'build/ClientLocaleTests.luau';f.write_text(pre+source+post)
subprocess.run([str(root/'.tools/bin/luau'),str(f)],cwd=root,check=True)
