class_name CozyTown
extends Node3D
func _ready():
 name="CozyTownVisualRoot"
 BakeryVisuals.box(self,Vector3(10,-0.3,-5),Vector3(42,0.25,46),Color("#D3DFC6"))
 BakeryVisuals.box(self,Vector3(8.5,-0.14,-4),Vector3(4,0.25,40),Color("#E9DECE"))
 BakeryVisuals.box(self,Vector3(13.5,-0.18,-4),Vector3(6,0.22,40),Color("#B6B5B4"))
 for z in range(-21,16,4):
  BakeryVisuals.box(self,Vector3(13.5,-0.055,z),Vector3(0.12,0.02,1.5),BakeryVisuals.CREAM)
 for z in range(-21,16,2):
  BakeryVisuals.box(self,Vector3(10.4,-0.015,z),Vector3(0.14,0.13,1.9),BakeryVisuals.CREAM)
 for i in 4:
  var at:=Vector3(20,0,-17+i*9)
  var palette:Color=[BakeryVisuals.MINT,BakeryVisuals.LAVENDER,BakeryVisuals.PINK,BakeryVisuals.CARAMEL][i]
  BakeryVisuals.box(self,at+Vector3(0,1.5,0),Vector3(5,3,5.5),palette)
  BakeryVisuals.box(self,at+Vector3(0,3.05,0),Vector3(5.4,0.25,5.9),palette.darkened(0.12))
  BakeryVisuals.box(self,at+Vector3(-2.54,0.8,0),Vector3(0.05,1.6,0.9),Color("#7E6F78"))
  for offset in [-1.8,1.8]:
   BakeryVisuals.box(self,at+Vector3(-2.55,1.8,offset),Vector3(0.07,0.9,0.9),BakeryVisuals.CREAM)
   BakeryVisuals.box(self,at+Vector3(-2.6,1.8,offset),Vector3(0.05,0.7,0.7),Color("#ADCCD1"))
  var label:=BakeryVisuals.label(self,at+Vector3(-2.65,2.7,0),["ЦВЕТЫ","КНИГИ","СОСЕДИ","ПОЧТА"][i],18)
  label.no_depth_test=false
 for z in [-17,-8,1,10]:
  tree(Vector3(10,0,z))
  BakeryVisuals.cylinder(self,Vector3(7.2,0.12,z),0.5,0.22,BakeryVisuals.CARAMEL)
  for i in 5:BakeryVisuals.ball(self,Vector3(7.2+cos(i*TAU/5)*0.3,0.32,z+sin(i*TAU/5)*0.3),0.15,BakeryVisuals.PINK if i%2==0 else BakeryVisuals.LAVENDER)
 for z in [-12,-3,7]:
  BakeryVisuals.cylinder(self,Vector3(10.2,1.2,z),0.045,2.4,Color("#7B7B83"))
  BakeryVisuals.ball(self,Vector3(10.2,2.48,z),0.17,BakeryVisuals.CREAM)
  BakeryVisuals.box(self,Vector3(7.1,0.5,z),Vector3(0.55,0.12,1.5),BakeryVisuals.CARAMEL)
  BakeryVisuals.box(self,Vector3(6.9,0.8,z),Vector3(0.1,0.5,1.5),BakeryVisuals.CARAMEL)
  for dz in [-0.5,0.5]:BakeryVisuals.box(self,Vector3(7.1,0.24,z+dz),Vector3(0.35,0.48,0.08),Color("#7B7B83"))
 var sign:=BakeryVisuals.label(self,Vector3(7.1,2.4,4.35),"SWEET EMPIRE
Добро пожаловать",20)
 sign.no_depth_test=false
func tree(at:Vector3):
 BakeryVisuals.cylinder(self,at+Vector3(0,0.7,0),0.12,1.4,BakeryVisuals.CARAMEL.darkened(0.2))
 var crown:=BakeryVisuals.ball(self,at+Vector3(0,1.9,0),0.8,BakeryVisuals.MINT.darkened(0.1));crown.scale=Vector3(0.8,1.2,0.8)
