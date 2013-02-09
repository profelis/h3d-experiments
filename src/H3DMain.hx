package ;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.Lib;
import flash.Vector;
import h2d.Bitmap;
import h2d.Scene;
import h2d.Scene3D;
import h2d.Tile;
import h2d.TileManager;
import h3d.Color;
import h3d.Engine;
import h3d.fx.Skybox;
import h3d.impl.TextureManager;
import h3d.mat.Material;
import h3d.mat.OutlineMaterial;
import h3d.mat.Texture;
import h3d.prim.Primitive;
import h3d.prim.RawPrimitive;
import h3d.scene.Mesh;
import h3d.scene.Object;
import h3d.scene.RenderContext;
import h3d.stats.Stats;
import h3d.mat.Data;
import h3d.scene.ShaderMaterialMesh;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */

 class Axis implements h3d.IDrawable {

	 var d:Bool;
	public function new(depth = true) {
		d = depth;
	}
	
	public function render( engine : h3d.Engine ) {
		engine.line(0, 0, 0, 50, 0, 0, 0xFFFF0000, d);
		engine.line(0, 0, 0, 0, 50, 0, 0xFF00FF00, d);
		engine.line(0, 0, 0, 0, 0, 50, 0xFF0000FF, d);
	}
	
	public function free() {}
	
}



class H3DMain extends Sprite
{
	
	static function main() 
	{	
		Lib.current.addChild(new H3DMain());
		var s = Lib.current.stage;
		s.align = StageAlign.TOP_LEFT;
		s.scaleMode = StageScaleMode.NO_SCALE;
	}
	
	var engine:Engine;
	var scene:Scene;
	var scene3d:h3d.scene.Scene;
	var tm:TileManager;
	
	@:access(h3d.Engine)
	public function new()
	{
		super();
		
		trace("click to dispose context");
		
		engine = new Engine(0, 0, true, 4);
		engine.onReady = onInit;
		engine.onDisposed = onDisposed;
		engine.debug = true;
		engine.backgroundColor = 0xdddddd;
		
		tm = new TileManager(engine);
		
		Lib.current.stage.addEventListener(MouseEvent.CLICK, function (_) engine.ctx.dispose());
		engine.init();
		
		addChild(new Stats(engine));
	}
	
	function onDisposed()
	{
		trace("disposed");
		
		engine.init(); // reinit
	}
	
	var obj1:ShaderMaterialMesh<OutlineShader>;
	
	var b:Bitmap;
	var tex:Texture;
	var mat:OutlineMaterial;
	
	function onInit()
	{
		addEventListener(Event.ENTER_FRAME, onRender);
		
		var bmp = new flash.display.BitmapData(512, 512);
		bmp.perlinNoise(64, 64, 8, 0, true, true, 7, false);
		tex = tm.makeTexture(bmp);
		//bmp.dispose();
		
		scene = new Scene();
		scene3d = new h3d.scene.Scene();
		
		scene3d.addPass(new Axis());
		
		var s3d = new Scene3D(scene3d, scene);
		
		bmp = new BitmapData(128, 128);
		bmp.perlinNoise(128, 128, 8, 0, true, true, 7, false);
		b = new Bitmap(tm.fromBitmap(bmp), scene);
		b.x = 1;
		b.y = 0;
		
		var n = 100;
		var prim = new h3d.prim.Sphere(n, n << 1);
		prim.addTCoords();
		prim.addNormals();
		
		/*
		var mat = new h3d.mat.MeshMaterial(tex);
		mat.colorMul = new h3d.Vector(1, 1, 1, 0.8);
		mat.blendSrc = Blend.One;
		mat.blendDst = Blend.OneMinusSrcAlpha;*/
		mat = new OutlineMaterial();
		mat.tex = tex;
		obj1 = new ShaderMaterialMesh<OutlineShader>(prim, mat, scene3d);
		obj1.scale(1.5);
		
		engine.onReady = function () {
			trace("rebuild context");
			engine.free();
			scene.free();
			tm.rebuildTextures();
		}
		
		//scene3d.camera.pos = new h3d.Vector(0, 0, 10);
	}
	
	var time = 0.0;
	
	function onRender(_)
	{
		time += 0.01;
		obj1.setRotate(0, 0, time);
		b.rotation = time * 10;
		engine.render(scene);
		
		var o = scene3d.camera.unproject((mouseX - 400)/400, (mouseY - 300)/300, 0);
		var d = scene3d.camera.unproject((mouseX - 400)/400, (mouseY - 300)/300, 1);
		d = d.sub(o);
		//d.normalize();
		//trace(d.length());
		//trace([o, d]);
		
		var a = d.dot3(d);
		var b = 2 * d.dot3(o);
		var c = o.dot3(o) - (1.5*1.5);
		
		var d = b * b - 4 * a * c;
		//trace(d);
		if (d < 0)
		{
			trace("no hint");
			return;
		}
		d = Math.sqrt(d);
		var q = ( -b + (b < 0? -1:1) * d) / 2;
		
		var t0 = q / a;
		var t1 = c / q;
		if (t0 > t1)
		{
			var t = t0;
			t0 = t1;
			t1 = t;
		}
		if (t1 < 0)
		{
			trace("no hit 2");
			return;
		}
		
		trace("hit");
	}
	
	
}