"""Run procedural construction and ownership against minimal Roblox value mocks.
This does not render a scene or replace Studio QA.
"""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
source=(root/'src/server/World.luau').read_text()
prefix=r'''
local V={}; V.__index=function(t,k) if k=="Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z) end; return V[k] end
Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},V) end}
V.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
V.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
V.__mul=function(a,b) if type(a)=="number" then a,b=b,a end; return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
V.__div=function(a,b) return a*(1/b) end
local CF={}; CF.__mul=function(a,b) return a end
CFrame={new=function(...) return setmetatable({},CF) end,Angles=function(...) return setmetatable({},CF) end,lookAt=function(...) return setmetatable({},CF) end}
Color3={fromRGB=function(...) return {} end,fromHSV=function(...) return {} end}
UDim2={fromOffset=function(...) return {} end,fromScale=function(...) return {} end}
UDim={new=function(...) return {} end}
Enum=setmetatable({},{__index=function(t,k) local v=setmetatable({},{__index=function(_,key) return key end}); rawset(t,k,v); return v end})
Random={new=function(seed) return {NextNumber=function(self,a,b) return if a then (a+b)/2 else .5 end} end}
local object={}
function object:SetAttribute(k,v) self.attributes[k]=v end
function object:GetAttribute(k) return self.attributes[k] end
function object:GetChildren() return table.clone(self.children) end
function object:FindFirstChildOfClass(class) for _,c in self.children do if c.ClassName==class then return c end end end
function object:Destroy() self.destroyed=true; if self.Parent then for i,c in self.Parent.children do if c==self then table.remove(self.Parent.children,i); break end end end end
local mt={__index=function(t,k) return object[k] or t.properties[k] end,__newindex=function(t,k,v) t.properties[k]=v; if k=="Parent" and v then table.insert(v.children,t); if t.ClassName=="TextLabel" then v.TextLabel=t end end end}
Instance={new=function(class) return setmetatable({ClassName=class,children={},attributes={},properties={CFrame=CFrame.new()}},mt) end}
workspace=Instance.new("Workspace")
local lighting=Instance.new("Lighting")
local game={GetService=function() return lighting end}
local function loadWorld()
'''
post=r'''
end
local Catalog=require("../src/shared/Catalog")
local Genetics=require("../src/shared/Genetics")
local sim=require("../src/shared/Simulation").new(Catalog,Genetics,function() return .4 end,function() return "id" end)
local world=loadWorld().new(Catalog)
assert(#world.plots==8)
local player={UserId=42,DisplayName="Gardener"}
local index=world:claim(player); assert(index==1 and player.RespawnLocation==world.plots[1].spawn)
local p=sim.profile(); world:render(index,p,sim,Genetics)
assert(#world.plots[1].cells==12)
p.expansion=5; world:render(index,p,sim,Genetics); assert(#world.plots[1].cells==96)
local positions={}
for i=1,96 do
 local pos=world:cell(world.plots[1],i)-world.plots[1].center
 assert(math.abs(pos.X)<30 and math.abs(pos.Z)<40)
 local key=pos.X..":"..pos.Z; assert(not positions[key]); positions[key]=true
end
print("PASS all 96 cells unique and inside the plot")
assert(sim.act(p,"Plant",{id="p01",cell=1},100,"Sunny")); world:render(index,p,sim,Genetics)
assert(world.visuals.id:GetAttribute("Owner")==42 and world.visuals.id:GetAttribute("Cell")==1)
local before=world.visuals.id; world:render(index,p,sim,Genetics); assert(world.visuals.id==before)
sim.advance(p,200,false); world:render(index,p,sim,Genetics); assert(world.visuals.id~=before)
print("PASS procedural plant attributes and stage-only reconstruction")
for _,cfg in Catalog.plants do
 for stage=0,4 do
  world:model({id="example",seed=1,mutations={}},cfg,Vector3.new(0,0,0),stage,world.root,Genetics.phenotype(Genetics.create(function() return .4 end)))
 end
end
print("PASS all 40 species construct at five stages with mocked values")
world:release(1); assert(not world.plots[1].owner and not player.RespawnLocation and #world.plots[1].cells==0 and not world.visuals.id)
print("PASS plot release removes cells, visuals and respawn binding")
'''
fixture=root/'build/WorldTests.luau'
fixture.write_text(prefix+source+post)
subprocess.run([str(root/'.tools/bin/luau'),str(fixture)],cwd=root,check=True)
