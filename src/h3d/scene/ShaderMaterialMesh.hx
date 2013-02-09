package h3d.scene;

import h3d.mat.ShaderMaterial;
/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
class ShaderMaterialMesh<T:hxsl.Shader> extends Mesh
{
	public var shaderMaterial:ShaderMaterial<T>;
	
	public function new(prim, ?mat:ShaderMaterial<T>, ?parent)
	{
		shaderMaterial = mat;
		super(prim, null, parent);
	}
	
	@:access(h3d.mat.ShaderMaterial)
	override private function draw(ctx:RenderContext) 
	{
		if( shaderMaterial.renderPass > ctx.currentPass ) {
			ctx.addPass(draw);
			return;
		}
		shaderMaterial.setup(this, ctx);
		ctx.engine.selectMaterial(shaderMaterial);
		primitive.render(ctx.engine);
	}
	
	override public function free() 
	{
		if (shaderMaterial != null) shaderMaterial.free();
		super.free();
	}
	
}