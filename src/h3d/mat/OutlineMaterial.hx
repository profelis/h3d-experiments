package h3d.mat;
import h3d.scene.Object;
import h3d.scene.RenderContext;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 * 
 * http://blogs.aerys.in/jeanmarc-leroux/2012/01/23/single-pass-cel-shading/
 */
class OutlineShader extends hxsl.Shader
{
	static var SRC = {
		var input : {
			pos : Float3,
			uv : Float2,
			n : Float3,
		};
		
		var camPos:Float3;
		var thickness:Float;
		
		var k:Float;
	
		function vertex( mpos : Matrix, mproj : Matrix ) {
			tuv = input.uv;
			var e = -0.05 < (input.pos - camPos).norm().dp3(input.n);
			k = e;

			var pp = input.pos.xyzw;
			pp.xyz += input.n * e * thickness;
			out = pp * mpos * mproj;
		}
		
		var tuv:Float2;
		
		function fragment( tex : Texture  ) {
			var t = 1 - k;
			out = tex.get(tuv) * t;
		}
	}
}

class OutlineMaterial extends ShaderMaterial<OutlineShader>
{
	public function new()
	{
		super(new OutlineShader());
	}
	
	public var tex:Texture;
	public var thickness = 0.02;
	
	@:access(h3d.scene.Object)
	override function setup(obj:Object, c:RenderContext)
	{
		s.tex = tex;
		s.thickness = thickness;
		
		s.mpos = obj.absPos;
		s.mproj = c.camera.m;
		var cpos = c.camera.pos.copy();
		var m = obj.absPos.copy();
		m.invert();
		cpos.project(m);
		s.camPos = cpos;
	}
}