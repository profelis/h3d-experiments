package h3d.mat;
import h3d.scene.Object;
import h3d.scene.RenderContext;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class ShaderMaterial<T:hxsl.Shader> extends Material
{
	var s:T;
	
	public function new(shader:T)
	{
		super(s = shader);
	}
	
	function setup(obj:Object, context:RenderContext) throw "not implemented";
	
	override public function free() 
	{
		if (s != null) s.free();
		super.free();
	}
}